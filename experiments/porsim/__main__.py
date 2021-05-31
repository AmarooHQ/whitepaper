"""
layers:
  - network -- peers + relay stuff between nodes (blocks to start with, mb txs too)
  - consensus -- mine and build a chain; calc best block tips and state
  - incentives -- track impact to miners' / attacker's profit/loss type stuff

basic idea:
- use a broadcast system using input and output queues for each node
- abstract these bits:
  - block production: variance, probabilities, difficulty, etc (don't actually do real hashing)
  - chain method: blockchain, GHOST, inclusive, PoR, whatever
  - network: mb include stuff to introduce delays later on
"""

import cProfile

from collections import defaultdict
import logging
import multiprocessing as mp
from typing import Any, Callable, DefaultDict, List, Literal, Tuple
from dataclasses import dataclass
from random import random
import time

from .sim_types import *
from .node import *
from .chain import BlockMD, BlockMetaData, SimpleChain
from .block import SimpleBlock, TBlock


logger = mp.log_to_stderr(logging.INFO)


NexusQs = DefaultDict[str, List[Tuple["mp.Queue[NodeMsg[TBlock]]", Coords]]]


class BroadcastNexus():
    def __init__(self):
        # distribute msgs to these qs
        self.listener_qs: NexusQs = defaultdict(list)
        # check these for incoming msgs
        self.broadcast_qs: NexusQs = defaultdict(list)
        # queue for managing tick/tock of simulation cycles
        self.clock_qs: List[mp.JoinableQueue[ClockSig]] = list()

    def reg_listen_q(self, network: str, coords: Coords = (0, 0)) -> "mp.Queue[NodeMsg[TBlock]]":
        q = mp.Queue()
        self.listener_qs[network].append((q, coords))
        return q

    def reg_send_q(self, network: str, coords: Coords = (0, 0)) -> "mp.Queue[NodeMsg[TBlock]]":
        q = mp.Queue()
        self.broadcast_qs[network].append((q, coords))
        return q

    def reg_clock_q(self) -> "mp.JoinableQueue[ClockSig]":
        q = mp.JoinableQueue(maxsize=1)
        self.clock_qs.append(q)
        return q

    def reg_all(self, network: str, coords: Coords = (0, 0)) -> NodeQs:
        return NodeQs(
            self.reg_listen_q(network, coords),
            self.reg_send_q(network, coords),
            self.reg_clock_q()
        )

    def send_c(self, sig: ClockSig):
        for q in self.clock_qs:
            q.put(sig)
        for q in self.clock_qs:
            q.join()

    def run_clock(self, tick_limit=100):
        for ts in range(1, tick_limit + 1):
            try:
                # self.send_c("tock")
                if ts % 100 == 0:
                    logger.info(f"## TICK NUMBER: {ts}")
                self.send_c(("tick", ts))
                # process any new msgs
                for _n, qs in self.broadcast_qs.items():
                    for q, _ in qs:
                        while q.qsize() > 0:
                            m = q.get()
                            for q_out, _ in self.listener_qs[_n]:
                                q_out.put(m)
                # sleep while debugging
                # time.sleep(0.1)
            except KeyboardInterrupt as e:
                logger.warning(f"run_clock got ctrl+c")
                return
        self.send_c("stop")


nexus = BroadcastNexus()


def simple_chain_factory() -> SimpleChain:
    return SimpleChain(genesis=TBlock(0, 0, 1, 1, 0), genesis_meta=BlockMetaData(0, 2**20, SimpleChain.FREQUENCY_GOAL_nHz, SimpleChain.BLOCK_TIME_GOAL))


def mk_node(network: str, chain_f: Callable[[], TChain[B, BlockMD]] = simple_chain_factory) -> Node[TChain[B, BlockMD]]:
    coords = (random(), random())
    qs = nexus.reg_all(network, coords)
    node = Node(logger, qs, chain_f())
    return node


def main(n_nodes=50):
    nodes = list(mk_node('net_1') for _ in range(n_nodes))
    logger.debug(f"Nodes: {nodes}")
    logger.debug(f"Clocks: {nexus.clock_qs}")
    ps = list(mp.Process(target=n.run) for n in nodes)
    list(p.start() for p in ps)
    nexus.run_clock(tick_limit=1000)
    logger.info("Main: run_clock finished.")
    list(p.join() for p in ps)
    # except KeyboardInterrupt as e:
    #     list(p.terminate() for p in ps)
    #     list(p.join() for p in ps)
    logger.info("Main: done.")


if __name__ == "__main__":
    # cProfile.run('main()')
    main()
