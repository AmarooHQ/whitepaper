use hashers::fx_hash::FxHasher;
use hashers::null::PassThroughHasher;
// use std::collections::{HashMap, HashSet};
use hashbrown::{HashMap, HashSet};
use std::hash::BuildHasherDefault;

use crate::RandHrMethod;

pub type Difficulty = u64;
pub type HashID = u64;
pub type Height = u32;
pub type Timestamp = u32;

pub type Weight = Difficulty;
pub type ChainWeight = Weight;

pub type PassThruHashMap<K, V> = HashMap<K, V, BuildHasherDefault<PassThroughHasher>>;
pub type PassThruHashSet<K> = HashSet<K, BuildHasherDefault<PassThroughHasher>>;

pub type ChainHeads = PassThruHashMap<HashID, ChainWeight>;

// pub type SeenBlocks = BTreeSet<HashID>;  // WAY slower
pub type SeenBlocks = PassThruHashSet<HashID>;

#[derive(Debug, Clone)]
pub struct NetworkArgs {
    pub block_target: u16,
    pub daa2_n_blocks: usize,
    pub fixed_difficulty: Option<Difficulty>,
    pub por_chains: u16,
    pub random_hr_distrib: bool,
    pub rand_hr_incl_main: bool,
    pub rand_hr_method: RandHrMethod,
}

impl NetworkArgs {
    pub fn new(block_target: u16) -> Self {
        NetworkArgs {
            block_target,
            daa2_n_blocks: 100,
            por_chains: 1,
            random_hr_distrib: false,
            rand_hr_incl_main: false,
            rand_hr_method: RandHrMethod::TwinUniform,
            fixed_difficulty: None,
        }
    }

    pub fn new_por(block_target: u16, por_chains: u16) -> Self {
        NetworkArgs {
            block_target,
            daa2_n_blocks: 100,
            por_chains,
            random_hr_distrib: false,
            rand_hr_incl_main: false,
            rand_hr_method: RandHrMethod::TwinUniform,
            fixed_difficulty: None,
        }
    }

    pub fn n_extra_chains(&self) -> u32 {
        if self.por_chains == 0 {
            0
        } else {
            self.por_chains as u32 - (if self.rand_hr_incl_main { 0 } else { 1 })
        }
    }

    /// clone and return self.
    /// if fixed_difficulty is not None, then it will be replaced with Some(d) (where d is the input variable.)
    pub fn clone_and_set_fixed_d(&self, d: u64) -> Self {
        let mut ret = self.clone();
        ret.fixed_difficulty = ret.fixed_difficulty.map(|_| d);
        return ret;
    }
}
