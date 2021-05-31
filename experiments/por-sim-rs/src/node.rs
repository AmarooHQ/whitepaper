use crate::block::BlockT;
use crate::chain::ChainErr;
use crate::chain::ChainT;
use crate::cryptosystem::CSystemT;
use crate::msg::Msg;
use crate::msg::Msg::*;
use log::*;

#[derive(Debug)]
pub struct Node<'a, S: CSystemT<'a>> {
    id: u16,
    pub chain: S::C,
    is_attacker: bool,
    attack_threshold: u128,
    mining_attempts_per_tick: u32,
}

impl<'a, S: CSystemT<'a>> Node<'a, S> {
    pub fn new(
        id: u16,
        chain: S::C,
        attack_threshold: Option<u128>,
        mining_attempts_per_tick: u32,
    ) -> Node<'a, S> {
        Node {
            id,
            chain,
            is_attacker: attack_threshold.is_some(),
            attack_threshold: attack_threshold.unwrap_or(0),
            mining_attempts_per_tick,
        }
    }

    fn got_block(&mut self, b: &S::B, is_private: bool) -> Result<(), ChainErr> {
        self.chain.add_block(b.clone(), is_private)
    }

    pub fn step(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut out_msgs = vec![];

        // process incoming messages
        for in_msg in msgs {
            match in_msg {
                MsgBlock(b) => {
                    self.got_block(&b, false)?;
                    // before the attack has started, treat all blocks
                    // like they were also private blocks
                    if self.is_attacker && self.attack_threshold > ts as u128 {
                        self.got_block(&b, true)?;
                    }
                }
                MsgPrivBlock(b) => {
                    // only attacking nodes should process these msgs
                    if self.is_attacker {
                        self.got_block(&b, true)?;
                    }
                } // MsgEcho(_m) => (),
            }
        }

        // try to mine
        match self.attempt_mining(ts, self.mining_attempts_per_tick) {
            Ok(b) => out_msgs.push(
                // if we're an attacker and past when the attack starts,
                // then relay private blocks. otherwise it's a normal block.
                if self.is_attacker && self.attack_threshold <= ts as u128 {
                    MsgPrivBlock(b)
                } else {
                    MsgBlock(b)
                },
            ),
            _ => (),
        };

        // return outgoing msgs
        Ok(out_msgs)
    }

    fn attempt_mining(&self, ts: u32, max_attempts: u32) -> Result<S::B, ()> {
        let mine_in_private = self.is_attacker && ts as u128 > self.attack_threshold;
        let mut b = self.chain.draft_block(ts, mine_in_private);
        for _ in 0..max_attempts {
            match self.chain.validate_block(&b) {
                Ok((b_md, _, _)) => {
                    info!(
                        "\nN={:3} NEW_BLOCK H={:4}, D={:4}, T={:4}, {:#x} ⭢  {:#x}",
                        self.id,
                        b_md.height,
                        b_md.difficulty,
                        b.get_ts(),
                        b.get_hash(),
                        b.prev()
                    );
                    return Ok(b);
                }
                Err(_e) => {
                    // warn!("Block with hash {:?} is not valid: {:?}", b.hash(), e);
                    b.increment_nonce();
                }
            }
        }
        Err(())
    }
}

mod tests {
    use super::*;
    use crate::block::Block;
    use crate::chain::fork_rules::LongestChain;
    use crate::chain::*;
    use crate::cryptosystem::SimpleCS;
    use crate::node;

    #[test]
    fn block_is_added_to_chain() -> Result<(), String> {
        let genesis = Block::genesis(0);
        let c = Chain::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, <SimpleCS as CSystemT>::C::DAA2_N_BLOCKS),
        );
        let mut n: Node<SimpleCS> = Node::new(1337, c, None, 100);

        // just so we make sure we can get a valid block via mining
        let _b = n.attempt_mining(10, 100000).unwrap();

        // create a valid block manually
        let mut b = n.chain.draft_block(10, false);
        b.id >>= 12;

        assert_eq!(b.prev(), genesis.get_hash());

        let prev_height = n.chain.get_fork_measure_pub_priv().public;
        // let _new_msgs = n.step(11, vec![MsgBlock(b)]).unwrap();
        n.got_block(&b, false)?;

        assert_eq!(n.chain.get_fork_measure_pub_priv().public, prev_height + 1);

        Ok(())
    }
}
