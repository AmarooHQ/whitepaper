use super::node::*;
use crate::block::BlockT;
use crate::chain::fork_rules::*;
use crate::chain::*;
use crate::cryptosystem::CSystemT;
use crate::msg::Msg;
use core::hash::Hash;
use itertools::Itertools;
use log::*;
use std::fmt::Debug;

pub struct MM<'a, S: CSystemT<'a>> {
    // tick: u32,
    nodes: Vec<Node<'a, S>>,
    // difficulty_cache: Mutex<HashMap<u128, u128>>,
    attack_starts_at: u128,
    genesis: S::B,
}

impl<'a, S: CSystemT<'a>> MM<'a, S> {
    pub fn new(
        nodes_honest: u16,
        nodes_attacking: u16,
        attack_starts_at: u128,
        mining_attempts_per_tick: u32,
    ) -> MM<'a, S> {
        let n_nodes = nodes_honest + nodes_attacking;
        info!(
            "Creating new simulation with {} honest nodes and {} attacking nodes. Attack starts at H={}.",
            nodes_honest, nodes_attacking, attack_starts_at
        );
        let genesis = S::B::genesis(0);
        let mut mm = MM {
            nodes: Vec::new(),
            attack_starts_at,
            genesis: genesis.clone(),
        };
        for i in 0..n_nodes {
            let atk_start_conds = if i >= nodes_honest {
                Some(attack_starts_at)
            } else {
                None
            };
            mm.add_node(Node::new(
                i,
                S::C::new(
                    genesis.clone(),
                    BlockMD::mk_genesis_md(&genesis.clone(), Chain::<S::B, S::FR>::DAA2_N_BLOCKS),
                ),
                atk_start_conds,
                mining_attempts_per_tick,
            ));
        }
        info!("Created {} nodes.", mm.nodes.len());
        mm
    }

    pub fn add_node(&mut self, node: Node<'a, S>) {
        self.nodes.push(node);
    }

    pub fn chain(&self) -> &S::C {
        return &self.nodes.first().unwrap().chain;
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut new_msgs = Vec::new();
        for node in self.nodes.iter_mut() {
            let in_msgs = node.step(ts, msgs.clone()).unwrap();
            if in_msgs.len() > 0 {
                info!("\nGot messages: {:?}", in_msgs);
            }
            new_msgs.extend(in_msgs.into_iter());
        }
        Ok(new_msgs.into_iter().unique().collect())
    }

    pub fn tick_many(&mut self, n_ticks: u32) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs = Vec::new();
        let mut all_msgs = Vec::new();
        // msgs.push(Msg::MsgEcho(String::from("test msg")));

        for ts in 1..(n_ticks + 1) {
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }
            msgs = self.tick(ts, msgs.clone())?;
            all_msgs.extend(msgs.iter().cloned());
        }

        Ok(all_msgs)
    }

    pub fn run_attack(&mut self, ts_limit: u32, win_thresh: u128) -> Result<bool, String> {
        let mut msgs = Vec::new();

        let mut atk_height_start = self.attack_starts_at;
        for ts in 1..(ts_limit + 1) {
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }

            if ts as u128 == self.attack_starts_at {
                atk_height_start = self
                    .nodes
                    .first()
                    .unwrap()
                    .chain
                    .get_heights_pub_priv()
                    .public;
            }

            msgs = self.tick(ts, msgs.clone())?;
            if let Some((hs, fms)) = self.attack_is_success(ts, atk_height_start, win_thresh) {
                info!(
                    "ATTACK SUCCESS! T={}, StartH={}, PubH={}, PrivH={}, PubFM={}, PrivFM={}",
                    ts, atk_height_start, hs.public, hs.private, fms.public, fms.private
                );
                return Ok(true);
            }
        }

        let hs = self.nodes.last().unwrap().chain.get_heights_pub_priv();
        info!(
            "Attack Failed, T={}, StartH={}, Pub={}, Priv={}",
            ts_limit, atk_height_start, hs.public, hs.private
        );
        Ok(false)
    }

    fn attack_is_success(
        &self,
        ts: u32,
        atk_height_start: u128,
        win_thres: u128,
    ) -> Option<(Heights, Heights)> {
        if (ts as u128) < self.attack_starts_at {
            None
        } else {
            let hs = self.nodes.last().unwrap().chain.get_heights_pub_priv();
            let fms = self.nodes.last().unwrap().chain.get_fork_measure_pub_priv();
            if fms.public < fms.private && hs.public >= atk_height_start + win_thres {
                Some((hs, fms))
            } else {
                None
            }
        }
    }
}

