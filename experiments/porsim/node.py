from abc import ABC
from queue import Empty
from .chain import BlockMetaData, Err, OK, TChain
from .block import TBlock
from logging import Logger
from random import randint, random
from typing import ClassVar, TypeVar, Tuple, Literal, Generic, Union
from dataclasses import dataclass
import dataclasses
from .sim_types import *
import multiprocessing as mp


B = TypeVar("B", bound=TBlock)
C = TypeVar("C", bound=TChain[TBlock, BlockMetaData])
P = TypeVar("P")


@dataclass
class Msg(Generic[P], ABC):
    ty: ClassVar[str]
    pl: P


class MsgBlock(Msg[B]):
    ty = "block"


class MsgPeer(Msg[str]):
    ty = "peer"


# @dataclass
# class NodeMsg(Generic[B]):
#     msg: MsgBlock[B] | MsgPeer


NodeMsg = Union[MsgBlock[B], MsgPeer]


@dataclass
class NodeQs():
    from_network: "mp.Queue[NodeMsg[TBlock]]"
    to_network: "mp.Queue[NodeMsg[TBlock]]"
    clock: "mp.JoinableQueue[ClockSig]"


@dataclass
class Node(Generic[C]):
    logger: Logger
    qs: NodeQs
    chain: C
    id: int = dataclasses.field(default_factory=lambda: randint(0, 2**24))

    def __str__(self):
        return f"{self.__class__.__qualname__}(id={self.id})"

    def run(self):
        self.logger.info(f"{self}: run() called. Current chain: {self.chain}.")
        try:
            while True:
                ticker = self.qs.clock.get()
                match ticker:
                    case "stop":
                        self.logger.info(f"{self}: Stopping!")
                        self.qs.clock.task_done()
                        return
                    case "tock":
                        self.logger.debug(f"{self}: Tock (NOP)")
                    case ("tick", ts):
                        self.logger.debug(f"{self}: Tick")
                        self._run_tick(ts)
                self.qs.clock.task_done()
        except KeyboardInterrupt as e:
            self.logger.warning(f"{self}: Terminating -- Ctrl+C")

    def _run_tick(self, ts: int):
        """
        Run an individual tick.

        Steps:
        - consume all incoming messages
        - try to produce a block if we can
        - send all outgoing messages (implicit in mining)
        """
        self._run_tick_consume_incoming(ts)
        self._run_tick_mine(ts)


    def _run_tick_consume_incoming(self, ts: int):
        while True:
            try:
                next = self.qs.from_network.get_nowait()
                if isinstance(next, MsgBlock):
                    b = next.pl
                    self.logger.debug(f"{self}: Got block {b}")
                    match self.chain.add_block(b):
                        case Err(e):
                            self.logger.warning(f"{self} found error ({e}) during add_block({b})")
            except Empty as e:
                break

    def _run_tick_mine(self, ts: int):
        for _ in range(10):
            new_b = self.chain.draft_block(ts)
            match self.chain.block_validation_test(new_b):
                case OK(b_meta):
                    self.logger.info(f"Found New Block: {new_b} w/ {b_meta}.")
                    self.qs.to_network.put(MsgBlock(new_b))
                    return
