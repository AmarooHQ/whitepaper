\begin{comment}

# Sharing Security with AuxPow

\todo{reread and edit - merged mining}

The security of Proof of Work depends on solutions to a challenge problem being *difficult to find* (e.g., time consuming, expensive, etc). The problem itself can differ between PoW methods, but, in each method, eventually a potential solution is verified via some function, and that verification method *must* be far more efficient than the generation method. Proof of Stake, in principle, operates the same way. The reason that solutions in Proof of Stake systems are difficult to find is because the rules that are imposed restrict the generation of solutions. Typically users are typically penalized if they break those rules.

*Verification Function*: the function that miners must satisfy for their proof to be valid.

In Bitcoin, the verification function is roughly:

```haskell
-- `target` is a large number inversely proportional to the network 'difficulty'
btcVerify target btcBlockHeader = target > hash btcBlockHeader
```

NB: in reality, Bitcoin's target can be calculated directly from its header; I am omitting this detail here to keep the examples simple.

Note that all relevant data for a Bitcoin block (the parent block, consensus details, included transactions, etc) are implied *exactly* by the block-header. It is *crucial* that we are able to *unambiguously* determine which data has been 'rolled up' in a given proof.

## AuxPoW (aka Merged Mining)

Miners commit to a specific *extension* (or *update*, *block*) to a network's *history* (it's *blockchain*, or *ledger*) by generating proofs (*mining*) that include a *single and unambiguous* group of non-conflicting transactions. That's what *mining* is. When generating the proofs for consensus mechanisms (PoW, PoS, PoA, etc), the miners (or auditors, or bakers, or w/e) have some control over the contents of the block they're generating. If they are able to include some arbitrary data in their draft block -- which ensures that data will be 'rolled up' into the proof -- then their generated solution(s) imply the knowledge of, and intent to include, said arbitrary data in the proof.

If miners are able to commit some *additional* data, which is also singular and unambiguous, could that data be used in a way that takes advantage of the work associated with the proof? Yes. In principle there is no significant difference between each data that can be shown to be included in a proof; the only significant factor is whether such data can be proven to have been included with appropriate properties for its intended use.

What do I mean by ``appropriate properties for its intended use''?

Let's look at a simple (fictional) method of merged mining in the context of Bitcoin. Take this partial pseudo-description of a bitcoin block:

```yaml
# block-structure.yaml
block:
  txs:
    # the coinbase transaction
    - inputs: []
      outputs:
        - { type: P2PKH, to: "<miner's address>", value: 50 }
        - { type: OP_RETURN, data: "<hash of a Namecoin block>", value: 0 }
```

We could write a verification function for Namecoin that looked like:

%%TC:ignore
```haskell
-- note: `target` comes from the *Namecoin* header, not the Bitcoin header
nmcVerify target btcBlockHeader btcBlock nmcBlockHeader
  = if nmcBlockImplicitInBtcBlock
    then btcVerify target btcBlockHeader
    else false
  where
    btcHeaderOkay = checkHeader btcBlockHeader btcBlock
    btcCoinbaseTx = getCoinbase btcBlock
    -- the data from the first OP_RETURN output or ""
    coinbaseAuxData = fromMaybe "" $ getAuxDataFrom btcCoinbaseTx
    nmcBlockImplicitInBtcBlock
      = btcHeaderOkay && coinbaseAuxData == hash nmcBlockHeader
```
%%TC:endignore

This is to say: the validity of a Namecoin block is based on it's singular and unambiguous inclusion in a Bitcoin block, and the *work* (in PoW) is calculated based on the hash of the Bitcoin block, not the Namecoin block. This indirection is why merged mining is referred to as *Auxiliary PoW* or AuxPoW; a Bitcoin miner can generate valid blocks for *both* Bitcoin and Namecoin *simultaneously*.

Is this example verification function one that could work? In principle, *yes* (though there are practical considerations that would make this particular verification function decisively worse than alternatives).

A requirement for this method (or any other) is that there is an *unambiguous* way to determine the precise intended addition to Namecoin's blockchain. In the example above, it is required that the Namecoin block hash is the exact data in the *first* OP_RETURN output. If the Namecoin block hash could be in *any* OP_RETURN output, then we would not be able to tell, *unambiguously*, if it was the *precise and only* intended update to the Namecoin ledger. Perhaps the miner included *multiple* Namecoin block hashes; if they did (and if they could be in any OP_RETURN output) then they might be able to publish *multiple, different* updates, which would violate the earlier conditions we've specified for valid updates.

In the case of Bitcoin/Namecoin merged mining, that is what I mean by ``appropriate properties for its intended use'' (though there are additional and different required properties in reality). However we choose to interpret the data behind a proof of work, we must be able to know it *exactly* and know that it was *intended*. Without that, we cannot meaningfully use the proof of work to secure a 'child' blockchain.

\end{comment}
