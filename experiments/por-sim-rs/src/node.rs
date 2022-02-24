use crate::block::BlockT;
use crate::chain::ChainErr;
use crate::chain::ChainT;
use crate::chain::ChainTxErr;
use crate::cryptosystem::CSystemT;
use crate::msg::Msg;
use crate::msg::Msg::*;
use crate::msg::MsgToNode;
use crate::transactions::ReflectionData;
use crate::transactions::Transaction;
use crate::types::*;
use log::*;

#[derive(Debug)]
pub struct Node<'a, /*R: RelayStrategyT,*/ S: CSystemT<'a>> {
    id: usize,
    pub chain: S::C,
    is_attacker: bool,
    mining_attempts_per_tick: Difficulty,
    curr_draft_block: Option<S::B>,
    add_mined_block_instant: bool,
}

impl<'a, S: CSystemT<'a>> Node<'a, S> {
    pub fn new(
        id: usize,
        chain: S::C,
        is_attacker: bool,
        mining_attempts_per_tick: Difficulty,
        add_mined_block_instant: bool,
    ) -> Node<'a, S> {
        Node {
            id,
            chain,
            is_attacker,
            // attack_threshold: attack_threshold.unwrap_or(0),
            mining_attempts_per_tick,
            curr_draft_block: None,
            add_mined_block_instant,
        }
    }

    fn got_block(&mut self, b: &S::B, is_private: bool) -> Result<(), ChainErr> {
        self.chain.add_block(b.clone(), is_private)
    }

    fn got_reflectable(
        &mut self,
        c_id: HashID,
        b: &S::B,
        is_private: bool,
    ) -> Result<(), ChainTxErr> {
        let my_chain_id = self.chain.get_chain_id();
        debug_assert_ne!(my_chain_id, c_id);

        let txs = b.get_txs();
        // the local chain is recorded in these txs as the r-chain (b/c the block is from a diff chain)
        let refl_ancestors: Vec<_> = txs
            .into_iter()
            .filter_map(|tx| tx.get_reflecting_r_block(my_chain_id).map(|b| (b, tx)))
            .map(|(b, tx)| b)
            // ! do we care (for this simulator) about the block being in the main chain?
            // .filter(|&b| self.chain.block_is_in_best_chain(b, is_private))
            .collect();
        // todo -- track best reflected CW so that non-reflecting R blocks count to
        // todo --  reflections of the most recently reflected L blocks (by R)
        // let prev_best_l_cw = S::B::get_cached_block(&b.prev())
        let l_cw = refl_ancestors
            .iter()
            .filter_map(S::B::get_cached_block)
            .map(|b| (b.1.chain_weight, ne_vec![b.0.get_hash()]))
            .max()
            .unwrap_or((0, ne_vec![my_chain_id]));
        // let count_weight = proving_ancestor_id != 0;
        // let weight = if count_weight { b.get_difficulty() } else { 0 };
        let weight = b.get_difficulty();
        let tx = Transaction::ReflectAndProve(ReflectionData {
            r_chain: c_id,
            r_block: b.get_hash(),
            r_cw: b.get_chain_weight(),
            weight,
            l_headers: refl_ancestors,
            l_cw,
        });
        let tx_id = tx.get_hash();
        Transaction::set_cached_tx(tx);
        let res = self.chain.add_tx_to_mempool(tx_id, is_private);
        res
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
        let l_chain_id = self.chain.get_chain_id();

        // process incoming messages
        for in_msg in msgs {
            match in_msg {
                MsgToNode::MsgBlock(c_id, b, is_private) => {
                    // todo: is it possible to do some higher-order function stuff here to make this code nicer? is it worth bothering?
                    if *c_id == l_chain_id {
                        // wipe draft block b/c we'll have found a better one
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
                    } else {
                        // this is a block on another chain -- worth considering for reflection
                        // (in practice we always want to reflect b/c it incents miners of R chains to reflect back)
                        match (is_private, self.is_attacker) {
                            (false, _) => {
                                self.got_reflectable(*c_id, b, false)?;
                                if self.is_attacker && !attack_started {
                                    self.got_reflectable(*c_id, b, true)?;
                                }
                            }
                            (true, true) => self.got_reflectable(*c_id, b, true)?,
                            _ => {}
                        }
                    }
                }
                _ => {}
            }
        }

        // try to mine
        for b in self.attempt_mining(ts, self.mining_attempts_per_tick as u16, attack_started) {
            out_msgs.push(
                // if we're an attacker and past when the attack starts,
                // then relay private blocks. otherwise it's a normal block.
                if self.is_attacker && attack_started {
                    MsgPrivBlock(self.chain.get_chain_id(), b)
                } else {
                    MsgBlock(self.chain.get_chain_id(), b)
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

        let mut target = self.chain.target_from_difficulty(b.get_difficulty());
        for _attempt in 0..max_attempts {
            if b.get_hash() < target {
                match self.chain.validate_block(&b, mine_in_private) {
                    Ok(b_md) => {
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
                        if self.add_mined_block_instant {
                            self.chain.add_block(b.clone(), mine_in_private).unwrap();
                        }
                        bs_out.push(b);
                        b = self.chain.draft_block(ts, mine_in_private);
                        target = self.chain.target_from_difficulty(b.get_difficulty());
                    }
                    Err(e) => {
                        warn!("Node got error while mining: {:?}", e);
                    }
                }
            }
            // warn!("Block with hash {:?} is not valid: {:?}", b.hash(), e);
            b.increment_nonce();
            // println!("incr {} / {}", _attempt, max_attempts);
        }
        // put b back if we didn't find a block
        self.curr_draft_block.replace(b);
        bs_out
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::DagBlock;
    use crate::block_metadata::*;
    use crate::chain::*;
    use crate::cryptosystem::*;
    use crate::message_manager::*;

    #[test]
    fn block_is_added_to_chain() -> Result<(), String> {
        let genesis = <SimpleCS as CSystemT>::B::genesis(0);
        let net_args = NetworkArgs::new(10);
        let c = Chain::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, net_args.daa2_n_blocks),
            net_args,
        );
        let chain_id = c.get_chain_id();
        let mut n: Node<SimpleCS> = Node::new(1337, c, false, 100, false);

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
        n.step(
            20,
            &vec![MsgToNode::MsgBlock(chain_id, b2.clone(), false)],
            true,
        )?;
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
        let genesis = <SimpleCS as CSystemT>::B::genesis(0);
        let net_args = NetworkArgs::new(10);
        let c = Chain::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, net_args.daa2_n_blocks),
            net_args,
        );
        let mut n: Node<SimpleCS> = Node::new(1337, c, false, 100, false);

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

    #[test]
    fn test_por_trivial_case() {
        let mut chains = vec![];
        let mut nodes = vec![];
        for i in 0..2 {
            let g = <DagCS as CSystemT>::B::genesis(0);
            let na = NetworkArgs::new(1);
            let g_md = BlockMD::mk_genesis_md(&g, na.daa2_n_blocks);
            let c = Chain::new(g, g_md, na);
            let n: Node<DagCS> = Node::new(i, c.clone(), false, 100, false);
            chains.push(c);
            nodes.push(n);
        }

        let c1 = &chains[0];
        let c2 = &chains[1];
        let c1_id = c1.get_chain_id();
        let c2_id = c2.get_chain_id();

        let mut msgs_out = vec![];
        let mut msgs_to = vec![];
        let mut msgs_to_new = vec![];

        let mut ts = 1;

        // get msgs out from node 1 -- mine a block
        while msgs_out.len() == 0 {
            msgs_out.extend(nodes[0].step(ts, &msgs_to, false).unwrap());
            ts += 1;
        }

        // we must have a block in msgs_out now
        let n_blocks_1: u32 = msgs_out
            .iter()
            .map(|msg| match msg {
                Msg::MsgBlock(_, _) => 1,
                _ => 0,
            })
            .sum();
        assert_ne!(n_blocks_1, 0);

        // process msgs for next chain
        for msg in msgs_out.clone() {
            match msg {
                Msg::MsgBlock(c, b) => msgs_to.push(MsgToNode::MsgBlock(c, b, false)),
                _ => (),
            };
        }
        msgs_out.clear();

        // mine a block on node 2
        while msgs_out.len() == 0 {
            msgs_out.extend(nodes[1].step(ts, &msgs_to, false).unwrap());
            ts += 1;
        }

        // chain 2 made a block that imaged the recent chain 1 block
        for msg in msgs_out.clone() {
            match msg {
                Msg::MsgBlock(c, b) => {
                    assert_eq!(b.get_txs()[0].is_reflect_and_prove(), true);
                    // ? part of broken por impl
                    // assert_eq!(b.get_txs()[0].get_reflected_weight(c2_id, c1_id), 0);
                }
                _ => (),
            }
        }
        msgs_to_new = msgs_from_into_to(&msgs_out);
        msgs_to.extend(msgs_to_new.iter().cloned());
        msgs_out.clear();

        // mine a block on node 1
        while msgs_out.len() == 0 {
            msgs_out.extend(nodes[0].step(ts, &msgs_to, false).unwrap());
            ts += 1;
        }
        msgs_to.clear();
        msgs_to.append(&mut msgs_to_new);
        msgs_to_new.append(&mut msgs_from_into_to(&msgs_out));
        msgs_to.extend(msgs_to_new.iter().cloned());

        // chain 1 made a block that imaged the recent chain 2 block
        for msg in msgs_out.clone() {
            match msg {
                Msg::MsgBlock(c, b) => {
                    assert_eq!(b.get_txs()[0].is_reflect_and_prove(), true);
                    assert_ne!(b.get_txs()[0].get_reflected_weight(c1_id, c2_id), 0);
                    assert_ne!(b.get_reflected_weight(), 0);
                }
                _ => (),
            }
        }

        // add block to chain 1
        let _msgs_out = nodes[0].step(ts, &msgs_to, false);
        // get block out of msg so we can get it from the cache
        let b = match &msgs_out[0] {
            Msg::MsgBlock(c, b) => Some(b),
            _ => None,
        }
        .unwrap();

        let b_bmd = DagBlock::get_cached_block(&b.get_hash()).unwrap();
        let n_refls = b_bmd.0.get_txs().len() as Difficulty;
        assert_ne!(n_refls, 0);
        assert_eq!(b_bmd.1.weight * n_refls, b_bmd.1.reflected_weight);
        assert_ne!(b_bmd.1.chain_weight, b_bmd.1.local_chain_weight);
        println!(
            "LCW: {} /= CW: {}\nW: {} == RW: {}",
            b_bmd.1.chain_weight,
            b_bmd.1.local_chain_weight,
            b_bmd.1.weight,
            b_bmd.1.reflected_weight
        )
    }
}
