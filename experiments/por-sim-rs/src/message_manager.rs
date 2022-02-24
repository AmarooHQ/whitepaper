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
use num::ToPrimitive;
use rand::prelude::*;
use std::iter::Chain;
use std::time::Duration;
use std::time::SystemTime;

struct ExtraChainNodes<'a, S: CSystemT<'a>> {
    honest: Node<'a, S>,
    attacker: Node<'a, S>,
}

pub struct MM<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> {
    honest_node: Node<'a, S>,
    attacker_node: Node<'a, S>,
    args: AttackArgs,
    strategy: Option<R>,
    atk_params: R::Params,
    atk_start_h: Option<Height>,
    extra_chain_nodes: Vec<ExtraChainNodes<'a, S>>,
    net_args: NetworkArgs,
    stop_simulation_at: Option<Timestamp>,
    avg_work_per_block_period: Difficulty,
}

#[derive(Debug, Clone)]
pub struct AttackArgs {
    pub q: f32,
    pub honest_hr: Difficulty,
    pub attacker_hr: Difficulty,
    pub attack_starts_at: Timestamp,
    pub end_simulation_at_t: Timestamp,
    pub attacker_instant_propagation: bool,
    pub atk_end_delay_ticks: Timestamp,
    pub use_dynamic_cutoff: bool,
}

impl AttackArgs {
    #[cfg(test)]
    fn new(honest_hr: Difficulty, attacker_hr: Difficulty, attack_starts_at: Timestamp) -> Self {
        let q = (honest_hr as f32) / ((honest_hr + attacker_hr) as f32);
        AttackArgs {
            q,
            honest_hr,
            attacker_hr,
            attack_starts_at,
            end_simulation_at_t: attack_starts_at * 3,
            attacker_instant_propagation: false,
            atk_end_delay_ticks: 0,
            use_dynamic_cutoff: false,
        }
    }

    fn total_hr(&self) -> Difficulty {
        self.honest_hr + self.attacker_hr
    }
}

