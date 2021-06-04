use super::node::*;
use crate::block::BlockT;
use crate::block_metadata::BlockMD;
use crate::chain::*;
use crate::cryptosystem::CSystemT;
use crate::msg::*;
use crate::strategies::relay::*;
use crate::types::*;
use itertools::Itertools;
use log::*;

pub struct MM<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> {
    // tick: u32,
    nodes: Vec<Node<'a, S>>,
    // difficulty_cache: Mutex<HashMap<u128, u128>>,
    // attack_starts_at: Difficulty,
    args: AttackArgs,
    // block_store:
    strategy: Option<R>,
    atk_params: R::Params,
    atk_start_h: Option<Height>,
}

#[derive(Debug, Clone)]
pub struct AttackArgs {
    pub n_honest: u16,
    pub n_attackers: u16,
    pub hash_rate: u32,
    pub attack_starts_at: Timestamp,
    pub end_simulation_at_t: Timestamp,
}

impl AttackArgs {
    #[cfg(test)]
    fn new(n_honest: u16, n_attackers: u16, hash_rate: u32, attack_starts_at: Timestamp) -> Self {
        AttackArgs {
            n_honest,
            n_attackers,
            hash_rate,
            attack_starts_at,
            end_simulation_at_t: attack_starts_at * 3,
        }
    }
}

