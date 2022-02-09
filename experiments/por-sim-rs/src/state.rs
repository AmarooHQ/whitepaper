/*!
 * State: what it says on the box.
 */

use crate::block::BlockT;
use crate::cryptosystem::CSystemT;
use crate::transactions::*;
use crate::types::*;
use hashers::null::PassThroughHasher;
use im_rc::{vector, HashMap, OrdSet, Vector};
use lazy_static::lazy_static;
use lru::LruCache;
use std::collections::LinkedList;
use std::hash::BuildHasherDefault;
use std::sync::Arc;
use std::sync::Mutex;

lazy_static! {
    // static ref STATE_CACHE: Mutex<PassThruHashMap<HashID, Arc<PoRStateIM<>>>> =
    //     Mutex::new(Default::default());
    // static ref STATE_LRU: Mutex<LruCache<HashID, Arc<PoRStateIM<>>>> =
    //     Mutex::new(LruCache::new(1024));
    // static ref DAGBLOCK_CACHE: Mutex<PassThruHashMap<u64, Arc<(Block, BlockMD<Block>)>>> =
    //     Mutex::new(Default::default());
    // static ref DAGBLOCK_LRU: Mutex<LruCache<u64, Arc<(Block, BlockMD<Block>)>>> =
    //     Mutex::new(LruCache::new(1024));
}
type HashMapIdPassthrough<V> = HashMap<HashID, V, BuildHasherDefault<PassThroughHasher>>;

#[derive(Clone, Hash, Default)]
pub struct ChainStateDelta {
    block_id: HashID,
    valid_txs: Vec<TxId>,
    invalid_txs: Vec<TxId>,
    hellos: Vec<u64>,
    balances: HashMapIdPassthrough<u64>,
    // reflections[chain_id] = [... r_block_ids]
    reflections: HashMapIdPassthrough<Vec<HashID>>,
}

#[derive(Clone, Default)]
pub struct ChainState {
    valid_txs: FxHashSet<TxId>,
    invalid_txs: FxHashSet<TxId>,
    hellos: Vec<TxId>,
    balances: HashMapIdPassthrough<u64>,
    // reflections[r_chain_id] = {... r_block_ids}
    reflections: HashMapIdPassthrough<FxHashSet<HashID>>,
}

#[derive(Clone)]
struct PoRStateIM {
    other_chains: HashMapIdPassthrough<LightChainIM>,
    kv_store: HashMapIdPassthrough<String>,
}

#[derive(Clone)]
struct LightChainIM {
    blocks: OrdSet<HashID>,
    heads: OrdSet<HashID>,
    block_frequency: u32,
    reflection_map: HashMapIdPassthrough<OrdSet<HashID>>,
}

#[derive(Clone)]
enum PoRStateTx {
    ReflectBlock { chain_id: HashID, block_id: HashID },
    AddKvStoreEntry { key: HashID, value: String },
}

enum StateTransErr {
    UnkTxType,
}

impl PoRStateIM {
    pub fn new() -> Self {
        PoRStateIM {
            other_chains: Default::default(),
            kv_store: Default::default(),
        }
    }

    pub fn on_tx(
        &self,
        pre_state: PoRStateIM,
        tx: PoRStateTx,
    ) -> Result<PoRStateIM, StateTransErr> {
        match tx {
            PoRStateTx::ReflectBlock { chain_id, block_id } => {
                // get light chain, or default (new LC from genesis)
                let lc = pre_state
                    .other_chains
                    .get(&chain_id)
                    .map(|c| c.clone())
                    .unwrap_or_else(|| LightChainIM::new(block_id));
                // update other_chains with updated light chain
                let other_chains = pre_state
                    .other_chains
                    .update(chain_id, self.update_light_chain(&lc, block_id));
                Ok(PoRStateIM {
                    other_chains,
                    ..pre_state
                })
            }
            PoRStateTx::AddKvStoreEntry { key, value } => {
                let kv_store = pre_state.kv_store.update(key, value);
                Ok(PoRStateIM {
                    kv_store,
                    ..pre_state
                })
            }
        }
    }

    fn update_light_chain(&self, lc: &LightChainIM, block: HashID) -> LightChainIM {
        let mut heads = lc.heads.clone();
        // for p_id in block.all_prev() {
        //     heads = heads.without(&S::B::get_cached_block(&p_id).unwrap().0);
        // }
        LightChainIM {
            blocks: lc.blocks.update(block.clone()),
            heads: heads.update(block.clone()),
            ..(lc.clone())
        }
    }
}

impl LightChainIM {
    fn new(block: HashID) -> Self {
        let reflection_map: HashMapIdPassthrough<_> = Default::default();
        LightChainIM {
            blocks: OrdSet::unit(block),
            heads: OrdSet::unit(block),
            block_frequency: 10,
            reflection_map: reflection_map.update(block, OrdSet::new()),
        }
    }
}

/*
 * # State for simulator
 *
 * - [x] Blocks need to support transactions
 * - [x] Tx types
 * - [ ] Transactions get processed when blocks do
 * - [ ] Transactions get applied to state to create new state
 * - [ ] Transactions have multiple types
 * - [ ] State needs to be accessible to consensus mechanism (which it sorta is anyway)
 * - [ ] fork rule includes reflected weight
 *
 *
 * */
