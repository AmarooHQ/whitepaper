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
    fn fork_measure(b_md: &BlockMD<B>) -> u64;
    // fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B>;
    fn weight_of<'a, F: ForkRules<B>>(b: &B, chain: &impl ChainT<'a, B, F>) -> u64;
    // fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128;

    fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B> {
        let d = Self::fork_measure(b1.1) - Self::fork_measure(b2.1);
        if d > 0 {
            BestBlock(b1.0)
        } else if d == 0 {
            BlocksEq
        } else {
            BestBlock(b2.0)
        }
    }
}

#[derive(new)]
pub struct LongestChain<B: BlockT> {
    _phantom: PhantomData<B>,
}
#[derive(new)]
pub struct HeaviestChain<B: BlockT> {
    _phantom: PhantomData<B>,
}

impl<B: BlockT> ForkRules<B> for LongestChain<B> {
    fn fork_measure(b_md: &BlockMD<B>) -> u64 {
        b_md.height as u64
    }

    // fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B> {
    //     let d = b1.1.height - b2.1.height;
    //     if d > 0 {
    //         BestBlock(b1.0)
    //     } else if d == 0 {
    //         BlocksEq
    //     } else {
    //         BestBlock(b2.0)
    //     }
    // }

    fn weight_of<'a, F: ForkRules<B>>(b: &B, chain: &impl ChainT<'a, B, F>) -> u64 {
        (chain.get_block(b.prev()).unwrap().1.height + 1) as u64
    }

    // fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128 {
    //     (f(b.prev()).unwrap().height + 1) as u128
    // }
}

impl ForkRules<Block> for HeaviestChain<Block> {
    fn fork_measure(b_md: &BlockMD<Block>) -> u64 {
        b_md.chain_weight
    }

    fn weight_of<'a, F: ForkRules<Block>>(b: &Block, chain: &impl ChainT<'a, Block, F>) -> u64 {
        let p_id = b.prev();
        let (p, p_md) = chain.get_block(p_id).unwrap();
        p_md.chain_weight + chain.next_difficulty(p, p_md)
    }
}

impl ForkRules<DagBlock> for HeaviestChain<DagBlock> {
    fn fork_measure(b_md: &BlockMD<DagBlock>) -> u64 {
        b_md.chain_weight
    }

    // fn best_of<'a>(
    //     b1: (&'a DagBlock, &BlockMD<DagBlock>),
    //     b2: (&'a DagBlock, &BlockMD<DagBlock>),
    // ) -> ForkResult<'a, DagBlock> {
    //     let d = b1.1.chain_weight - b2.1.chain_weight;
    //     if d > 0 {
    //         BestBlock(b1.0)
    //     } else if d == 0 {
    //         BlocksEq
    //     } else {
    //         BestBlock(b2.0)
    //     }
    // }

    fn weight_of<'a, F: ForkRules<DagBlock>>(
        b: &DagBlock,
        chain: &impl ChainT<'a, DagBlock, F>,
    ) -> u64 {
        let (_lca, lca_intermediates) = chain.find_lca_and_intermediates(&b.parents).unwrap();
        let min_h = lca_intermediates.keys().min().unwrap();
        let max_h = lca_intermediates.keys().max().unwrap();

        let lca_info = &lca_intermediates[min_h].iter().cloned().collect::<Vec<_>>()[0];
        let base_chain_weight = lca_info.b_md.chain_weight;
        let intermediate_weights: u64 = lca_intermediates
            .iter()
            .filter(|(h, _)| *h != min_h)
            .map::<u64, _>(|(_, infos)| infos.iter().map(|i| i.weight).sum())
            .sum();

        let some_p_info = lca_intermediates[max_h]
            .iter()
            .choose(&mut rand::thread_rng())
            .unwrap();

        base_chain_weight
            + intermediate_weights
            + chain.next_difficulty(&some_p_info.b, &some_p_info.b_md)
    }
}
