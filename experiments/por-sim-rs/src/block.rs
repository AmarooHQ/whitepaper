use crate::block_metadata::BlockMD;
use crate::hash::*;
use crate::transactions::{Transaction, TxId};
use crate::types::*;
use array_tool::vec::Uniq;
use getrandom::getrandom;
use itertools::{sorted, Itertools};
use lazy_static::lazy_static;
use lru::LruCache;
use rand::prelude::*;
use rand::seq::IteratorRandom;
use std::cmp::Ordering;
use std::collections::VecDeque;
use std::env;
use std::fmt::Debug;
use std::hash::Hash;
use std::iter::FilterMap;
use std::iter::Map;
use std::iter::{FromIterator, IntoIterator};
use std::sync::{Arc, Mutex};
use std::time::SystemTime;
use std::{fmt, fmt::Display};

// static BLOCK_HASH_F: fn(u64) -> u64 = xx_hash_u64;
// static BLOCK_HASH_F: fn(u64) -> u64 = xx_rev_hash_u64;
// static BLOCK_HASH_F: fn(u64) -> u64 = blake3_hash_u64;
// static BLOCK_HASH_F: fn(u64) -> u64 = sha256_hash_u64;

lazy_static! {
    static ref BLOCK_HASH_F: fn(u64) -> u64 = match env::var("POR_SIM_HASH") {
        Ok(h) => match h.as_str() {
            "blake" => blake3_hash_u64,
            "blake3" => blake3_hash_u64,
            "xx" => xx_hash_u64,
            "xxh3" => xx_hash_u64,
            "xx_rev" => xx_rev_hash_u64,
            "sha256" => sha256_hash_u64,
            "sha1" => sha1_hash_u64,
            "md5" => md5_hash_u64,
            _ => panic!("Unknown hashing algorithm: {}", h),
        },
        // if env var isn't present, default to xx
        _ => xx_hash_u64,
    };
    static ref BLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(Block, BlockMD<Block>)>>> =
        Mutex::new(Default::default());
    static ref BLOCK_LRU: Mutex<LruCache<u64, Arc<(Block, BlockMD<Block>)>>> =
        Mutex::new(LruCache::new(1024 * 16));
    static ref DAGBLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
        Mutex::new(Default::default());
    static ref DAGBLOCK_LRU: Mutex<LruCache<u64, Arc<(DagBlock, BlockMD<DagBlock>)>>> =
        Mutex::new(LruCache::new(1024 * 16));
    static ref EMPTY_HASH_ID_SET: PassThruHashSet<HashID> = Default::default();
}

pub struct PrevBlockIter<B: BlockT> {
    curr_block: Arc<(B, BlockMD<B>)>,
}

impl<B: BlockT> Iterator for PrevBlockIter<B> {
    type Item = Arc<(B, BlockMD<B>)>;

    fn next(&mut self) -> Option<Self::Item> {
        let p_id = self.curr_block.0.prev();
        if p_id == self.curr_block.0.get_hash() {
            None
        } else {
            match B::get_cached_block(&p_id) {
                None => None,
                Some(p) => {
                    self.curr_block = p.clone();
                    Some(p)
                }
            }
        }
    }
}

pub struct FilteredAllPrevBlockIter<'a, B: BlockT> {
    last_block: Option<Arc<(B, BlockMD<B>)>>,
    edge_blocks: VecDeque<HashID>,
    exclude_blocks: &'a SeenBlocks,
    seen_blocks: SeenBlocks,
}

impl<'a, B: BlockT> FilteredAllPrevBlockIter<'a, B> {
    fn new(start_block: &B, exclude_blocks: &'a SeenBlocks) -> Self {
        // start our edge blocks with the provided start_block
        let edge_blocks = VecDeque::from(vec![start_block.get_hash()]);
        FilteredAllPrevBlockIter {
            last_block: None,
            edge_blocks,
            exclude_blocks,
            seen_blocks: Default::default(),
        }
    }

    fn new_all(start_block: &B) -> Self {
        Self::new(start_block, &EMPTY_HASH_ID_SET)
    }
}

impl<'a, B: BlockT> Iterator for FilteredAllPrevBlockIter<'a, B> {
    type Item = Arc<(B, BlockMD<B>)>;

