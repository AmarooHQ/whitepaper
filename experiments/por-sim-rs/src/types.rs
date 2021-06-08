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
pub type PassThruHashSet<K> = HashSet<K, BuildHasherDefault<PassThroughHasher>>;

pub type ChainHeads = PassThruHashMap<HashID, ChainWeight>;
