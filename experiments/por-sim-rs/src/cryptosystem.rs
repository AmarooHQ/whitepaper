use crate::block::*;
use crate::chain::fork_rules::*;
use crate::chain::*;

pub trait CSystemT<'a> {
    type B: BlockT;
    type FR: ForkRules<Self::B>;
    type C: ChainT<'a, Self::B, Self::FR>;
}

// pub struct CSystem {}

// impl<'a, B: BlockT, F: ForkRules<B>, C: ChainT<'a, B, F>> CSystemT<'a> for CSystem {
//     type B = B;
//     type FR = F;
//     type C = C;
// }

pub struct SimpleCS {}

impl<'a> CSystemT<'a> for SimpleCS {
    type B = Block;
    type FR = LongestChain<Block>;
    type C = Chain<Self::B, Self::FR>;
}

pub struct WeightedChainCS {}

impl<'a> CSystemT<'a> for WeightedChainCS {
    type B = Block;
    type FR = HeaviestChain<Self::B>;
    type C = Chain<Self::B, Self::FR>;
}

pub struct DagCS {}

impl<'a> CSystemT<'a> for DagCS {
    type B = DagBlock;
    type FR = HeaviestChain<Self::B>;
    type C = Chain<Self::B, Self::FR>;
}