    fn next(&mut self) -> Option<Self::Item> {
        let p_id = self.edge_blocks.pop_front()?;
        if self.seen_blocks.contains(&p_id) || self.exclude_blocks.contains(&p_id) {
            return self.next();
        }
        self.seen_blocks.insert(p_id);
        let p = B::get_cached_block(&p_id);
        // genesis condition
        if p_id
            == self
                .last_block
                .as_ref()
                .map(|b| b.0.get_hash())
                .unwrap_or(0)
        {
            None
        } else {
            match p {
                None => None,
                Some(p) => {
                    self.edge_blocks.extend(p.0.all_parents());
                    self.last_block = Some(p.clone());
                    Some(p)
                }
            }
        }
    }
}

pub trait BlockT: Clone + Debug + Display + PartialEq + Eq + PartialOrd + Hash {
    // note: this doesn't work b/c lazy_static inits those things as a Struct apparently.
    // const MY_CACHE: Mutex<PassThruHashMap<u64, Arc<(Self, BlockMD<Self>)>>>;

    fn new(ts: u32, parent: HashID, d: Difficulty, chain_id: HashID, cw: Difficulty) -> Self;
    fn new_from(
        ts: u32,
        parent_opts: impl IntoIterator<Item = HashID>,
        chain_heads: &ChainHeads,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self;
    fn genesis(ts: u32) -> Self;
    fn get_hash(&self) -> HashID;
    // fn hash_sha3(&self) -> HashID;
    fn prev(&self) -> HashID;
    fn all_parents(&self) -> Vec<HashID>;

    fn prev_iter(&self) -> PrevBlockIter<Self> {
        PrevBlockIter {
            curr_block: Self::get_cached_block(&self.get_hash()).unwrap(),
        }
    }

    fn all_prev_iter(&self) -> FilteredAllPrevBlockIter<Self> {
        FilteredAllPrevBlockIter::new(self, &EMPTY_HASH_ID_SET)
    }

    fn all_prev_iter_excluding<'a>(
        &self,
        exclude_blocks: &'a SeenBlocks,
    ) -> FilteredAllPrevBlockIter<'a, Self> {
        FilteredAllPrevBlockIter::new(self, exclude_blocks)
    }

    fn get_ts(&self) -> u32;
    fn set_ts(&mut self, ts: u32);
    fn increment_nonce(&mut self);
    fn get_difficulty(&self) -> Difficulty;
    fn set_difficulty(&mut self, d: Difficulty);
    fn get_height(&self) -> Height;

    fn get_chain_id(&self) -> HashID;

    fn get_rand_id() -> HashID {
        // Self::get_urand_id()
        thread_rng().gen::<u64>()
            ^ sha256_hash_u64(
                SystemTime::now()
                    .duration_since(SystemTime::UNIX_EPOCH)
                    .unwrap()
                    .as_nanos() as u64,
            )
    }

    fn get_urand_id() -> HashID {
        let mut e: [u8; 16] = [0; 16];
        getrandom(&mut e).unwrap();
        u128::from_be_bytes(e) as HashID
    }

    fn select_parent_from<B, C: IntoIterator<Item = B>>(ps: C) -> B {
        ps.into_iter().choose(&mut rand::thread_rng()).unwrap()
    }

    #[cfg(test)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self;

    fn get_cached_block(id: &HashID) -> Option<Arc<(Self, BlockMD<Self>)>>;
    // fn get_cached_blocks(ids: &[HashID]) -> Option<Box<[Arc<(Self, BlockMD<Self>)>]>>;
    fn set_cached_block(b: (Self, BlockMD<Self>));

    // transaction support
    fn get_transactions(&self) -> &Vec<TxId>;
    // fn add_transaction(&mut self, id: TxId);
    // fn add_transactions(&mut self, ids: Vec<TxId>);
    fn _push_tx(&mut self, id: TxId);
    fn get_reflected_ancestors(&self) -> Option<&Vec<(HashID, HashID)>>;
    /// Record that an ancestor of this block was reflected by R chain
    fn add_reflected_ancestor(&mut self, l_b_id: HashID, r_chain_id: HashID);
    fn add_refl_weight(&mut self, w: Difficulty);

    /// Claimed reflected weight
    fn get_reflected_weight(&self) -> Difficulty;

    fn get_chain_weight(&self) -> Difficulty;
    fn set_chain_weight(&mut self, cw: Difficulty);

    fn get_total_weight(&self) -> Difficulty {
        self.get_reflected_weight() + self.get_difficulty()
    }

    /// Weight reflected by this block (calculated from txs).
    /// Note: this does not do conversion to local weight since the hashing algs are the same
    /// Todo: (in future) account for conversion of weight
    fn calc_reflected_weight(&self) -> Difficulty {
        self.get_transactions()
            .iter()
            .map(|&tx_id| {
                if let Some(tx) = Transaction::get_cached_tx(tx_id) {
                    // match tx.get_reflection_data() {
                    //     Some(r) => Self::get_cached_block(&r.block)
                    //         .map(|md| md.1.difficulty)
                    //         .unwrap_or(0),
                    //     _ => 0,
                    // }
                    tx.get_reflected_weight2(self.get_chain_id())
                } else {
                    0
                }
            })
            .sum()
    }

    fn get_cached_txs(&self) -> Option<Vec<Arc<Transaction>>>;
    fn put_cached_txs(&mut self, txs: Vec<Arc<Transaction>>);
    fn wipe_cached_txs(&mut self);

    fn get_txs(&self) -> Vec<Arc<Transaction>> {
        match self.get_cached_txs() {
            None => {
                let txs: Vec<_> = self
                    .get_transactions()
                    .iter()
                    .filter_map(|&tx_id| Transaction::get_cached_tx(tx_id))
                    .collect();
                // we want to access this from Arc<Block>, so we can't mutate
                // self.put_cached_txs(txs.clone());
                txs
            }
            Some(txs) => txs,
        }
    }

    fn add_transaction(&mut self, id: TxId) {
        self.add_transactions(vec![id]);
    }

    fn add_transactions(&mut self, ids: Vec<TxId>) {
        for &id in ids.iter().unique() {
            if !self.get_transactions().contains(&id) {
                if let Some(tx) = Transaction::get_cached_tx(id) {
                    if let Some(ancestors) = tx.get_reflected_l_blocks() {
                        let r = tx.get_reflection_data().unwrap();
                        for &ancestor in ancestors {
                            self.add_reflected_ancestor(ancestor, r.r_chain);
                        }
                        self.add_refl_weight(tx.get_reflected_weight2(self.get_chain_id()));
                    }
                }
                self._push_tx(id);
            }
        }
        // clear tx cache and then update it
        self.wipe_cached_txs();
        self.put_cached_txs(self.get_txs());
        // simulate change of hash when txs added
        self.increment_nonce();
    }
}

