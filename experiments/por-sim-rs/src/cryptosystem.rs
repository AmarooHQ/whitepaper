use crate::block::*;
use crate::chain::fork_rules::*;
use crate::chain::*;

pub trait CSystemT<'a>: Clone {
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

#[derive(Clone)]
pub struct SimpleCS {}

impl<'a> CSystemT<'a> for SimpleCS {
    type B = Block;
    type FR = LongestChain<Self::B>;
    type C = Chain<Self::B, Self::FR>;
}

#[derive(Clone)]
pub struct WeightedChainCS {}

impl<'a> CSystemT<'a> for WeightedChainCS {
    type B = Block;
    type FR = HeaviestChain<Self::B>;
    type C = Chain<Self::B, Self::FR>;
}

#[derive(Clone)]
pub struct DagCS {}

impl<'a> CSystemT<'a> for DagCS {
    type B = DagBlock;
    type FR = HeaviestChain<Self::B>;
    type C = Chain<Self::B, Self::FR>;
}
