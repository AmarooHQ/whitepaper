use hashers::fx_hash::FxHasher;
use hashers::null::PassThroughHasher;
use std::collections::{HashMap, HashSet};
use std::hash::BuildHasherDefault;

pub type Difficulty = u32;
pub type HashID = u64;
pub type Height = u32;
pub type Timestamp = u32;

pub type Weight = Difficulty;
pub type ChainWeight = Weight;

pub type PassThruHashMap<K, V> = HashMap<K, V, BuildHasherDefault<PassThroughHasher>>;
pub type FxHashSet<K> = HashSet<K, BuildHasherDefault<FxHasher>>;

pub type ChainHeads = PassThruHashMap<HashID, ChainWeight>;

// pub type SeenBlocks = BTreeSet<HashID>;  // WAY slower
pub type SeenBlocks = FxHashSet<HashID>;

#[derive(Debug, Clone)]
pub struct NetworkArgs {
    pub block_target: u16,
    pub daa2_n_blocks: usize,
    pub por_chains: u16,
}

impl NetworkArgs {
    pub fn new(block_target: u16) -> Self {
        NetworkArgs {
            block_target,
            daa2_n_blocks: 100,
            por_chains: 0,
        }
    }
}
