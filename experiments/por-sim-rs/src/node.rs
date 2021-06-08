use crate::block::BlockT;
use crate::chain::ChainErr;
use crate::chain::ChainT;
use crate::cryptosystem::CSystemT;
use crate::msg::Msg;
use crate::msg::Msg::*;
use crate::msg::MsgToNode;
use crate::types::*;
use log::*;

#[derive(Debug)]
pub struct Node<'a, /*R: RelayStrategyT,*/ S: CSystemT<'a>> {
    id: u16,
    pub chain: S::C,
    is_attacker: bool,
    mining_attempts_per_tick: u16,
    curr_draft_block: Option<S::B>,
}

impl<'a, S: CSystemT<'a>> Node<'a, S> {
    pub fn new(
        id: u16,
        chain: S::C,
        is_attacker: bool,
        mining_attempts_per_tick: u16,
    ) -> Node<'a, S> {
        Node {
            id,
            chain,
            is_attacker,
            // attack_threshold: attack_threshold.unwrap_or(0),
            mining_attempts_per_tick,
            curr_draft_block: None,
        }
    }

    fn got_block(&mut self, b: &S::B, is_private: bool) -> Result<(), ChainErr> {
        self.chain.add_block(b.clone(), is_private)
    }

    #[cfg(test)]
    fn notify_of_block(&mut self, id: HashID, p: bool) -> Result<(), ChainErr> {
        self.chain.notify_block(id, p)
    }

    pub fn step(
        &mut self,
        ts: Timestamp,
        msgs: &Vec<MsgToNode<S::B>>,
        attack_started: bool,
    ) -> Result<Vec<Msg<S::B>>, String> {
        let mut out_msgs = vec![];

        // process incoming messages
        for in_msg in msgs {
            match in_msg {
                MsgToNode::MsgBlock(b, is_private) => {
                    self.curr_draft_block = None;
                    match (is_private, self.is_attacker) {
                        (false, _) => {
                            self.got_block(b, false)?;
                            // before the attack has started, treat all blocks
                            // like they were also private blocks
                            if self.is_attacker && !attack_started {
                                self.got_block(b, true)?;
                            }
                        }
                        (true, true) => self.got_block(b, true)?,
                        (true, false) => {}
                    }
                }
            }
        }

        // try to mine
        for b in self.attempt_mining(ts, self.mining_attempts_per_tick, attack_started) {
            out_msgs.push(
                // if we're an attacker and past when the attack starts,
                // then relay private blocks. otherwise it's a normal block.
                if self.is_attacker && attack_started {
                    MsgPrivBlock(b)
                } else {
                    MsgBlock(b)
                },
            );
        }

        // return outgoing msgs
        Ok(out_msgs)
    }

    fn attempt_mining(&mut self, ts: u32, max_attempts: u16, attack_started: bool) -> Vec<S::B> {
        let mine_in_private = self.is_attacker && attack_started;

        let mut b = if let Some(mut b) = self.curr_draft_block.take() {
            b.set_ts(ts);
            b
        } else {
            self.chain.draft_block(ts, mine_in_private)
        };

        let mut bs_out = vec![];

        let target = self.chain.target_from_difficulty(b.get_difficulty());
        for _ in 0..max_attempts {
            if b.get_hash() < target {
                let b_md = self.chain.validate_block(&b, mine_in_private).unwrap();
                debug!(
                    // "\nN={:3} NEW_BLOCK (priv={:}) H={:4}, D={:4}, ΣW={:8}, T={:4}, {:#x} ⭢  {:#x}",
                    "\nN={:3} NEW_BLOCK (priv={:}) H={:4}, D={:4}, ΣW={:8}, T={:4}, {:#} ⭢  {:#}",
                    // "\nN={:} NEW_BLOCK H={:}, D={:}, T={:}, {:} ⭢  {:}",
                    self.id,
                    mine_in_private,
                    b_md.height,
                    b_md.difficulty,
                    b_md.chain_weight,
                    b.get_ts(),
                    b.get_hash(),
                    b.prev(),
                );
                bs_out.push(b);
                b = self.chain.draft_block(ts, mine_in_private);
            }
            // warn!("Block with hash {:?} is not valid: {:?}", b.hash(), e);
            b.increment_nonce();
        }
        // put b back if we didn't find a block
        self.curr_draft_block.replace(b);
        bs_out
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::*;
    use crate::block_metadata::*;
    use crate::chain::*;
    use crate::cryptosystem::SimpleCS;

    #[test]
    fn block_is_added_to_chain() -> Result<(), String> {
        let genesis = Block::genesis(0);
        let c = Chain::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, <SimpleCS as CSystemT>::C::DAA2_N_BLOCKS),
        );
        let mut n: Node<SimpleCS> = Node::new(1337, c, false, 100);

        // just so we make sure we can get a valid block via mining
        let _bs = n.attempt_mining(10, 30000, false);
        assert_eq!(_bs.len() > 0, true, "mined >=1 block");

        // create a valid block manually
        let mut b = n.chain.draft_block(10, false);
        b.id >>= 12;

        assert_eq!(b.prev(), genesis.get_hash());

        let prev_height = n.chain.get_fork_measure_pub_priv().public;
        // let _new_msgs = n.step(11, vec![MsgBlock(b)]).unwrap();
        n.got_block(&b, false)?;

        assert_eq!(n.chain.get_fork_measure_pub_priv().public, prev_height + 1);

        // public block
        let b2 = n.chain.draft_block(19, false).test_set_work_bits(16);
        // process it after the attack has started
        n.step(20, &vec![MsgToNode::MsgBlock(b2.clone(), false)], true)?;
        assert_eq!(
            n.chain.get_best_blocks(false).contains(&b2.get_hash()),
            true,
            "b2 in pub blocks"
        );
        assert_eq!(
            n.chain.get_best_blocks(true).contains(&b2.get_hash()),
            false,
            "b2 not in priv blocks"
        );

        Ok(())
    }

    #[test]
    fn test_block_added_via_notify() -> Result<(), ChainErr> {
        let genesis = Block::genesis(0);
        let c = Chain::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, <SimpleCS as CSystemT>::C::DAA2_N_BLOCKS),
        );
        let mut n: Node<SimpleCS> = Node::new(1337, c, false, 100);

        let prev_height = n.chain.get_fork_measure_pub_priv().public;

        // create a valid block manually
        let b = n.chain.draft_block(10, false).test_set_work_bits(16);
        let id = b.get_hash();
        let b_md = n.chain.validate_block(&b, false)?;
        <SimpleCS as CSystemT>::B::set_cached_block((b, b_md));
        n.notify_of_block(id, false)?;

        assert_eq!(n.chain.get_fork_measure_pub_priv().public, prev_height + 1);

        Ok(())
    }
}
