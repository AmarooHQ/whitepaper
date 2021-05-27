use crate::block::BlockT;
use crate::chain::ChainErr;
use crate::chain::ChainT;
use crate::msg::Msg;
use crate::msg::Msg::*;
use log::*;
use std::collections::HashSet;
// use std::fmt;
use std::marker::PhantomData;

#[derive(Debug)]
pub struct Node<B, C> {
    id: u16,
    pub chain: C,
    _phantom: PhantomData<B>,
    is_attacker: bool,
    attack_threshold: u32,
}

impl<'a, B: 'a + BlockT + Clone, C: ChainT<'a, B>> Node<B, C> {
    pub fn new(id: u16, chain: C, attack_threshold: Option<u32>) -> Node<B, C> {
        Node {
            id,
            chain,
            _phantom: PhantomData,
            is_attacker: attack_threshold.is_some(),
            attack_threshold: attack_threshold.unwrap_or(0),
        }
    }

    fn got_block(&mut self, b: &B, is_private: bool) -> Result<(), ChainErr> {
        self.chain.add_block(b.clone(), is_private)
    }

    pub fn step(&mut self, ts: u32, msgs: Vec<Msg<B>>) -> Result<Vec<Msg<B>>, String> {
        let mut out_msgs = vec![];

        // process incoming messages
        for in_msg in msgs {
            match in_msg {
                MsgBlock(b) => {
                    self.got_block(&b, false)?;
                    // before the attack has started, treat all blocks
                    // like they were also private blocks
                    if self.is_attacker && self.attack_threshold > ts {
                        self.got_block(&b, true)?;
                    }
                }
                MsgPrivBlock(b) => {
                    // only attacking nodes should process these msgs
                    if self.is_attacker {
                        self.got_block(&b, true)?;
                    }
                }
                MsgEcho(m) => (),
            }
        }

        // try to mine
        match self.attempt_mining(ts, 100) {
            Ok(b) => out_msgs.push(
                // if we're an attacker and past when the attack starts,
                // then relay private blocks. otherwise it's a normal block.
                if self.is_attacker && self.attack_threshold <= ts {
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

    fn attempt_mining(&self, ts: u32, max_attempts: u32) -> Result<B, ()> {
        let mut b = if self.is_attacker && ts > self.attack_threshold {
            self.chain.draft_attack_block(ts)
        } else {
            self.chain.draft_block(ts)
        };
        for _ in 0..max_attempts {
            match self.chain.validate_block(&b) {
                Ok((b_md, _, _)) => {
                    info!(
                        "\nN={:4} NEW_BLOCK H={:6}, D={:6}, T={:5}, {:#x} ⭢  {:#x}",
                        self.id,
                        b_md.height,
                        b_md.difficulty,
                        b.get_ts(),
                        b.hash(),
                        b.prev()
                    );
                    return Ok(b);
                }
                Err(_e) => {
                    // warn!("Block with hash {:?} is not valid: {:?}", b.hash(), e);
                    // b.increment_nonce();
                }
            }
        }
        Err(())
    }
}

mod tests {
    use super::*;
    use crate::block::Block;
    use crate::chain::*;

    #[test]
    fn block_is_added_to_chain() -> Result<(), String> {
        let genesis = Block::genesis(0);
        let mut n = Node::<Block, Chain<Block>>::new(
            1337,
            Chain::new(
                genesis,
                BlockMD::mk_genesis_md(&genesis, Chain::<Block>::DAA2_N_BLOCKS),
            ),
            None,
        );
        // let b = n.attempt_mining(10, 1000000).unwrap();
        let mut b = n.chain.draft_block(10);
        b.id >>= 12;

        assert_eq!(b.prev(), genesis.hash());

        let prev_height = n.chain.get_heights_pub_priv().public;
        // let _new_msgs = n.step(11, vec![MsgBlock(b)]).unwrap();
        n.got_block(&b, false)?;

        assert_ne!(n.chain.get_heights_pub_priv().public, prev_height);

        Ok(())
    }
}
