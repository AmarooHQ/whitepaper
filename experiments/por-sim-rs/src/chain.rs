use crate::block::*;
use crate::chain::fork_rules::*;
use crate::ForkResult::BestBlock;
use log::*;
use std::cmp::max;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::fmt;
use std::fmt::Debug;
use std::marker::PhantomData;
use std::rc::Rc;
use std::sync::Mutex;

pub mod fork_rules;
mod inclusive;

#[derive(Debug)]
pub enum ChainErr {
    BadPoW(u128, u128),
    UnkParent,
    BadDifficulty,
    TsBeforeParent,
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

#[derive(Debug)]
pub struct Heights {
    pub public: u64,
    pub private: u64,
}

/// Used for LCA calculations
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Debug)]
pub struct BInfo<'a, B> {
    _p: PhantomData<B>,
    id: u128,
    weight: u64,
    chain_weight: u64,
    b: &'a B,
    b_md: &'a BlockMD<B>,
}

/// Used for tracking Daa2 metadata
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Debug, Hash)]
pub struct Daa2Info {
    // id: u128,
    ts: u32,
    d: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct BlockMD<B> {
    pub difficulty: u64,
    pub height: u32,
    pub weight: u64,
    pub chain_weight: u64,
    pub daa2_blocks: Vec<u128>,
    // pub daa2_blocks: Vec<Daa2Info>,
    _phantom_b: PhantomData<B>,
}

pub struct Chain<B: BlockT, F: ForkRules<B> = LongestChain<B>> {
    blocks: BTreeMap<u128, (B, BlockMD<B>)>,
    pub best_blocks: BTreeSet<u128>,
    best_priv_blocks: BTreeSet<u128>,
    goal_block_time: u32,
    difficulty_cache: Mutex<BTreeMap<u64, u64>>,
    // fork_rules: LongestChain<B>,
    _phantom: PhantomData<F>,
}

pub trait ChainT<'a, B: BlockT, F: ForkRules<B> = LongestChain<B>> {
    fn new(genesis: B, genesis_meta: BlockMD<B>) -> Self;

    fn save_block(&mut self, b_id: u128, b: (B, BlockMD<B>));
    fn get_block(&self, b: u128) -> Option<&(B, BlockMD<B>)>;

    fn get_best_blocks(&self, is_private: bool) -> &BTreeSet<u128>;
    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut BTreeSet<u128>;
    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr>;
    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> u64;
    fn get_fork_measure_pub_priv(&self) -> Heights;
    fn get_heights_pub_priv(&self) -> Heights;

    fn get_chain_weight_at(&self, b: u128) -> u64 {
        self.get_block(b).unwrap().1.chain_weight
    }

    fn add_block(&mut self, b: B, is_private: bool) -> Result<(), ChainErr> {
        let (b_meta, _p, _p_meta) = self.validate_block(&b)?;
        self.update_best_block(&b, &b_meta, is_private);
        self.save_block(b.get_hash(), (b, b_meta));
        Ok(())
    }

    fn get_best_blocks_md(&self, is_private: bool) -> Vec<(u128, (B, BlockMD<B>))> {
        self.get_best_blocks(is_private)
            .iter()
            .map(|&b| (b, self.get_block(b).unwrap().clone()))
            .collect()
    }

    fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
        let bb_id = self.select_best_block(is_private);
        let (bb, bb_md) = self.get_block(bb_id).unwrap();
        let best_of: ForkResult<B> = F::best_of((b, b_meta), (&bb, &bb_md));
        match best_of {
            BestBlock(_b) => {
                if _b.get_hash() == b.get_hash() {
                    let best_blocks = self.get_best_blocks_mut(is_private);
                    best_blocks.clear();
                    best_blocks.insert(b.get_hash());
                }
            }
            ForkResult::BlocksEq => {
                let best_blocks = self.get_best_blocks_mut(is_private);
                best_blocks.insert(b.get_hash());
            }
        };
    }

    fn draft_block(&self, ts: u32, is_private: bool) -> B {
        let mut b = B::new_from(
            ts,
            self.get_best_blocks(is_private).iter().cloned().collect(),
            0,
        );
        let (p, p_md) = self.get_block(b.prev()).unwrap();
        b.set_difficulty(self.next_difficulty(p, p_md));
        b
    }

    // fn select_best_block(&self, is_private: bool) -> u128;
    fn select_best_block(&self, is_private: bool) -> u128 {
        let blocks: Vec<u128> = self.get_best_blocks(is_private).iter().cloned().collect();
        B::select_parent_from(blocks)
    }

    fn target_from_difficulty(&self, d: u64) -> u128 {
        // division is *expensive*, this saves some cycles
        u128::from(u64::MAX / d) << 64
    }

    fn find_lca_and_intermediates(
        &self,
        bs: &Vec<u128>,
    ) -> Option<(u128, BTreeMap<u32, BTreeSet<BInfo<B>>>)> {
        let mut intermediates = BTreeMap::<u32, BTreeSet<BInfo<B>>>::new();
        let mut intermediate_q = BTreeMap::<u32, BTreeSet<u128>>::new();
        let mut heights = Vec::new();

        if bs.len() == 0 {
            return None;
        }

        for &id in bs {
            let b_md = &self.get_block(id).unwrap().1;

            heights.push(b_md.height);

            let iq_e = intermediate_q.entry(b_md.height);
            let iq_v = iq_e.or_insert(Default::default());
            iq_v.insert(id);
        }

        let mut min_h = *heights.iter().min().unwrap();
        let max_h = *heights.iter().max().unwrap();

        for h in (0..=max_h).rev() {
            trace!("LCA at H={}", h);
            let at_h: Vec<_> = intermediate_q.get(&h).unwrap().iter().cloned().collect();
            trace!("LCA at H={}, at_h.len={}, at_h={:?}", h, at_h.len(), at_h);

            // iterate through block hashes at this height
            for &id in at_h.iter() {
                let (b, b_md) = self.get_block(id).unwrap();

                let e = intermediates.entry(b_md.height);
                let v = e.or_insert(Default::default());

                // this part adds all_prev() of the current block to the intermediate_q.
                // we only want to do this if we haven't yet reached the min_h OR we have
                // multiple blocks at this height (and thus haven't found the LCA yet).
                if h > min_h || at_h.len() > 1 {
                    for p in b.all_prev() {
                        let p_md = &self.get_block(p).unwrap().1;
                        let iq_e = intermediate_q.entry(p_md.height);
                        iq_e.or_insert(Default::default()).insert(p);
                        if p_md.height < min_h {
                            min_h = p_md.height;
                        }
                    }
                }

                v.insert(BInfo {
                    _p: PhantomData,
                    id,
                    weight: b_md.weight,
                    chain_weight: b_md.chain_weight,
                    b,
                    b_md,
                });
            }

            // we should only hit this condition when we've found the LCA
            if h <= min_h && at_h.len() == 1 {
                return Some((*at_h.iter().collect::<Vec<_>>()[0], intermediates));
            }
        }

        None
    }
}

impl<B: BlockT> fmt::Display for BlockMD<B> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        // let mut md2 = self.clone();
        // md2.daa2_blocks = vec![];
        // fmt::Debug::fmt(&md2, f)
        write!(
            f,
            "BlockMD D={} | H={} | W={} | ΣW={}",
            self.difficulty, self.height, self.weight, self.chain_weight
        )
    }
}

impl<B: BlockT> BlockMD<B> {
    pub fn mk_genesis_md(genesis: &B, daa2_n_blocks: usize) -> Self {
        let difficulty = 1;
        BlockMD {
            difficulty,
            height: 0,
            weight: 0,
            chain_weight: 0,
            // daa2_blocks: vec![(genesis.clone(), difficulty); daa2_n_blocks],
            daa2_blocks: vec![
                // Daa2Info {
                //     // id: genesis.get_hash(),
                //     ts: genesis.get_ts(),
                //     d: difficulty
                // };
                genesis.get_hash();
                daa2_n_blocks
            ],
            _phantom_b: PhantomData,
        }
    }
}

