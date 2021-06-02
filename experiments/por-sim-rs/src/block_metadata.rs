use crate::block::BlockT;
use crate::types::*;
use crate::Difficulty;
use core::marker::PhantomData;
use lazy_static::lazy_static;
use std::fmt;
use std::sync::Arc;
use std::sync::Mutex;

lazy_static! {
    static ref DAA2_CACHE: Mutex<PassThruHashMap<u64, Arc<Vec<HashID>>>> =
        Mutex::new(Default::default());
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct BlockMD<B> {
    pub difficulty: Difficulty,
    pub height: u32,
    pub weight: Difficulty,
    pub chain_weight: Difficulty,
    // pub daa2_blocks: Vec<HashID>,
    // pub daa2_blocks: Vec<Daa2Info>,
    pub _phantom_b: PhantomData<B>,
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
        BlockMD::<B>::set_daa2_blocks(genesis.get_hash(), vec![genesis.get_hash(); daa2_n_blocks]);
        BlockMD {
            difficulty,
            height: 0,
            weight: 0,
            chain_weight: 0,
            // daa2_blocks: vec![(genesis.clone(), difficulty); daa2_n_blocks],
            // daa2_blocks: vec![genesis.get_hash(); daa2_n_blocks],
            _phantom_b: PhantomData,
        }
    }

    pub fn get_daa2_blocks(id: HashID) -> Option<Arc<Vec<HashID>>> {
        DAA2_CACHE
            .lock()
            .ok()
            .and_then(|c| c.get(&id).map(|v| v.clone()))
    }

    pub fn set_daa2_blocks(id: HashID, v: Vec<HashID>) {
        DAA2_CACHE.lock().unwrap().insert(id, Arc::new(v));
    }
}
