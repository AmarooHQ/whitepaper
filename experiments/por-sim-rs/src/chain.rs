use crate::block::*;
use log::*;
use rand::seq::IteratorRandom;
use std::cmp::max;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::fmt;
use std::fmt::Debug;
use std::sync::Mutex;

mod inclusive;

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

pub struct Heights {
    pub public: u32,
    pub private: u32,
}

pub trait ChainT<'a, B: BlockT> {
    fn save_block(&mut self, b_id: u128, b: B);
    fn save_block_meta(&mut self, b_id: u128, b: BlockMD<B>);
    fn get_block(&self, b: u128) -> Option<&B>;
    fn get_block_meta(&self, b: u128) -> Option<&BlockMD<B>>;

    fn select_best_block(&self, is_private: bool) -> u128;
    fn get_best_blocks(&self, is_private: bool) -> &BTreeSet<u128>;
    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut BTreeSet<u128>;
    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr>;
    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> u128;
    fn get_heights_pub_priv(&self) -> Heights;

    fn add_block(&mut self, b: B, is_private: bool) -> Result<(), ChainErr> {
        let (b_meta, _p, _p_meta) = self.validate_block(&b)?;
        self.update_best_block(&b, &b_meta, is_private);
        self.save_block(b.hash(), b.clone());
        self.save_block_meta(b.hash(), b_meta);
        Ok(())
    }

    fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool);

    // fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
    //     let best_height = self
    //         .get_block_meta(self.select_best_block(is_private))
    //         .unwrap()
    //         .height;
    //     let best_blocks = self.get_best_blocks_mut(is_private);
    //     if b_meta.height > best_height {
    //         best_blocks.clear();
    //     }
    //     if b_meta.height >= best_height {
    //         best_blocks.insert(b.hash());
    //     }
    // }

    fn draft_block(&self, ts: u32, is_private: bool) -> B {
        B::new(ts, self.select_best_block(is_private))
    }
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
    pub best_blocks: BTreeSet<u128>,
    best_priv_blocks: BTreeSet<u128>,
    blocks_meta: BTreeMap<u128, BlockMD<B>>,
    goal_block_time: u32,
    difficulty_cache: Mutex<BTreeMap<u128, u128>>,
}

