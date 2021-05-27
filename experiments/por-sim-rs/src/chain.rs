use crate::block::*;
use log::*;
use rand::seq::IteratorRandom;
use std::cmp::max;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::fmt;
use std::fmt::Debug;
use std::sync::Mutex;

#[derive(Debug)]
pub enum ChainErr {
    BadPoW(u128, u128),
    UnkParent,
}

impl fmt::Display for ChainErr {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

impl From<ChainErr> for String {
    fn from(ce: ChainErr) -> Self {
        ce.to_string()
    }
}

use ChainErr::*;

pub trait ChainT<'a, B: BlockT> {
    // fn new() -> impl ChainT<'a, B>;
    fn add_block(&mut self, b: B) -> Result<(), ChainErr>;
    fn draft_block(&self, ts: u32) -> B;
    fn select_best_block(&self) -> u128;
    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr>;
    fn next_difficulty(&self, b: &B) -> u128;
    // fn fork_rule
}

#[derive(Clone, PartialEq, Eq, Hash)]
pub struct BlockMD<B> {
    pub difficulty: u128,
    pub height: u32,
    pub daa2_blocks: Vec<(B, u128)>,
}

impl<B: BlockT> BlockMD<B> {
    pub fn mk_genesis_md(genesis: &B, daa2_n_blocks: usize) -> Self {
        let difficulty = 1;
        BlockMD {
            difficulty,
            height: 0,
            daa2_blocks: vec![(genesis.clone(), difficulty); daa2_n_blocks],
        }
    }
}

pub struct Chain<B: BlockT> {
    blocks: BTreeMap<u128, B>,
    best_blocks: BTreeSet<u128>,
    blocks_meta: BTreeMap<u128, BlockMD<B>>,
    goal_block_time: u32,
    difficulty_cache: Mutex<BTreeMap<u128, u128>>,
}

impl<'a, B: BlockT + Clone> Chain<B> {
    pub const DAA2_N_BLOCKS: usize = 100;

    pub fn new(
        genesis: B,
        genesis_meta: BlockMD<B>,
        // difficulty_cache: Mutex<HashMap<u128, u128>>,
    ) -> Chain<B> {
        let g_hash = genesis.hash();
        trace!("genesis.hash:{}", g_hash);
        Chain {
            blocks: [(g_hash, genesis.clone())].iter().cloned().collect(),
            best_blocks: [g_hash].iter().cloned().collect(),
            blocks_meta: [(g_hash, genesis_meta)].iter().cloned().collect(),
            goal_block_time: 10,
            difficulty_cache: Mutex::new([].iter().cloned().collect()),
        }
    }

    // fn get_with_n_ancestors<'b>(&'b self, b: &'b B, n: u32) -> Vec<&'b B> {
    //     let mut bs = vec![b];
    //     let mut c = b;
    //     for _ in 0..n {
    //         c = &self.blocks[&c.hash()];
    //         bs.push(c);
    //     }
    //     bs
    // }

    fn next_difficulty_daa2_raw(&self, b_hash: u128) -> u128 {
        let b_meta = &self.blocks_meta[&b_hash];
        if b_meta.height < u32::try_from(Self::DAA2_N_BLOCKS >> 4).unwrap() {
            return 1000;
        }
        let blocks = &b_meta.daa2_blocks;
        let block_time_sum: u32 =
            self.blocks[&b_hash].get_ts() - b_meta.daa2_blocks.last().unwrap().0.get_ts();
        let win_rate_sum: u128 = blocks.iter().map(|t| t.1).sum();
        u128::from(self.goal_block_time) * win_rate_sum / max(u128::from(block_time_sum), 1)
    }

    fn next_difficulty_daa2(&self, b_hash: u128) -> u128 {
        let mut c = self.difficulty_cache.lock().unwrap();
        let cached_d = c.get(&b_hash).clone();
        match cached_d {
            Some(d) => *d,
            None => {
                let d = self.next_difficulty_daa2_raw(b_hash);
                c.insert(b_hash, d);
                d
            }
        }
    }

    fn target_from_difficulty(&self, d: u128) -> u128 {
        (1 << 127) / d
    }
}

impl<'a, B: BlockT + Clone + Debug> ChainT<'a, B> for Chain<B> {
    fn add_block(&mut self, b: B) -> Result<(), ChainErr> {
        let (b_meta, _p, _p_meta) = self.validate_block(&b)?;

        let best_height = self.blocks_meta[&self.select_best_block()].height;
        if b_meta.height > best_height {
            self.best_blocks.clear();
            // self.best_blocks = [b.hash()].iter().cloned().collect();
        }
        if b_meta.height >= best_height {
            self.best_blocks.insert(b.hash());
        }

        self.blocks.insert(b.hash(), b.clone());
        self.blocks_meta.insert(b.hash(), b_meta);

        Ok(())
    }

    fn draft_block(&self, ts: u32) -> B {
        B::new(ts, self.select_best_block())
    }

    fn select_best_block(&self) -> u128 {
        *self
            .best_blocks
            .iter()
            .choose(&mut rand::thread_rng())
            .unwrap()
    }

    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr> {
        if !self.blocks.contains_key(&b.prev()) {
            return Err(UnkParent);
        }

        let p = self.blocks.get(&b.prev()).unwrap();
        let p_meta = self.blocks_meta.get(&b.prev()).unwrap();
        let d = self.next_difficulty(&p);
        let target = self.target_from_difficulty(d);

        if b.hash() > target {
            return Err(BadPoW(b.hash(), target));
        }

        Ok((
            BlockMD {
                difficulty: d,
                height: p_meta.height + 1,
                daa2_blocks: Vec::from(
                    [
                        &[(b.clone(), d)],
                        &p_meta.daa2_blocks[..(Self::DAA2_N_BLOCKS - 1)],
                    ]
                    .concat(),
                ),
            },
            p,
            p_meta,
        ))
    }

    fn next_difficulty(&self, b: &B) -> u128 {
        self.next_difficulty_daa2(b.hash())
    }
}

// #[cfg(tests)]
mod tests {
    use super::*;

    fn setup_chain() -> (Block, BlockMD<Block>, Chain<Block>) {
        let genesis = Block::genesis(0);
        let g_md = BlockMD::mk_genesis_md(&genesis, Chain::<Block>::DAA2_N_BLOCKS);
        // let chain = Chain::new(genesis, g_md.clone(), Mutex::new(HashMap::new()));
        let chain = Chain::new(genesis, g_md.clone());
        (genesis, g_md, chain)
    }

    #[test]
    fn target_from_d() {
        let (_, _, chain) = setup_chain();
        assert_eq!(chain.target_from_difficulty(1), 1 << 127);
        assert_eq!(chain.target_from_difficulty(2), 1 << 126);
        assert_eq!(chain.target_from_difficulty(8), 1 << 124);
        assert_eq!(chain.target_from_difficulty(1024), 1 << 117);
        assert_eq!(
            chain.target_from_difficulty(1000),
            170141183460469231731687303715884105
        );
    }

    #[test]
    fn block_md() -> Result<(), String> {
        let (_genesis, g_md, chain) = setup_chain();
        assert_eq!(g_md.daa2_blocks.len(), Chain::<Block>::DAA2_N_BLOCKS);

        let next_d = chain.next_difficulty(&_genesis);
        assert_eq!(next_d, 1000);

        let mut b = chain.draft_block(10);
        b.id >>= 11;

        let (b_md, _, _) = chain.validate_block(&b)?;
        assert_eq!(b_md.daa2_blocks.len(), Chain::<Block>::DAA2_N_BLOCKS);
        Ok(())
    }
}
