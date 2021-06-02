use crate::block_metadata::BlockMD;
use crate::hash::*;
use crate::types::*;
use getrandom::getrandom;
use lazy_static::lazy_static;
use lru::LruCache;
use rand::prelude::*;
use rand::seq::IteratorRandom;
use std::fmt::Debug;
use std::hash::Hash;
use std::iter::{FromIterator, IntoIterator};
use std::sync::{Arc, Mutex};
use std::{fmt, fmt::Display};

lazy_static! {
    static ref BLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(Block, BlockMD<Block>)>>> =
        Mutex::new(Default::default());
    static ref BLOCK_LRU: Mutex<LruCache<u64, Arc<(Block, BlockMD<Block>)>>> =
        Mutex::new(LruCache::new(1024));
    static ref DAGBLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
        Mutex::new(Default::default());
    static ref DAGBLOCK_LRU: Mutex<LruCache<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
        Mutex::new(LruCache::new(1024));
}

pub trait BlockT: Clone + Debug + Display + PartialEq + Eq + PartialOrd + Ord + Hash {
    // note: this doesn't work b/c lazy_static inits those things as a Struct apparently.
    // const MY_CACHE: Mutex<PassThruHashMap<u64, Arc<(Self, BlockMD<Self>)>>>;

    fn new(ts: u32, parent: HashID, d: Difficulty) -> Self;
    fn new_from(ts: u32, parent_opts: impl IntoIterator<Item = HashID>, d: Difficulty) -> Self;
    fn genesis(ts: u32) -> Self;
    fn get_hash(&self) -> HashID;
    // fn hash_sha3(&self) -> HashID;
    fn prev(&self) -> HashID;
    fn all_prev(&self) -> Vec<HashID>;
    fn get_ts(&self) -> u32;
    fn set_ts(&mut self, ts: u32);
    fn increment_nonce(&mut self);
    fn get_difficulty(&self) -> Difficulty;
    fn set_difficulty(&mut self, d: Difficulty);

    fn get_rand_id() -> HashID {
        // Self::get_urand_id()
        thread_rng().gen()
    }

    fn get_urand_id() -> HashID {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        u128::from_be_bytes(e) as HashID
    }

    fn select_parent_from<B, C: IntoIterator<Item = B>>(ps: C) -> B {
        ps.into_iter().choose(&mut rand::thread_rng()).unwrap()
    }

    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self;

    fn get_cached_block(id: HashID) -> Option<Arc<(Self, BlockMD<Self>)>>;
    fn set_cached_block(b: (Self, BlockMD<Self>));
}

pub trait SingleParentBlockT: BlockT {}

pub trait ManyParentsBlockT: BlockT {
    fn new_multi_parent(
        timestamp: u32,
        parents: impl IntoIterator<Item = HashID>,
        d: Difficulty,
    ) -> Self;
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Block {
    pub id: HashID,
    pub parent: HashID,
    pub timestamp: u32,
    pub d: Difficulty,
}

impl Display for Block {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Block@{:4} | {:#16x} -> {:#16x}",
            self.timestamp, self.id, self.parent
        )
    }
}

impl SingleParentBlockT for Block {}

impl BlockT for Block {
    fn new(ts: u32, parent: HashID, d: Difficulty) -> Self {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        let id = u128::from_be_bytes(e) as HashID;
        Self {
            id,
            timestamp: ts,
            parent,
            d,
        }
    }

