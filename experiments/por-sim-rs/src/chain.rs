use crate::block::*;
use crate::block_metadata::BlockMD;
use crate::chain::fork_rules::*;
use crate::types::PassThruHashMap;
use crate::types::*;
use crate::ForkResult::BestBlock;
// use fnv::FnvHashMap;
// use hashbrown;
use hashers::null::PassThroughHasher;
// use intmap::IntMap;
use lazy_static::lazy_static;
use log::*;
use std::cmp::max;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::collections::HashMap;
use std::collections::HashSet;
use std::fmt;
use std::fmt::Debug;
use std::hash::BuildHasherDefault;
use std::iter::FromIterator;
use std::marker::PhantomData;
use std::sync::Arc;
use std::sync::Mutex;

pub mod fork_rules;
mod inclusive;

#[derive(Debug, PartialEq, Eq)]
pub enum ChainErr {
    BadPoW(HashID, HashID),
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
    pub public: Difficulty,
    pub private: Difficulty,
}

/// Used for LCA calculations
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Debug)]
pub struct BInfo {
    // _p: PhantomData<B>,
    id: HashID,
    weight: Difficulty,
    chain_weight: Difficulty,
    // b: &'a B,
    // b_md: &'a BlockMD<B>,
}

/// Used for tracking Daa2 metadata
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Debug, Hash)]
pub struct Daa2Info {
    // id: HashID,
    ts: u32,
    d: Difficulty,
}

pub struct Chain<B: BlockT, F: ForkRules<B> = LongestChain<B>> {
    // blocks: PassThruHashMap<u64, (B, BlockMD<B>)>, // 593ms
    // blocks: hashbrown::HashMap<u64, (B, BlockMD<B>)>, // 622ms
    // blocks: FnvHashMap<u64, (B, BlockMD<B>)>, // 639ms
    // blocks: IntMap<(B, BlockMD<B>)>, // 692ms
    pub best_blocks: HashSet<HashID>,
    best_priv_blocks: HashSet<HashID>,
    goal_block_time: u32,
    // fork_rules: LongestChain<B>,
    _phantom_f: PhantomData<F>,
    _phantom_b: PhantomData<B>,
}

#[inline]
fn conv_u128_id_to_u64(u: u128) -> u64 {
    (u as u64) ^ ((u >> 64) as u64)
}

lazy_static! {
    static ref DIFFICULTY_CACHE: Mutex<PassThruHashMap<u64, Difficulty>> =
        Mutex::new(Default::default());
    static ref LCAS_CACHE: Mutex<HashMap<Vec<HashID>, Arc<(HashID, BTreeMap<u32, BTreeSet<BInfo>>)>>> =
        Mutex::new(Default::default());
}

