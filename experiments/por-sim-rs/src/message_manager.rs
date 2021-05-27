use super::node::*;
use crate::block::BlockT;
use crate::chain::*;
use crate::msg::{Msg, Msg::*};
use core::hash::Hash;
use log::*;
use std::collections::{HashMap, HashSet};
use std::fmt::Debug;
use std::sync::Mutex;

pub struct MM<B, C> {
    // tick: u32,
    nodes: Vec<Node<B, C>>,
    // difficulty_cache: Mutex<HashMap<u128, u128>>,
}

impl<'a, B: BlockT + Clone + Eq + Hash + Debug> MM<B, Chain<B>> {
    pub fn new(nodes: u16) -> MM<B, Chain<B>> {
        info!("Creating new simulation with {} nodes", nodes);
        // let diff_cache = Mutex::new(HashMap::new());
        let mut mm = MM {
            // tick: 0,
            nodes: Vec::new(),
            // difficulty_cache: Mutex::new(HashMap::new()),
        };
        let genesis = B::genesis(0);
        for i in 0..nodes {
            let g = genesis.clone();
            // let genesis_meta = BlockMD {
            //     difficulty: init_d,
            //     height: 0,
            //     daa2_blocks: vec![(g.clone(), init_d); 100],
            // };
            mm.add_node(Node::new(
                i,
                Chain::<B>::new(
                    g.clone(),
                    BlockMD::mk_genesis_md(&genesis, Chain::<B>::DAA2_N_BLOCKS),
                    // Mutex::new(HashMap::new()),
                ),
            ));
        }
        mm
    }

    pub fn add_node(&mut self, node: Node<B, Chain<B>>) {
        self.nodes.push(node);
    }

    pub fn tick(&mut self, ts: u32, msgs: HashSet<Msg<B>>) -> Result<HashSet<Msg<B>>, String> {
        let mut new_msgs = HashSet::new();
        for node in self.nodes.iter_mut() {
            let in_msgs = node.step(ts, msgs.clone()).unwrap();
            if in_msgs.len() > 0 {
                // info!("Got messages: {:?}", in_msgs);
            }
            new_msgs.extend(in_msgs.into_iter());
        }
        Ok(new_msgs)
    }

    pub fn tick_many(&mut self, n_ticks: u32) -> Result<HashSet<Msg<B>>, String> {
        // let msgs = Vec::<Msg<'a>>::new();
        let mut msgs = HashSet::new();
        msgs.insert(MsgEcho(String::from("test msg")));

        for ts in 1..(n_ticks + 1) {
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }
            msgs = self.tick(ts, msgs.clone())?;
        }

        Ok(msgs)
    }
}