pub trait SingleParentBlockT: BlockT {}

pub trait ManyParentsBlockT: BlockT {
    fn new_multi_parent(
        timestamp: u32,
        parents: impl IntoIterator<Item = HashID>,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self;
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Block {
    pub id: HashID,
    pub parent: HashID,
    pub timestamp: u32,
    pub d: Difficulty,
    pub refl_weight: Difficulty,
    pub h: Height,
    pub txs: Vec<TxId>,
    pub chain_id: HashID,
    cw: Difficulty,
    // pub reflected_ancestors: Vec<(HashID, HashID)>,
    // pub best_refl_ancestors:
    pub cached_txs: Option<Vec<Arc<Transaction>>>,
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

impl PartialOrd for Block {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Block {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.get_height().cmp(&other.get_height()) {
            Ordering::Equal => match self.get_difficulty().cmp(&other.get_difficulty()) {
                Ordering::Equal => self.get_hash().cmp(&other.get_hash()),
                _ord => _ord,
            },
            _ord => _ord,
        }
    }
}

impl SingleParentBlockT for Block {}

impl BlockT for Block {
    fn new(ts: u32, parent: HashID, d: Difficulty, chain_id: HashID, cw: Difficulty) -> Self {
        // let mut e: [u8; 16] = [0; 16];
        // getrandom(&mut e).unwrap();
        // let id = u128::from_be_bytes(e) as HashID;
        let id = Self::get_rand_id();
        // let (h, reflected_ancestors) = Self::get_cached_block(&parent)
        //     .map(|b| (b.0.h + 1, b.0.reflected_ancestors.clone()))
        //     .unwrap_or((0, vec![]));
        let p_bmd = Self::get_cached_block(&parent);
        let h = p_bmd.map(|b| b.0.h + 1).unwrap_or(0);
        // let cw = d + p_bmd.map(|b| b.1.chain_weight).unwrap_or(0);
        Self {
            id,
            timestamp: ts,
            parent,
            d,
            h,
            refl_weight: 0,
            txs: vec![],
            chain_id,
            cw,
            cached_txs: None,
        }
    }

    fn new_from(
        ts: u32,
        parent_opts: impl IntoIterator<Item = HashID>,
        _chain_heads: &ChainHeads,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self {
        Self::new(ts, Self::select_parent_from(parent_opts), d, chain_id, cw)
    }

    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0, 0, 0);
        g.id >>= 10;
        g.parent = g.id;
        g.chain_id = g.id;
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

    fn all_parents(&self) -> Vec<HashID> {
        vec![self.parent]
    }

    fn get_ts(&self) -> u32 {
        self.timestamp
    }

    fn set_ts(&mut self, ts: u32) {
        self.timestamp = ts
    }
    fn get_height(&self) -> Height {
        self.h
    }

    #[inline(always)]
    fn increment_nonce(&mut self) {
        self.id = BLOCK_HASH_F(self.id + 1337)
    }

    fn get_difficulty(&self) -> Difficulty {
        self.d
    }
    fn set_difficulty(&mut self, d: Difficulty) {
        self.d = d;
    }
    fn get_chain_id(&self) -> HashID {
        self.chain_id
    }

    #[cfg(test)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= HashID::MAX >> n_bits;
        self.clone()
    }

    fn get_cached_block(id: &HashID) -> Option<Arc<(Self, BlockMD<Self>)>> {
        BLOCK_LRU.lock().ok().and_then(|mut c| {
            c.get(id).map(|b| b.clone()).or_else(|| {
                BLOCK_CACHE
                    .lock()
                    .ok()
                    .and_then(|c| c.get(&id).map(|b| b.clone()))
            })
        })
    }

    // fn get_cached_blocks(ids: &[HashID]) -> Option<Box<[Arc<(Self, BlockMD<Self>)>]>> {

    // }

    fn set_cached_block(b: (Self, BlockMD<Self>)) {
        let b_id = b.0.get_hash();
        let b_arc = Arc::new(b);
        BLOCK_LRU.lock().unwrap().put(b_id, b_arc.clone());
        BLOCK_CACHE.lock().unwrap().insert(b_id, b_arc.clone());
    }

    fn get_transactions(&self) -> &Vec<TxId> {
        &self.txs
    }

    fn get_reflected_weight(&self) -> Difficulty {
        self.refl_weight
    }

    fn get_chain_weight(&self) -> Difficulty {
        self.cw
    }

    fn set_chain_weight(&mut self, cw: Difficulty) {
        self.cw = cw
    }

    fn _push_tx(&mut self, id: TxId) {
        self.txs.push(id)
    }

    fn get_cached_txs(&self) -> Option<Vec<Arc<Transaction>>> {
        self.cached_txs.clone()
    }

    fn put_cached_txs(&mut self, txs: Vec<Arc<Transaction>>) {
        self.cached_txs = Some(txs);
    }

    fn wipe_cached_txs(&mut self) {
        self.cached_txs = None;
    }

    fn get_reflected_ancestors(&self) -> Option<&Vec<(HashID, HashID)>> {
        // &self.reflected_ancestors
        None
    }

    fn add_reflected_ancestor(&mut self, b_id: HashID, r_chain_id: HashID) {
        // self.reflected_ancestors.push((b_id, r_chain_id))
    }

    fn add_refl_weight(&mut self, w: Difficulty) {
        self.refl_weight += w;
        self.cw += w;
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Hash)]
pub struct DagBlock {
    pub id: HashID,
    pub parents: Vec<HashID>,
    pub timestamp: u32,
    d: Difficulty,
    refl_weight: Difficulty,
    cw: Difficulty,
    h: Height,
    txs: Vec<TxId>,
    chain_id: HashID,
    cached_txs: Option<Vec<Arc<Transaction>>>,
    // pub reflected_ancestors: Vec<(HashID, HashID)>,
}

impl Display for DagBlock {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            // "DagBlock@{:4} | {:#16x} -> {:?}",
            "DagBlock@{:4} | {:#} -> {:?}",
            self.timestamp, self.id, self.parents
        )
    }
}