pub trait ChainT<'a, B: BlockT, F: ForkRules<B> = LongestChain<B>> {
    fn new(genesis: B, genesis_meta: BlockMD<B>) -> Self;

    // fn save_block(&mut self, b_id: HashID, b: (B, BlockMD<B>));
    // fn get_block(&self, b: HashID) -> Option<&(B, BlockMD<B>)>;

    fn get_cached_block(b: HashID) -> Option<Arc<(B, BlockMD<B>)>> {
        B::get_cached_block(b).map(|b| b.clone())
    }

    // #[inline]
    fn set_cached_block(b: (B, BlockMD<B>)) {
        B::set_cached_block(b)
    }

    fn get_best_blocks(&self, is_private: bool) -> &HashSet<HashID>;
    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut HashSet<HashID>;
    fn validate_block_pure(&self, b: &B) -> Result<Arc<(B, BlockMD<B>)>, ChainErr>;
    fn validate_block(&self, b: &B) -> Result<BlockMD<B>, ChainErr>;
    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty;
    fn get_fork_measure_pub_priv(&self) -> Heights;
    fn get_heights_pub_priv(&self) -> Heights;

    fn get_chain_weight_at(&self, b: HashID) -> Difficulty {
        Self::get_cached_block(b).unwrap().1.chain_weight
    }

    fn notify_block(&mut self, id: HashID, is_private: bool) -> Result<(), ChainErr> {
        let b_c = Self::get_cached_block(id).unwrap();
        self.update_best_block(&b_c.0, &b_c.1, is_private);
        Ok(())
    }

    fn add_block(&mut self, b: B, is_private: bool) -> Result<(), ChainErr> {
        let b_id = b.get_hash();
        let b_c;
        // note, it *is* faster to check than just insert
        match Self::get_cached_block(b_id) {
            Some(b_cached) => {
                b_c = b_cached;
            }
            None => {
                let b_meta = self.validate_block(&b)?;
                Self::set_cached_block((b, b_meta));
                b_c = Self::get_cached_block(b_id).unwrap();
            }
        };
        self.update_best_block(&b_c.0, &b_c.1, is_private);
        // self.save_block(b.get_hash(), (b, b_meta));
        Ok(())
    }

    fn get_best_blocks_md(&self, is_private: bool) -> Vec<(HashID, Arc<(B, BlockMD<B>)>)> {
        self.get_best_blocks(is_private)
            .iter()
            .map(|&b| (b, Self::get_cached_block(b).unwrap().clone()))
            .collect()
    }

    fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
        let bb_id = self.select_best_block(is_private);
        let bb = Self::get_cached_block(bb_id).unwrap();
        let best_of: ForkResult<B> = F::best_of((b, b_meta), (&bb.0, &bb.1));
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
        let mut b = B::new_from(ts, self.get_best_blocks(is_private).iter().cloned(), 0);
        let p = Self::get_cached_block(b.prev()).unwrap();
        b.set_difficulty(self.next_difficulty(&p.0, &p.1));
        b
    }

    #[inline]
    fn select_best_block(&self, is_private: bool) -> HashID {
        // let blocks: Vec<HashID> = Vec::from_iter(self.get_best_blocks(is_private).iter().cloned());
        B::select_parent_from(self.get_best_blocks(is_private).iter().cloned())
    }

    #[inline]
    fn target_from_difficulty(&self, d: Difficulty) -> HashID {
        // division is *expensive*, this saves some cycles

        // for u128
        // HashID::from(u64::MAX / u64::from(d)) << 64

        // for u64
        u64::MAX / u64::from(d)
    }

    fn find_lca_and_intermediates(
        &self,
        bs: &Vec<HashID>,
    ) -> Option<Arc<(HashID, BTreeMap<u32, BTreeSet<BInfo>>)>> {
        if let Some(r) = LCAS_CACHE
            .lock()
            .ok()
            .and_then(|c| c.get(bs).map(|v| v.clone()))
        {
            return Some(r.clone());
        };

        match bs.len() {
            0 => {
                return None;
            }
            1 => {
                let h = bs[0];
                let b = Self::get_cached_block(h).unwrap();
                let info_set: BTreeSet<_> = BTreeSet::from_iter(vec![BInfo {
                    // _p: PhantomData,
                    id: h,
                    weight: b.1.weight,
                    chain_weight: b.1.chain_weight,
                    // b,
                    // b.1,
                }]);
                let r = Arc::new((h, BTreeMap::from_iter(vec![(b.1.height, info_set)])));
                LCAS_CACHE.lock().unwrap().insert(bs.clone(), r.clone());
                return Some(r);
            }
            _ => {}
        }

        let mut intermediates = BTreeMap::<u32, BTreeSet<BInfo>>::new();
        let mut intermediate_q = BTreeMap::<u32, HashSet<HashID>>::new();
        let mut heights = Vec::new();

        for &id in bs {
            let b_md = &Self::get_cached_block(id).unwrap().1;

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
                let b = Self::get_cached_block(id).unwrap();

                let e = intermediates.entry(b.1.height);
                let v = e.or_insert(Default::default());

                // this part adds all_prev() of the current block to the intermediate_q.
                // we only want to do this if we haven't yet reached the min_h OR we have
                // multiple blocks at this height (and thus haven't found the LCA yet).
                if h > min_h || at_h.len() > 1 {
                    for p in b.0.all_prev() {
                        let p_md = &Self::get_cached_block(p).unwrap().1;
                        let iq_e = intermediate_q.entry(p_md.height);
                        iq_e.or_insert(Default::default()).insert(p);
                        if p_md.height < min_h {
                            min_h = p_md.height;
                        }
                    }
                }

                v.insert(BInfo {
                    // _p: PhantomData,
                    id,
                    weight: b.1.weight,
                    chain_weight: b.1.chain_weight,
                    // b,
                    // b.1,
                });
            }

            // we should only hit this condition when we've found the LCA
            if h <= min_h && at_h.len() == 1 {
                let r = Arc::new((*at_h.iter().collect::<Vec<_>>()[0], intermediates));
                LCAS_CACHE.lock().unwrap().insert(bs.clone(), r.clone());
                return Some(r);
            }
        }
        None
    }
}

