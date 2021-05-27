use getrandom::getrandom;
use sha3::{Digest, Sha3_256};
use std::convert::TryFrom;
use std::fmt::Debug;
use std::hash::Hash;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Block {
    pub id: u128,
    pub parent: u128,
    pub timestamp: u32,
}

impl BlockT for Block {
    fn new(ts: u32, parent: u128) -> Self {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        let id = u128::from_be_bytes(e);
        // let id = 0;
        Self {
            id,
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
        let r = Sha3_256::digest(&[id_bs, id_bs].concat());
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

pub trait BlockT: Clone + Debug + PartialEq + Eq {
    fn new(ts: u32, parent: u128) -> Self;
    fn genesis(ts: u32) -> Self;
    fn hash(&self) -> u128;
    fn hash_sha3(&self) -> u128;
    fn prev(&self) -> u128;
    fn get_ts(&self) -> u32;
    fn increment_nonce(&mut self);
}
