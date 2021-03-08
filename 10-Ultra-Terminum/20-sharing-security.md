## Methods of Sharing Security

The security of Proof of Work depends on solutions to a challenge problem being difficult to find (time consuming, expensive, etc). The problem can differ between PoW methods, but eventually a potential solution is verified via some function, and that function *must* be far more efficient than the method of generation. Proof of Stake, in principle, operates the same way. The reason that solutions in Proof of Stake systems are difficult to find is because rules are imposed that restrict the generation of solutions (and users are typically penalised if they break those rules).

*Verification Function*: the function that miners must satisfy for their proof to be valid.

In Bitcoin, the verification function is roughly:

```haskell
-- `target` is a large number inversely proportional to the network 'difficulty'
btc_verify target btc_block_header = target > hash btc_block_header
```

**TODO**: replace snake case names with camel case.

NB: in reality, Bitcoin's target can be calculated directly from its header; I am omitting this detail here to keep the examples simple.

Crucially, the interpretation of data 'rolled up' in a proof must be *unambiguous*.

### AuxPoW (aka Merged Mining)

Miners commit to a specific *extension* (or *update*, *block*) to a blockchain's *history* (it's *blockchain*, or *ledger*) by generating proofs (*mining*) that include a *single and unambiguous* group of non-conflicting transactions. When generating the proofs for consensus mechanisms (PoW, PoS, PoA, etc), the miners (or auditors, or bakers, or w/e) have some control over the contents of the block they're generating. If they are able to include some arbitrary data in their draft block -- which ensures that it will be 'rolled up' into the proof -- then their generated solution(s) imply the knowledge of, and intent to include, said arbitrary data in the proof.

If miners commit some *additional* data, which is also singular and unambiguous, could that not also be used in a way that takes advantage of the work associated with the proof? Yes. In principle there is no significant difference between each data that can be shown to be included in a proof; the only significant factor is whether such data can be proven to have been included with appropriate properties for its intended use.

What do I mean by "appropriate properties for its intended use"?

Let's look at a simple (fictional) method of merged mining in the context of Bitcoin. Take this partial pseudo-description of a bitcoin block:

```yaml
block:
  txs:
    # the coinbase transaction
    - inputs: []
      outputs:
        - { type: P2PKH, to: "<miner's address>", value: 50 }
        - { type: OP_RETURN, data: "<hash of a Namecoin block>", value: 0 }
```

We could write a verification function for Namecoin that looked like:

```haskell
nmc_verify target btc_block_header btc_block nmc_block_header
  = if nmc_block_implicit_in_btc_block
    then target > hash btc_block_header
    else false
  where
    btc_header_okay = check_header btc_block_header btc_block
    btc_coinbase_tx = get_coinbase btc_block
    -- the data from the first OP_RETURN output or ""
    coinbase_aux_data = fromMaybe "" $ getAuxDataFrom btc_coinbase_tx
    nmc_block_implicit_in_btc_block
      = btc_header_okay && coinbase_aux_data == hash nmc_block_header
```

This is to say: the validity of a Namecoin block is based on it's singular and unambiguous inclusion in a Bitcoin block, and the *work* (in PoW) is calculated based on the hash of the Bitcoin block, not the Namecoin block. This indirection is why merged mining is referred to as *Auxiliary PoW* or AuxPoW; a Bitcoin miner can generate valid blocks for *both* Bitcoin and Namecoin *simultaneously*.

Is this example verification function one that could work? In principle, *yes* (though there are practical considerations that would make this particular verification function decisively worse than alternatives).

A requirement for this method (or any other) is that there is an *unambiguous* way to determine the precise intended addition to Namecoin's blockchain. In the example above, it is required that the Namecoin block hash is the exact data in the *first* OP_RETURN output. If the Namecoin block hash could be in *any* OP_RETURN output, then we would not be able to tell, *unambiguously*, if it was the *precise and only* intended update to the Namecoin ledger. Perhaps the miner included *multiple* Namecoin block hashes; if they did (and if it was allowed) then they might be able to publish *multiple, different* updates, which would violate the earlier conditions we've specified for valid updates.

