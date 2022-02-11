use crate::block::*;
use crate::block_metadata::*;
use crate::chain::fork_rules::*;
use crate::transactions::*;
use crate::types::*;
use crate::ForkResult::BestBlock;
use itertools::Itertools;
use lazy_static::lazy_static;
use log::*;
use lru::LruCache;
use std::cmp::max;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::collections::HashMap;
use std::fmt;
use std::fmt::Debug;
use std::iter::FromIterator;
use std::marker::PhantomData;
use std::sync::Arc;
use std::sync::Mutex;

pub mod fork_rules;

/**
 * - [ ] apply_block -- actually run txs through state
 * - [ ] remove txs from mempool when applying new block
 */

#[derive(Debug, PartialEq, Eq)]
pub enum ChainErr {
    BadPoW(HashID, HashID),
    BlockRefsUnkParent(HashID, HashID, bool),
    BadParentOrder(String, (HashID, ChainWeight), (HashID, ChainWeight)),
    BadDifficulty,
    BadReflWeightInBlock,
    TsBeforeParent,
    BlockHeightInvalid,
    TxInParent { b: HashID, txid: HashID },
    ApplyErr(ChainApplyErr),
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

impl From<ChainApplyErr> for ChainErr {
    fn from(ce: ChainApplyErr) -> Self {
        ApplyErr(ce)
    }
}

use ChainErr::*;

#[derive(Debug, PartialEq, Eq)]
pub enum ChainTxErr {
    // AlreadySeen(HashID),
    Conflicting { new_id: HashID, existing_id: HashID },
}

impl fmt::Display for ChainTxErr {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

impl From<ChainTxErr> for String {
    fn from(ce: ChainTxErr) -> Self {
        ce.to_string()
    }
}

#[derive(Debug, PartialEq, Eq)]
pub enum ChainApplyErr {
    // AlreadySeen(HashID),
    Conflicting { new_id: HashID, existing_id: HashID },
}

impl fmt::Display for ChainApplyErr {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

impl From<ChainApplyErr> for String {
    fn from(ce: ChainApplyErr) -> Self {
        ce.to_string()
    }
}

#[derive(Debug)]
pub struct Heights {
    pub public: Difficulty,
    pub private: Difficulty,
}

/// Used for LCA calculations
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Debug)]
pub struct BInfo {
    // _p: PhantomData<B>,
    pub id: HashID,
    weight: Difficulty,
    reflected_weight: Difficulty,
    chain_weight: Difficulty,
    local_chain_weight: Difficulty,
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

#[derive(Clone)]
pub struct Chain<B: BlockT, F: ForkRules<B> = LongestChain<B>> {
    chain_id: HashID,
    pub best_blocks: FxHashSet<HashID>,
    pub_chain_heads: ChainHeads,
    best_priv_blocks: FxHashSet<HashID>,
    priv_chain_heads: ChainHeads,
    seen_pub_blocks: SeenBlocks,
    seen_priv_blocks: SeenBlocks,
    pub_mempool: FxHashSet<HashID>,
    priv_mempool: FxHashSet<HashID>,
    net_args: NetworkArgs,
    _phantom_f: PhantomData<F>,
    _phantom_b: PhantomData<B>,
}

#[cfg(test)] // remove later if we use it again
#[inline]
fn conv_u128_id_to_u64(u: u128) -> u64 {
    (u as u64) ^ ((u >> 64) as u64)
}

lazy_static! {
    static ref DIFFICULTY_CACHE: Mutex<PassThruHashMap<u64, Difficulty>> =
        Mutex::new(Default::default());
    static ref DIFFICULTY_LRU: Mutex<LruCache<u64, Difficulty>> = Mutex::new(LruCache::new(1024));
    static ref LCAS_CACHE: Mutex<HashMap<Vec<HashID>, Arc<(HashID, BTreeMap<u32, BTreeSet<BInfo>>)>>> =
        Mutex::new(Default::default());
}

pub trait ChainT<'a, B: BlockT, F: ForkRules<B> = LongestChain<B>>: Clone {
    fn new(genesis: B, genesis_meta: BlockMD<B>, net_args: NetworkArgs) -> Self;

    fn get_chain_id(&self) -> HashID;

    // fn save_block(&mut self, b_id: HashID, b: (B, BlockMD<B>));
    // fn get_block(&self, b: HashID) -> Option<&(B, BlockMD<B>)>;

    fn get_cached_block(b: &HashID) -> Option<Arc<(B, BlockMD<B>)>> {
        // B::get_cached_block(&b).map(|b| b.clone())
        B::get_cached_block(&b)
    }

    // fn get_cached_blocks(ids: &[HashID]) -> Option<Box<[Arc<(B, BlockMD<B>)>]>> {
    //     B::get_cached_blocks(ids)
    // }

    fn set_cached_block(b: (B, BlockMD<B>)) {
        B::set_cached_block(b)
    }