impl ManyParentsBlockT for DagBlock {
    fn new_multi_parent(
        timestamp: u32,
        parents: impl IntoIterator<Item = HashID>,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self {
        let parents = Vec::from_iter(parents);
        let p1 = Self::get_cached_block(&parents[0]);
        let h = p1.map(|b| b.0.h + 1).unwrap_or(0);
        // let reflected_ancestors = parents
        //     .iter()
        //     .map(Self::get_cached_block)
        //     .map(|mb| {
        //         mb.map(|b| b.0.reflected_ancestors.clone())
        //             .unwrap_or(vec![])
        //     })
        //     .collect::<Vec<_>>()
        //     .concat()
        //     .unique();
        DagBlock {
            timestamp,
            id: Self::get_rand_id(),
            parents,
            d,
            h,
            refl_weight: 0,
            txs: vec![],
            chain_id,
            cw,
            cached_txs: None,
        }
    }
}

impl BlockT for DagBlock {
    fn new(
        timestamp: u32,
        parent: HashID,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self {
        Self::new_multi_parent(timestamp, vec![parent], d, chain_id, cw)
    }
    fn new_from(
        ts: u32,
        parent_opts: impl IntoIterator<Item = HashID>,
        chain_heads: &ChainHeads,
        d: Difficulty,
        chain_id: HashID,
        cw: Difficulty,
    ) -> Self {
        let parents = parent_opts
            .into_iter()
            .chain(
                sorted(chain_heads.iter().map(|(id, cw)| (cw, id)))
                    .rev()
                    .map(|(_cw, id)| id)
                    .cloned(),
            )
            .unique();
        Self::new_multi_parent(ts, parents, d, chain_id, cw)
    }
    fn genesis(ts: u32) -> Self {
        let mut g = Self::new(ts, 0, 0, 0, 0);
        g.id >>= 10;
        g.parents = vec![g.id];
        g.chain_id = g.id;
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
    fn all_parents(&self) -> Vec<HashID> {
        self.parents.clone()
    }
    fn get_ts(&self) -> u32 {
        self.timestamp
    }
    fn set_ts(&mut self, ts: u32) {
        self.timestamp = ts
    }
    fn get_height(&self) -> Height {
        self.h
    }
    #[inline(always)]
    fn increment_nonce(&mut self) {
        self.id = BLOCK_HASH_F(self.id + 1337)
    }
    fn get_difficulty(&self) -> Difficulty {
        self.d
    }
    fn set_difficulty(&mut self, d: Difficulty) {
        self.d = d;
    }
    fn get_chain_id(&self) -> HashID {
        self.chain_id
    }
    #[cfg(test)]
    fn test_set_work_bits(&mut self, n_bits: u8) -> Self {
        self.id &= HashID::MAX >> n_bits;
        self.clone()
    }

    fn get_cached_block(id: &HashID) -> Option<Arc<(Self, BlockMD<Self>)>> {
        DAGBLOCK_LRU.lock().ok().and_then(|mut c| {
            c.get(id).map(|b| b.clone()).or_else(|| {
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

    fn get_transactions(&self) -> &Vec<TxId> {
        &self.txs
    }

    fn get_reflected_weight(&self) -> Difficulty {
        self.refl_weight
    }

    fn get_chain_weight(&self) -> Difficulty {
        self.cw
    }

    fn set_chain_weight(&mut self, cw: Difficulty) {
        self.cw = cw
    }

    fn _push_tx(&mut self, id: TxId) {
        self.txs.push(id)
    }

    fn get_cached_txs(&self) -> Option<Vec<Arc<Transaction>>> {
        self.cached_txs.clone()
    }

    fn put_cached_txs(&mut self, txs: Vec<Arc<Transaction>>) {
        self.cached_txs = Some(txs);
    }

    fn wipe_cached_txs(&mut self) {
        self.cached_txs = None;
    }

    fn get_reflected_ancestors(&self) -> Option<&Vec<(HashID, HashID)>> {
        // &self.reflected_ancestors
        None
    }

    fn add_reflected_ancestor(&mut self, b_id: HashID, r_chain_id: HashID) {
        // self.reflected_ancestors.push((b_id, r_chain_id))
    }

    fn add_refl_weight(&mut self, w: Difficulty) {
        self.refl_weight += w;
        self.cw += w;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::transactions::ReflectionData;

    #[test]
    fn hash_sha3() -> Result<(), String> {
        let _b = Block::genesis(0);
        // let _h = b.hash_sha3();
        // DagBlock::genesis(0).hash_sha3();
        Ok(())
    }

    #[test]
    fn adding_por_transaction_updates_header_deets() {
        fn check_block<B: BlockT>(mut _b: B) {
            let orig_id = _b.get_hash();
            let tx = Transaction::ReflectAndProve(ReflectionData {
                r_chain: orig_id + 1,
                r_block: 0,
                r_cw: 0,
                weight: 222,
                l_headers: vec![orig_id],
                l_cw: (_b.get_chain_weight(), ne_vec![orig_id]),
            });
            Transaction::set_cached_tx(tx.clone());
            _b.set_difficulty(111);
            let w1 = _b.get_difficulty();
            let rw1 = _b.get_reflected_weight();
            assert_eq!(w1, 111);
            assert_eq!(rw1, 0);
            // assert_eq!(_b.get_reflected_ancestors().len(), 0);

            _b.add_transaction(tx.get_hash());
            let w2 = _b.get_difficulty();
            let rw2 = _b.get_reflected_weight();
            assert_eq!(w2, 111);
            assert_eq!(rw2, 222);
            // todo: do we need to check that the proving_ancestor_id block is actually in our history?
            // assert_eq!(_b.get_reflected_ancestors().len(), 1);

            // need block to be available in cache -- NB: we don't care about BlockMD in this test
            B::set_cached_block((_b.clone(), BlockMD::mk_genesis_md(&_b.clone(), 10)));

            let mut b2 = B::new(
                10,
                _b.get_hash(),
                _b.get_difficulty(),
                _b.get_chain_id(),
                _b.get_chain_weight() + _b.get_difficulty(),
            );
            // assert_eq!(b2.get_reflected_ancestors().len(), 1);
            assert_eq!(b2.get_reflected_weight(), 0);
            let tx2 = Transaction::ReflectAndProve(ReflectionData {
                r_chain: orig_id + 1,
                r_block: 0,
                r_cw: 0,
                weight: 333,
                l_headers: vec![orig_id],
                l_cw: (_b.get_chain_weight(), ne_vec![orig_id]),
            });
            Transaction::set_cached_tx(tx2.clone());
            b2.add_transaction(tx2.get_hash());
            // no changes here b/c proving_ancestor_id is already in list of prev reflected blocks
            // println!("{:?}", b2.get_reflected_ancestors());
            // assert_eq!(b2.get_reflected_ancestors().len(), 1);
            // assert_eq!(b2.get_reflected_weight(), 0);
            assert_eq!(b2.get_reflected_weight(), 333);

            let tx3 = Transaction::ReflectAndProve(ReflectionData {
                r_chain: orig_id + 1,
                r_block: 0,
                r_cw: 0,
                weight: 333,
                l_headers: vec![_b.get_hash()],
                l_cw: (_b.get_chain_weight(), ne_vec![_b.get_hash()]),
            });
            Transaction::set_cached_tx(tx3.clone());
            b2.add_transaction(tx3.get_hash());
            // changes now b/c hash of _b changed when we added a transaction
            // assert_eq!(b2.get_reflected_ancestors().len(), 2);
            // assert_eq!(b2.get_reflected_weight(), 333);
            assert_eq!(b2.get_reflected_weight(), 666);
        }
        // let mut _b = Block::genesis(0);
        check_block(Block::genesis(0));
        check_block(DagBlock::genesis(0));
    }
}