impl<'a, B: BlockT, F: ForkRules<B>> Chain<B, F> {
    pub const DAA2_N_BLOCKS: usize = 100;

    // fn get_with_n_ancestors<'b>(&'b self, b: &'b B, n: u32) -> Vec<&'b B> {
    //     let mut bs = vec![b];
    //     let mut c = b;
    //     for _ in 0..n {
    //         c = &self.blocks[&c.hash()];
    //         bs.push(c);
    //     }
    //     bs
    // }

    fn next_difficulty_daa2_raw(&self, b: &B, b_meta: &BlockMD<B>) -> u64 {
        if b_meta.height < 5 as u32 {
            return 1000;
        }
        let blocks = &b_meta.daa2_blocks;
        let (p, p_md) = self.get_block(*b_meta.daa2_blocks.last().unwrap()).unwrap();
        let block_time_sum: u32 = b.get_ts() - p.get_ts();
        let win_rate_sum: u64 = b_meta.chain_weight - p_md.chain_weight;
        u64::from(self.goal_block_time) * win_rate_sum / max(u64::from(block_time_sum), 1)
    }

    fn next_difficulty_daa2(&self, b: &B, b_meta: &BlockMD<B>) -> u64 {
        // my guess as to a good place to swap to cached difficulty
        if Self::DAA2_N_BLOCKS < 150 {
            return self.next_difficulty_daa2_raw(b, b_meta);
        } else {
            let b_hash = b.get_hash();
            let mut c = self.difficulty_cache.lock().unwrap();
            let cached_d = c.get(&(b_hash as u64));
            match cached_d {
                Some(d) => *d,
                None => {
                    let d = self.next_difficulty_daa2_raw(b, b_meta);
                    c.insert(b_hash as u64, d);
                    d
                }
            }
        }
    }
}

impl<'a, B: BlockT, F: ForkRules<B>> ChainT<'a, B, F> for Chain<B, F> {
    fn new(genesis: B, genesis_meta: BlockMD<B>) -> Chain<B, F> {
        let g_hash = genesis.get_hash();
        trace!("genesis.hash:{}", g_hash);
        Chain {
            blocks: [(g_hash, (genesis, genesis_meta))]
                .iter()
                .cloned()
                .collect(),
            best_blocks: [g_hash].iter().cloned().collect(),
            best_priv_blocks: [g_hash].iter().cloned().collect(),
            goal_block_time: 10,
            difficulty_cache: Mutex::new([].iter().cloned().collect()),
            // fork_rules: LongestChain::<B>::new(),
            _phantom: PhantomData,
        }
    }

    fn save_block(&mut self, id: u128, b: (B, BlockMD<B>)) {
        self.blocks.insert(id, b);
    }

    fn get_block(&self, b: u128) -> Option<&(B, BlockMD<B>)> {
        self.blocks.get(&b)
    }

    // fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
    //     let best_height = self.blocks_meta[&self.select_best_block(is_private)].height;
    //     let best_blocks = self.get_best_blocks_mut(is_private);
    //     if b_meta.height > best_height {
    //         best_blocks.clear();
    //     }
    //     if b_meta.height >= best_height {
    //         best_blocks.insert(b.hash());
    //     }
    // }

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

    fn get_fork_measure_pub_priv(&self) -> Heights {
        Heights {
            public: F::fork_measure(&self.blocks[&self.select_best_block(false)].1),
            private: F::fork_measure(&self.blocks[&self.select_best_block(true)].1),
        }
    }

    fn get_heights_pub_priv(&self) -> Heights {
        Heights {
            public: self.blocks[&self.select_best_block(false)].1.height as u64,
            private: self.blocks[&self.select_best_block(true)].1.height as u64,
        }
    }

