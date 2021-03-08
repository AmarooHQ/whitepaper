## Scaling Complexity Analysis of *Ultra Terminum*

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the scaling ideas proposed for other networks (polkadot, eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other networks.

### Complexity of Dapp-Chains

Dapp-chains look and act like typical shards; i.e. dapp-chains are 'child' chains of some 'parent' chain. If we presume that all chains have some constant maximum capacity (similar to the block-limit in Bitcoin and gas-limit in Ethereum) then calculating the scaling complexity is straight-forward and typical.

NB: capacity is often discussed in *transactions per second* (tps) or in terms of maximum block size and block production rate. For example, Bitcoin's block production rate is 1/600 blocks/sec (given a 10 minute block target time) and Ethereum's is 1/15 blocks/sec (given a 15 second block target time). Since Bitcoin's block limit is 1 000 000 bytes (though, practically it's slightly more due to segwit), Bitcoin's capacity is approx 1670 bytes/sec. Ethereum's capacity is approx 3100 bytes/sec[^1]. Readers familiar with the architecture of both Bitcoin and Ethereum will realize that this is not really a fair comparison as there are significant differences between each network's method of state management. In the context of this analysis we are't too concerned with that; these numbers are here to give us reasonable expectations and enable both sanity checking and order-of-magnitude estimates.

[^1]: Ethereum's capacity is slightly harder to calculate in bytes/sec since we need to convert from gas/sec to bytes/sec. Averaging the size of blocks 11949129 to 11949134 (which were all above 98% gas utilization) gives 46896 bytes per block, or 3126.4 bytes/sec.

Each dapp-chain has some maximum capacity, `k bytes/sec/dchain`, and some header-size `h bytes/header`. Additionally, there is some average block production rate per dapp-chain: `b blocks/sec/dchain`. The parent chain also has some maximum capacity, which we set equal to the dapp-chains' capacity, `k bytes/sec/pchain` (nb: since there is only one parent-chain we can omit the `pchain` component from these units). We can choose `k` to fit with reasonable expectations about each nodes' computational capacity, `c`. Note that `O(k) = O(c)`; throughput grows with computational capacity (naturally).

The parent chain can host multiple dapp-chains. If it is *only* hosting dapp-chains, then, at maximum capacity, each parent-block will be full of headers for dapp-chains. That is, a parent chain can handle up to `k/h headers/sec/pchain = k/h headers/sec`. We've said that there is, on average, `b blocks/sec/dchain`, and headers have a 1:1 relationship to blocks. Thus we can say that we can support up to `k/bh dchains`.

*Total capacity* (or throughput) of a parent-child architecture, like this, is the sum of the capacity of all child-chains. Each child chain has `k` capacity. Since we have `k/bh dchains` total, we can say that the total throughput is approximately `k/bh dchains * k bytes/sec/dchain = k^2/bh bytes/sec`. Since `b` and `h` are constants, a parent-child architecture like this has total capacity in `O(k^2) = O(c^2)`. Given previous research, this is the expected result.

todo: is 'in' correct to use, as used in "has total capacity in `O(k^2) = O(c^2)`"?

### Complexity of PoW Reflection

- similar to above

k space in each block split between headers of other chains + transactions; `k = k[tx] + k[r]`

`k[r]` bytes/sec shared between all the headers of other chains, so we get `k[r]/bh rchains` - note that these `b` and `h` are for PoW reflected chains (block times and header sizes of reflected chains might be diff to those of dapp-chains).

we end up with `k[tx]*k[r]/bh` throughput --> roughly `space for txs * space for headers / header size / header frequency`

to maximize `k[tx]*k[r]` we set `k[tx] = k[r] = k/2` => so final calc is `k^2/4bh` => scales with `O(k^2) = O(c^2)`.

### Complexity of UT

Basically, replace `k[tx]` with dapp-chain headers. so dapp-chain capacity decreases from `k^2/bh` to `k^2/2bh` (for dapp-chain values of `b` and `h`). but we get to multiply by `k[r]/bh = k/2bh` rchains (for reflected chain values of `b` and `h`).

it's unlikely that `b` and `h` will be the same for reflected parent PoW chains and dapp-chains, but presuming they are:

`total throughput = k^2/2bh * k/2bh = k^3/(4*b^2*h^2)`

we simplify as before, and we have complexity `O(k^3) = O(c^3)`.

the total (`t`) number of dapp-chains we can have is `t = r*d`. We know that `r*h[r] + d*h[d] = k`; i.e. `reflection-chains * size of reflection header + dapp-chains * size of dapp-chain headers = k`. We can use these two to obtain: `t = r*(k - r*h[r])/h[d]` (eliminating the variable `d`). we then get `dt/dr = k/h[d] - 2*r*h[r]/h[d]`. find the maximum at `dt/dr = 0` to yield `r = k/(2*h[r])` at maximum throughput. since `t = r*(k - r*h[r])/h[d] = rk/h[d] - r^2*h[r]/h[d]` we get `t[max] = k^2/(2*h[r]*h[d]) - k^2/(4*h[r]^2) * h[r]/h[d] = 2*k^2/(4*h[r]*h[d]) - k^2/(4*h[r]*h[d]) = k^2/(4*h[r]*h[d])`

thus: the maximum number of dapp chains is given by `k^2/(4*h[r]*h[d])`.

### Some numbers

at 3000 bytes/sec (Ethereum), 60s block times, geom avg 200 byte headers (`sqrt(h[r]*h[d])`), 500 byte avg tx size => UT can do 1,215,000 tps. With just dapp-chains (like polkadot, eth2, etc) those params would give 5,400 tps.

3000 bytes/sec, 60s block times, avg 500 byte headers, 200 byte txs => UT: 486,000 tps; Eth2: 5,400 tps.

(note that UT is v sensitive to header sizes; better to have smaller headers and larger txs if we get a choice)

3000 bytes/sec, 15s block times, avg 500 byte headers, 200 byte txs => UT: 30,375 tps; Eth2: 1,350 tps.

3000 bytes/sec, 150s block times, 500 byte headers, 500 byte txs => UT: 1,215,000 tps; Eth2: 5,400 tps.

3000 bytes/sec, 600s block times, 500 byte headers, 500 byte txs => UT: 19,440,000 tps; Eth2: 21,600 tps.
