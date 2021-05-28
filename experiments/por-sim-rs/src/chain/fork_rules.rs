use crate::block::{Block, BlockT, DagBlock};
use crate::chain::BlockMD;
use crate::chain::ChainT;

pub enum ForkResult<B: BlockT> {
    BestBlock(B),
    BlocksEq,
}

use ForkResult::*;

type BForForkRule<B> = (B, BlockMD<B>);

pub trait ForkRules<B: BlockT> {
    fn best_of(b1: BForForkRule<B>, b2: BForForkRule<B>) -> ForkResult<B>;
}

pub struct LongestChain {}
pub struct HeaviestChain {}

impl<B: BlockT> ForkRules<B> for LongestChain {
    fn best_of(b1: BForForkRule<B>, b2: BForForkRule<B>) -> ForkResult<B> {
        let d = b1.1.height - b2.1.height;
        if d > 0 {
            BestBlock(b1.0)
        } else if d == 0 {
            BlocksEq
        } else {
            BestBlock(b2.0)
        }
    }
}

impl<B: BlockT> ForkRules<B> for HeaviestChain {
    fn best_of(b1: BForForkRule<B>, b2: BForForkRule<B>) -> ForkResult<B> {
        let d = b1.1.chain_weight - b2.1.chain_weight;
        if d > 0 {
            BestBlock(b1.0)
        } else if d == 0 {
            BlocksEq
        } else {
            BestBlock(b2.0)
        }
    }
}

pub trait WeightAlg<B: BlockT> {
    fn weight_of<'a>(b: &B, chain: &impl ChainT<'a, B>) -> u128;
}

impl<B: BlockT> WeightAlg<B> for LongestChain {
    fn weight_of<'a>(b: &B, chain: &impl ChainT<'a, B>) -> u128 {
        (chain.get_block_meta(b.prev()).unwrap().height + 1) as u128
    }
}

impl WeightAlg<Block> for HeaviestChain {
    fn weight_of<'a>(b: &Block, chain: &impl ChainT<'a, Block>) -> u128 {
        let p_id = b.prev();
        let p = chain.get_block(p_id).unwrap();
        let p_md = chain.get_block_meta(p_id).unwrap();
        p_md.chain_weight + chain.next_difficulty(p, p_md)
    }
}

impl WeightAlg<DagBlock> for HeaviestChain {
    fn weight_of<'a>(b: &DagBlock, chain: &impl ChainT<'a, DagBlock>) -> u128 {
        let _common_ancestor = chain.find_lca_and_intermediates(&b.parents);
        0
    }
}
