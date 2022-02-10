use crate::hash::*;
use crate::types::*;
use getrandom::getrandom;
use itertools::{sorted, Itertools};
use lazy_static::lazy_static;
use lru::LruCache;
use rand::prelude::*;
use rand::seq::IteratorRandom;
use std::cmp::Ordering;
use std::collections::VecDeque;
use std::fmt::Debug;
use std::hash::{Hash, Hasher};
use std::iter::{FromIterator, IntoIterator};
use std::sync::{Arc, Mutex};
use std::{fmt, fmt::Display};
use twox_hash::RandomXxh3HashBuilder64;
use twox_hash::Xxh3Hash64;

pub type TxId = u64;
pub type TxInCache = Transaction;

lazy_static! {
    static ref TX_CACHE: Mutex<PassThruHashMap<TxId, Arc<TxInCache>>> =
        Mutex::new(Default::default());
    static ref TX_LRU: Mutex<LruCache<TxId, Arc<TxInCache>>> =
        Mutex::new(LruCache::new(1024));
    // static ref DAGBLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
    //     Mutex::new(Default::default());
    // static ref DAGBLOCK_LRU: Mutex<LruCache<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
    //     Mutex::new(LruCache::new(1024));
    // static ref HASHER: twox_hash::Xxh3Hash64 = Default::default();
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ReflectionData {
    pub chain: HashID,
    pub block: HashID,
    pub weight: Difficulty,
    pub proving_ancestor_id: HashID,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Transaction {
    /// Trivial transaction (for testing)
    HelloWorld(u64),
    /// Normal transaction type
    SendFromTo { from: u64, to: u64, value: u64 },
    /// Tx for reflecting other blocks
    ReflectAndProve(ReflectionData),
    /// Load some balances in the genesis block (this tx should be invalid outside the genesis block)
    GenesisBalance { account: u64, value: u64 },
    /// Used to check doublespends
    AtomicOnce(u64),
}

impl Transaction {
    pub fn id(&self) -> TxId {
        self.get_hash()
    }

    pub fn get_hash(&self) -> TxId {
        let mut hasher: Xxh3Hash64 = Default::default();
        self.hash(&mut hasher);
        hasher.finish()
    }

    pub fn get_cached_tx(id: TxId) -> Option<Arc<TxInCache>> {
        TX_LRU.lock().ok().and_then(|mut c| {
            c.get(&id).map(|tx| tx.clone()).or_else(|| {
                TX_CACHE
                    .lock()
                    .ok()
                    .and_then(|c| c.get(&id).map(|tx| tx.clone()))
            })
        })
    }

    pub fn set_cached_tx(tx: TxInCache) {
        let tx_id = tx.get_hash();
        let tx_arc = Arc::new(tx);
        TX_LRU.lock().unwrap().put(tx_id, tx_arc.clone());
        TX_CACHE.lock().unwrap().insert(tx_id, tx_arc.clone());
    }

    pub fn get_reflection_data(&self) -> Option<&ReflectionData> {
        match self {
            Transaction::ReflectAndProve(r) => Some(r),
            _ => None,
        }
    }

    pub fn get_reflected_weight(&self, chain_id: HashID) -> Difficulty {
        // todo: the chain== check here broke stuff, I don't think it'd every be true.
        self.get_reflection_data()
            // .map(|r| if r.chain == chain_id { r.weight } else { 0 })
            .map(|r| r.weight)
            .unwrap_or(0)
    }

    pub fn is_reflect_and_prove(&self) -> bool {
        match self {
            Transaction::ReflectAndProve(_) => true,
            _ => false,
        }
    }

    pub fn is_reflecting(&self, b: HashID, chain_id: HashID) -> bool {
        match self {
            Transaction::ReflectAndProve(ReflectionData { block, chain, .. }) => {
                b == *block && *chain == chain_id
            }
            _ => false,
        }
    }

    pub fn reflecting_ancestor_of_chain(&self, c_id: HashID) -> Option<HashID> {
        match self {
            Transaction::ReflectAndProve(ReflectionData { chain, block, .. }) if *chain == c_id => {
                Some(*block)
            }
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::transactions::Transaction::*;

    #[test]
    fn txs_have_different_hashes() {
        let tx0 = HelloWorld(0);
        let tx0_dup = HelloWorld(0);
        let tx2 = HelloWorld(2);
        assert_ne!(tx0.id(), tx2.id());
        assert_eq!(tx0.id(), tx0_dup.id());

        let tx3 = GenesisBalance {
            account: 123,
            value: 123,
        };
        assert_ne!(tx0.id(), tx3.id());

        // match int passed to tx0
        let tx_atomic0 = AtomicOnce(0);
        let tx_atomic2 = AtomicOnce(2);
        assert_ne!(tx0.id(), tx_atomic0.id());
        assert_ne!(tx2.id(), tx_atomic2.id());
        assert_ne!(tx_atomic0.id(), tx_atomic2.id());
    }
}