impl<'a, B: BlockT, F: ForkRules<B>> Chain<B, F> {
    pub const DAA2_N_BLOCKS: usize = 100;

    fn next_difficulty_daa2_raw(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty {
        if b_meta.height < 5 as u32 {
            return 1000;
        }
        let daa2_bs = BlockMD::<B>::get_daa2_blocks(b.get_hash());
        let daa2_bs = match daa2_bs {
            Some(bs) => bs,
            None => {
                todo!();
            }
        };
        let p = Self::get_cached_block(*daa2_bs.last().unwrap()).unwrap();
        let block_time_sum: u32 = b.get_ts() - p.0.get_ts();
        let win_rate_sum: Difficulty = b_meta.chain_weight - p.1.chain_weight;
        Difficulty::from(self.goal_block_time) * win_rate_sum
            / max(Difficulty::from(block_time_sum), 1)
    }

    fn next_difficulty_daa2(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty {
        let b_hash = b.get_hash();
        let mut c = DIFFICULTY_CACHE.lock().unwrap();
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

impl<'a, B: BlockT, F: ForkRules<B>> ChainT<'a, B, F> for Chain<B, F> {
    fn new(genesis: B, genesis_meta: BlockMD<B>) -> Chain<B, F> {
        let g_hash = genesis.get_hash();
        trace!("genesis.hash:{}", g_hash);
        // let mut blocks = HashMap::with_hasher(BuildHasherDefault::<PassThroughHasher>::default());
        // blocks.insert(conv_u128_id_to_u64(g_hash), (genesis, genesis_meta));
        // blocks.insert(g_hash, (genesis, genesis_meta));
        Self::set_cached_block((genesis, genesis_meta));
        Chain {
            // blocks,
            best_blocks: [g_hash].iter().cloned().collect(),
            best_priv_blocks: [g_hash].iter().cloned().collect(),
            goal_block_time: 10,
            // fork_rules: LongestChain::<B>::new(),
            _phantom_b: PhantomData,
            _phantom_f: PhantomData,
        }
    }

    // fn save_block(&mut self, id: HashID, b: (B, BlockMD<B>)) {
    //     // self.blocks.insert(conv_u128_id_to_u64(id), b);
    //     self.blocks.insert(id, b);
    // }

    // fn get_block(&self, b: HashID) -> Option<&(B, BlockMD<B>)> {
    //     // self.blocks.get(&conv_u128_id_to_u64(b))
    //     self.blocks.get(&b)
    // }

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

    fn get_best_blocks(&self, is_private: bool) -> &HashSet<HashID> {
        if is_private {
            &self.best_priv_blocks
        } else {
            &self.best_blocks
        }
    }

    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut HashSet<HashID> {
        if is_private {
            &mut self.best_priv_blocks
        } else {
            &mut self.best_blocks
        }
    }

    fn get_fork_measure_pub_priv(&self) -> Heights {
        Heights {
            public: F::fork_measure(
                &Self::get_cached_block(self.select_best_block(false))
                    .unwrap()
                    .1,
            ),
            private: F::fork_measure(
                &Self::get_cached_block(self.select_best_block(true))
                    .unwrap()
                    .1,
            ),
        }
    }

    fn get_heights_pub_priv(&self) -> Heights {
        Heights {
            public: Difficulty::from(
                Self::get_cached_block(self.select_best_block(false))
                    .unwrap()
                    .1
                    .height,
            ),
            private: Difficulty::from(
                Self::get_cached_block(self.select_best_block(true))
                    .unwrap()
                    .1
                    .height,
            ),
        }
    }

    fn validate_block_pure(&self, b: &B) -> Result<Arc<(B, BlockMD<B>)>, ChainErr> {
        todo!()
        // Ok(pm)
    }

    fn validate_block(&self, b: &B) -> Result<BlockMD<B>, ChainErr> {
        if b.get_hash() > self.target_from_difficulty(b.get_difficulty()) {
            return Err(BadPoW(
                b.get_hash(),
                self.target_from_difficulty(b.get_difficulty()),
            ));
        }

        // TODO: will honest nodes ever know about attacking blocks and accidentally find a parent they shouldn't? those blocks are the in cache. I don't *think* so.
        let pm = Self::get_cached_block(b.prev());
        if pm.is_none() {
            return Err(UnkParent);
        }

        let pm = pm.unwrap();

        if b.get_ts() <= pm.0.get_ts() {
            return Err(TsBeforeParent);
        }

        // let pm = self.validate_block_pure(b)?;

        let d = self.next_difficulty(&pm.0, &pm.1);
        if d != b.get_difficulty() {
            return Err(BadDifficulty);
        }

        let lca_r = self.find_lca_and_intermediates(&b.all_prev()).unwrap();

        /* FIRST VERSION OF THE CODE
         * SOMEHOW the difference in speed between this version of the code, and
         * the version below is like 10x (worse for this one). Wtf?!
         */
        // let delta_chain_weight;
        // let lca_chain_weight;
        // if lca_r.0 == pm.0.get_hash() {
        //     delta_chain_weight = 0;
        //     lca_chain_weight = pm.1.chain_weight;
        // } else {
        //     let lca_md = &Self::get_cached_block(lca_r.0).unwrap().clone().1;
        //     lca_chain_weight = lca_md.chain_weight;
        //     let lca_height = lca_md.height;
        //     delta_chain_weight = lca_r
        //         .1
        //         .iter()
        //         .filter(|(&k, _v)| k != lca_height) // make sure we don't count the LCA in delta CW
        //         .map::<Difficulty, _>(|(_k, v)| v.iter().map(|info| info.weight).sum())
        //         .sum();
        // }

        /* SECOND VERSION OF THE CODE
         */
        let lca_md = Self::get_cached_block(lca_r.0).unwrap().1.clone();
        let delta_chain_weight: Difficulty = lca_r
            .1
            .iter()
            .filter(|(&k, _v)| k != lca_md.height) // make sure we don't count the LCA in delta CW
            .map::<Difficulty, _>(|(_k, v)| v.iter().map(|info| info.weight).sum())
            .sum();
        let lca_chain_weight = lca_md.chain_weight;

        /* END DIFF VERSIONS */

        // // TODO: Add all parents recursively for daa2_blocks
        // let to_add = vec![Daa2Info {
        //     id: b.get_hash(),
        //     ts: b.get_ts(),
        //     d,
        // }];

        // ensure that the daa2 vector is in the cache
        match BlockMD::<B>::get_daa2_blocks(b.get_hash()) {
            Some(_) => (),
            None => {
                let mut daa2_blocks = Vec::with_capacity(Self::DAA2_N_BLOCKS);
                daa2_blocks.push(b.get_hash());
                let p_daa2_bs = BlockMD::<B>::get_daa2_blocks(pm.0.get_hash()).unwrap();
                daa2_blocks.extend_from_slice(&p_daa2_bs[..(Self::DAA2_N_BLOCKS - 1)]);
                BlockMD::<B>::set_daa2_blocks(b.get_hash(), daa2_blocks);
            }
        }

        Ok(BlockMD {
            difficulty: d,
            height: pm.1.height + 1,
            weight: d,
            chain_weight: lca_chain_weight + delta_chain_weight + d,
            // daa2_blocks,
            _phantom_b: PhantomData,
        })
    }

    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty {
        self.next_difficulty_daa2(b, b_meta)
    }
}

// #[cfg(tests)]
mod tests {
    use super::*;

    fn _setup_chain<'a, B: BlockT, F: ForkRules<B>>(
        ts: Option<u32>,
    ) -> (B, BlockMD<B>, Chain<B, F>) {
        let genesis = B::genesis(ts.unwrap_or(0));
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
        let (_, _, chain) = _setup_chain::<Block, LongestChain<Block>>(None);
        assert_eq!(
            chain.target_from_difficulty(1),
            // HashID::from(u64::MAX) << 64
            HashID::from(u64::MAX)
        );
        assert_eq!(
            chain.target_from_difficulty(2),
            // HashID::from(u64::MAX / 2) << 64
            HashID::from(u64::MAX / 2)
        );
        assert_eq!(
            chain.target_from_difficulty(8),
            // HashID::from(u64::MAX / 8) << 64
            HashID::from(u64::MAX / 8)
        );
        assert_eq!(
            chain.target_from_difficulty(1024),
            // HashID::from(u64::MAX / 1024) << 64
            HashID::from(u64::MAX / 1024)
        );
        assert_eq!(
            chain.target_from_difficulty(1000),
            // 0x004189374bc6a7ef0000000000000000
            0x004189374bc6a7ef
        );
    }

    #[test]
    fn update_best_block() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>(None);
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
        let (genesis, _g_md, mut chain) = _setup_chain::<Block, HeaviestChain<Block>>(None);
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
        type B = DagBlock;

        let (genesis, _g_md, mut chain) = _setup_chain::<DagBlock, HeaviestChain<DagBlock>>(None);
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
        let b4_md = &B::get_cached_block(b4.get_hash()).unwrap().1;

        assert_eq!(b4_md.height, 2, "b4_md has correct height");
        assert_eq!(b4_md.weight, 1000, "b4_md has correct weight");
        assert_eq!(b4_md.chain_weight, 4000, "b4_md has correct Σ weight");

        for &b in chain.get_best_blocks(false) {
            assert_eq!(B::get_cached_block(b).unwrap().1.height, 2);
        }

        for i in 0..10 {
            let tmp_b = _mk_draft_block(&chain, 30 + i * 10, false);
            chain.add_block(tmp_b, false)?;
        }

        let b130 = _mk_draft_block(&chain, 130, false);
        chain.add_block(b130.clone(), false)?;
        let b140 = _mk_draft_block(&chain, 140, false);
        chain.add_block(b140.clone(), false)?;

        let b130_md = &B::get_cached_block(b130.get_hash()).unwrap().1;
        let b140_md = &B::get_cached_block(b140.get_hash()).unwrap().1;

        assert_eq!(b130.all_prev().len(), 1);
        assert_eq!(
            b140_md.chain_weight,
            b140.get_difficulty() + b130_md.chain_weight
        );

        Ok(())
    }

    #[test]
    fn block_md() -> Result<(), String> {
        type B = Block;

        let (genesis, g_md, mut chain) = _setup_chain::<B, LongestChain<B>>(None);
        assert_eq!(
            BlockMD::<B>::get_daa2_blocks(genesis.get_hash())
                .unwrap()
                .len(),
            Chain::<B, LongestChain<B>>::DAA2_N_BLOCKS
        );

        let next_d = chain.next_difficulty(&genesis, &g_md);
        // assert_eq!(next_d, 1000);
        assert_eq!(next_d, 1000);

        let b = _mk_draft_block(&chain, 10, false);

        chain.validate_block(&b)?;
        assert_eq!(
            BlockMD::<B>::get_daa2_blocks(genesis.get_hash())
                .unwrap()
                .len(),
            Chain::<B, LongestChain<B>>::DAA2_N_BLOCKS
        );

        let is_priv = false;
        let pre_bb = chain.select_best_block(is_priv);
        assert_eq!(
            B::get_cached_block(chain.select_best_block(is_priv))
                .unwrap()
                .1
                .height,
            0
        );
        assert_eq!(B::get_cached_block(b.get_hash()).is_none(), true);
        chain.add_block(b.clone(), is_priv)?;
        assert_eq!(B::get_cached_block(b.get_hash()).is_some(), true);

        assert_ne!(chain.select_best_block(is_priv), pre_bb);
        assert_ne!(
            B::get_cached_block(chain.select_best_block(is_priv))
                .unwrap()
                .1
                .height,
            0
        );

        Ok(())
    }

    #[test]
    fn find_lca_simple() -> Result<(), String> {
        // creates a single-parent chain
        let (g, _g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>(None);

        let b1 = _mk_draft_block(&chain, 10, false);
        let b2 = _mk_draft_block(&chain, 10, false);

        chain.add_block(b1.clone(), false)?;
        chain.add_block(b2.clone(), false)?;

        let lca_r = chain
            .find_lca_and_intermediates(&vec![b1.get_hash(), b2.get_hash()])
            .unwrap();

        assert_eq!(lca_r.0, g.get_hash());

        assert_eq!(lca_r.1[&1].len(), 2);
        assert_eq!(lca_r.1[&0].len(), 1);

        // add a 3rd block, make sure it builds off b2
        let mut b3 = _mk_draft_block(&chain, 20, false);
        b3.parent = b2.get_hash();
        chain.add_block(b3.clone(), false)?;

        // find chain-segment from b3 (at h=2) and genesis
        let lca_r = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), g.get_hash()])
            .unwrap();

        assert_eq!(lca_r.0, g.get_hash());

        assert_eq!(lca_r.1[&2].len(), 1);
        // only expect one block at h=1 to be included.
        assert_eq!(lca_r.1[&1].len(), 1);
        assert_eq!(lca_r.1[&0].len(), 1);

        let lca_r = chain
            .find_lca_and_intermediates(&vec![b3.get_hash()])
            .unwrap();
        assert_eq!(lca_r.0, b3.get_hash());
        assert_eq!(lca_r.1.len(), 1);
        assert_eq!(lca_r.1[&2].len(), 1);

        // b3 builds off b2, so this should return b2 as the LCA
        let lca_r = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), b2.get_hash()])
            .unwrap();
        assert_eq!(lca_r.0, b2.get_hash());
        assert_eq!(lca_r.1.len(), 2);
        assert_eq!(lca_r.1[&2].len(), 1);
        assert_eq!(lca_r.1[&1].len(), 1);

        Ok(())
    }

    #[test]
    fn find_lca_dag_simple() -> Result<(), String> {
        // creates a multi-parent chain
        let (g, _g_md, mut chain) = _setup_chain::<DagBlock, HeaviestChain<DagBlock>>(None);

        let b1 = _mk_draft_block(&chain, 10, false);
        let b2 = _mk_draft_block(&chain, 10, false);

        chain.add_block(b1.clone(), false)?;
        chain.add_block(b2.clone(), false)?;

        let lca_r = chain
            .find_lca_and_intermediates(&vec![b1.get_hash(), b2.get_hash()])
            .unwrap();

        assert_eq!(lca_r.0, g.get_hash());

        assert_eq!(lca_r.1[&1].len(), 2);
        assert_eq!(lca_r.1[&0].len(), 1);

        // add a 3rd block; should build of both h=1 blocks.
        let b3 = _mk_draft_block(&chain, 20, false);
        let b4 = _mk_draft_block(&chain, 20, false); // add this later

        chain.add_block(b3.clone(), false)?;
        // find chain-segment from b3 (at h=2) and genesis
        let lca_r = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), g.get_hash()])
            .unwrap();

        assert_eq!(lca_r.0, g.get_hash());

        assert_eq!(lca_r.1[&2].len(), 1);
        // expect 2 blocks at h=1 to be included b/c it's a dag!.
        assert_eq!(lca_r.1[&1].len(), 2);
        assert_eq!(lca_r.1[&0].len(), 1);

        // 5 blocks including genesis, and genesis is LCA of most recent 2 blocks
        chain.add_block(b4.clone(), false)?;
        let lca_r = chain
            .find_lca_and_intermediates(&vec![b3.get_hash(), b4.get_hash()])
            .unwrap();
        assert_eq!(lca_r.0, g.get_hash());
        assert_eq!(lca_r.1[&2].len(), 2);
        assert_eq!(lca_r.1[&1].len(), 2);
        assert_eq!(lca_r.1[&0].len(), 1);

        let b5 = _mk_draft_block(&chain, 30, false);
        chain.add_block(b5.clone(), false)?;
        let lca_r = chain.find_lca_and_intermediates(&b5.parents).unwrap();
        assert_eq!(lca_r.0, g.get_hash());
        assert_eq!(lca_r.1[&2].len(), 2);
        assert_eq!(lca_r.1[&1].len(), 2);
        assert_eq!(lca_r.1[&0].len(), 1);

        let lca_r = chain
            .find_lca_and_intermediates(&vec![b5.get_hash()])
            .unwrap();
        assert_eq!(lca_r.0, b5.get_hash());
        assert_eq!(lca_r.1[&3].len(), 1);
        assert_eq!(lca_r.1.len(), 1);

        Ok(())
    }

    #[test]
    fn reject_child_older_than_parent() {
        let (_g, _g_md, mut chain) = _setup_chain::<DagBlock, HeaviestChain<DagBlock>>(Some(10));
        let b = _mk_draft_block(&chain, 5, false);
        assert_eq!(_g.get_ts() > b.get_ts(), true, "timestamps: b < g");
        assert_eq!(chain.add_block(b, false), Err(ChainErr::TsBeforeParent));
    }

    #[test]
    fn u128_xor_key_test() {
        assert_eq!(
            conv_u128_id_to_u64(0xAAAAAAAAAAAAAAAA5555555555555555),
            0xFFFFFFFFFFFFFFFF
        );
        assert_eq!(
            conv_u128_id_to_u64(0x5555555555555555AAAAAAAAAAAAAAAA),
            0xFFFFFFFFFFFFFFFF
        );
        assert_eq!(conv_u128_id_to_u64(0x55555555555555555555555555555555), 0x0);
    }
}
