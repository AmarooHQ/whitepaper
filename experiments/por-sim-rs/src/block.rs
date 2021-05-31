use crate::hash::hash_u128;
use getrandom::getrandom;
use rand::prelude::*;
use rand::seq::IteratorRandom;
use std::fmt::Debug;
use std::hash::Hash;
use std::{fmt, fmt::Display};

pub trait BlockT: Clone + Debug + Display + PartialEq + Eq + PartialOrd + Ord + Hash {
    fn new(ts: u32, parent: u128, d: u64) -> Self;
    fn new_from(ts: u32, parent_opts: Vec<u128>, d: u64) -> Self;
    fn genesis(ts: u32) -> Self;
    fn get_hash(&self) -> u128;
    // fn hash_sha3(&self) -> u128;
    fn prev(&self) -> u128;
    fn all_prev(&self) -> Vec<u128>;
    fn get_ts(&self) -> u32;
    fn increment_nonce(&mut self);
    fn get_difficulty(&self) -> u64;
    fn set_difficulty(&mut self, d: u64);

    fn get_rand_id() -> u128 {
        // Self::get_urand_id()
        thread_rng().gen()
    }

    fn get_urand_id() -> u128 {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        u128::from_be_bytes(e)
    }

    fn select_parent_from<C: IntoIterator<Item = u128>>(ps: C) -> u128 {
        ps.into_iter().choose(&mut rand::thread_rng()).unwrap()
    }

    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self;
}

pub trait SingleParentBlockT: BlockT {}

pub trait ManyParentsBlockT: BlockT {
    fn new_multi_parent(timestamp: u32, parents: Vec<u128>, d: u64) -> Self;
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Block {
    pub id: u128,
    pub parent: u128,
    pub timestamp: u32,
    pub d: u64,
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
    fn new(ts: u32, parent: u128, d: u64) -> Self {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        let id = u128::from_be_bytes(e);
        Self {
            id,
            timestamp: ts,
            parent,
            d,
        }
    }

    fn new_from(ts: u32, parent_opts: Vec<u128>, d: u64) -> Self {
        Self::new(ts, Self::select_parent_from(parent_opts), d)
    }

    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0);
        g.id >>= 10;
        g.parent = g.id;
        g
    }

    /* fn hash_sha3(&self) -> u128 {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs = &self.parent.to_be_bytes()[..];
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, parent_bs, ts_bs].concat());
        u128::from_be_bytes(r[..16].try_into().unwrap())
        // u128::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    } */

    fn get_hash(&self) -> u128 {
        self.id
    }

    fn prev(&self) -> u128 {
        self.parent
    }

    fn all_prev(&self) -> Vec<u128> {
        vec![self.parent]
    }

    fn get_ts(&self) -> u32 {
        self.timestamp
    }

    fn increment_nonce(&mut self) {
        self.id = hash_u128(self.id);
    }

    fn get_difficulty(&self) -> u64 {
        self.d
    }
    fn set_difficulty(&mut self, d: u64) {
        self.d = d;
    }

    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= u128::MAX >> n_bits;
        self.clone()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct DagBlock {
    pub id: u128,
    pub parents: Vec<u128>,
    pub timestamp: u32,
    d: u64,
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
    fn new_multi_parent(timestamp: u32, parents: Vec<u128>, d: u64) -> Self {
        DagBlock {
            timestamp,
            id: Self::get_rand_id(),
            parents,
            d,
        }
    }
}

impl BlockT for DagBlock {
    fn new(timestamp: u32, parent: u128, d: u64) -> Self {
        Self::new_multi_parent(timestamp, vec![parent], d)
    }
    fn new_from(ts: u32, parent_opts: Vec<u128>, d: u64) -> Self {
        Self::new_multi_parent(ts, parent_opts, d)
    }
    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0);
        g.parents = vec![g.id];
        g
    }
    fn get_hash(&self) -> u128 {
        self.id
    }
    /* fn hash_sha3(&self) -> u128 {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs: Vec<[u8; 16]> = self.parents.iter().map(|p| p.to_be_bytes()).collect();
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, &parent_bs[..].concat(), ts_bs].concat());
        u128::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    } */
    fn prev(&self) -> u128 {
        self.parents[0]
    }
    fn all_prev(&self) -> Vec<u128> {
        self.parents.clone()
    }
    fn get_ts(&self) -> u32 {
        self.timestamp
    }
    fn increment_nonce(&mut self) {
        self.id = hash_u128(self.id);
        // let bs = &self.id.to_be_bytes()[..];
        // let h = &Sha3_256::digest(bs)[..16];
        // self.id = u128::from_be_bytes(h.try_into().unwrap());
    }
    fn get_difficulty(&self) -> u64 {
        self.d
    }
    fn set_difficulty(&mut self, d: u64) {
        self.d = d;
    }
    #[cfg(debug_assertions)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= u128::MAX >> n_bits;
        self.clone()
    }
}

mod tests {
    use super::*;

    #[test]
    fn hash_sha3() -> Result<(), String> {
        let b = Block::genesis(0);
        // let _h = b.hash_sha3();
        // DagBlock::genesis(0).hash_sha3();
        Ok(())
    }
}
