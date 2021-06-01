use crate::block::*;
use crate::chain::*;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::sync::Mutex;

struct InclusiveChain<B> {
    blocks: BTreeMap<u128, B>,
    pub best_blocks: BTreeSet<u128>,
    best_priv_blocks: BTreeSet<u128>,
    blocks_meta: BTreeMap<u128, BlockMD<B>>,
    goal_block_time: u32,
    difficulty_cache: Mutex<BTreeMap<u128, u128>>,
}

// impl<'a, B: ManyParentsBlockT> ChainT<'a, B> for InclusiveChain<B> {
//     fn new(_genesis: B, _genesis_meta: BlockMD<B>) -> Self {
//         todo!()
//     }
//     fn add_block(&mut self, _: B, _: bool) -> std::result::Result<(), ChainErr> {
//         todo!()
//     }
//     fn draft_block(&self, _: u32, _: bool) -> B {
//         todo!()
//     }
//     fn get_block(&self, _: u128) -> Option<&B> {
//         todo!()
//     }
//     fn get_block_meta(&self, _: u128) -> Option<&BlockMD<B>> {
//         todo!()
//     }
//     fn select_best_block(&self, _: bool) -> u128 {
//         todo!()
//     }
//     fn validate_block(
//         &self,
//         _: &B,
//     ) -> std::result::Result<(BlockMD<B>, &B, &BlockMD<B>), ChainErr> {
//         todo!()
//     }
//     fn next_difficulty(&self, _: &B, _: &BlockMD<B>) -> u64 {
//         todo!()
//     }
//     fn get_fork_measure_pub_priv(&self) -> Heights {
//         todo!()
//     }
//     fn save_block(&mut self, _: u128, _: B) {
//         todo!()
//     }
//     fn save_block_meta(&mut self, _: u128, _: BlockMD<B>) {
//         todo!()
//     }
//     fn update_best_block(&mut self, _: &B, _: &BlockMD<B>, _: bool) {
//         todo!()
//     }
//     fn get_best_blocks(&self, _: bool) -> &BTreeSet<u128> {
//         todo!()
//     }
//     fn get_best_blocks_mut(&mut self, _: bool) -> &mut std::collections::BTreeSet<u128> {
//         todo!()
//     }
//     fn get_heights_pub_priv(&self) -> Heights {
//         todo!()
//     }
// }