impl<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> MM<'a, S, R> {
    pub fn new(args: AttackArgs, atk_params: R::Params) -> MM<'a, S, R> {
        let nodes_honest: u16 = args.n_honest;
        let nodes_attacking: u16 = args.n_attackers;
        let mining_attempts_per_tick: u32 = args.hash_rate;
        let n_nodes = nodes_honest + nodes_attacking;
        warn!(
            "Creating new simulation with {} honest nodes and {} attacking nodes. Attack starts at T={}",
            nodes_honest, nodes_attacking, args.attack_starts_at,
        );
        let genesis = S::B::genesis(0);
        let mut mm = MM {
            nodes: Vec::new(),
            strategy: None,
            args,
            atk_params,
            atk_start_h: None,
        };
        for i in 0..n_nodes {
            mm.add_node(Node::new(
                i,
                S::C::new(
                    genesis.clone(),
                    BlockMD::mk_genesis_md(&genesis.clone(), Chain::<S::B, S::FR>::DAA2_N_BLOCKS),
                ),
                i >= nodes_honest,
                mining_attempts_per_tick,
            ));
        }
        info!("Created {} nodes.", mm.nodes.len());
        mm
    }

    pub fn add_node(&mut self, node: Node<'a, S>) {
        self.nodes.push(node);
    }

    #[cfg(test)]
    pub fn chain(&self) -> &S::C {
        return &self.nodes.first().unwrap().chain;
    }

    fn msgs_from_into_to(&mut self, msgs_from: Vec<Msg<S::B>>) -> Vec<MsgToNode<S::B>> {
        let mut msgs_to: Vec<_> = Default::default();
        for msg in msgs_from {
            match msg {
                Msg::MsgBlock(b) => {
                    msgs_to.push(MsgToNode::MsgBlock(b, false));
                }
                Msg::MsgPrivBlock(b) => {
                    msgs_to.push(MsgToNode::MsgBlock(b, true));
                }
            }
        }
        msgs_to
    }

    pub fn attack_started(&self, ts: Timestamp) -> bool {
        ts >= self.args.attack_starts_at
    }

    pub fn check_and_set_atk_start_h(&mut self, ts: Timestamp) {
        if self.attack_started(ts) && self.atk_start_h.is_none() {
            self.atk_start_h = Some(Height::from(
                self.nodes
                    .first()
                    .unwrap()
                    .chain
                    .get_heights_pub_priv()
                    .public,
            ));
        }
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs_to = self.msgs_from_into_to(msgs);
        let atk_node = self.nodes.last().unwrap();
        let attack_started = self.attack_started(ts);
        if attack_started && self.strategy.is_none() {
            // let atk_start_height = atk_node.chain.get_heights_pub_priv().public;
            self.strategy.get_or_insert(R::init(
                &atk_node.chain,
                self.atk_start_h.unwrap(),
                self.atk_params,
            ));
        }
        if self.strategy.is_some() {
            let s = self.strategy.as_mut().unwrap();
            let attacker_msgs_to = msgs_to
                .iter()
                .map(|m| s.on_msg(m, &atk_node.chain))
                .collect::<Vec<_>>()
                .concat();
            msgs_to = [attacker_msgs_to, msgs_to].concat();
        }
        let output_msgs = self
            .nodes
            .iter_mut()
            .map(|node| {
                let in_msgs = node.step(ts, &msgs_to, attack_started).unwrap();
                if in_msgs.len() > 0 {
                    debug!("\nGot messages: {:?}", in_msgs);
                }
                in_msgs
            })
            .concat();
        Ok(Vec::from(output_msgs))
    }

    // can remove #[cfg(test)] later
    #[cfg(test)]
    pub fn tick_many(&mut self, n_ticks: u32) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs_from = Vec::new();
        let mut all_msgs = Vec::new();
        // msgs.push(Msg::MsgEcho(String::from("test msg")));

        for ts in 1..(n_ticks + 1) {
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }
            msgs_from = self.tick(ts, msgs_from)?;
            all_msgs.extend(msgs_from.clone().into_iter());
        }

        Ok(all_msgs)
    }

    pub fn run_attack(&mut self) -> Result<bool, String> {
        let mut msgs_from = Vec::new();
        let ts_limit = self.args.end_simulation_at_t;

        let mut last_ts = 0;
        for ts in 1..(ts_limit + 1) {
            last_ts = ts;
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }

            self.check_and_set_atk_start_h(ts);
            msgs_from = self.tick(ts, msgs_from)?;

            // condition for stopping based on RelayStrategy
            if self
                .strategy
                .as_ref()
                .map(|s| s.should_stop_simulation(ts, &self.nodes.last().unwrap().chain))
                .unwrap_or(false)
            {
                break;
            }
        }

        let chain = &self.nodes.last().unwrap().chain;
        let hs = chain.get_heights_pub_priv();
        let fms = chain.get_fork_measure_pub_priv();
        match self.strategy.as_ref().and_then(|s| s.get_results(chain)) {
            None => {
                warn!(
                    "Attack Failed. T={}, StartH={}, PubH={}, PrivH={}, PubFM={}, PrivFM={}",
                    last_ts,
                    self.atk_start_h.unwrap_or(0),
                    hs.public,
                    hs.private,
                    fms.public,
                    fms.private
                );
                Ok(false)
            }
            Some(r) => {
                warn!(
                    "ATTACK SUCCESS! T={}, StartH={}, PubH={}, PrivH={}, PubFM={}, PrivFM={}",
                    last_ts,
                    self.atk_start_h.unwrap_or(0),
                    hs.public,
                    hs.private,
                    fms.public,
                    fms.private
                );
                warn!("Attack Results: {:?}", r);
                Ok(true)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::*;
    use crate::cryptosystem::*;

    fn create_mm_no_priv<'a, S: CSystemT<'a>>() -> MM<'a, S, DoubleSpendStrat> {
        MM::<'a, S, DoubleSpendStrat>::new(
            AttackArgs::new(20, 0, 33, 100),
            DoubleSpendParams::new(100, 20),
        )
    }

    fn ensure_chain_progress<'a, S: CSystemT<'a>>(mm: &MM<'a, S, DoubleSpendStrat>) {
        let hs = mm.chain().get_fork_measure_pub_priv();

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
    fn run_attack_test() {
        let mut mm = create_mm_no_priv::<'_, DagCS>();
        mm.run_attack().unwrap();
        ensure_chain_progress(&mm);
    }

    #[test]
    fn mm_with_dag_block_has_many_parents() {
        let mut mm = MM::<'_, DagCS, DoubleSpendStrat>::new(
            AttackArgs::new(10, 0, 0, 100),
            DoubleSpendParams::new(100, 20),
        );

        // set ts far in future to avoid issues with difficulty alg
        let t1_ts = 1000;
        mm.check_and_set_atk_start_h(t1_ts);
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
        let bb = &DagBlock::get_cached_block(&chain.select_best_block(false))
            .unwrap()
            .0;
        assert_ne!(bb.parents.len(), 0);
        assert_eq!(bb.parents.len(), 1);

        // this is the tick where blocks from tick 1 are added, and new blocks produced (but not yet added)
        let t2_ts = 1200;
        mm.check_and_set_atk_start_h(t2_ts);
        let mut msgs = mm.tick(t2_ts, msgs).unwrap();
        if msgs.len() == 0 {
            let mut b = mm.chain().draft_block(t2_ts, false);
            b.id >>= 30;
            msgs.push(Msg::MsgBlock(b));
        }

        // lets add blocks from the last tick.
        let _msgs = mm.tick(1300, msgs).unwrap();

        let chain = &mm.chain();
        let bb = DagBlock::get_cached_block(&chain.select_best_block(false)).unwrap();
        println!(
            "best blocks: {:#?}",
            chain
                .get_best_blocks_md(false)
                .iter()
                .map(|(i, b)| (i, b.0.to_string(), b.1.to_string()))
                .collect::<Vec<_>>()
        );
        assert_eq!(bb.1.height, 2);
        assert_ne!(bb.0.parents.len(), 0);
        assert_ne!(bb.0.parents.len(), 1);
    }
}
