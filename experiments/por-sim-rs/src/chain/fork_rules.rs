use crate::block::{Block, BlockT, DagBlock};
use crate::chain::BlockMD;
use crate::chain::ChainT;
use crate::types::Difficulty;
use rand::seq::IteratorRandom;
use std::convert::TryFrom;
use std::marker::PhantomData;

pub enum ForkResult<'a, B: BlockT> {
    BestBlock(&'a B),
    BlocksEq,
}

use ForkResult::*;

pub trait ForkRules<B: BlockT> {
    // fn new() -> Self;
    fn fork_measure(b_md: &BlockMD<B>) -> Difficulty;
    // fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B>;
    fn weight_of<'a, F: ForkRules<B>>(b: &B, chain: &impl ChainT<'a, B, F>) -> Difficulty;
    // fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128;

    fn best_of<'a>(b1: (&'a B, &BlockMD<B>), b2: (&'a B, &BlockMD<B>)) -> ForkResult<'a, B> {
        let d = i32::try_from(Self::fork_measure(b1.1)).unwrap()
            - i32::try_from(Self::fork_measure(b2.1)).unwrap();
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
    fn fork_measure(b_md: &BlockMD<B>) -> Difficulty {
        Difficulty::from(b_md.height)
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

    fn weight_of<'a, F: ForkRules<B>>(b: &B, _chain: &impl ChainT<'a, B, F>) -> Difficulty {
        Difficulty::from(B::get_cached_block(&b.prev()).unwrap().1.height + 1)
    }

    // fn weight_of<'a>(b: &B, f: Box<impl Fn(u128) -> Option<BlockMD<B>>>) -> u128 {
    //     (f(b.prev()).unwrap().height + 1) as u128
    // }
}

impl ForkRules<Block> for HeaviestChain<Block> {
    fn fork_measure(b_md: &BlockMD<Block>) -> Difficulty {
        b_md.chain_weight
    }

    fn weight_of<'a, F: ForkRules<Block>>(
        b: &Block,
        chain: &impl ChainT<'a, Block, F>,
    ) -> Difficulty {
        let p_id = b.prev();
        let p = Block::get_cached_block(&p_id).unwrap();
        p.1.chain_weight + chain.next_difficulty(&p.0, &p.1)
    }
}

impl ForkRules<DagBlock> for HeaviestChain<DagBlock> {
    fn fork_measure(b_md: &BlockMD<DagBlock>) -> Difficulty {
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
    ) -> Difficulty {
        let lca_r = chain.find_lca_and_intermediates(&b.parents).unwrap();
        let min_h = lca_r.1.keys().min().unwrap();
        let max_h = lca_r.1.keys().max().unwrap();

        let lca_info = &lca_r.1[min_h].iter().cloned().collect::<Vec<_>>()[0];
        let base_chain_weight = lca_info.chain_weight;
        let intermediate_weights: Difficulty = lca_r
            .1
            .iter()
            .filter(|(h, _)| *h != min_h)
            .map::<Difficulty, _>(|(_, infos)| infos.iter().map(|i| i.weight).sum())
            .sum();

        let some_p_info = lca_r.1[max_h]
            .iter()
            .choose(&mut rand::thread_rng())
            .unwrap();

        let b = DagBlock::get_cached_block(&some_p_info.id).unwrap();
        base_chain_weight + intermediate_weights + chain.next_difficulty(&b.0, &b.1)
    }
}
