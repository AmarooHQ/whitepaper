#!/usr/bin/env python3

import sys

repeat_i, repeat_times, start_to_last_r, this_r = map(int, sys.argv[1:])

pct_total = 0
eta_min = 0
total_min = 0

if repeat_i > 1:
    done_i = repeat_i - 1
    s_per_r = start_to_last_r / done_i
    pct_this_r = this_r / s_per_r
    frac_pct_total = pct_this_r / repeat_times
    r_pct = done_i / repeat_times
    pct_total = r_pct + frac_pct_total
    r_to_go = (repeat_times - done_i) - pct_this_r
    eta_min = r_to_go * s_per_r / 60
    total_min = repeat_times * s_per_r / 60

print(f"{repeat_i}/{repeat_times} | {start_to_last_r} +{this_r} s | {pct_total:.1%} | ETA: {eta_min:.1f} min (total: {total_min:.1f} min)")
