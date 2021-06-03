// use crate::block::BlockT;
use crate::chain::ChainT;
use crate::msg::*;
use crate::types::Height;
use crate::CSystemT;
// use crate::ForkRules;

/// a strategy that runs at a network level based on incoming msgs
pub trait RelayStrategyT<'a, S: CSystemT<'a>> {
    fn init(c: &S::C) -> Self;
    fn on_msg(&mut self, m: &MsgToNode<S::B>) -> Vec<MsgToNode<S::B>>;
}

pub struct NullRelayStrat();

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for NullRelayStrat {
    fn init(_: &<S as CSystemT<'a>>::C) -> Self {
        NullRelayStrat()
    }
    fn on_msg(
        &mut self,
        _: &MsgToNode<<S as CSystemT<'a>>::B>,
    ) -> Vec<MsgToNode<<S as CSystemT<'a>>::B>> {
        vec![]
    }
}

pub struct SelfishMining {
    pub_height: Height,
    priv_height: Height,
    priv_branch_len: u32,
}

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for SelfishMining {
    fn init(chain: &S::C) -> Self {
        SelfishMining {
            pub_height: chain.get_any_best_block(false).1.height,
            priv_height: chain.get_any_best_block(false).1.height,
            priv_branch_len: 0,
        }
    }
    fn on_msg(&mut self, msg_from: &MsgToNode<S::B>) -> Vec<MsgToNode<S::B>> {
        let delta_prev = self.priv_height - self.pub_height;
        match msg_from {
            MsgToNode::MsgBlock(b, is_private) => {
                match is_private {
                    false => {
                        // [SM] append block to pub chain -- recalc pub length.
                        // NB: -- this will happen when nodes process msgs (after this step),
                        // but worth noting in case we need to do calculations before then.
                        match delta_prev {
                            0 => {
                                // [SM] sync public and private chains
                                self.priv_branch_len = 0;
                                // return a msg that adds this block to the priv chain too so the chains stay in sync.
                                vec![MsgToNode::MsgBlock(b.clone(), true)]
                            }
                            1 => {
                                // [SM] publish last block of priv chain (there's only one)
                                // vec![MsgToNode::MsgBlock()]
                                todo!()
                            }
                            2 => {
                                // publish all of private chain
                                self.priv_branch_len = 0;
                                todo!()
                            }
                            _ => {
                                // publish first unpublished block from private chain
                                todo!()
                            }
                        }
                    }
                    true => {
                        // recalc priv length -- append block to priv chain
                        self.priv_branch_len += 1;
                        if delta_prev == 0 && self.priv_branch_len == 2 {
                            // publish all priv chain
                            self.priv_branch_len = 0;
                        }
                        todo!()
                    }
                }
            }
        }
    }
}
