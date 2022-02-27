#!/usr/bin/env python3

from dataclasses import dataclass
from datetime import datetime
import sys


def curr_time() -> str:
    d = datetime.now()
    return f"{d.hour:02d}:{d.minute:02d}:{d.second:02d}"


@dataclass
class Progress:
    repeat_i: int
    repeat_times: int
    start_to_last_r: int  # seconds
    this_r: int  # seconds
    last_r_duration: int = 0

    @property
    def done_i(self):
        return self.repeat_i - 1

    @property
    def s_per_r(self):
        return max(1, self.start_to_last_r / self.done_i)

    @property
    def pct_this_r(self):
        return self.this_r / self.s_per_r

    @property
    def frac_pct_total(self):
        return self.pct_this_r / self.repeat_times

    @property
    def r_pct(self):
        return self.done_i / self.repeat_times

    @property
    def pct_total(self):
        return self.r_pct + self.frac_pct_total

    @property
    def r_to_go(self):
        return (self.repeat_times - self.done_i) - self.pct_this_r

    @property
    def eta_min(self):
        return self.r_to_go * self.s_per_r / 60

    @property
    def total_min(self):
        return self.repeat_times * self.s_per_r / 60

    def progress_string(self):
        parts = [
            f"{curr_time()}",
            f"{self.repeat_i}/{self.repeat_times}",
            f"{self.start_to_last_r}+{self.this_r}s",
        ]
        if self.last_r_duration > 0:
            parts.append(f"L:{self.last_r_duration}s")
        if self.repeat_i <= 1:
            parts.extend([
                f"-% / -%",
                f"ETA: ? min (total: ? min)",
            ])
        else:
            parts.extend([
                f"{self.pct_total:.1%} / {self.pct_this_r:.1%}",
                f"ETA: {self.eta_min:.1f} min (T:{self.total_min:.1f}m)",
            ])
        return  " | ".join(parts)


def main():
    repeat_i, repeat_times, start_to_last_r, this_r = map(int, sys.argv[1:5])
    last_r_duration = 0
    if len(sys.argv) > 5:
        last_r_duration = int(sys.argv[5])
    this_prog = Progress(repeat_i, repeat_times, start_to_last_r, this_r, last_r_duration=last_r_duration)
    print(this_prog.progress_string())


if __name__ == "__main__":
    main()
