use crate::block::BlockT;
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
    chain: C,
    _phantom: PhantomData<B>,
}

impl<'a, B: 'a + BlockT + Clone, C: ChainT<'a, B>> Node<B, C> {
    pub fn new(id: u16, chain: C) -> Node<B, C> {
        Node {
            id,
            chain,
            _phantom: PhantomData,
        }
    }

    pub fn step(&mut self, ts: u32, msgs: HashSet<Msg<B>>) -> Result<Vec<Msg<B>>, String> {
        let mut out_msgs = vec![];

        // process incoming messages
        for in_msg in msgs {
            match in_msg {
                MsgBlock(b) => self.chain.add_block(b.clone()).unwrap_or_else(|e| {
                    warn!("Failed to add_block via MsgBlock: {:?}, err: {:?}", b, e);
                }),
                MsgEcho(m) => (),
            }
        }

        // try to mine
        match self.attempt_mining(ts, 100) {
            Ok(b) => out_msgs.push(MsgBlock(b)),
            _ => (),
        };

        // return outgoing msgs
        Ok(out_msgs)
    }

    fn attempt_mining(&mut self, ts: u32, max_attempts: u32) -> Result<B, ()> {
        let mut b = self.chain.draft_block(ts);
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
                    b.increment_nonce();
                }
            }
        }
        Err(())
    }
}