    fn new_from(ts: u32, parent_opts: impl IntoIterator<Item = HashID>, d: Difficulty) -> Self {
        Self::new(ts, Self::select_parent_from(parent_opts), d)
    }

    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0);
        g.id >>= 10;
        g.parent = g.id;
        g
    }

    /* fn hash_sha3(&self) -> HashID {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs = &self.parent.to_be_bytes()[..];
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, parent_bs, ts_bs].concat());
        HashID::from_be_bytes(r[..16].try_into().unwrap())
        // HashID::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    } */

    fn get_hash(&self) -> HashID {
        self.id
    }

    fn prev(&self) -> HashID {
        self.parent
    }

    fn all_prev(&self) -> Vec<HashID> {
        vec![self.parent]
    }

    fn get_ts(&self) -> u32 {
        self.timestamp
    }

    fn set_ts(&mut self, ts: u32) {
        self.timestamp = ts
    }

    #[inline]
    fn increment_nonce(&mut self) {
        // self.id = hash_u128(self.id);
        self.id = hash_u64(self.id);
    }

    fn get_difficulty(&self) -> Difficulty {
        self.d
    }
    fn set_difficulty(&mut self, d: Difficulty) {
        self.d = d;
    }

    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= HashID::MAX >> n_bits;
        self.clone()
    }

    fn get_cached_block(id: HashID) -> Option<Arc<(Self, BlockMD<Self>)>> {
        BLOCK_LRU.lock().ok().and_then(|mut c| {
            c.get(&id).map(|b| b.clone()).or_else(|| {
                BLOCK_CACHE
                    .lock()
                    .ok()
                    .and_then(|c| c.get(&id).map(|b| b.clone()))
            })
        })
    }

    fn set_cached_block(b: (Self, BlockMD<Self>)) {
        let b_id = b.0.get_hash();
        let b_arc = Arc::new(b);
        BLOCK_LRU.lock().unwrap().put(b_id, b_arc.clone());
        BLOCK_CACHE.lock().unwrap().insert(b_id, b_arc.clone());
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct DagBlock {
    pub id: HashID,
    pub parents: Vec<HashID>,
    pub timestamp: u32,
    d: Difficulty,
}

impl Display for DagBlock {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "DagBlock@{:4} | {:#16x} -> {:?}",
            self.timestamp, self.id, self.parents
        )
    }
}

impl ManyParentsBlockT for DagBlock {
    fn new_multi_parent(
        timestamp: u32,
        parents: impl IntoIterator<Item = HashID>,
        d: Difficulty,
    ) -> Self {
        DagBlock {
            timestamp,
            id: Self::get_rand_id(),
            parents: Vec::from_iter(parents),
            d,
        }
    }
}

impl BlockT for DagBlock {
    fn new(timestamp: u32, parent: HashID, d: Difficulty) -> Self {
        Self::new_multi_parent(timestamp, vec![parent], d)
    }
    fn new_from(ts: u32, parent_opts: impl IntoIterator<Item = HashID>, d: Difficulty) -> Self {
        Self::new_multi_parent(ts, parent_opts, d)
    }
    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0);
        g.parents = vec![g.id];
        g
    }
    fn get_hash(&self) -> HashID {
        self.id
    }
    /* fn hash_sha3(&self) -> HashID {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs: Vec<[u8; 16]> = self.parents.iter().map(|p| p.to_be_bytes()).collect();
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, &parent_bs[..].concat(), ts_bs].concat());
        HashID::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    } */
    fn prev(&self) -> HashID {
        self.parents[0]
    }
    fn all_prev(&self) -> Vec<HashID> {
        self.parents.clone()
    }
    fn get_ts(&self) -> u32 {
        self.timestamp
    }
    fn set_ts(&mut self, ts: u32) {
        self.timestamp = ts
    }
    #[inline]
    fn increment_nonce(&mut self) {
        // self.id = hash_u128(self.id);
        self.id = hash_u64(self.id);
        // let bs = &self.id.to_be_bytes()[..];
        // let h = &Sha3_256::digest(bs)[..16];
        // self.id = HashID::from_be_bytes(h.try_into().unwrap());
    }
    fn get_difficulty(&self) -> Difficulty {
        self.d
    }
    fn set_difficulty(&mut self, d: Difficulty) {
        self.d = d;
    }
    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= HashID::MAX >> n_bits;
        self.clone()
    }

    fn get_cached_block(id: HashID) -> Option<Arc<(Self, BlockMD<Self>)>> {
        DAGBLOCK_LRU.lock().ok().and_then(|mut c| {
            c.get(&id).map(|b| b.clone()).or_else(|| {
                DAGBLOCK_CACHE
                    .lock()
                    .ok()
                    .and_then(|c| c.get(&id).map(|b| b.clone()))
            })
        })
    }

    fn set_cached_block(b: (Self, BlockMD<Self>)) {
        let b_id = b.0.get_hash();
        let b_arc = Arc::new(b);
        DAGBLOCK_LRU.lock().unwrap().put(b_id, b_arc.clone());
        DAGBLOCK_CACHE.lock().unwrap().insert(b_id, b_arc.clone());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_sha3() -> Result<(), String> {
        let _b = Block::genesis(0);
        // let _h = b.hash_sha3();
        // DagBlock::genesis(0).hash_sha3();
        Ok(())
    }
}