mod tests {
    use super::*;
    use crate::block::*;
    use crate::cryptosystem::DagCS;
    use crate::cryptosystem::SimpleCS;

    fn create_mm_no_priv<'a, S: CSystemT<'a>>() -> MM<'a, S> {
        MM::<'a, S>::new(20, 0, 0, 100)
    }

    fn ensure_chain_progress<'a, S: CSystemT<'a>>(mm: &MM<'a, S>) {
        let hs = mm.nodes.first().unwrap().chain.get_fork_measure_pub_priv();

        assert_ne!(hs.public, 0);
        assert_eq!(hs.private, 0);

        for node in &mm.nodes[..] {
            println!(
                "baseline: {:?}, this node: {:?}, {:?}, {:?}",
                hs,
                node.chain.get_fork_measure_pub_priv(),
                node.chain.get_fork_measure_pub_priv(),
                node.chain.get_fork_measure_pub_priv(),
            );
            assert_eq!(node.chain.get_fork_measure_pub_priv().public, hs.public);
        }
    }

    #[test]
    fn blocks_propagate() {
        let mut mm = create_mm_no_priv::<'_, SimpleCS>();
        let all_msgs = mm.tick_many(10).unwrap();

        assert_eq!(all_msgs.len() > 0, true);
        // println!("All Msgs: {:?}", all_msgs);

        ensure_chain_progress(&mm);
    }

    #[test]
    fn mm_with_vanilla_block() {
        let mut mm = create_mm_no_priv::<'_, SimpleCS>();
        mm.tick_many(20).unwrap();
        ensure_chain_progress(&mm);
    }

    #[test]
    fn mm_with_dag_block() {
        let mut mm = create_mm_no_priv::<'_, DagCS>();
        mm.tick_many(20).unwrap();
        ensure_chain_progress(&mm);
    }

    #[test]
    fn mm_with_dag_block_has_many_parents() {
        let mut mm = MM::<'_, DagCS>::new(10, 0, 0, 100);

        // set ts far in future to avoid issues with difficulty alg
        let t1_ts = 1000;
        let mut msgs = mm.tick(t1_ts, vec![]).unwrap();

        // create 2 dagblocks
        let b_h1_1 = mm.chain().draft_block(t1_ts, false).test_set_work_bits(24);
        let b_h1_2 = mm.chain().draft_block(t1_ts, false).test_set_work_bits(24);
        msgs.extend(vec![Msg::MsgBlock(b_h1_1), Msg::MsgBlock(b_h1_2)]);

        // we made at least 2 blocks
        assert_eq!(
            msgs.len() > 1,
            true,
            "we made at least two blocks on the first tick: {:?}",
            msgs
        );

        // check that the best block has exactly 1 parent (the genesis block)
        let chain = mm.chain();
        let bb = chain.get_block(chain.select_best_block(false)).unwrap();
        assert_ne!(bb.parents.len(), 0);
        assert_eq!(bb.parents.len(), 1);

        // this is the tick where blocks from tick 1 are added, and new blocks produced (but not yet added)
        let t2_ts = 1200;
        let mut msgs = mm.tick(t2_ts, msgs).unwrap();
        if msgs.len() == 0 {
            let mut b = mm.chain().draft_block(t2_ts, false);
            b.id >>= 30;
            msgs.push(Msg::MsgBlock(b));
        }

        // lets add blocks from the last tick.
        let _msgs = mm.tick(1300, msgs).unwrap();

        let chain = &mm.chain();
        let bb = chain.get_block(chain.select_best_block(false)).unwrap();
        let bb_meta = chain.get_block_meta(bb.get_hash()).unwrap();
        println!(
            "best blocks: {:#?}",
            chain
                .get_best_blocks_md(false)
                .iter()
                .map(|(i, b, md)| (i, b.to_string(), md.to_string()))
                .collect::<Vec<_>>()
        );
        assert_eq!(bb_meta.height, 2);
        assert_ne!(bb.parents.len(), 0);
        assert_ne!(bb.parents.len(), 1);
    }
}
