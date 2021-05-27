use getrandom::getrandom;
use rand::seq::IteratorRandom;
use sha3::{Digest, Sha3_256};
use std::convert::TryFrom;
use std::fmt::Debug;
use std::hash::Hash;
use std::slice::Iter;

pub trait BlockT: Clone + Debug + PartialEq + Eq {
    fn new(ts: u32, parent: u128) -> Self;
    fn genesis(ts: u32) -> Self;
    fn hash(&self) -> u128;
    fn hash_sha3(&self) -> u128;
    fn prev(&self) -> u128;
    fn get_ts(&self) -> u32;
    fn increment_nonce(&mut self);

    fn get_rand_id() -> u128 {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        u128::from_be_bytes(e)
    }

    // fn select_parent_from(ps: &[u128]) -> u128 {
    //     *ps.iter().choose(&mut rand::thread_rng()).unwrap()
    // }
}

pub trait ManyParentsBlockT: BlockT {
    fn new_multi_parent(timestamp: u32, parents: Vec<u128>) -> Self;
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Block {
    pub id: u128,
    pub parent: u128,
    pub timestamp: u32,
}

impl BlockT for Block {
    fn new(ts: u32, parent: u128) -> Self {
        Self {
            id: Self::get_rand_id(),
            timestamp: ts,
            parent,
        }
    }

    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0);
        g.id >>= 10;
        g.parent = g.id;
        g
    }

    fn hash_sha3(&self) -> u128 {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs = &self.parent.to_be_bytes()[..];
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, parent_bs, ts_bs].concat());
        u128::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    }

    fn hash(&self) -> u128 {
        self.id
    }

    fn prev(&self) -> u128 {
        self.parent
    }

    fn get_ts(&self) -> u32 {
        self.timestamp
    }

    fn increment_nonce(&mut self) {
        self.id += 1;
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct DagBlock {
    pub id: u128,
    pub parents: Vec<u128>,
    pub timestamp: u32,
}

impl ManyParentsBlockT for DagBlock {
    fn new_multi_parent(timestamp: u32, parents: Vec<u128>) -> Self {
        DagBlock {
            timestamp,
            id: Self::get_rand_id(),
            parents,
        }
    }
}

impl BlockT for DagBlock {
    fn new(timestamp: u32, parent: u128) -> Self {
        Self::new_multi_parent(timestamp, vec![parent])
    }
    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0);
        g.parents = vec![g.id];
        g
    }
    fn hash(&self) -> u128 {
        self.id
    }
    fn hash_sha3(&self) -> u128 {
        let id_bs = &self.id.to_be_bytes()[..];
        let parent_bs: Vec<[u8; 16]> = self.parents.iter().map(|p| p.to_be_bytes()).collect();
        let ts_bs = &self.timestamp.to_be_bytes()[..];
        let r = Sha3_256::digest(&[id_bs, &parent_bs[..].concat(), ts_bs].concat());
        u128::from_be_bytes(<[u8; 16]>::try_from(&r[..16]).unwrap())
    }
    fn prev(&self) -> u128 {
        self.parents[0]
    }
    fn get_ts(&self) -> u32 {
        self.timestamp
    }
    fn increment_nonce(&mut self) {
        self.id += 1
    }
}

mod tests {
    use super::*;

    #[test]
    fn hash_sha3() -> Result<(), String> {
        let b = Block::genesis(0);
        let _h = b.hash_sha3();

        DagBlock::genesis(0).hash_sha3();

        Ok(())
    }
}