    fn validate_block(&self, b: &B) -> Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr> {
        if b.get_hash() > self.target_from_difficulty(b.get_difficulty()) {
            return Err(BadPoW(
                b.get_hash(),
                self.target_from_difficulty(b.get_difficulty()),
            ));
        }
        let pm = self.blocks.get(&b.prev());
        if pm.is_none() {
            return Err(UnkParent);
        }

        let (p, p_meta) = pm.unwrap();
        let d = self.next_difficulty(&p, &p_meta);
        if d != b.get_difficulty() {
            return Err(BadDifficulty);
        }

        if b.get_ts() <= p.get_ts() {
            return Err(TsBeforeParent);
        }

        let (lca_id, intermediates_map) = self.find_lca_and_intermediates(&b.all_prev()).unwrap();
        let (_, lca_md) = self.get_block(lca_id).unwrap();
        let delta_chain_weight: u64 = intermediates_map
            .iter()
            .filter(|(&k, _v)| k != lca_md.height) // make sure we don't count the LCA in delta CW
            .map::<u64, _>(|(_k, v)| v.iter().map(|info| info.weight).sum())
            .sum();

        // // TODO: Add all parents recursively for daa2_blocks
        // let to_add = vec![Daa2Info {
        //     id: b.get_hash(),
        //     ts: b.get_ts(),
        //     d,
        // }];

        let mut daa2_blocks = Vec::with_capacity(Self::DAA2_N_BLOCKS);
        // daa2_blocks.push(Daa2Info {
        //     // id: b.get_hash(),
        //     ts: b.get_ts(),
        //     d,
        // });
        daa2_blocks.push(b.get_hash());
        daa2_blocks.extend_from_slice(&p_meta.daa2_blocks[..(Self::DAA2_N_BLOCKS - 1)]);

        Ok((
            BlockMD {
                difficulty: d,
                height: p_meta.height + 1,
                weight: d,
                chain_weight: lca_md.chain_weight + delta_chain_weight + d,
                daa2_blocks,
                _phantom_b: PhantomData,
            },
            p,
            p_meta,
        ))
    }

    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> u64 {
        self.next_difficulty_daa2(b, b_meta)
    }
}

// #[cfg(tests)]
mod tests {
    use super::*;

