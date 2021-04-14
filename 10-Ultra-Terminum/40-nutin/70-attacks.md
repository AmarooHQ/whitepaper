## Attacks

### 51% and double-spends

\todo{discuss 51 percent and how difficult it is in UT vs Bitcoin, et al.}

need to do 51% attacks on 51% of simplex chains

similar to how you can theoretically win govt in a democracy by winning 51% of votes in 51% of electorates => only 25% of total votes. it's still harder than winning 51% of votes in one seat, tho.

### Poisoning the Well

\todo{the deliberate and malicious production of malformed data}

- e.g. making blocks with valid PoW but invalid contents so that they get reflected

### Selfish Mining

\todo{discuss selfish mining, and how it doesn't work}

- PoW reflection means that withholding blocks is a big disadvantage b/c you want the network (and other chains) to know about them ASAP.

### DAG based attacks

- creating lots of DAG blocks to link back to with low PoW
- more backlinks -> larger headers -> lower total throughput

### other attacks?

\todo{find some}

### dialog between Max and Nef

\mk{
    idea is to have a dialog between me and a fictional attacker (Nef, for *nefarious*) where we talk through attacks and mitigation.
}
