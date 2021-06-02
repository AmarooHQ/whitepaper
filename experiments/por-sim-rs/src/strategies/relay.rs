// use crate::block::BlockT;
use crate::chain::ChainT;
use crate::msg::*;
use crate::types::Height;
use crate::CSystemT;
// use crate::ForkRules;

/// a strategy that runs at a network level based on incoming msgs
pub trait RelayStrategyT<'a, S: CSystemT<'a>> {
    fn init(c: &S::C) -> Self;
    fn on_msg(&mut self, m: &MsgToNode<S::B>) -> Vec<Msg<S::B>>;
    fn get_mine_on(&self) -> MiningChoice;
}

#[derive(Clone)]
enum MiningChoice {
    Public,
    Private,
}

struct SelfishMining {
    pub_height: Height,
    priv_height: Height,
    priv_branch_len: u32,
    latest_mining_choice: MiningChoice,
}

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for SelfishMining {
    fn init(chain: &S::C) -> Self {
        SelfishMining {
            pub_height: chain.get_any_best_block(false).1.height,
            priv_height: chain.get_any_best_block(false).1.height,
            priv_branch_len: 0,
            latest_mining_choice: MiningChoice::Private,
        }
    }
    fn on_msg(&mut self, msg_from: &MsgToNode<S::B>) -> Vec<Msg<S::B>> {
        let delta_prev = self.priv_height - self.pub_height;
        match msg_from {
            MsgToNode::MsgBlock(_) => {
                // recalc pub length
                match delta_prev {
                    0 => {
                        // sync public and private chains
                        self.priv_branch_len = 0;
                        todo!();
                    }
                    1 => {
                        // publish last block of priv chain
                        todo!();
                    }
                    2 => {
                        // publish all of private chain
                        self.priv_branch_len = 0;
                        todo!();
                    }
                    _ => {
                        // publish first unpublished block from private chain
                        todo!();
                    }
                }
                self.latest_mining_choice = MiningChoice::Private;
                todo!()
            }
            MsgToNode::MsgPrivBlock(_) => {
                // recalc priv length
                self.priv_branch_len += 1;
                if delta_prev == 0 && self.priv_branch_len == 2 {
                    // publish all priv chain
                    self.priv_branch_len = 0;
                }
                self.latest_mining_choice = MiningChoice::Private;
                todo!();
            }
            #[cfg(test)]
            MsgToNode::MsgCachedBlock(_, _) => {
                panic!("not implemented")
            }
        }
    }
    fn get_mine_on(&self) -> MiningChoice {
        self.latest_mining_choice.clone()
    }
}