    fn get_best_blocks(&self, is_private: bool) -> &FxHashSet<HashID>;
    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut FxHashSet<HashID>;
    fn get_seen_blocks(&self, is_private: bool) -> &SeenBlocks;
    fn get_seen_blocks_mut(&mut self, is_private: bool) -> &mut SeenBlocks;
    fn get_chain_heads(&self, is_private: bool) -> &ChainHeads;
    fn get_chain_heads_mut(&mut self, is_private: bool) -> &mut ChainHeads;
    // fn validate_block_pure(&self, b: &B) -> Result<Arc<(B, BlockMD<B>)>, ChainErr>;
    fn validate_block(&self, b: &B, is_private: bool) -> Result<BlockMD<B>, ChainErr>;
    fn validate_block_local(&self, b: &B, is_private: bool) -> Result<(), ChainErr>;
    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty;
    fn get_fork_measure_pub_priv(&self) -> Heights;
    fn get_heights_pub_priv(&self) -> Heights;

    fn add_tx_to_mempool(&mut self, tx_id: TxId, is_private: bool) -> Result<(), ChainTxErr>;
    fn get_mempool_tx_ids(&self, is_private: bool) -> &FxHashSet<HashID>;
    fn remove_mempool_tx_ids(&mut self, tx_ids: &Vec<HashID>, is_private: bool);

    fn get_chain_weight_at(&self, b: HashID) -> Difficulty {
        Self::get_cached_block(&b).unwrap().1.chain_weight
    }

    fn notify_block(&mut self, id: HashID, is_private: bool) -> Result<(), ChainErr> {
        let b_c = Self::get_cached_block(&id).unwrap();
        self.update_best_block(&b_c.0, &b_c.1, is_private);
        Ok(())
    }

    fn add_block(&mut self, b: B, is_private: bool) -> Result<(), ChainErr> {
        let b_id = b.get_hash();
        let b_c;
        // will error on invalid blocks
        self.validate_block_local(&b, is_private)?;
        // note, it *is* faster to check than just insert
        match Self::get_cached_block(&b_id) {
            Some(b_cached) => {
                b_c = b_cached;
            }
            None => {
                let b_meta = self.validate_block(&b, is_private)?;
                Self::set_cached_block((b, b_meta));
                b_c = Self::get_cached_block(&b_id).unwrap();
            }
        };
        // todo: diff between curr blocks and future blocks
        // todo cont: zip/unzip (or wind/unwind) like bitcoin
        // bitcoin alg (roughly):
        // - find most recent common ancestor (LCA)
        // - find all blocks from current head to LCA
        // - apply those blocks in reverse (add txs to mempool)
        // - find blocks from LCA to new head
        // - apply those blocks in order
        // ! note: state should be calculated in `validate_block_local` -- that way we know that it's always accessible at this point. creating and keeping extra state (if blocks are invalid) is not a problem in this simulator.
        self.apply_block(&b_c.0, is_private)?;
        self.update_best_block(&b_c.0, &b_c.1, is_private);
        self.update_chain_heads(&b_c.0, &b_c.1, is_private);
        self.update_seen_blocks(b_id, is_private);
        // self.save_block(b.get_hash(), (b, b_meta));
        Ok(())
    }

    fn apply_block(&mut self, b: &B, is_private: bool) -> Result<(), ChainApplyErr> {
        self.remove_mempool_tx_ids(b.get_transactions(), is_private);
        // todo: make new state
        Ok(())
    }

    fn get_best_blocks_md(&self, is_private: bool) -> Vec<(HashID, Arc<(B, BlockMD<B>)>)> {
        self.get_best_blocks(is_private)
            .iter()
            .map(|&b| (b, Self::get_cached_block(&b).unwrap().clone()))
            .collect()
    }

