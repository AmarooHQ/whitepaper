// use crate::block::BlockT;
use crate::chain::ChainT;
use crate::msg::*;
use crate::types::Height;
use crate::CSystemT;
// use crate::ForkRules;

/// a strategy that runs at a network level based on incoming msgs
pub trait RelayStrategyT<'a, S: CSystemT<'a>> {
    fn init(c: &S::C) -> Self;
    fn on_msg(&mut self, m: &MsgToNode<S::B>, chain: &S::C) -> Vec<MsgToNode<S::B>>;
}

pub struct NullRelayStrat();

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for NullRelayStrat {
    fn init(_: &<S as CSystemT<'a>>::C) -> Self {
        NullRelayStrat()
    }
    fn on_msg(&mut self, _msg_from: &MsgToNode<S::B>, _chain: &S::C) -> Vec<MsgToNode<S::B>> {
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
    fn on_msg(&mut self, msg_from: &MsgToNode<S::B>, atk_chain: &S::C) -> Vec<MsgToNode<S::B>> {
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
                                // return a msg that adds this block to the priv chain, too,
                                // so the chains stay in sync.
                                vec![MsgToNode::MsgBlock(b.clone(), true)]
                            }
                            1 => {
                                // [SM] publish last block of priv chain (there's only one)
                                /* Note: SM algorithm doesn't include privateBranchLen<-0 for this case.
                                 * IDK if that's correct or not.
                                 * self.priv_branch_len = 0;
                                 * */
                                // NB: we might have got multiple private heads, so iter over them and b'cast all
                                atk_chain
                                    .get_best_blocks(true)
                                    .iter()
                                    .map(|id| {
                                        MsgToNode::MsgBlock(
                                            S::C::get_cached_block(*id).unwrap().0.clone(),
                                            false,
                                        )
                                    })
                                    .collect()
                            }
                            2 => {
                                // [SM] publish all of private chain (should be 2 blocks)
                                self.priv_branch_len = 0;
                                /* NB: this is the same code as above. As long as chain's don't track
                                 * state, then we can just broadcast the latest best block (since the
                                 * parent block already exists in the block cache.)
                                 * */
                                atk_chain
                                    .get_best_blocks(true)
                                    .iter()
                                    .map(|id| {
                                        MsgToNode::MsgBlock(
                                            S::C::get_cached_block(*id).unwrap().0.clone(),
                                            false,
                                        )
                                    })
                                    .collect()
                            }
                            _ => {
                                // [SM] publish first unpublished block from private chain\
                                let best_atk_blocks = atk_chain.get_best_blocks(true);
                                let best_pub_blocks = atk_chain.get_best_blocks(false);
                                atk_chain.find_lca_and_intermediates(
                                    &best_atk_blocks
                                        .iter()
                                        .chain(best_pub_blocks)
                                        .cloned()
                                        .collect(),
                                );
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
