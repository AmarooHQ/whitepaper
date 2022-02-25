use crate::chain::fork_rules::*;
use crate::cryptosystem::*;
use crate::message_manager::*;
use crate::strategies::relay::*;
use crate::types::*;
use clap::{value_t_or_exit, ArgMatches};
use core::fmt::Display;
use log::LevelFilter;
use num::Num;
use num::ToPrimitive;
use std::time::SystemTime;

#[macro_use]
extern crate clap;
#[macro_use]
extern crate derive_new;
#[macro_use]
extern crate log;
extern crate env_logger;
extern crate intmap;
#[macro_use]
extern crate non_empty_vec;

mod block;
mod block_metadata;
mod chain;
mod cryptosystem;
// mod extrinsics;
mod hash;
mod message_manager;
mod msg;
mod node;
mod state;
mod strategies;
mod transactions;
mod types;

arg_enum! {
    #[derive(Debug)]
    pub enum CryptoSystemArg {
        LongestChain,
        WeightedChain,
        WeightedDag,
    }
}
arg_enum! {
    #[derive(Debug, PartialEq)]
    pub enum RelayStrategyArg {
        DoubleSpend,
        DoubleSpendWork,
        SelfishMining,
    }
}

fn num_is_between<T: PartialOrd + Display>(n: T, min: T, max: T) -> Result<(), String> {
    if min <= n && n <= max {
        return Ok(());
    }
    Err(format!("{} is outside range ({}, {}).", n, min, max))
}

fn validate_ratio(v: String) -> Result<(), String> {
    v.parse::<f32>()
        .map_err(|e| e.to_string())
        .and_then(|r| num_is_between(r, 0.0, 1.0))
}

fn validate_n_chains(s: String) -> Result<(), String> {
    s.parse::<u16>()
        .map_err(|e| e.to_string())
        .and_then(|v| num_is_between(v, 1, 999))
}

fn validate_daa2_n_blocks(s: String) -> Result<(), String> {
    s.parse::<u16>()
        .map_err(|e| e.to_string())
        .and_then(|v| num_is_between(v, 5, 2_000))
}

// fn validate_n_between<T: PartialOrd, F: Fn(String) -> Result<(), String>>(min: T, max: T) -> F {
//     return |s: String| s.parse::<T>().map_err(|e| e.to_string());
// }

fn get_arg_matches<'a>() -> ArgMatches<'a> {
    clap_app!(sim =>
        (about: "Blockchain PoW + PoR simulator")
        (version: "0.2.0")
        (@arg attacker_ratio: -r --ratio +takes_value default_value("0.45") {validate_ratio} "Proportion of hash-rate belonging to attackers.")
        (@arg start_attack_at_t: -s --start_attack_tick +takes_value default_value("1000") "Tick at which to start the attack.")
        (@arg end_simulation_at_t: -e --end_tick +takes_value "Maximum number of ticks for the simulation. Defaults to 3*start_attack_tick.")
        (@arg use_dynamic_cutoff: --use_dyn_end_tick !takes_value "Instead of ending the simulation at a fixed tick, end the simulation when the attacker is far behind.")
        (@arg hash_rate: -H --hash_rate +takes_value default_value("1000") "Network hash-rate per tick.")
        (@arg block_target: -b --block_target_time +takes_value default_value("10") "Target time (in ticks) between blocks.")
        (@arg crypto_system: -S --crypto_system +takes_value default_value("WeightedDag") possible_values(&CryptoSystemArg::variants()) "Name of the cryptosystem template to use.")
        (@arg relay_strategy: -R --relay_strategy +takes_value default_value("DoubleSpend") possible_values(&RelayStrategyArg::variants()) "Name of the relay strategy to use")
        (@arg attacker_instant_propagation: --attacker_instant_prop !takes_value "Attacker's blocks instantly propagate to attackers (no wasted mining)")
        (@arg atk_end_delay_ticks: --atk_end_delay_ticks +takes_value default_value("0") "Number of ticks to delay ending the simulation if the attacker gets ahead")
        // doublspend params
        (@arg win_threshold: --ds_win_threshold +takes_value default_value("20") "[DoubleSpend] Minimum number of confirmations before the double-spending private chain is published.")
        (@arg random_hr_distrib: --random_hr_distrib !takes_value "If true, distribute the attackers hash-rate randomly over all chains. (No effect with -P=1)")
        // selfish mining params
        // <none>
        // PoR params
        (@arg por_n_chains: -P --por_n_chains +takes_value default_value("1") {validate_n_chains} "Number of chains to use PoR between (only matters if >1)")
        // DAA params
        (@arg daa2_n_blocks: --daa2_n_blocks +takes_value default_value("100") {validate_daa2_n_blocks} "Number of blocks to use to recalculate difficulty")
    )
    .get_matches()
}

