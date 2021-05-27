from collections import OrderedDict
import dataclasses
from functools import reduce
from operator import ne
import os
from math import exp
from random import randint, random, choice
from typing import Callable, Dict, Generic, Literal, TypeAlias, TypeVar
from abc import ABC, abstractmethod
from dataclasses import asdict, dataclass
from .block import SimpleBlock, TBlock


@dataclass
class BlockMetaData:
    height: int
    difficulty: int
    measured_f_nHz: int
    block_time: int

    def __str__(self) -> str:
        return f"{asdict(self)}"


B = TypeVar("B", bound=TBlock)
BlockMD = TypeVar("BlockMD", bound=BlockMetaData)
E = TypeVar("E")
R = TypeVar("R")
T = TypeVar("T")
T2 = TypeVar("T2")


class Fmap(Generic[T], ABC):

    @abstractmethod
    def map(self, f: Callable[[T], "Fmap[T2]"]) -> "Fmap[T2]":
        pass


@dataclass(frozen=True)
class OK(Generic[R]):
    result: R

    def map(self, f):
        return f(self.result)


@dataclass(frozen=True)
class Err(Generic[E]):
    msg: E

    def map(self, f):
        return self


BlockResult = OK[TBlock] | Err[str]


@dataclass(frozen=True)
class Some(Generic[R]):
    val: R


BlockValidationResult = Err[str] | OK[BlockMetaData]

Ord = Literal["gt", "eq", "lt"]


@dataclass
class BestOf(Generic[B]):
    compare: Callable[[B, B], Ord]
    curr_best: list[B] = dataclasses.field(default_factory=list)

    def _get_a_best(self):
        return choice(self.curr_best)

    def put(self, thing: B):
        if len(self.curr_best) == 0:
            self.curr_best.append(thing)
            return

        _cmp = self.compare(thing, self._get_a_best())
        match _cmp:
            case "lt":
                return
            case "eq":
                self.curr_best.append(thing)
            case "gt":
                self.curr_best = [thing]

    def get(self) -> list[B]:
        return self.curr_best

    def get_one(self) -> B:
        return self._get_a_best()


def simple_block_cmp(b1: TBlock, b2: TBlock) -> Ord:
    w_diff = b1.sigma_weight - b2.sigma_weight
    if w_diff > 0:
        return "gt"
    if w_diff == 0:
        return "eq"
    return "lt"


class TChain(Generic[B, BlockMD], ABC):
    def __init__(self, genesis: B, genesis_meta: BlockMD) -> None:
        self.genesis = genesis
        self.blocks = OrderedDict[int, B]()
        self.blocks[genesis.id] = genesis
        self.best = BestOf(simple_block_cmp)
        self.best.put(genesis)
        self.blocks_meta = dict[int, BlockMD]({genesis.id: genesis_meta})


    def __str__(self) -> str:
        return f"{self.__class__.__name__}(blocks=[{self.blocks.get(0, None)}, ...])"

    @abstractmethod
    def add_block(self, b: B) -> bool:
        pass

    @abstractmethod
    def draft_block(self, ts: int) -> B:
        pass

    @abstractmethod
    def chain_heads(self) -> list[B]:
        pass

    @abstractmethod
    def block_validation_test(self, block: B) -> BlockValidationResult:
        pass


