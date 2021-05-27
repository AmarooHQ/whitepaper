use super::node::*;
use crate::block::BlockT;
use crate::chain::*;
use crate::msg::Msg;
use core::hash::Hash;
use itertools::Itertools;
use log::*;
use std::fmt::Debug;

pub struct MM<B, C> {
    // tick: u32,
    nodes: Vec<Node<B, C>>,
    // difficulty_cache: Mutex<HashMap<u128, u128>>,
    attack_starts_at: u32,
}

impl<'a, B: BlockT + Clone + Eq + Hash + Debug> MM<B, Chain<B>> {
    pub fn new(nodes_honest: u16, nodes_attacking: u16, attack_starts_at: u32) -> MM<B, Chain<B>> {
        let n_nodes = nodes_honest + nodes_attacking;
        info!(
            "Creating new simulation with {} honest nodes and {} attacking nodes. Attack starts at H={}.",
            nodes_honest, nodes_attacking, attack_starts_at
        );
        let mut mm = MM {
            nodes: Vec::new(),
            attack_starts_at,
        };
        let genesis = B::genesis(0);
        for i in 0..n_nodes {
            let g = genesis.clone();
            let atk_start_conds = if i >= nodes_honest {
                Some(attack_starts_at)
            } else {
                None
            };
            mm.add_node(Node::new(
                i,
                Chain::<B>::new(
                    g.clone(),
                    BlockMD::mk_genesis_md(&genesis, Chain::<B>::DAA2_N_BLOCKS),
                ),
                atk_start_conds,
            ));
        }
        mm
    }

    pub fn add_node(&mut self, node: Node<B, Chain<B>>) {
        self.nodes.push(node);
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<B>>) -> Result<Vec<Msg<B>>, String> {
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

    pub fn tick_many(&mut self, n_ticks: u32) -> Result<Vec<Msg<B>>, String> {
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

    pub fn run_attack(&mut self, ts_limit: u32, win_thresh: u32) -> Result<bool, String> {
        let mut msgs = Vec::new();

        let mut atk_height_start = self.attack_starts_at;
        for ts in 1..(ts_limit + 1) {
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }

            if ts == self.attack_starts_at {
                atk_height_start = self
                    .nodes
                    .first()
                    .unwrap()
                    .chain
                    .get_heights_pub_priv()
                    .public;
            }

            msgs = self.tick(ts, msgs.clone())?;
            if let Some(hs) = self.attack_is_success(ts, atk_height_start, win_thresh) {
                info!(
                    "ATTACK SUCCESS! T={}, StartH={}, Pub={}, Priv={}",
                    ts, atk_height_start, hs.public, hs.private
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

    fn attack_is_success(&self, ts: u32, atk_height_start: u32, win_thres: u32) -> Option<Heights> {
        if ts < self.attack_starts_at {
            None
        } else {
            let hs = self.nodes.last().unwrap().chain.get_heights_pub_priv();
            if hs.public < hs.private && hs.public >= atk_height_start + win_thres {
                Some(hs)
            } else {
                None
            }
        }
    }
}

mod tests {
    use super::*;
    use crate::block::Block;

    #[test]
    fn blocks_propagate() {
        let mut mm = MM::<Block, Chain<Block>>::new(10, 0, 0);
        let all_msgs = mm.tick_many(10).unwrap();

        assert_eq!(all_msgs.len() > 0, true);
        println!("All Msgs: {:?}", all_msgs);

        let hs = mm.nodes.first().unwrap().chain.get_heights_pub_priv();
        assert_ne!(hs.public, 0);
        assert_eq!(hs.private, 0);

        for node in &mm.nodes[..] {
            assert_eq!(node.chain.get_heights_pub_priv().public, hs.public);
        }
    }
}
