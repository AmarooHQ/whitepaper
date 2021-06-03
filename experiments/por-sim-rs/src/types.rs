use hashers::null::PassThroughHasher;
use std::collections::HashMap;
use std::hash::BuildHasherDefault;

pub type Difficulty = u32;
pub type HashID = u64;
pub type Height = u32;
pub type Timestamp = u32;

pub type PassThruHashMap<K, V> = HashMap<K, V, BuildHasherDefault<PassThroughHasher>>;