pub fn main() -> Result<(), String> {
    // return 1;
    let start_main = SystemTime::now();
    log::set_max_level(LevelFilter::Info);
    env_logger::init();
    // SimpleLogger::new()
    //     .with_level(LevelFilter::Info)
    //     .init()
    //     .unwrap();
    let args = get_arg_matches();

    let attacker_ratio = value_t_or_exit!(args.value_of("attacker_ratio"), f32);
    let attack_at_h = value_t_or_exit!(args.value_of("start_attack_at_t"), u32);
    let end_simulation_at_t = value_t!(args, "end_simulation_at_t", u32).unwrap_or(3 * attack_at_h);
    let hash_rate = value_t_or_exit!(args.value_of("hash_rate"), f32);
    let attacker_instant_propagation = args.is_present("attacker_instant_propagation");
    let block_target = value_t_or_exit!(args.value_of("block_target"), u16);
    let crypto_system =
        value_t!(args, "crypto_system", CryptoSystemArg).unwrap_or_else(|e| e.exit());
    let honest_hr = (hash_rate * (1. - attacker_ratio)).to_u16().unwrap() as Difficulty;
    let attacker_hr = (hash_rate * attacker_ratio).to_u16().unwrap() as Difficulty;
    let attack_starts_at = attack_at_h as Timestamp;
    let por_chains = value_t_or_exit!(args.value_of("por_n_chains"), u16);
    let daa2_n_blocks = value_t_or_exit!(args.value_of("daa2_n_blocks"), usize);
    let atk_end_delay_ticks = value_t_or_exit!(args.value_of("atk_end_delay_ticks"), Timestamp);
    let random_hr_distrib = args.is_present("random_hr_distrib");
    let use_dynamic_cutoff = args.is_present("use_dynamic_cutoff");

    let atk_args = AttackArgs {
        q: attacker_ratio,
        honest_hr,
        attacker_hr,
        attack_starts_at,
        end_simulation_at_t,
        attacker_instant_propagation,
        atk_end_delay_ticks,
        use_dynamic_cutoff,
    };
    let network_args = NetworkArgs {
        block_target,
        por_chains,
        daa2_n_blocks,
        random_hr_distrib,
    };

    let start_atk = SystemTime::now();

    let r = match crypto_system {
        CryptoSystemArg::WeightedDag => mk_run_atk(
            CryptoSystemArg::WeightedDag,
            DagCS {},
            atk_args,
            network_args,
            args,
        ),
        CryptoSystemArg::WeightedChain => mk_run_atk(
            CryptoSystemArg::WeightedChain,
            WeightedChainCS {},
            atk_args,
            network_args,
            args,
        ),
        CryptoSystemArg::LongestChain => mk_run_atk(
            CryptoSystemArg::LongestChain,
            SimpleCS {},
            atk_args,
            network_args,
            args,
        ),
    }
    .map(|_s| ());

    let end_main = SystemTime::now();

    info!(
        "Simulation took {} ms, total execution time {} ms",
        end_main.duration_since(start_atk).unwrap().as_millis(),
        end_main.duration_since(start_main).unwrap().as_millis(),
    );
    r
}

// fn(n1: u16, n2: u16, at: u128, hr: u32)
// R: RelayStrategyT<'a, S>
fn mk_run_atk<'a, S: CSystemT<'a>>(
    cs_arg: CryptoSystemArg,
    _cs: S,
    args: AttackArgs,
    network_args: NetworkArgs,
    cli_args: ArgMatches,
) -> Result<bool, String> {
    let relay_strat = value_t_or_exit!(cli_args, "relay_strategy", RelayStrategyArg);

    if args.attacker_instant_propagation && relay_strat == RelayStrategyArg::SelfishMining {
        warn!("PLEASE NOTE: --attacker_instant_prop sometimes causes SelfishMining to fail for an unknown reason");
    }

    // ~~let n_chains_range = 0..network_args.por_chains;~~
    // this is legacy from before PoR was handled by MM
    let n_chains_range = 0..1;
    match relay_strat {
        RelayStrategyArg::DoubleSpend => {
            let win_thresh = value_t_or_exit!(cli_args, "win_threshold", Height);
            let mut mms = n_chains_range
                .map(|_i| {
                    let params = DoubleSpendParams::new(args.attack_starts_at, win_thresh);
                    MM::<'_, S, DoubleSpendStrat>::new(args.clone(), params, network_args.clone())
                })
                .collect::<Vec<_>>();
            mms[0].run_attack()
        }
        RelayStrategyArg::DoubleSpendWork => {
            let win_thresh = value_t_or_exit!(cli_args, "win_threshold", Height);
            let mut mms = n_chains_range
                .map(|_i| {
                    let params = DoubleSpendWorkParams::new(
                        args.attack_starts_at,
                        win_thresh,
                        network_args.por_chains,
                    );
                    MM::<'_, S, DoubleSpendWorkStrat>::new(
                        args.clone(),
                        params,
                        network_args.clone(),
                    )
                })
                .collect::<Vec<_>>();
            mms[0].run_attack()
        }
        RelayStrategyArg::SelfishMining => {
            let chain_type = match cs_arg {
                CryptoSystemArg::WeightedDag => SmChainType::WeightedDag,
                CryptoSystemArg::WeightedChain => SmChainType::WeightedChain,
                CryptoSystemArg::LongestChain => SmChainType::LongestChain,
            };
            let mut mms = n_chains_range
                .map(|_i| {
                    MM::<'_, S, SelfishMining<S>>::new(
                        args.clone(),
                        SelfishMiningParams { chain_type },
                        network_args.clone(),
                    )
                })
                .collect::<Vec<_>>();
            mms[0].run_attack()
        }
    }
}
