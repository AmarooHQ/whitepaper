from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TypeVar


Tx = TypeVar('Tx')


@dataclass(frozen=True)
class TBlock(ABC):
    id: int
    parent: int
    weight: int
    sigma_weight: int
    timestamp: int

    def __str__(self):
        return f"{self.__class__.__name__}({self.id} ⭢ {self.parent})"


@dataclass(frozen=True)
class SimpleBlock(TBlock):
    pass
