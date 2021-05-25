"""
Types used throughout porsim.
"""

from typing import Literal


Coords = tuple[float, float]
ClockSig = tuple[Literal["tick"], int] | Literal["tock", "stop"]