impl<'a, S: CSystemT<'a>, R: RelayStrategyT<'a, S>> MM<'a, S, R> {
    pub fn new(args: AttackArgs, atk_params: R::Params, net_args: NetworkArgs) -> MM<'a, S, R> {
        warn!(
            "Creating new simulation with {} honest HR and {} attacking HR. Attack starts at T={}. InstantProp={}",
            args.honest_hr, args.attacker_hr, args.attack_starts_at, args.attacker_instant_propagation
        );
        let extra_chain_nodes = Self::mk_extra_chain_nodes(&args, &net_args);
        let genesis = S::B::genesis(0);
        let chain = S::C::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis.clone(), net_args.daa2_n_blocks.to_usize().unwrap()),
            net_args.clone(),
        );
        // this later gets updated in self.check_and_set_atk_start_h
        let avg_work_per_block_period =
            (net_args.por_chains as u64) * (net_args.block_target as u64) * args.total_hr();
        MM {
            honest_node: Node::new(
                0,
                chain.clone(),
                None,
                args.honest_hr,
                false,
                net_args.por_chains,
            ),
            attacker_node: Node::new(
                1,
                chain.clone(),
                Some(NodeAtkParams { is_r_chain: false }),
                args.attacker_hr,
                args.attacker_instant_propagation,
                net_args.por_chains,
            ),
            strategy: None,
            args: args.clone(),
            atk_params,
            atk_start_h: None,
            extra_chain_nodes,
            net_args,
            stop_simulation_at: None,
            avg_work_per_block_period,
        }
    }

    /// Make extra chains + nodes
    fn mk_extra_chain_nodes(
        args: &AttackArgs,
        net_args: &NetworkArgs,
    ) -> Vec<ExtraChainNodes<'a, S>> {
        if net_args.por_chains <= 1 {
            return vec![];
        }

        let n_chains = net_args.por_chains as u32 - 1;
        let avg_hr_per_chain = (args.attacker_hr + args.honest_hr) as u64;
        let total_hr: Difficulty = n_chains as u64 * avg_hr_per_chain;
        let avg_honest_hr_ratio: f32 = (args.honest_hr as f32) / (avg_hr_per_chain as f32);
        let hr_p = avg_honest_hr_ratio;
        let hr_q = 1.0 - hr_p;
        let expected_q = (args.attacker_hr as f32) / (avg_hr_per_chain as f32);
        debug_assert!(
            (hr_q - expected_q).abs() < 0.00001,
            "hr_q == expected_q: {} == {}",
            hr_q,
            expected_q
        );

        // vec of tuples: (honest_hr, attacker_hr)
        let cw_hash_rates: Vec<(Difficulty, Difficulty)>;

        if net_args.random_hr_distrib {
            let rd_h = gen_random_hr_distribution(n_chains, hr_p, total_hr);
            let rd_a = gen_random_hr_distribution(n_chains, hr_q, total_hr);
            cw_hash_rates = rd_h.into_iter().zip(rd_a.into_iter()).collect();
        } else {
            // uniform hash rates over all chains
            let honest_hr_ratios: Vec<f32> = (1..net_args.por_chains)
                .map(|_| avg_honest_hr_ratio)
                .collect();
            // println!("honest node HR ratios: {:?}", honest_hr_ratios);
            // no ratios <0.05 or >0.95
            debug_assert_eq!(
                honest_hr_ratios
                    .iter()
                    .filter(|&&r| r < 0.0 || 1.0 < r)
                    .count(),
                0
            );
            debug_assert_eq!(honest_hr_ratios.len() + 1, net_args.por_chains as usize);

            let cw_relative: Vec<f32> = vec![1.0; honest_hr_ratios.len()];
            // vec of tuples: (honest_hr, attacker_hr)
            cw_hash_rates = cw_relative
                .iter()
                // absolute hashes per tick
                .map(|cwr| (cwr * avg_hr_per_chain as f32) as u32)
                .zip(honest_hr_ratios)
                .map(|(hpt, honest_hr_ratio)| {
                    let honest_hr = (hpt as f32 * honest_hr_ratio) as u64;
                    let attacker_hr = (hpt as f32 * (1.0 - honest_hr_ratio)) as u64;
                    (honest_hr, attacker_hr)
                })
                .collect();
        }

        debug_assert_eq!(
            avg_hr_per_chain * net_args.por_chains as u64,
            avg_hr_per_chain + cw_hash_rates.iter().map(|&(h, a)| h + a).sum::<u64>()
        );
        if args.attacker_hr < args.honest_hr {
            let h_sum: Difficulty = cw_hash_rates.iter().cloned().map(|(h, _)| h).sum();
            let atk_sum: Difficulty = cw_hash_rates.iter().cloned().map(|(_, a)| a).sum();
            // println!("H:{}, ATK:{}", h_sum, atk_sum);
            debug_assert!(h_sum > atk_sum);
        }

        // panic!("\n\ncw_hash_rates: {:?}\n\n", cw_hash_rates);

        cw_hash_rates
            .iter()
            .enumerate()
            .map(|(i, &(honest_hr, attacker_hr))| {
                let genesis = S::B::genesis(0);
                let chain = S::C::new(
                    genesis.clone(),
                    BlockMD::mk_genesis_md(
                        &genesis.clone(),
                        net_args.daa2_n_blocks.to_usize().unwrap(),
                    ),
                    net_args.clone(),
                );
                let honest = Node::new(
                    i * 1_000,
                    chain.clone(),
                    None,
                    honest_hr,
                    false,
                    net_args.por_chains,
                );
                let attacker = Node::new(
                    i * 1_000 + 1,
                    chain.clone(),
                    Some(NodeAtkParams { is_r_chain: true }),
                    attacker_hr,
                    args.attacker_instant_propagation,
                    net_args.por_chains,
                );
                ExtraChainNodes { honest, attacker }
            })
            .collect()
    }

    #[cfg(test)]
    pub fn chain(&self) -> &S::C {
        return &self.honest_node.chain;
    }

    #[cfg(test)]
    pub fn chains(&self) -> Vec<&S::C> {
        self.extra_chain_nodes
            .iter()
            .map(|ecn| &ecn.honest.chain)
            .collect()
    }

    pub fn attack_started(&self, ts: Timestamp) -> bool {
        ts >= self.args.attack_starts_at
    }

    pub fn check_and_set_atk_start_h(&mut self, ts: Timestamp) {
        if self.attack_started(ts) && self.atk_start_h.is_none() {
            let h = self.honest_node.chain.get_heights_pub_priv().public as Height;
            self.atk_start_h = Some(h);
            debug!("setting atk_start_h:{}", h);
            let bb = self.honest_node.chain.get_any_best_block(false);
            let bb_id = bb.0.get_hash();
            let daa2_bs = BlockMD::<S::B>::get_daa2_blocks(bb_id).unwrap();
            let _ago = daa2_bs.len() as Difficulty / 4;
            let past_b = S::C::get_cached_block(&daa2_bs[_ago as usize]).unwrap();
            self.avg_work_per_block_period = (bb.1.chain_weight - past_b.1.chain_weight) / _ago;
        }
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs_to = msgs_from_into_to(&msgs);
        let atk_started = self.attack_started(ts);
        let atk_chain = &self.attacker_node.chain;
        if self.strategy.is_some() {
            let s = self.strategy.as_mut().unwrap();
            let attacker_msgs_to = msgs_to
                .iter()
                .map(|m| s.on_msg(m, atk_chain))
                .collect::<Vec<_>>()
                .concat();
            msgs_to = [msgs_to, attacker_msgs_to].concat();
        }
        // let other_nodes = .iter().map(
        //     |ExtraChainNodes {
        //          mut honest,
        //          mut attacker,
        //      }| (honest, attacker),
        // );
        let mut output_msgs = vec![
            self.honest_node.step(ts, &msgs_to, atk_started).unwrap(),
            self.attacker_node.step(ts, &msgs_to, atk_started).unwrap(),
        ]
        .concat();
        for extra_ns in (&mut self.extra_chain_nodes).into_iter() {
            output_msgs.extend(extra_ns.honest.step(ts, &msgs_to, atk_started).unwrap());
            output_msgs.extend(extra_ns.attacker.step(ts, &msgs_to, atk_started).unwrap());
        }

        if atk_started && self.strategy.is_none() && self.attacker_node.attack_has_started() {
            // let atk_start_height = atk_node.chain.get_heights_pub_priv().public;
            let h_pre = self.atk_start_h.unwrap_or(0);
            let h = *self
                .atk_start_h
                .insert(self.attacker_node.chain.get_heights_pub_priv().public as Height);
            if h != h_pre {
                debug!("prev atk_start_h:{}, current:{}", h_pre, h);
            }
            // let h = &self.atk_start_h.unwrap_or(0);
            self.strategy
                .get_or_insert(R::init(&self.attacker_node.chain, h, self.atk_params));
        }

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
        let ts_limit = if self.args.use_dynamic_cutoff {
            100.max(self.atk_params.ds_win_threshold().unwrap_or(20).pow(2))
                .min(1000)
                * self.net_args.block_target as u32
                + self.args.attack_starts_at
        } else {
            self.args.end_simulation_at_t
        };

        let run_atk_start = SystemTime::now();

        let mut last_ts = 0;
        for ts in 1..(ts_limit + 1) {
            last_ts = ts;
            if ts % 100 == 0 {
                info!("tick: {}", ts);
            }

            self.check_and_set_atk_start_h(ts);
            msgs_from = self.tick(ts, msgs_from)?;

            // condition for stopping based on RelayStrategy
            if self.stop_simulation_at.is_some()
                || self
                    .strategy
                    .as_ref()
                    .map(|s| s.should_stop_simulation(ts, &self.attacker_node.chain))
                    .unwrap_or(false)
            {
                if self.stop_simulation_at.is_none() {
                    self.stop_simulation_at = Some(ts + self.args.atk_end_delay_ticks);
                }
                if self.stop_simulation_at.map(|at| ts >= at).unwrap_or(false) {
                    break;
                }
            }

            // end when attack has started and attacker is behind honest chain by a lot
            if self.args.use_dynamic_cutoff && ts > self.args.attack_starts_at {
                let fm = self.attacker_node.chain.get_fork_measure_pub_priv();
                if self
                    .strategy
                    .as_ref()
                    .unwrap()
                    .dynamic_cutoff(fm, self.avg_work_per_block_period)
                {
                    break;
                }
            }
        }

        let run_atk_end = SystemTime::now();
        let atk_duration_ms = run_atk_end
            .duration_since(run_atk_start)
            .unwrap_or(Duration::new(0, 0))
            .as_millis();

        let chain = &self.attacker_node.chain;
        match self.strategy.as_ref().and_then(|s| s.get_results(chain)) {
            None => {
                self.print_atk_summary(false, last_ts, chain, atk_duration_ms);
                Ok(false)
            }
            Some((r, success)) => {
                self.print_atk_summary(success, last_ts, chain, atk_duration_ms);
                warn!("Attack Results: {:?}", r);
                Ok(true)
            }
        }
    }

    fn print_atk_summary(&self, success: bool, last_ts: Timestamp, chain: &S::C, ms_elapsed: u128) {
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
        let win = if success { 1 } else { 0 };
        // win, ticks_elapsed, atk_start_h, pub_h, priv_h, pub_cw, priv_cw, atk_q, block_target, daa2_n_blocks, n_chains, ms_elapsed, ...atk_strategy_cols
        println!(
            "RESULT:{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}",
            win,
            last_ts,
            self.atk_start_h.unwrap_or(0),
            hs.public,
            hs.private,
            fms.public,
            fms.private,
            self.args.q,
            self.net_args.block_target,
            self.net_args.daa2_n_blocks,
            self.net_args.por_chains,
            ms_elapsed,
            self.strategy
                .as_ref()
                .map(|s| s.params_as_csv())
                .unwrap_or("_,_".to_string()),
        );
    }
}

