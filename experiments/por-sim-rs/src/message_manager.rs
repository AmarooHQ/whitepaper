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
}

#[derive(Debug, Clone)]
pub struct AttackArgs {
    pub q: f32,
    pub honest_hr: u32,
    pub attacker_hr: u32,
    pub attack_starts_at: Timestamp,
    pub end_simulation_at_t: Timestamp,
    pub attacker_instant_propagation: bool,
}

impl AttackArgs {
    #[cfg(test)]
    fn new(honest_hr: u32, attacker_hr: u32, attack_starts_at: Timestamp) -> Self {
        let q = (honest_hr as f32) / ((honest_hr + attacker_hr) as f32);
        AttackArgs {
            q,
            honest_hr,
            attacker_hr,
            attack_starts_at,
            end_simulation_at_t: attack_starts_at * 3,
            attacker_instant_propagation: false,
        }
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
        MM {
            honest_node: Node::new(0, chain.clone(), false, args.honest_hr, false),
            attacker_node: Node::new(
                1,
                chain.clone(),
                true,
                args.attacker_hr,
                args.attacker_instant_propagation,
            ),
            strategy: None,
            args: args.clone(),
            atk_params,
            atk_start_h: None,
            extra_chain_nodes,
            net_args,
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

        // todo: randomize hash-rates a bit. need to figure out how to do this sensibly so that the maths works out. nbd yet

        // k = net_args.por_chains - 1
        // target chain (not generated here) should have 1/(k+1) of network hash-rate.
        // so other chains have, in total, have total HR: k * (args.honest_hr + args.attacker_hr)
        // we don't want this to be perfectly even though, so let's randomize a bit.
        let avg_hr_per_chain = args.attacker_hr + args.honest_hr;
        let avg_honest_hr_ratio: f32 = (args.honest_hr as f32) / (avg_hr_per_chain as f32);

        // // vec of *honest* hash ratios per chain (between 0.3 and 0.7)
        // // -- we want these to average out to be in proportion to args.honest_hr vs args.attacker_hr
        // let honest_hr_ratios: Vec<f32> = (1..net_args.por_chains)
        //     .map(|_| thread_rng().gen::<f32>() * 0.4 + 0.3)
        //     .collect();
        // let hr_ratio_avg: f32 =
        //     honest_hr_ratios.iter().sum::<f32>() / (honest_hr_ratios.len() as f32);
        // let hr_ratio_scale = avg_honest_hr_ratio / hr_ratio_avg;
        // let honest_hr_ratios: Vec<f32> = honest_hr_ratios
        //     .iter()
        //     .map(|hr| hr * hr_ratio_scale)
        //     .collect();

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

        // // vec of ratio of chain-weights (on avg)
        // let cw_relative: Vec<f32> = (1..net_args.por_chains)
        //     .map(|_| thread_rng().gen::<f32>() + 0.5)
        //     .collect();
        let cw_relative: Vec<f32> = vec![1.0; honest_hr_ratios.len()];
        // vec of tuples: (honest_hr, attacker_hr)
        let cw_hash_rates: Vec<(u32, u32)> = cw_relative
            .iter()
            // absolute hashes per tick
            .map(|cwr| (cwr * avg_hr_per_chain as f32) as u32)
            .zip(honest_hr_ratios)
            .map(|(hpt, honest_hr_ratio)| {
                let honest_hr = (hpt as f32 * honest_hr_ratio) as u32;
                let attacker_hr = (hpt as f32 * (1.0 - honest_hr_ratio)) as u32;
                (honest_hr, attacker_hr)
            })
            .collect();

        debug_assert_eq!(
            avg_hr_per_chain * net_args.por_chains as u32,
            avg_hr_per_chain + cw_hash_rates.iter().map(|&(h, a)| h + a).sum::<u32>()
        );

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
                let honest = Node::new(i * 1_000, chain.clone(), false, honest_hr, false);
                let attacker = Node::new(
                    i * 1_000 + 1,
                    chain.clone(),
                    true,
                    attacker_hr,
                    args.attacker_instant_propagation,
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
            self.atk_start_h = Some(Height::from(
                self.honest_node.chain.get_heights_pub_priv().public,
            ));
        }
    }

    pub fn tick(&mut self, ts: u32, msgs: Vec<Msg<S::B>>) -> Result<Vec<Msg<S::B>>, String> {
        let mut msgs_to = msgs_from_into_to(&msgs);
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
        // let all_nodes = vec![(&mut self.honest_node, &mut self.attacker_node)]
        //     .into_iter()
        //     .chain(other_nodes);
        // let output_msgs = all_nodes
        //     .map(|(mut h, mut a)| {
        //         vec![
        //             h.step(ts, &msgs_to, atk_started).unwrap(),
        //             a.step(ts, &msgs_to, atk_started).unwrap(),
        //         ]
        //         .concat()
        //     })
        //     .collect::<Vec<_>>()
        //     .concat();
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
            if self
                .strategy
                .as_ref()
                .map(|s| s.should_stop_simulation(ts, &self.attacker_node.chain))
                .unwrap_or(false)
            {
                break;
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
        if fms.public >= 4_000_000_000 || fms.private >= 4_000_000_000 {
            panic!("Reflection stuff going wrong -- chain_weight over 4b (which is impossible in reasonable time given this simulation -- 2022/02/09)");
        }
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
            self.strategy.as_ref().unwrap().params_as_csv(),
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::*;
    use crate::cryptosystem::*;
    use crate::transactions::Transaction;
    use crate::transactions::TxId;

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
            DoubleSpendParams::new(100, 20),
            NetworkArgs::new_por(10, 10),
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
            txs.extend(b.get_transactions());
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

        mm.tick_many(100).unwrap();

        let chain = mm.chain();
        let bb = mm.chain().get_any_best_block(false);
        let chain_remote = &mm.extra_chain_nodes.first().as_ref().unwrap().honest.chain;
        let chain_remote_id = chain_remote.get_chain_id();
        let bb_remote = chain_remote.get_any_best_block(false);

        let b_id_at_h2 = chain
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

        let mut txs_remote: Vec<_> = vec![];
        for b in bb_remote.0.all_prev_iter_excluding(&Default::default()) {
            txs_remote.extend(b.get_txs());
        }

        let n_refl_txs = txs_remote
            .iter()
            .unique()
            .filter(|tx| tx.is_reflecting(b_id_at_h2, chain_id))
            .map(|tx| {
                println!(
                    "remote tx: {:?}, {} \nrefl L-block: {}, {:?}",
                    tx,
                    tx.get_reflected_weight(chain_remote_id, chain_id),
                    b_id_at_h2,
                    DagBlock::get_cached_block(&b_id_at_h2)
                );
                tx
            })
            .count();
        assert_ne!(
            n_refl_txs, 0,
            "should have some other chains reflecting b_id_at_h2"
        );
        // this assert is wrong: we're only looking at txs from 1 other chain so there should be like 1 or 2 of them.
        // assert_eq!(
        //     n_refl_txs,
        //     mm.extra_chain_nodes.len(),
        //     "should have N_1 other chains reflecting b_id_at_h2"
        // );

        let mut txs: Vec<_> = vec![];
        for b in bb.0.all_prev_iter_excluding(&Default::default()) {
            txs.extend(b.get_txs());
        }

        let total_rw: u32 = txs_remote
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
    }
}
