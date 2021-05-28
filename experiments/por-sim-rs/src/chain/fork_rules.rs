use crate::block::{Block, BlockT, DagBlock};
use crate::chain::BlockMD;
use crate::chain::ChainT;
use rand::seq::IteratorRandom;
use std::marker::PhantomData;

pub enum ForkResult<'a, B: BlockT> {
    BestBlock(&'a B),
    BlocksEq,
}

use ForkResult::*;

pub trait ForkRules<B: BlockT> {
    // fn new() -> Self;
    fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B>;
    fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128;
}

#[derive(new)]
pub struct LongestChain<B: BlockT> {
    _phantom: PhantomData<B>,
}
#[derive(new)]
pub struct HeaviestChain<B: BlockT> {
    _phantom: PhantomData<B>,
}

fn testing<B: BlockT>() {
    let l = LongestChain::<B>::new();
}

impl<B: BlockT> ForkRules<B> for LongestChain<B> {
    fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B> {
        let d = b1.1.height - b2.1.height;
        if d > 0 {
            BestBlock(b1.0)
        } else if d == 0 {
            BlocksEq
        } else {
            BestBlock(b2.0)
        }
    }
    fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128 {
        (f(b.prev()).unwrap().height + 1) as u128
    }
}

// impl<B: BlockT> ForkRules<B> for HeaviestChain<B> {
//     fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B> {
//         let d = b1.1.chain_weight - b2.1.chain_weight;
//         if d > 0 {
//             BestBlock(b1.0)
//         } else if d == 0 {
//             BlocksEq
//         } else {
//             BestBlock(b2.0)
//         }
//     }
// }

// impl ForkRules<Block> for HeaviestChain<Block> {
//     // fn new() -> Self {
//     //     HeaviestChain {}
//     // }
//     fn weight_of<'a>(b: &Block, chain: &impl ChainT<'a, Block>) -> u128 {
//         let p_id = b.prev();
//         let p = chain.get_block(p_id).unwrap();
//         let p_md = chain.get_block_meta(p_id).unwrap();
//         p_md.chain_weight + chain.next_difficulty(p, p_md)
//     }
// }

// impl ForkRules<DagBlock> for HeaviestChain<DagBlock> {
//     // fn new() -> Self {
//     //     HeaviestChain {}
//     // }
//     fn weight_of<'a>(b: &DagBlock, chain: &impl ChainT<'a, DagBlock>) -> u128 {
//         let (_lca, lca_intermediates) = chain.find_lca_and_intermediates(&b.parents).unwrap();
//         let min_h = lca_intermediates.keys().min().unwrap();
//         let max_h = lca_intermediates.keys().max().unwrap();

//         let lca_info = &lca_intermediates[min_h].iter().cloned().collect::<Vec<_>>()[0];
//         let base_chain_weight = lca_info.b_md.chain_weight;
//         let intermediate_weights: u128 = lca_intermediates
//             .iter()
//             .filter(|(h, _)| *h != min_h)
//             .map::<u128, _>(|(_, infos)| infos.iter().map(|i| i.b_md.weight).sum())
//             .sum();

//         let some_p_info = lca_intermediates[max_h]
//             .iter()
//             .choose(&mut rand::thread_rng())
//             .unwrap();

//         base_chain_weight
//             + intermediate_weights
//             + chain.next_difficulty(&some_p_info.b, &some_p_info.b_md)
//     }
// }