pub fn msgs_from_into_to<B: BlockT>(msgs_from: &Vec<Msg<B>>) -> Vec<MsgToNode<B>> {
    let mut msgs_to: Vec<_> = Default::default();
    for msg in msgs_from {
        match msg {
            Msg::MsgBlock(c_id, b) => {
                msgs_to.push(MsgToNode::MsgBlock(*c_id, b.clone(), false));
            }
            Msg::MsgPrivBlock(c_id, b) => {
                msgs_to.push(MsgToNode::MsgBlock(*c_id, b.clone(), true));
            }
        }
    }
    msgs_to
}

/// randomly distribute hash-rate over N_1 partitions so that the *overall* p+q=1 identity is maintained
pub fn gen_random_hr_distribution(n_chains: u32, q: f32, total_hr: Difficulty) -> Vec<Difficulty> {
    // let attacker_raw_agg_hr = q as f64 * total_hr as f64;
    // let attacker_avg_hr = (attacker_raw_agg_hr / n_chains as f64).round() as u32;

    // idea: create a random distrib to start with -- doesn't rly matter how it looks
    let mut rd = vec![];
    for _i in 0..n_chains {
        rd.push(random::<f64>())
    }
    // now we need to scale it so that it adds to `q`
    let rd_sum: f64 = rd.iter().sum();
    let scale = q as f64 / rd_sum;
    rd = rd.iter().map(|v| v * scale).collect();
    debug_assert!((q as f64 - rd.iter().sum::<f64>()).abs() < 0.00000001);
    // we have: list of fractions of network wide HR controlled by the attacker for each chain
    let exp_total = (total_hr as f64 * q as f64).round();
    rd = rd
        .iter()
        .map(|q_frac| (q_frac * total_hr as f64).floor())
        .collect();
    let actual_total: f64 = rd.iter().cloned().sum();
    let missing = exp_total - actual_total;
    debug_assert!(missing >= 0.0);
    debug_assert_eq!(missing, missing.round(), "no fractional component");
    for _i in 0..(missing as u32) {
        let rand_i = random::<usize>() % (n_chains as usize);
        rd[rand_i] += 1.0;
    }
    let actual_total: f64 = rd.iter().cloned().sum();
    debug_assert_eq!(exp_total, actual_total);
    rd.into_iter().map(|v| v as Difficulty).collect()
}

