use super::node::*;
use crate::block::BlockT;
use crate::block_metadata::BlockMD;
use crate::chain::*;
use crate::cryptosystem::CSystemT;
use crate::msg::*;
use crate::strategies::relay::*;
use crate::types::*;
use log::*;

pub struct MM<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> {
    honest_node: Node<'a, S>,
    attacker_node: Node<'a, S>,
    args: AttackArgs,
    strategy: Option<R>,
    atk_params: R::Params,
    atk_start_h: Option<Height>,
}

#[derive(Debug, Clone)]
pub struct AttackArgs {
    pub honest_hr: u16,
    pub attacker_hr: u16,
    pub attack_starts_at: Timestamp,
    pub end_simulation_at_t: Timestamp,
}

impl AttackArgs {
    #[cfg(test)]
    fn new(honest_hr: u16, attacker_hr: u16, attack_starts_at: Timestamp) -> Self {
        AttackArgs {
            honest_hr,
            attacker_hr,
            attack_starts_at,
            end_simulation_at_t: attack_starts_at * 3,
        }
    }
}

impl<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> MM<'a, S, R> {
    pub fn new(args: AttackArgs, atk_params: R::Params) -> MM<'a, S, R> {
        warn!(
            "Creating new simulation with {} honest HR and {} attacking HR. Attack starts at T={}",
            args.honest_hr, args.attacker_hr, args.attack_starts_at,
        );
        let genesis = S::B::genesis(0);
        let chain = S::C::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis.clone(), Chain::<S::B, S::FR>::DAA2_N_BLOCKS),
        );
        MM {
            honest_node: Node::new(0, chain.clone(), false, args.honest_hr),
            attacker_node: Node::new(1, chain.clone(), true, args.attacker_hr),
            strategy: None,
            args: args.clone(),
            atk_params,
            atk_start_h: None,
        }
    }

    #[cfg(test)]
    pub fn chain(&self) -> &S::C {
        return &self.honest_node.chain;
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
                self.honest_node.chain.get_heights_pub_priv().public,
            ));
        }
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs_to = self.msgs_from_into_to(msgs);
        let atk_started = self.attack_started(ts);
        if atk_started && self.strategy.is_none() {
            // let atk_start_height = atk_node.chain.get_heights_pub_priv().public;
            self.strategy.get_or_insert(R::init(
                &self.attacker_node.chain,
                self.atk_start_h.unwrap(),
                self.atk_params,
            ));
        }
        let atk_chain = &self.attacker_node.chain;
        if self.strategy.is_some() {
            let s = self.strategy.as_mut().unwrap();
            let attacker_msgs_to = msgs_to
                .iter()
                .map(|m| s.on_msg(m, atk_chain))
                .collect::<Vec<_>>()
                .concat();
            msgs_to = [attacker_msgs_to, msgs_to].concat();
        }
        let output_msgs = vec![
            self.honest_node.step(ts, &msgs_to, atk_started).unwrap(),
            self.attacker_node.step(ts, &msgs_to, atk_started).unwrap(),
        ]
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
                .map(|s| s.should_stop_simulation(ts, &self.attacker_node.chain))
                .unwrap_or(false)
            {
                break;
            }
        }

        let chain = &self.attacker_node.chain;
        match self.strategy.as_ref().and_then(|s| s.get_results(chain)) {
            None => {
                self.print_atk_summary(false, last_ts, chain);
                Ok(false)
            }
            Some((r, success)) => {
                self.print_atk_summary(success, last_ts, chain);
                warn!("Attack Results: {:?}", r);
                Ok(true)
            }
        }
    }

    fn print_atk_summary(&self, success: bool, last_ts: Timestamp, chain: &S::C) {
        let hs = chain.get_heights_pub_priv();
        let fms = chain.get_fork_measure_pub_priv();
        let atk_success_fail = if success {
            "ATTACK SUCCESS!"
        } else {
            "Attack Failed."
        };
        warn!(
            "{} T={}, StartH={}, PubH={}, PrivH={}, PubFM={}, PrivFM={}",
            atk_success_fail,
            last_ts,
            self.atk_start_h.unwrap_or(0),
            hs.public,
            hs.private,
            fms.public,
            fms.private
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::*;
    use crate::cryptosystem::*;

    fn create_mm_no_priv<'a, S: CSystemT<'a>>() -> MM<'a, S, DoubleSpendStrat> {
        MM::<'a, S, DoubleSpendStrat>::new(
            AttackArgs::new(1000, 0, 100),
            DoubleSpendParams::new(100, 20),
        )
    }

    fn ensure_chain_progress<'a, S: CSystemT<'a>>(mm: &MM<'a, S, DoubleSpendStrat>) {
        let hs = mm.chain().get_fork_measure_pub_priv();

        assert_ne!(hs.public, 0);
        assert_eq!(hs.private, 0);

        for node in vec![&mm.honest_node, &mm.attacker_node] {
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
            AttackArgs::new(1000, 0, 100),
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