In the case of Bitcoin/Namecoin merged mining, that is what I mean by "appropriate properties for its intended use" (though there are additional and different required properties in reality). However we choose to interpret the data behind a proof of work, we must be able to know it *exactly* and know that it was *intended*. Without that ability, we cannot meaningfully use the proof of work to secure a blockchain.

### Microchains

A *microchain* (coined by Gav Wood in 2014) is the concept of a small and highly restrictive blockchain; the purpose of which is to create an *abstraction layer* separating the *consensus mechanism* from *transactions and state transitions*. A microchain can thus support *multiple different and independent* (transaction, state) schemes -- in effect this means supporting multiple "blockchains" via a single consensus mechanism. Seen in this way, microchains are a generalised form of merged mining where one proof can support multiple different blocks, each belonging to a different blockchain. In today's language this might be described as a single blockchain with multiple heterogeneous shards. End users could synchronise only those shards they cared about, but miners would need to fully validate *all* shards to ensure they didn't build on invalid histories. Miners could opt to extend only a subset of shards if the protocol supported it.

NB: one problem is the requirement for miners to validate all shards; we'll dissolve that problem later.

https://xk.io/2014/08/27/microchains/

Here is a demonstrative example of a data structure for a basic microchain:

```
type MicroBlockHeader =
  ( Hash      -- previous MicroBlockHeader's hash
  , Integer   -- nonce for mining
  , Metadata  -- metadata like timestamp, etc
  , Hash      -- the root of the MicroBlock
  )

-- The keys of this MPT of type ChainID, and the values of type ShardUpdate.
-- The ShardUpdate values must be valid for the corresponding chain.
type MicroBlock = MerklePatriciaTree ChainID ShardUpdate
```

The idea of microchains, within Ethereum, eventually grew into the more sophisticated *chain fibers* via the work of Gav Wood and other Ethereum devs in 2014/5. With chain fibers, the "blockchains", i.e. (transaction, state) schemes, are called *fibres*, *subspaces*, or *strata* (although their technical definitions and exact properties differ to what I've described above). Since then, many more descendant ideas have been created, like Eth2's *beacon chain and shards*, Polkadot's *relay chain and parachains*, and, as we'll soon see, *Ultra Terminum*.

https://blog.ethereum.org/2015/04/05/blockchain-scalability-chain-fibers-redux/
https://ethereum.org/en/eth2/beacon-chain/
ref: polkadot whitepaper

### a bit wrong about microchains (I posted this to forum a few days after posting the above)

microchains aren't a blockchain of their own in the simplest construction.

e.g., like BTC and NMC now, if they were using a microchain then their proofs would be:

- branch + header -> does root meet difficulty? -> if 'yes' then valid

If the chains have different difficulty requirements then some proofs will be valid for one but not the other. (this is sorta the point of merged mining, a valid NMC block doesn't need to be a valid BTC block)

But this means that we can't have a common history via the microchain (or at least can't guarantee we'll have one).

One reason for this is that BTC/NMC blocks calc difficulty to produce blocks at a certain rate. if miners can choose their difficulty then they can choose the same difficulty in both NMC and BTC (this can be done via DAGs).

DAGs also give us a way to deal with conflicting transactions (we include them and flag them), so we can merge histories even if they have incompatible txs (we just take all the good txs). the flagging of invalid txs is done in *future* blocks, not current ones. (they still can't include txs that break rules according to *that block's* history, tho; then the whole block is invalid)

So if a miner can be sure that a PoW can be valid on both chains then we can make rules about requiring them to produce valid updates for all chains they mergemine. how?

If the chains *within* a 'microchain' reflect eachother then we can detect which blocks are included as valid and which are not. do they end up in the common history?

say BTC has the rule 'your mining reward is nonzero if all your updates are vaild on all chains, otherwise it's zero'



--  i think i overlooked something previously but it's fixable (particularly: microchains don't have state, and aren't actually a chain of their own).
