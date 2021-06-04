use crate::chain::fork_rules::*;
use crate::cryptosystem::*;
use crate::message_manager::AttackArgs;
use crate::message_manager::MM;
use crate::strategies::relay::*;
use crate::types::*;
use clap::{value_t_or_exit, ArgMatches};
use log::LevelFilter;
use std::time::SystemTime;

#[macro_use]
extern crate clap;
#[macro_use]
extern crate derive_new;
#[macro_use]
extern crate log;
extern crate env_logger;
extern crate intmap;

mod block;
mod block_metadata;
mod chain;
mod cryptosystem;
mod hash;
mod message_manager;
mod msg;
mod node;
mod strategies;
mod types;

arg_enum! {
    #[derive(Debug)]
    pub enum CryptoSystemArg {
        SimpleChain,
        WeightedChain,
        WeightedDag,
    }
}
arg_enum! {
    #[derive(Debug)]
    pub enum RelayStrategyArg {
        DoubleSpend,
        SelfishMining
    }
}

fn get_arg_matches<'a>() -> ArgMatches<'a> {
    clap_app!(sim =>
        (about: "Blockchain PoW + PoR simulator")
        (version: "0.1.0")
        (@arg nodes: -n --nodes +takes_value default_value("75") "Number of nodes in total.")
        (@arg attacker_ratio: -r --ratio +takes_value default_value("0.45") #{0, 1} "Proportion of nodes which are attackers.")
        (@arg start_attack_at_t: -s --start_attack_tick +takes_value default_value("1000") "Tick at which to start the attack.")
        (@arg end_simulation_at_t: -e --end_tick +takes_value "Maximum number of ticks for the simulation. Defaults to 3*start_attack_at_t")
        (@arg hash_rate: -H --hash_rate +takes_value default_value("10") "Maximum hashes each node will perform each tick attempting to produce a block.")
        (@arg crypto_system: -S --crypto_system +takes_value default_value("WeightedDag") possible_values(&CryptoSystemArg::variants()) "Name of the cryptosystem template to use.")
        (@arg relay_strategy: -R --relay_strategy +takes_value default_value("DoubleSpend") possible_values(&RelayStrategyArg::variants()) "Name of the relay strategy to use")
        // doublspend params
        (@arg win_threshold: --ds_win_threshold +takes_value default_value("20") "[DoubleSpend] Minimum number of confirmations before the double-spending private chain is published.")
        // selfish mining params
    )
    .get_matches()
}

pub fn main() -> Result<(), String> {
    let start_main = SystemTime::now();
    log::set_max_level(LevelFilter::Info);
    env_logger::init();
    // SimpleLogger::new()
    //     .with_level(LevelFilter::Info)
    //     .init()
    //     .unwrap();
    let args = get_arg_matches();

    let n_total = value_t_or_exit!(args.value_of("nodes"), u16);
    let attacker_ratio = value_t_or_exit!(args.value_of("attacker_ratio"), f64);
    let attack_at_h = value_t_or_exit!(args.value_of("start_attack_at_t"), u32);
    let end_simulation_at_t = value_t!(args, "end_simulation_at_t", u32).unwrap_or(3 * attack_at_h);
    let hash_rate = value_t_or_exit!(args.value_of("hash_rate"), u32);
    let crypto_system =
        value_t!(args, "crypto_system", CryptoSystemArg).unwrap_or_else(|e| e.exit());
    let n_honest = ((n_total as f64) * (1. - attacker_ratio)) as u16;
    let n_attackers = n_total - n_honest;
    let attack_starts_at = attack_at_h as Difficulty;
    let atk_args = AttackArgs {
        n_honest,
        n_attackers,
        attack_starts_at,
        hash_rate,
        end_simulation_at_t,
    };

    let start_atk = SystemTime::now();

    let r = match crypto_system {
        CryptoSystemArg::WeightedDag => {
            mk_run_atk(CryptoSystemArg::WeightedDag, DagCS {}, atk_args, args)
        }
        CryptoSystemArg::WeightedChain => mk_run_atk(
            CryptoSystemArg::WeightedChain,
            WeightedChainCS {},
            atk_args,
            args,
        ),
        CryptoSystemArg::SimpleChain => {
            mk_run_atk(CryptoSystemArg::SimpleChain, SimpleCS {}, atk_args, args)
        }
    }
    .map(|_s| ());

    let end_main = SystemTime::now();

    warn!(
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
    cli_args: ArgMatches,
) -> Result<bool, String> {
    let relay_strat = value_t_or_exit!(cli_args, "relay_strategy", RelayStrategyArg);

    todo!("refactor chain to include chain_heads");

    match relay_strat {
        RelayStrategyArg::DoubleSpend => {
            let win_thresh = value_t_or_exit!(cli_args, "win_threshold", Height);
            let params = DoubleSpendParams::new(args.attack_starts_at, win_thresh);
            MM::<'_, S, DoubleSpendStrat>::new(args.clone(), params).run_attack()
        }
        RelayStrategyArg::SelfishMining => {
            let chain_type = match cs_arg {
                CryptoSystemArg::WeightedDag => SmChainType::WeightedDag,
                CryptoSystemArg::WeightedChain => SmChainType::WeightedChain,
                CryptoSystemArg::SimpleChain => SmChainType::LongestChain,
            };
            MM::<'_, S, SelfishMining<S>>::new(args.clone(), SelfishMiningParams { chain_type })
                .run_attack()
        }
    }
}