class SimpleChain(Generic[B], TChain[B, BlockMetaData]):
    MbBlock = Some[B] | None

    TARGET_BYTES = 8
    MAX_TARGET = 256**TARGET_BYTES
    BLOCK_TIME_GOAL = 10
    FREQUENCY_GOAL_nHz = 10**9 // BLOCK_TIME_GOAL

    def add_block(self, b: B) -> BlockResult:
        invalid_res = self.block_validation_test(b)
        match invalid_res:
            case Some(err):
                return Err(err)
        p = self.blocks[b.parent]
        p_meta = self.blocks_meta[p.id]
        self.blocks[b.id] = b
        self.best.put(b)
        self.blocks_meta[b.id] = BlockMetaData(
            p_meta.height + 1,
            self.next_difficulty(p),
            self.measure_nHz(p),
            b.timestamp - p.timestamp
            )
        return OK(b)

    def draft_block(self, ts: int):
        p = self.best.get_one()
        d = self.calc_next_difficulty(p)
        # take 2 fewer bytes than target to simulate luckiest/best attempt
        new_id = int.from_bytes(os.urandom(self.TARGET_BYTES - 2), byteorder='big')
        return p.__class__(new_id, p.id, 1, p.sigma_weight + 1, ts)

    def chain_heads(self):
        return super().chain_heads()

    def block_validation_test(self, b: B) -> BlockValidationResult:
        if b.parent not in self.blocks:
            return Err(f"Unknown Parent {b.parent}")
        p = self.blocks[b.parent]
        p_meta = self.blocks_meta[p.id]

        next_diff = self.next_difficulty(p)
        target = self.target_from_difficulty(next_diff)
        if b.id > target:
            return Err(f"Invalid Seal (PoW ({b.id}) does not meet target ({target}))")

        if b.sigma_weight != b.weight + p.sigma_weight:
            return Err(f"Incorrect Sigma Weight {b.sigma_weight}")

        return OK(BlockMetaData(p_meta.height + 1, next_diff, self.measure_nHz(p), b.timestamp - p.timestamp))

    def calc_next_difficulty(self, p: B):
        # last_ten = reduce()
        pass

    def blocks_ancestor(self, b: B, n_generations: int) -> MbBlock:
        _b = b
        for _ in range(n_generations):
            if _b.parent not in self.blocks or n_generations < 0:
                return None
            if _b.parent == self.genesis.id:
                return None
            _b = self.blocks[_b.parent]
        return Some(_b)

    def height_of(self, b: B) -> int:
        return self.blocks_meta[b.id].height

    def next_difficulty_ethlike(self, p: B) -> int:
        if p.id == 0:
            return 2**17
        old_p = self.blocks[p.parent]
        delta_ts = (p.timestamp - old_p.timestamp)
        assert delta_ts > 0
        modifier = max(1 - delta_ts // self.BLOCK_TIME_GOAL, -99)
        old_diff = self.blocks_meta[old_p.id].difficulty
        new_diff = old_diff + old_diff * modifier // 1024
        return max(new_diff, 1024)

    def next_difficulty_pde(self, b: B) -> int:
        p = self.blocks[b.parent]
        p_meta = self.blocks_meta[p.id]
        p_diff = p_meta.difficulty
        prev_nHz = self.measure_nHz(p)
        a = 100
        f_prime = (prev_nHz - self.FREQUENCY_GOAL_nHz) // a
        return p_diff + p_diff * f_prime // prev_nHz

    def next_difficulty_daa2(self, b: B) -> int:
        sum_last = 100
        # sum_last = 2048
        b_with_ancestors = self.get_with_n_ancestors(b, sum_last - 1)
        block_time_sum = sum(self.blocks_meta[_b.id].block_time for _b in b_with_ancestors)
        win_rate_sum = sum(self.blocks_meta[_b.id].difficulty for _b in b_with_ancestors)
        return self.BLOCK_TIME_GOAL * win_rate_sum // block_time_sum

    def get_with_n_ancestors(self, b: B, n: int) -> list[B]:
        ancestors = [b]
        c = b
        for _ in range(n):
            c = self.blocks[c.parent]
            ancestors.append(c)
        return ancestors

    def next_difficulty(self, b: B) -> int:
        return self.next_difficulty_daa2(b)

    def measure_nHz(self, b: B) -> int:
        if b.id == 0:
            return self.FREQUENCY_GOAL_nHz
        p = self.blocks[b.parent]
        return self.blocks_meta[b.id].measured_f_nHz * 90 // 100 + 10**9 // (b.timestamp - p.timestamp) * 10 // 100

    def target_from_difficulty(self, d: int) -> int:
        return self.MAX_TARGET // d
