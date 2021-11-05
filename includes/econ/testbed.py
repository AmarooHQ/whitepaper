from math import *
from datetime import date, datetime, timedelta


btc_blocks_per_yr = 2016 * 26

def btc_reward(b: int, start_block: int = 0, r: float = 50):
    if r == 0:
        return 0
    if b < start_block:
        raise Exception('b < start_b')
    # halving every 4 yrs -- 4 yrs to get to 1/2 supply
    # starts w/ 50
    blocks_d = b - start_block
    if blocks_d > 4 * btc_blocks_per_yr:
        return btc_reward(b, start_block + 4 * btc_blocks_per_yr, r / 2)

    return r

def block_n_to_ts(b):
    return datetime(2009, 1, 3, 0) + b * timedelta(seconds=600)

print('\n'.join(list(str((block_n_to_ts(b), btc_reward(b))) for b in range(1000, 1_000_000, 5_000))))

t = 0
for b in range(0, 1_000_000):
    t += btc_reward(b)
    if b % 1000 == 0:
        print(block_n_to_ts(b).isoformat(), f"Supply: {t}")