    fn update_best_block(&mut self, b: &B, b_meta: &BlockMD<B>, is_private: bool) {
        let bb_id = self.select_best_block(is_private);
        let bb = Self::get_cached_block(&bb_id).unwrap();
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

    fn update_chain_heads(&mut self, _b: &B, _b_meta: &BlockMD<B>, is_private: bool) {
        let chs = self.get_chain_heads_mut(is_private);
        for p_id in _b.all_prev() {
            chs.remove(&p_id);
        }
        chs.insert(_b.get_hash(), _b_meta.chain_weight);
    }

    fn update_seen_blocks(&mut self, b_id: HashID, is_private: bool) {
        self.get_seen_blocks_mut(is_private).insert(b_id);
    }

    fn draft_block(&self, ts: u32, is_private: bool) -> B {
        let mut b = B::new_from(
            ts,
            self.get_best_blocks(is_private).iter().cloned(),
            &self.get_chain_heads(is_private),
            0,
            self.get_chain_id(),
        );
        let p = Self::get_cached_block(&b.prev()).unwrap();
        b.set_difficulty(self.next_difficulty(&p.0, &p.1));
        b.add_transactions(
            self.get_mempool_tx_ids(is_private)
                .iter()
                .cloned()
                .collect(),
        );
        b
    }

    #[inline]
    fn select_best_block(&self, is_private: bool) -> HashID {
        // let blocks: Vec<HashID> = Vec::from_iter(self.get_best_blocks(is_private).iter().cloned());
        B::select_parent_from(self.get_best_blocks(is_private).iter().cloned())
    }

    #[inline]
    fn get_any_best_block(&self, is_private: bool) -> Arc<(B, BlockMD<B>)> {
        Self::get_cached_block(&self.select_best_block(is_private)).unwrap()
    }

    #[inline]
    fn target_from_difficulty(&self, d: Difficulty) -> HashID {
        // division is *expensive*, this saves some cycles

        // for u128
        // HashID::from(u64::MAX / u64::from(d)) << 64

        // for u64
        u64::MAX / u64::from(d)
    }

    fn find_priv_blocks_not_in_pub(&self) -> Vec<B> {
        self.find_missing_blocks_in(true)
    }

    fn find_pub_blocks_not_in_priv(&self) -> Vec<B> {
        self.find_missing_blocks_in(false)
    }

    fn get_all_txs_in_history_of(&self, tip: &B) -> Vec<TxId> {
        let mut prev_txids: Vec<TxId> = vec![];
        for b in tip.all_prev_iter_excluding(&Default::default()) {
            prev_txids.extend(b.get_transactions());
        }
        prev_txids.into_iter().unique().collect()
    }

    /// Return all blocks from one chain (priv or pub) that are needed to update the other
    /// chain (pub or priv) so that both chains have the same history.
    fn find_missing_blocks_in(&self, is_private: bool) -> Vec<B> {
        // if is_private==true then we are looking for private blocks that aren't in pub
        let sync_from_best = self.get_chain_heads(is_private).keys();
        let mut exclude_blocks: SeenBlocks = self.get_seen_blocks(!is_private).clone();
        let mut missing_blocks = Vec::new();
        for id in sync_from_best {
            let b = Self::get_cached_block(id).unwrap().0.clone();
            let bs = Vec::from_iter(b.all_prev_iter_excluding(&exclude_blocks));
            exclude_blocks.extend(bs.iter().map(|b| b.get_hash()));
            missing_blocks.extend(bs);
        }
        // make sure that the blocks we return are from lease recent to most recent.
        missing_blocks.sort_by_key(|b| (b.get_ts(), b.get_height()));
        missing_blocks
    }

    fn block_is_ancestor_of(&self, ancestor: HashID, descendant: HashID) -> bool {
        match self.find_lca_and_intermediates(&vec![ancestor, descendant]) {
            None => false,
            Some(lca_r) => lca_r.0 == ancestor,
        }
    }

    fn block_is_in_best_chain(&self, ancestor: HashID, is_private: bool) -> bool {
        let bbs = self.get_best_blocks(is_private);
        if bbs.contains(&ancestor) {
            return true;
        }
        bbs.iter()
            .any(|&bb| self.block_is_ancestor_of(ancestor, bb))
    }

    /// is this ancestor block one of the parents or in the history of these parents?
    fn block_is_in_history_of(&self, ancestor: HashID, parents: &Vec<HashID>) -> bool {
        if parents.contains(&ancestor) {
            return true;
        }
        for p_id in parents {
            if self.block_is_ancestor_of(ancestor, *p_id) {
                return true;
            }
        }
        false
    }

    /// Return priv blocks that are one better than known public blocks
    fn find_first_priv_blocks_better_than_public(&self) -> Vec<Arc<(B, BlockMD<B>)>> {
        let fm = self.get_fork_measure_pub_priv();
        if fm.private <= fm.public {
            return vec![];
        }
        let priv_blocks_tmp = self.get_best_blocks(true);
        let best_pub_blocks = self.get_best_blocks(false);

        let mut next_edge = priv_blocks_tmp.clone();
        let mut blocks_to_ret: FxHashSet<HashID> = Default::default();
        while next_edge.len() > 0 {
            let curr_edge = next_edge.clone();
            next_edge = Default::default();
            for id in curr_edge {
                if best_pub_blocks.contains(&id) {
                    continue;
                }
                let b = Self::get_cached_block(&id).unwrap();
                if b.1.chain_weight <= fm.public {
                    continue;
                }
                let mut add_to_edge: FxHashSet<HashID> = Default::default();
                for p_id in b.0.all_prev() {
                    // if b has a parent in best_pub_blocks then b satisfies the condition
                    if best_pub_blocks.contains(&p_id) {
                        blocks_to_ret.insert(b.0.get_hash());
                        continue;
                    }
                    let p = Self::get_cached_block(&p_id).unwrap();
                    // if a parent p is worse than fm.public then it's not heavy enough
                    if p.1.chain_weight <= fm.public {
                        continue;
                    }
                    // otherwise the parent is better than pub blocks but we need to check its parents
                    add_to_edge.insert(p_id);
                }
                if add_to_edge.len() == 0 {
                    // if this block didn't produce anthing to add to the edge, then it must satisfy the condition
                    blocks_to_ret.insert(id);
                    continue;
                }
                next_edge = next_edge.union(&add_to_edge).cloned().collect();
            }
        }
        blocks_to_ret
            .into_iter()
            .map(|id| Self::get_cached_block(&id).unwrap())
            .collect()
    }

    /// find most recent common ancestor (technically LCA; the furthest common ancestor should always be the genesis block)
    fn find_lca_and_intermediates(
        &self,
        bs: &Vec<HashID>,
    ) -> Option<Arc<(HashID, BTreeMap<Height, BTreeSet<BInfo>>)>> {
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
                let b = Self::get_cached_block(&h).unwrap();
                let info_set: BTreeSet<_> = BTreeSet::from_iter(vec![BInfo {
                    // _p: PhantomData,
                    id: h,
                    weight: b.1.weight,
                    reflected_weight: b.1.reflected_weight,
                    chain_weight: b.1.chain_weight,
                    local_chain_weight: b.1.local_chain_weight,
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
        let mut intermediate_q = BTreeMap::<u32, FxHashSet<HashID>>::new();
        let mut heights = Vec::new();

        for &id in bs {
            let cache_resp = Self::get_cached_block(&id);
            if cache_resp.is_none() {
                return None;
            }
            let b_md = &cache_resp.unwrap().1;

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
                let b = Self::get_cached_block(&id).unwrap();

                let e = intermediates.entry(b.1.height);
                let v = e.or_insert(Default::default());

                // this part adds all_prev() of the current block to the intermediate_q.
                // we only want to do this if we haven't yet reached the min_h OR we have
                // multiple blocks at this height (and thus haven't found the LCA yet).
                if h > min_h || at_h.len() > 1 {
                    for p in b.0.all_prev() {
                        let p_md = &Self::get_cached_block(&p).unwrap().1;
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
                    reflected_weight: b.1.reflected_weight,
                    chain_weight: b.1.chain_weight,
                    local_chain_weight: b.1.local_chain_weight,
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
        let p = Self::get_cached_block(&*daa2_bs.last().unwrap()).unwrap();
        let block_time_sum: u32 = b.get_ts() - p.0.get_ts();
        let win_rate_sum: Difficulty = b_meta.local_chain_weight - p.1.local_chain_weight;
        Difficulty::from(self.net_args.block_target) * win_rate_sum
            / max(Difficulty::from(block_time_sum), 1)
    }

    fn next_difficulty_daa2(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty {
        let b_hash = b.get_hash();
        return DIFFICULTY_LRU
            .lock()
            .ok()
            .and_then(|mut lru| {
                lru.get(&b_hash).map(|d| d.clone()).or_else(|| {
                    DIFFICULTY_CACHE.lock().ok().and_then(|mut c| {
                        c.get(&(b_hash as u64)).map(|d| d.clone()).or_else(|| {
                            let d = self.next_difficulty_daa2_raw(b, b_meta);
                            lru.put(b_hash, d);
                            c.insert(b_hash as u64, d);
                            Some(d)
                        })
                    })
                })
            })
            .unwrap();
    }

    fn _mempool(&mut self, is_private: bool) -> &mut FxHashSet<HashID> {
        if is_private {
            &mut self.priv_mempool
        } else {
            &mut self.pub_mempool
        }
    }
}

impl<'a, B: BlockT, F: ForkRules<B>> ChainT<'a, B, F> for Chain<B, F> {
    fn new(genesis: B, genesis_meta: BlockMD<B>, net_args: NetworkArgs) -> Chain<B, F> {
        let g_hash = genesis.get_hash();
        let g_diff = genesis.get_difficulty();
        trace!("genesis.hash:{}", g_hash);
        // let mut blocks = HashMap::with_hasher(BuildHasherDefault::<PassThroughHasher>::default());
        // blocks.insert(conv_u128_id_to_u64(g_hash), (genesis, genesis_meta));
        // blocks.insert(g_hash, (genesis, genesis_meta));
        Self::set_cached_block((genesis, genesis_meta));
        Chain {
            // blocks,
            chain_id: g_hash,
            best_blocks: [g_hash].iter().cloned().collect(),
            best_priv_blocks: [g_hash].iter().cloned().collect(),
            seen_pub_blocks: [g_hash].iter().cloned().collect(),
            seen_priv_blocks: [g_hash].iter().cloned().collect(),
            priv_chain_heads: [(g_hash, g_diff)].iter().cloned().collect(),
            pub_chain_heads: [(g_hash, g_diff)].iter().cloned().collect(),
            pub_mempool: Default::default(),
            priv_mempool: Default::default(),
            net_args,
            // fork_rules: LongestChain::<B>::new(),
            _phantom_b: PhantomData,
            _phantom_f: PhantomData,
        }
    }

    fn get_chain_id(&self) -> HashID {
        self.chain_id
    }

    fn get_best_blocks(&self, is_private: bool) -> &FxHashSet<HashID> {
        if is_private {
            &self.best_priv_blocks
        } else {
            &self.best_blocks
        }
    }

    fn get_best_blocks_mut(&mut self, is_private: bool) -> &mut FxHashSet<HashID> {
        if is_private {
            &mut self.best_priv_blocks
        } else {
            &mut self.best_blocks
        }
    }

    fn get_seen_blocks(&self, is_private: bool) -> &SeenBlocks {
        if is_private {
            &self.seen_priv_blocks
        } else {
            &self.seen_pub_blocks
        }
    }

    fn get_seen_blocks_mut(&mut self, is_private: bool) -> &mut SeenBlocks {
        if is_private {
            &mut self.seen_priv_blocks
        } else {
            &mut self.seen_pub_blocks
        }
    }

    fn get_chain_heads(&self, is_private: bool) -> &ChainHeads {
        match is_private {
            true => &self.priv_chain_heads,
            false => &self.pub_chain_heads,
        }
    }

    fn get_chain_heads_mut(&mut self, is_private: bool) -> &mut ChainHeads {
        match is_private {
            true => &mut self.priv_chain_heads,
            false => &mut self.pub_chain_heads,
        }
    }

    fn get_fork_measure_pub_priv(&self) -> Heights {
        Heights {
            public: F::fork_measure(
                &Self::get_cached_block(&self.select_best_block(false))
                    .unwrap()
                    .1,
            ),
            private: F::fork_measure(
                &Self::get_cached_block(&self.select_best_block(true))
                    .unwrap()
                    .1,
            ),
        }
    }

    fn get_heights_pub_priv(&self) -> Heights {
        Heights {
            public: Difficulty::from(
                Self::get_cached_block(&self.select_best_block(false))
                    .unwrap()
                    .1
                    .height,
            ),
            private: Difficulty::from(
                Self::get_cached_block(&self.select_best_block(true))
                    .unwrap()
                    .1
                    .height,
            ),
        }
    }

    fn add_tx_to_mempool(&mut self, tx_id: TxId, is_private: bool) -> Result<(), ChainTxErr> {
        self._mempool(is_private).insert(tx_id);
        Ok(())
    }

    fn get_mempool_tx_ids(&self, is_private: bool) -> &FxHashSet<HashID> {
        if is_private {
            &self.priv_mempool
        } else {
            &self.pub_mempool
        }
    }

    fn remove_mempool_tx_ids(&mut self, tx_ids: &Vec<HashID>, is_private: bool) {
        for tx_id in tx_ids.iter() {
            self._mempool(is_private).remove(tx_id);
        }
    }

    // fn validate_block_pure(&self, _b: &B) -> Result<Arc<(B, BlockMD<B>)>, ChainErr> {
    //     todo!()
    //     // Ok(pm)
    // }

    fn validate_block_local(&self, b: &B, is_private: bool) -> Result<(), ChainErr> {
        for p_id in b.all_prev() {
            if !self.get_seen_blocks(is_private).contains(&p_id) {
                return Err(BlockRefsUnkParent(b.get_hash(), p_id, is_private));
            }
        }

        Ok(())
    }

    fn validate_block(&self, b: &B, is_private: bool) -> Result<BlockMD<B>, ChainErr> {
        let target = self.target_from_difficulty(b.get_difficulty());
        if b.get_hash() > target {
            return Err(BadPoW(b.get_hash(), target));
        }

        let pm = Self::get_cached_block(&b.prev());
        let pm = pm.unwrap();
        if b.get_height() != pm.0.get_height() + 1 {
            return Err(BlockHeightInvalid);
        }

        let all_parents = b.all_prev();
        let pms: Vec<_> = all_parents
            .iter()
            .map(|id| (id, Self::get_cached_block(id)))
            .collect();
        for (p_id, pm) in pms.clone() {
            if pm.is_none() {
                return Err(BlockRefsUnkParent(b.get_hash(), p_id.clone(), is_private));
            }
            let pm_b = &pm.unwrap().0;
            if b.get_ts() < pm_b.get_ts() {
                return Err(TsBeforeParent);
            }
            let p_txids = pm_b.get_transactions();
            let txs_in_blocks_history = self.get_all_txs_in_history_of(pm_b);
            let txids_in_parent: Vec<_> = b
                .get_transactions()
                .iter()
                .filter(|txid| txs_in_blocks_history.contains(txid))
                .collect();
            if txids_in_parent.len() > 0 {
                return Err(TxInParent {
                    b: b.get_hash(),
                    txid: *txids_in_parent[0],
                });
            }
        }
        if pms.len() > 1 {
            let n_ps = pms.len();
            let zipped = pms[..(n_ps - 1)].iter().zip(pms[1..].iter());
            for ((&p1_id, p1), (&p2_id, p2)) in zipped {
                match (p1, p2) {
                    (Some(p1), Some(p2)) => {
                        if p1.1.chain_weight < p2.1.chain_weight {
                            return Err(BadParentOrder(
                                "total".to_string(),
                                (p1.0.get_hash(), p1.1.chain_weight),
                                (p2.0.get_hash(), p2.1.chain_weight),
                            ));
                        }
                        // todo: local_chain_weight isn't a violation of rules under PoR ((sanity) check this later)
                        // if p1.1.local_chain_weight < p2.1.local_chain_weight {
                        //     return Err(BadParentOrder(
                        //         "local".to_string(),
                        //         (p1.0.get_hash(), p1.1.local_chain_weight),
                        //         (p2.0.get_hash(), p2.1.local_chain_weight),
                        //     ));
                        // }
                    }
                    (_, Some(_)) => {
                        return Err(BlockRefsUnkParent(b.get_hash(), p1_id.clone(), is_private))
                    }
                    (_, _) => {
                        return Err(BlockRefsUnkParent(b.get_hash(), p2_id.clone(), is_private))
                    }
                }
            }
        }

        // let pm = self.validate_block_pure(b)?;

        let d = self.next_difficulty(&pm.0, &pm.1);
        if d != b.get_difficulty() {
            return Err(BadDifficulty);
        }

        if pm.0.get_reflected_weight() != pm.0.calc_reflected_weight() {
            return Err(BadReflWeightInBlock);
        }

        // check reflections are in our past
        if pm.0.get_reflected_weight() > 0 {
            let total_refl_weight_expected: Difficulty =
                pm.0.get_txs()
                    .into_iter()
                    .map(|tx| (tx.clone(), tx.get_reflected_l_block()))
                    .filter(|(_, mpb)| mpb.is_some())
                    .map(|(tx, mpb)| (tx, mpb.unwrap()))
                    .filter(|(_, pb)| self.block_is_in_history_of(*pb, &b.all_prev()))
                    .map(|(tx, _)| tx.get_reflected_weight2(self.chain_id))
                    // .map(|pb| B::get_cached_block(&pb).unwrap())
                    // .map(|pb_bmd| pb_bmd.1.weight)
                    .sum();
            if total_refl_weight_expected != pm.0.get_reflected_weight() {
                warn!(
                    "RW exp vs real: {} /= {}",
                    total_refl_weight_expected,
                    pm.0.get_reflected_weight()
                );
                return Err(BadReflWeightInBlock);
            }
        }
        // todo: check each reflection tx has correct weight
        // todo!("implement reflected weight stuff in block validation");
        // - reflected block not seen
        // - reflected header PoW/difficulty mismatch
        // todo: validate txs in general

        let lca_r = self.find_lca_and_intermediates(&b.all_prev()).unwrap();

        /* FIRST VERSION OF THE CODE
         * This was wrong. ~~SOMEHOW the difference in speed between this version of the code, and
         * the version below is like 10x (worse for this one). Wtf?!~~
         *
         */
        let delta_chain_weight;
        let reflected_delta_chain_weight;
        let lca_chain_weight;
        let lca_local_chain_weight;
        if lca_r.0 == pm.0.get_hash() {
            delta_chain_weight = 0;
            reflected_delta_chain_weight = 0;
            lca_chain_weight = pm.1.chain_weight;
            lca_local_chain_weight = pm.1.local_chain_weight;
        } else {
            let lca_md = &Self::get_cached_block(&lca_r.0).unwrap().clone().1;
            lca_chain_weight = lca_md.chain_weight;
            lca_local_chain_weight = lca_md.local_chain_weight;
            let lca_height = lca_md.height;
            let [dcw, rdcw] = [|i: &BInfo| i.weight, |i: &BInfo| i.reflected_weight].map(|f| {
                lca_r
                    .1
                    .iter()
                    .filter(|(&k, _v)| k != lca_height) // make sure we don't count the LCA in delta CW
                    .map::<Difficulty, _>(|(_k, v)| v.iter().map(f).sum())
                    .sum()
            });
            delta_chain_weight = dcw;
            reflected_delta_chain_weight = rdcw;
            // todo: remove below if/when above works properly
            // delta_chain_weight = lca_r
            //     .1
            //     .iter()
            //     .filter(|(&k, _v)| k != lca_height) // make sure we don't count the LCA in delta CW
            //     .map::<Difficulty, _>(|(_k, v)| v.iter().map(|info| info.weight).sum())
            //     .sum();
            // reflected_delta_chain_weight = lca_r
            //     .1
            //     .iter()
            //     .filter(|(&k, _v)| k != lca_height)
            //     .map::<Difficulty, _>(|(_, v)| v.iter().map(|i| i.reflected_weight).sum())
            //     .sum();
        }

        /* SECOND VERSION OF THE CODE
         */
        // let lca_md = Self::get_cached_block(&lca_r.0).unwrap().1.clone();
        // let delta_chain_weight: Difficulty = lca_r
        //     .1
        //     .iter()
        //     .filter(|(&k, _v)| k != lca_md.height) // make sure we don't count the LCA in delta CW
        //     .map::<Difficulty, _>(|(_k, v)| v.iter().map(|info| info.weight).sum())
        //     .sum();
        // let lca_chain_weight = lca_md.chain_weight;

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
                let mut daa2_blocks = Vec::with_capacity(self.net_args.daa2_n_blocks);
                daa2_blocks.push(b.get_hash());
                let p_daa2_bs = BlockMD::<B>::get_daa2_blocks(pm.0.get_hash()).unwrap();
                daa2_blocks.extend_from_slice(&p_daa2_bs[..(self.net_args.daa2_n_blocks - 1)]);
                BlockMD::<B>::set_daa2_blocks(b.get_hash(), daa2_blocks);
            }
        }

        let reflected_weight = b.get_reflected_weight();
        let all_delta_local_w = delta_chain_weight + d;
        let all_delta_refl_w = reflected_delta_chain_weight + reflected_weight;
        let local_chain_weight = lca_local_chain_weight + all_delta_local_w;
        let chain_weight = lca_chain_weight + all_delta_local_w + all_delta_refl_w;
        Ok(BlockMD {
            difficulty: d,
            height: pm.1.height + 1,
            weight: d,
            local_chain_weight,
            reflected_weight,
            chain_weight,
            // daa2_blocks,
            _phantom_b: PhantomData,
        })
    }

    fn next_difficulty(&self, b: &B, b_meta: &BlockMD<B>) -> Difficulty {
        self.next_difficulty_daa2(b, b_meta)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn _setup_chain<'a, B: BlockT, F: ForkRules<B>>(
        ts: Option<u32>,
    ) -> (B, BlockMD<B>, Chain<B, F>) {
        let genesis = B::genesis(ts.unwrap_or(0));
        let net_args = NetworkArgs::new(10);
        let g_md = BlockMD::mk_genesis_md(&genesis, net_args.daa2_n_blocks);
        let chain = Chain::new(genesis.clone(), g_md.clone(), net_args);
        (genesis, g_md, chain)
    }

    #[cfg(debug_assertions)]
    /// make the id (PoW proxy) small so that it passes all difficulty checks.
    fn _mk_draft_block<'a, B: BlockT, F: ForkRules<B>, C: ChainT<'a, B, F>>(
        chain: &C,
        ts: u32,
        is_private: bool,
    ) -> B {
        _mk_draft_block_w_txs(chain, ts, is_private, vec![])
    }

    fn _mk_draft_block_w_txs<'a, B: BlockT, F: ForkRules<B>, C: ChainT<'a, B, F>>(
        chain: &C,
        ts: u32,
        is_private: bool,
        txs: Vec<TxId>,
    ) -> B {
        let mut b = chain.draft_block(ts, is_private);
        txs.iter().for_each(|&tx_id| b.add_transaction(tx_id));
        b.test_set_work_bits(24)
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
        assert_eq!(genesis.get_height(), 0, "genesis height should be 0");
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

        assert_eq!(b.get_reflected_weight(), 0);

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
    fn update_best_heaviest_block_w_refls() -> Result<(), String> {
        let (genesis, _g_md, mut chain) = _setup_chain::<Block, HeaviestChain<Block>>(None);
        /// a test block to add as a reflecting block
        /// todo: should be on a diff chain
        let b_refl = _mk_draft_block(&mut chain, 10, false);

        let refl_tx = Transaction::ReflectAndProve(ReflectionData {
            r_chain: 1234, // chain.get_chain_id(),
            r_block: b_refl.get_hash(),
            weight: b_refl.d,
            proving_ancestor_id: genesis.get_hash(),
        });
        Transaction::set_cached_tx(refl_tx.clone());

        let b = _mk_draft_block_w_txs(&mut chain, 10, false, vec![refl_tx.id()]);

        // reflecting block is at the same diff as `b`
        assert_eq!(b.get_difficulty(), b.get_reflected_weight());

        assert_eq!(chain.select_best_block(false), genesis.get_hash());
        assert_eq!(chain.select_best_block(true), genesis.get_hash());

        chain.add_block(b.clone(), false)?;

        let b_md = &Block::get_cached_block(&b.get_hash()).unwrap().1;
        assert_ne!(b_md.chain_weight, b_md.local_chain_weight);
        assert_eq!(
            b_md.chain_weight,
            b_md.local_chain_weight + b.get_reflected_weight()
        );

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
        assert_eq!(
            chain.get_chain_heads(false)[&b.get_hash()],
            chain.get_chain_weight_at(b.get_hash())
        );
        assert_eq!(
            chain.get_chain_heads(true)[&genesis.get_hash()],
            chain.get_chain_weight_at(genesis.get_hash())
        );

        chain.add_block(b.clone(), true)?;

        assert_eq!(chain.select_best_block(false), b.get_hash());
        assert_eq!(chain.select_best_block(true), b.get_hash());
        assert_eq!(
            chain.get_chain_heads(true)[&b.get_hash()],
            chain.get_chain_weight_at(b.get_hash())
        );

        chain.add_block(b2.clone(), false)?;
        chain.add_block(b3.clone(), false)?;

        assert_eq!(chain.get_chain_weight_at(b2.get_hash()), 1000);
        assert_eq!(chain.get_chain_weight_at(b3.get_hash()), 1000);

        let b4 = _mk_draft_block(&chain, 20, false);
        chain.add_block(b4.clone(), false)?;
        let b4_md = &B::get_cached_block(&b4.get_hash()).unwrap().1;

        assert_eq!(b4_md.height, 2, "b4_md has correct height");
        assert_eq!(b4_md.weight, 1000, "b4_md has correct weight");
        assert_eq!(b4_md.chain_weight, 4000, "b4_md has correct Σ weight");

        for &b in chain.get_best_blocks(false) {
            assert_eq!(B::get_cached_block(&b).unwrap().1.height, 2);
        }

        for i in 0..10 {
            let tmp_b = _mk_draft_block(&chain, 30 + i * 10, false);
            chain.add_block(tmp_b, false)?;
        }

        let b130 = _mk_draft_block(&chain, 130, false);
        chain.add_block(b130.clone(), false)?;
        let b140 = _mk_draft_block(&chain, 140, false);
        chain.add_block(b140.clone(), false)?;

        let b130_md = &B::get_cached_block(&b130.get_hash()).unwrap().1;
        let b140_md = &B::get_cached_block(&b140.get_hash()).unwrap().1;

        assert_eq!(b130.all_prev().len(), 1);
        assert_eq!(
            b140_md.chain_weight,
            b140.get_difficulty() + b130_md.chain_weight
        );
        assert_eq!(
            chain.get_chain_heads(false)[&b140.get_hash()],
            chain.get_chain_weight_at(b140.get_hash())
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
            chain.net_args.daa2_n_blocks,
        );

        let next_d = chain.next_difficulty(&genesis, &g_md);
        // assert_eq!(next_d, 1000);
        assert_eq!(next_d, 1000);

        let b = _mk_draft_block(&chain, 10, false);

        chain.validate_block(&b, false)?;
        assert_eq!(
            BlockMD::<B>::get_daa2_blocks(genesis.get_hash())
                .unwrap()
                .len(),
            chain.net_args.daa2_n_blocks,
        );

        let is_priv = false;
        let pre_bb = chain.select_best_block(is_priv);
        assert_eq!(
            B::get_cached_block(&chain.select_best_block(is_priv))
                .unwrap()
                .1
                .height,
            0
        );
        assert_eq!(B::get_cached_block(&b.get_hash()).is_none(), true);
        chain.add_block(b.clone(), is_priv)?;
        assert_eq!(B::get_cached_block(&b.get_hash()).is_some(), true);

        assert_ne!(chain.select_best_block(is_priv), pre_bb);
        assert_ne!(
            B::get_cached_block(&chain.select_best_block(is_priv))
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
    fn test_find_first_priv_blocks_better_than_public_longest() -> Result<(), ChainErr> {
        let (_g, _g_md, mut chain) = _setup_chain::<Block, LongestChain<Block>>(None);
        let b = _mk_draft_block(&chain, 10, false);
        chain.add_block(b.clone(), false)?;
        assert_eq!(chain.find_first_priv_blocks_better_than_public().len(), 0);
        chain.add_block(b, true)?;
        assert_eq!(chain.find_first_priv_blocks_better_than_public().len(), 0);

        let b1 = _mk_draft_block(&chain, 20, true);
        let b1_id = b1.get_hash();
        chain.add_block(b1.clone(), true)?;
        let ps: Vec<_> = chain
            .find_first_priv_blocks_better_than_public()
            .iter()
            .map(|p| p.0.get_hash())
            .collect();
        assert_eq!(ps, vec![b1_id]);

        let b2 = _mk_draft_block(&chain, 30, true);
        let b2_id = b2.get_hash();
        chain.add_block(b2, true)?;
        let ps: Vec<_> = chain
            .find_first_priv_blocks_better_than_public()
            .iter()
            .map(|p| p.0.get_hash())
            .collect();
        assert_eq!(ps, vec![b1_id]);

        chain.add_block(b1.clone(), false)?;
        let ps: Vec<_> = chain
            .find_first_priv_blocks_better_than_public()
            .iter()
            .map(|p| p.0.get_hash())
            .collect();
        assert_eq!(ps, vec![b2_id]);

        Ok(())
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

    #[test]
    #[ignore]
    fn test_equivalence_of_notify_block_vs_add_block() {}
}