pub fn gen_paired_80_20_hr_distributions(
    n_chains: u32,
    q: f32,
    total_hr: Difficulty,
) -> Vec<(Difficulty, Difficulty)> {
    let p = 1. - q;
    let mut hr_a = gen_random_hr_distribution(n_chains, q, total_hr);
    let mut hr_h = gen_random_hr_distribution(n_chains, p, total_hr);
    // now, we want to ensure that for each pair, neither makes up less than 20% of the total (0.2 <= q <= 0.8 and same for p)
    // this breaks at low q, so set lower bound to (q/2).min(p/2);
    let l_bound = (q / 2.).min(p / 2.);
    todo!();
    vec![]
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::*;
    use crate::cryptosystem::*;
    use crate::transactions::Transaction;
    use crate::transactions::TxId;
    use conv::ConvUtil;
    use rstats::*;

    fn create_mm_no_priv<'a, S: CSystemT<'a>>() -> MM<'a, S, DoubleSpendStrat> {
        MM::<'a, S, DoubleSpendStrat>::new(
            AttackArgs::new(1000, 0, 100),
            DoubleSpendParams::new(100, 20),
            NetworkArgs::new(10),
        )
    }

    fn create_mm_multichain_no_priv<'a, S: CSystemT<'a>>() -> MM<'a, S, DoubleSpendStrat> {
        MM::<'a, S, DoubleSpendStrat>::new(
            AttackArgs::new(1000, 0, 10000),
            DoubleSpendParams::new(10000, 20),
            NetworkArgs {
                block_target: 3,
                daa2_n_blocks: 100,
                por_chains: 10,
                random_hr_distrib: false,
            },
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

    fn ensure_chains_progress<'a, S: CSystemT<'a>>(mm: &MM<'a, S, DoubleSpendStrat>) {
        mm.extra_chain_nodes.iter().for_each(|ecn| {
            let c = &ecn.honest.chain;
            let hs = c.get_fork_measure_pub_priv();

            assert_ne!(hs.public, 0);
            assert_eq!(hs.private, 0);

            for node in vec![&ecn.honest, &ecn.attacker] {
                println!(
                    "baseline: {:?}, this node: {:?}, {:?}, {:?}",
                    hs,
                    node.chain.get_fork_measure_pub_priv(),
                    node.chain.get_fork_measure_pub_priv(),
                    node.chain.get_fork_measure_pub_priv(),
                );
                assert_eq!(node.chain.get_fork_measure_pub_priv().public, hs.public);
            }
        })
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
            NetworkArgs::new(10),
        );
        let chain_id = mm.chain().get_chain_id();

        // set ts far in future to avoid issues with difficulty alg
        let t1_ts = 1000;
        mm.check_and_set_atk_start_h(t1_ts);
        let mut msgs = mm.tick(t1_ts, vec![]).unwrap();

        // create 2 dagblocks
        let b_h1_1 = mm.chain().draft_block(t1_ts, false).test_set_work_bits(24);
        let b_h1_2 = mm.chain().draft_block(t1_ts, false).test_set_work_bits(24);
        msgs.extend(vec![
            Msg::MsgBlock(chain_id, b_h1_1),
            Msg::MsgBlock(chain_id, b_h1_2),
        ]);

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
            msgs.push(Msg::MsgBlock(chain_id, b));
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

    #[test]
    fn mm_init_with_multiple_chains() {
        // this triggers debug_assert in `mk_extra_chain_nodes`
        let _mm = create_mm_multichain_no_priv::<'_, DagCS>();
    }

    #[test]
    fn mm_multichain_progress() {
        // this triggers debug_assert in `mk_extra_chain_nodes`
        let mut mm = create_mm_multichain_no_priv::<'_, DagCS>();
        mm.tick_many(30).unwrap();
        ensure_chain_progress(&mm);
        ensure_chains_progress(&mm);
    }

    #[test]
    fn mm_multichain_blocks_get_reflected() {
        let mut mm = create_mm_multichain_no_priv::<'_, DagCS>();
        mm.tick_many(30).unwrap();
        // todo: do this for every chain (not just the target chain)
        let bb = mm.chain().get_any_best_block(false);
        let mut txs: Vec<TxId> = vec![];
        for b in bb.0.all_prev_iter_excluding(&Default::default()) {
            txs.extend(b.0.get_transactions());
        }
        let n_refl_txs = txs
            .iter()
            .cloned()
            .filter(|&id| {
                Transaction::get_cached_tx(id)
                    .unwrap()
                    .is_reflect_and_prove()
            })
            .count();
        assert_ne!(n_refl_txs, 0);
    }

    #[test]
    fn mm_multichain_por_added_to_chain_weight() {
        let mut mm = create_mm_multichain_no_priv::<'_, DagCS>();
        let chain_id = mm.chain().get_chain_id();

        mm.tick_many(150).unwrap();

        let chain = mm.chain();
        let bb = mm.chain().get_any_best_block(false);
        let chain_remote = &mm.extra_chain_nodes.first().as_ref().unwrap().honest.chain;
        let chain_remote_id = chain_remote.get_chain_id();
        let bb_remote = chain_remote.get_any_best_block(false);

        let refl_counts: Vec<usize> =
            bb.0.all_prev_iter()
                .map(|b| {
                    b.0.get_txs()
                        .iter()
                        .map(|tx| {
                            tx.get_reflected_l_blocks()
                                .map(|rlbs| rlbs.len())
                                .unwrap_or(0)
                        })
                        .sum()
                })
                .collect();
        let refl_avg: f32 = refl_counts.iter().sum::<usize>() as f32 / refl_counts.len() as f32;
        assert!(refl_avg > 2.0);
        assert!(refl_avg < 20.0);

        // println!("{:?}", bb);
        // println!("{:?}", chain.get_best_blocks(false));
        // println!("{:?}", chain.draft_block(bb.0.timestamp + 10, false));
        // println!("{:?}", bb_remote);

        // chain.next_difficulty()

        let b_id_at_h3 = chain
            .find_lca_and_intermediates(&vec![bb.0.get_hash(), chain_id])
            .unwrap()
            .1
            .get(&3)
            .unwrap()
            .iter()
            .cloned()
            .next()
            .unwrap()
            .id;
        let b_at_h3 = DagBlock::get_cached_block(&b_id_at_h3).unwrap();

        let bb_height = bb.0.get_height();
        assert!(bb_height > 3);
        assert!(bb_height > 6, "should have many blocks above this one");
        // println!("bb height: {}", bb_height);
        // println!("bb: {:?}\n\n", bb.0);

        let mut txs_remote: Vec<_> = vec![];
        let mut remote_txid_to_r_blocks: PassThruHashMap<TxId, Vec<HashID>> = Default::default();
        for b in bb_remote.0.all_prev_iter_excluding(&Default::default()) {
            let txs = b.0.get_txs();
            for tx in &txs {
                let txid = tx.get_hash();
                if !remote_txid_to_r_blocks.contains_key(&txid) {
                    remote_txid_to_r_blocks.insert(txid, vec![]);
                }
                let r_blocks = remote_txid_to_r_blocks.get_mut(&txid).unwrap();
                r_blocks.push(b.0.get_hash());
            }
            txs_remote.extend(txs);
        }
        assert_ne!(txs_remote.len(), 0);
        // println!("n remote txs: {}", txs_remote.len());
        let n_uniq_txs = txs_remote.iter().unique().count();
        // println!("n remote txs unique: {}", n_uniq_txs);
        // assert_eq!(n_uniq_txs, txs_remote.len());  // this won't work w/ dags b/c txs can be duplicated

        let n_refl_txs = txs_remote
            .iter()
            .unique()
            .filter(|tx| tx.is_reflecting(b_id_at_h3, chain_id))
            // .map(|tx| {
            //     println!(
            //         "\n\nremote tx: {:?}, {}\n\nrefl L-block: {}, {:?}",
            //         tx,
            //         tx.get_reflected_weight2(chain_remote_id),
            //         b_id_at_h3,
            //         DagBlock::get_cached_block(&b_id_at_h3)
            //     );
            //     tx
            // })
            .count();
        // inspect block, txs, and ancestors
        /*
        println!("\n{:?}\n", b_at_h3.0);
        println!(
            "{:?}\n",
            b_at_h3
                .0
                .all_prev_iter()
                .map(|b| b.0.get_hash())
                .collect::<Vec<_>>()
        );
        println!("{:?}\n\n", b_at_h3.0.get_txs());
        println!(
            "is block {} on chain {} in this list?\n{:?}",
            b_id_at_h3, chain_id, txs_remote
        );
        */
        let a_refl_tx = txs_remote
            .iter()
            .unique()
            .filter(|tx| tx.is_reflect_and_prove())
            .next()
            .unwrap();
        let blocks_including = remote_txid_to_r_blocks.get(&a_refl_tx.get_hash());
        println!("\n\nincluded in blocks: {:?}", blocks_including);
        assert_ne!(
            n_refl_txs, 0,
            "should have some other chains reflecting b_id_at_h3"
        );
        // this assert is wrong: we're only looking at txs from 1 other chain so there should be like 1 or 2 of them.
        // assert_eq!(
        //     n_refl_txs,
        //     mm.extra_chain_nodes.len(),
        //     "should have N_1 other chains reflecting b_id_at_h3"
        // );

        let mut txs: Vec<_> = vec![];
        for b in bb.0.all_prev_iter_excluding(&Default::default()) {
            txs.extend(b.0.get_txs());
        }

        let total_rw: Difficulty = txs_remote
            .iter()
            .map(|tx| tx.get_reflected_weight2(chain_remote_id))
            .sum();
        assert_ne!(total_rw, 0);

        assert_ne!(
            bb.1.chain_weight, bb.1.local_chain_weight,
            "PoR should mean chain_weight and local_chain_weight are different"
        );
        println!(
            "cw: {}, lcw: {}",
            bb.1.chain_weight, bb.1.local_chain_weight
        );

        let lcw =
            bb.0.all_prev_iter_excluding(&Default::default())
                .map(|b| b.0.get_difficulty())
                .sum::<Difficulty>();
        assert_eq!(lcw, bb.1.local_chain_weight);

        assert!(
            bb.1.chain_weight > 5 * bb.1.local_chain_weight,
            "reflected weight should be at least 5x (expected 10x long-term)"
        );
    }

    #[test]
    fn test_gen_random_hr_distribution() {
        // 7 chains, q=0.4, total_hr=66*7
        for chain_hr in [66] {
            for n_chains in [7] {
                let total_hr = (chain_hr * n_chains) as Difficulty;
                for q in [0.4, 0.41, 0.11333, 0.6] {
                    let rd1 = gen_random_hr_distribution(n_chains, q, total_hr);
                    let rd1_f64: Vec<f64> = rd1
                        .iter()
                        .cloned()
                        .map(|v| v.value_as::<f64>().unwrap())
                        .collect();

                    let exp_avg_hr = (chain_hr as f32 * q).round() as f64;
                    let exp_total_hr = (total_hr) as f64 * q as f64;
                    assert_eq!(
                        exp_avg_hr,
                        rd1_f64.amean().unwrap().round(),
                        "average HR per chain should be {} * {}",
                        chain_hr,
                        q
                    );
                    assert_eq!(
                        exp_total_hr.round(),
                        rd1_f64.iter().sum(),
                        "total hr should match expected ({:?})",
                        rd1
                    );

                    // test honest + attacker distributions at once
                    let rd_h = gen_random_hr_distribution(n_chains, 1.0 - q, total_hr);
                    let rd_a = gen_random_hr_distribution(n_chains, q, total_hr);
                    let actual_total: Difficulty = rd_h.iter().cloned().sum::<Difficulty>()
                        + rd_a.iter().cloned().sum::<Difficulty>();
                    assert_eq!(total_hr, actual_total);
                    let rd_comb: Vec<_> = rd_h
                        .iter()
                        .cloned()
                        .zip(rd_a.iter().cloned())
                        .map(|(h, a)| (h + a) as u32)
                        .collect();
                    println!("Attacker: {:?}", rd_a);
                    println!("Honest:   {:?}", rd_h);
                    println!("Combined: {:?}", rd_comb);
                    println!(
                        "Average:  {:?} == {:?}",
                        chain_hr,
                        rd_comb.amean().unwrap() as Difficulty
                    );
                }
            }
        }
    }
}