    fn _setup_chain<'a, B: BlockT, F: ForkRules<B>>() -> (B, BlockMD<B>, Chain<B, F>) {
        let genesis = B::genesis(0);
        let g_md = BlockMD::mk_genesis_md(&genesis, Chain::<B, F>::DAA2_N_BLOCKS);
        let chain = Chain::new(genesis.clone(), g_md.clone());
        (genesis, g_md, chain)
    }

    #[cfg(debug_assertions)]
    /// make the id (PoW proxy) small so that it passes all difficulty checks.
    fn _mk_draft_block<'a, B: BlockT, F: ForkRules<B>, C: ChainT<'a, B, F>>(
        chain: &C,
        ts: u32,
        is_private: bool,
    ) -> B {
        chain.draft_block(ts, is_private).test_set_work_bits(24)
    }

    #[test]
    fn target_from_d() {
        let (_, _, chain) = _setup_chain::<Block, LongestChain<Block>>();
        assert_eq!(chain.target_from_difficulty(1), u128::from(u64::MAX) << 64);
        assert_eq!(
            chain.target_from_difficulty(2),
            u128::from(u64::MAX / 2) << 64
        );
        assert_eq!(
            chain.target_from_difficulty(8),
            u128::from(u64::MAX / 8) << 64
        );
        assert_eq!(
            chain.target_from_difficulty(1024),
            u128::from(u64::MAX / 1024) << 64
        );
        assert_eq!(
            chain.target_from_difficulty(1000),
            0x004189374bc6a7ef0000000000000000
        );
    }

    #[test]
    fn update_best_block() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>();
        let b = _mk_draft_block(&mut chain, 10, false);

        assert_eq!(chain.select_best_block(false), genesis.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), false)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), true)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), b.get_hash());

        Ok(())
    }

    #[test]
    fn update_best_heaviest_block() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain::<Block, HeaviestChain<Block>>();
        let b = _mk_draft_block(&mut chain, 10, false);

        assert_eq!(chain.select_best_block(false), genesis.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), false)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), true)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), b.get_hash());

        Ok(())
    }

    #[test]
    fn update_best_heaviest_dagblock() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain::<DagBlock, HeaviestChain<DagBlock>>();
        let b = _mk_draft_block(&mut chain, 10, false);
        let b2 = _mk_draft_block(&mut chain, 10, false);
        let b3 = _mk_draft_block(&mut chain, 10, false);

        assert_eq!(chain.select_best_block(false), genesis.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), false)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());
        assert_eq!(chain.get_chain_weight_at(b.get_hash()), 1000);

        chain.add_block(b.clone(), true)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), b.get_hash());

        chain.add_block(b2.clone(), false)?;
        chain.add_block(b3.clone(), false)?;

        assert_eq!(chain.get_chain_weight_at(b2.get_hash()), 1000);
        assert_eq!(chain.get_chain_weight_at(b3.get_hash()), 1000);

        let b4 = _mk_draft_block(&chain, 20, false);
        chain.add_block(b4.clone(), false)?;
        let b4_md = &chain.get_block(b4.get_hash()).unwrap().1;

        assert_eq!(b4_md.height, 2, "b4_md has correct height");
        assert_eq!(b4_md.weight, 1000, "b4_md has correct weight");
        assert_eq!(b4_md.chain_weight, 4000, "b4_md has correct Σ weight");

        for &b in chain.get_best_blocks(false) {
            assert_eq!(chain.get_block(b).unwrap().1.height, 2);
        }

        for i in 0..10 {
            let tmp_b = _mk_draft_block(&chain, 30 + i * 10, false);
            chain.add_block(tmp_b, false)?;
        }

        let b130 = _mk_draft_block(&chain, 130, false);
        chain.add_block(b130.clone(), false)?;
        let b140 = _mk_draft_block(&chain, 140, false);
        chain.add_block(b140.clone(), false)?;

        let b130_md = &chain.get_block(b130.get_hash()).unwrap().1;
        let b140_md = &chain.get_block(b140.get_hash()).unwrap().1;

        assert_eq!(b130.all_prev().len(), 1);
        assert_eq!(
            b140_md.chain_weight,
            b140.get_difficulty() + b130_md.chain_weight
        );

        Ok(())
    }

    #[test]
    fn block_md() -> Result<(), String> {
        let (genesis, g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>();
        assert_eq!(
            g_md.daa2_blocks.len(),
            Chain::<Block, LongestChain<Block>>::DAA2_N_BLOCKS
        );

        let next_d = chain.next_difficulty(&genesis, &g_md);
        // assert_eq!(next_d, 1000);
        assert_eq!(next_d, 1000);

        let b = _mk_draft_block(&chain, 10, false);

        let (b_md, _, _) = chain.validate_block(&b)?;
        assert_eq!(
            b_md.daa2_blocks.len(),
            Chain::<Block, LongestChain<Block>>::DAA2_N_BLOCKS
        );

        let is_priv = false;
        let pre_bb = chain.select_best_block(is_priv);
        assert_eq!(chain.blocks[&chain.select_best_block(is_priv)].1.height, 0);
        assert_eq!(chain.blocks.get(&b.get_hash()).is_none(), true);
        chain.add_block(b.clone(), is_priv)?;
        assert_eq!(chain.blocks.get(&b.get_hash()).is_some(), true);

        assert_ne!(chain.select_best_block(is_priv), pre_bb);
        assert_ne!(chain.blocks[&chain.select_best_block(is_priv)].1.height, 0);

        Ok(())
    }

    #[test]
    fn find_lca_simple() -> Result<(), String> {
        // creates a single-parent chain
        let (g, _g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>();

        let b1 = _mk_draft_block(&chain, 10, false);
        let b2 = _mk_draft_block(&chain, 10, false);

        chain.add_block(b1.clone(), false)?;
        chain.add_block(b2.clone(), false)?;

        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b1.get_hash(), b2.get_hash()])
            .unwrap();

        assert_eq!(lca_id, g.get_hash());

        assert_eq!(inter[&1].len(), 2);
        assert_eq!(inter[&0].len(), 1);

        // add a 3rd block, make sure it builds off b2
        let mut b3 = _mk_draft_block(&chain, 20, false);
        b3.parent = b2.get_hash();
        chain.add_block(b3.clone(), false)?;

        // find chain-segment from b3 (at h=2) and genesis
        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), g.get_hash()])
            .unwrap();

        assert_eq!(lca_id, g.get_hash());

        assert_eq!(inter[&2].len(), 1);
        // only expect one block at h=1 to be included.
        assert_eq!(inter[&1].len(), 1);
        assert_eq!(inter[&0].len(), 1);

        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b3.get_hash()])
            .unwrap();
        assert_eq!(lca_id, b3.get_hash());
        assert_eq!(inter.len(), 1);
        assert_eq!(inter[&2].len(), 1);

        // b3 builds off b2, so this should return b2 as the LCA
        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), b2.get_hash()])
            .unwrap();
        assert_eq!(lca_id, b2.get_hash());
        assert_eq!(inter.len(), 2);
        assert_eq!(inter[&2].len(), 1);
        assert_eq!(inter[&1].len(), 1);

        Ok(())
    }

    #[test]
    fn find_lca_dag_simple() -> Result<(), String> {
        // creates a multi-parent chain
        let (g, _g_md, mut chain) = _setup_chain::<DagBlock, HeaviestChain<DagBlock>>();

        let b1 = _mk_draft_block(&chain, 10, false);
        let b2 = _mk_draft_block(&chain, 10, false);

        chain.add_block(b1.clone(), false)?;
        chain.add_block(b2.clone(), false)?;

        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b1.get_hash(), b2.get_hash()])
            .unwrap();

        assert_eq!(lca_id, g.get_hash());

        assert_eq!(inter[&1].len(), 2);
        assert_eq!(inter[&0].len(), 1);

        // add a 3rd block; should build of both h=1 blocks.
        let b3 = _mk_draft_block(&chain, 20, false);
        let b4 = _mk_draft_block(&chain, 20, false); // add this later

        chain.add_block(b3.clone(), false)?;
        // find chain-segment from b3 (at h=2) and genesis
        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), g.get_hash()])
            .unwrap();

        assert_eq!(lca_id, g.get_hash());

        assert_eq!(inter[&2].len(), 1);
        // expect 2 blocks at h=1 to be included b/c it's a dag!.
        assert_eq!(inter[&1].len(), 2);
        assert_eq!(inter[&0].len(), 1);

        // 5 blocks including genesis, and genesis is LCA of most recent 2 blocks
        chain.add_block(b4.clone(), false)?;
        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), b4.get_hash()])
            .unwrap();
        assert_eq!(lca_id, g.get_hash());
        assert_eq!(inter[&2].len(), 2);
        assert_eq!(inter[&1].len(), 2);
        assert_eq!(inter[&0].len(), 1);

        let b5 = _mk_draft_block(&chain, 30, false);
        chain.add_block(b5.clone(), false)?;
        let (lca_id, inter) = chain.find_lca_and_intermediates(&b5.parents).unwrap();
        assert_eq!(lca_id, g.get_hash());
        assert_eq!(inter[&2].len(), 2);
        assert_eq!(inter[&1].len(), 2);
        assert_eq!(inter[&0].len(), 1);

        let (lca_id, inter) = chain
            .find_lca_and_intermediates(&vec![b5.get_hash()])
            .unwrap();
        assert_eq!(lca_id, b5.get_hash());
        assert_eq!(inter[&3].len(), 1);
        assert_eq!(inter.len(), 1);

        Ok(())
    }

    #[test]
    fn reject_child_older_than_parent() {
        unimplemented!();
    }
}
