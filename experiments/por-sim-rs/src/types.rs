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