impl<'a, B: BlockT + Clone> Chain<B> {
    pub const DAA2_N_BLOCKS: usize = 100;

    pub fn new(genesis: B, genesis_meta: BlockMD<B>) -> Chain<B> {
        let g_hash = genesis.hash();
        trace!("genesis.hash:{}", g_hash);
        Chain {
            blocks: [(g_hash, genesis.clone())].iter().cloned().collect(),
            best_blocks: [g_hash].iter().cloned().collect(),
            best_priv_blocks: [g_hash].iter().cloned().collect(),
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

    fn next_difficulty_daa2_raw(&self, b_hash: u128, b_meta: &BlockMD<B>) -> u128 {
        if b_meta.height < (Self::DAA2_N_BLOCKS >> 4) as u32 {
            return 1000;
        }
        let blocks = &b_meta.daa2_blocks;
        let block_time_sum: u32 =
            self.blocks[&b_hash].get_ts() - b_meta.daa2_blocks.last().unwrap().0.get_ts();
        let win_rate_sum: u128 = blocks.iter().map(|t| t.1).sum();
        u128::from(self.goal_block_time) * win_rate_sum / max(u128::from(block_time_sum), 1)
    }

    fn next_difficulty_daa2(&self, b_hash: u128, b_meta: &BlockMD<B>) -> u128 {
        let mut c = self.difficulty_cache.lock().unwrap();
        let cached_d = c.get(&b_hash).clone();
        match cached_d {
            Some(d) => *d,
            None => {
                let d = self.next_difficulty_daa2_raw(b_hash, b_meta);
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
    fn save_block(&mut self, id: u128, b: B) {
        self.blocks.insert(id, b);
    }

    fn save_block_meta(&mut self, id: u128, b_meta: BlockMD<B>) {
        self.blocks_meta.insert(id, b_meta);
    }

    fn get_block(&self, b: u128) -> Option<&B> {
        self.blocks.get(&b)
    }

    fn get_block_meta(&self, b: u128) -> Option<&BlockMD<B>> {
        self.blocks_meta.get(&b)
    }

    fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
        let best_height = self.blocks_meta[&self.select_best_block(is_private)].height;
        let best_blocks = self.get_best_blocks_mut(is_private);
        if b_meta.height > best_height {
            best_blocks.clear();
        }
        if b_meta.height >= best_height {
            best_blocks.insert(b.hash());
        }
    }

    fn get_best_blocks(&self, is_private: bool) -> &BTreeSet<u128> {
        if is_private {
            &self.best_priv_blocks
        } else {
            &self.best_blocks
        }
    }

    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut BTreeSet<u128> {
        if is_private {
            &mut self.best_priv_blocks
        } else {
            &mut self.best_blocks
        }
    }

    fn select_best_block(&self, is_private: bool) -> u128 {
        let blocks = self.get_best_blocks(is_private);
        *blocks.iter().choose(&mut rand::thread_rng()).unwrap()
    }

    fn get_heights_pub_priv(&self) -> Heights {
        Heights {
            public: self.blocks_meta[&self.select_best_block(false)].height,
            private: self.blocks_meta[&self.select_best_block(true)].height,
        }
    }

    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr> {
        let pm = self.blocks.get(&b.prev());
        if pm.is_none() {
            return Err(UnkParent);
        }

        let p = pm.unwrap();
        let p_meta = self.blocks_meta.get(&b.prev()).unwrap();
        let d = self.next_difficulty(&p, &p_meta);
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

    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> u128 {
        self.next_difficulty_daa2(b.hash(), b_meta)
    }
}

// #[cfg(tests)]
mod tests {
    use super::*;

    fn _setup_chain() -> (Block, BlockMD<Block>, Chain<Block>) {
        let genesis = Block::genesis(0);
        let g_md = BlockMD::mk_genesis_md(&genesis, Chain::<Block>::DAA2_N_BLOCKS);
        let chain = Chain::new(genesis.clone(), g_md.clone());
        (genesis, g_md, chain)
    }

    #[test]
    fn target_from_d() {
        let (_, _, chain) = _setup_chain();
        assert_eq!(chain.target_from_difficulty(1), 1 << 127);
        assert_eq!(chain.target_from_difficulty(2), 1 << 126);
        assert_eq!(chain.target_from_difficulty(8), 1 << 124);
        assert_eq!(chain.target_from_difficulty(1024), 1 << 117);
        assert_eq!(
            chain.target_from_difficulty(1000),
            170141183460469231731687303715884105
        );
    }

    fn _mk_test_block(chain: &mut Chain<Block>, ts: u32) -> Block {
        let mut b = chain.draft_block(ts, false);
        b.id >>= 16;
        b
    }

    #[test]
    fn update_best_block() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain();
        let b = _mk_test_block(&mut chain, 10);

        assert_eq!(chain.select_best_block(false), genesis.hash());
        assert_eq!(chain.select_best_block(true), genesis.hash());

        chain.add_block(b.clone(), false)?;

        assert_eq!(chain.select_best_block(false), b.hash());
        assert_eq!(chain.select_best_block(true), genesis.hash());

        chain.add_block(b.clone(), true)?;

        assert_eq!(chain.select_best_block(false), b.hash());
        assert_eq!(chain.select_best_block(true), b.hash());

        Ok(())
    }

    #[test]
    fn block_md() -> Result<(), String> {
        let (genesis, g_md, mut chain) = _setup_chain();
        assert_eq!(g_md.daa2_blocks.len(), Chain::<Block>::DAA2_N_BLOCKS);

        let next_d = chain.next_difficulty(&genesis, &g_md);
        assert_eq!(next_d, 1000);

        let mut b = chain.draft_block(10, false);
        // make the id (PoW proxy) smaller than starting difficulty (1000).
        b.id >>= 11;

        let (b_md, _, _) = chain.validate_block(&b)?;
        assert_eq!(b_md.daa2_blocks.len(), Chain::<Block>::DAA2_N_BLOCKS);

        let is_priv = false;
        let pre_bb = chain.select_best_block(is_priv);
        assert_eq!(
            chain.blocks_meta[&chain.select_best_block(is_priv)].height,
            0
        );
        assert_eq!(chain.blocks.get(&b.hash()).is_none(), true);
        chain.add_block(b.clone(), is_priv)?;
        assert_eq!(chain.blocks.get(&b.hash()).is_some(), true);

        assert_ne!(chain.select_best_block(is_priv), pre_bb);
        assert_ne!(
            chain.blocks_meta[&chain.select_best_block(is_priv)].height,
            0
        );

        Ok(())
    }
}
