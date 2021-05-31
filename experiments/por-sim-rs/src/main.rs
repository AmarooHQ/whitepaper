use crate::block::*;
use crate::chain::fork_rules::*;
use crate::chain::Chain;
use crate::cryptosystem::CSystemT;
use crate::cryptosystem::DagCS;
use crate::cryptosystem::SimpleCS;
use crate::cryptosystem::WeightedChainCS;
use crate::message_manager::AttackArgs;
use clap::{value_t_or_exit, App, Arg, ArgMatches, SubCommand};
use log::LevelFilter;

#[macro_use]
extern crate clap;
#[macro_use]
extern crate derive_new;
#[macro_use]
extern crate log;
extern crate env_logger;

mod block;
mod chain;
mod cryptosystem;
mod hash;
mod message_manager;
mod msg;
mod node;
mod strategies;

arg_enum! {
    #[derive(Debug)]
    pub enum CryptoSystemArg {
        SimpleChain,
        WeightedChain,
        WeightedDag,
    }
}

fn get_arg_matches<'a>() -> ArgMatches<'a> {
    clap_app!(sim =>
        (about: "Blockchain PoW + PoR simulator")
        (version: "0.1.0")
        (@arg nodes: -n --nodes +takes_value default_value("75") "Number of nodes in total.")
        (@arg attacker_ratio: -r --ratio +takes_value default_value("0.45") #{0, 1} "Proportion of nodes which are attackers.")
        (@arg start_attack_at_h: -s --start_attack_height +takes_value default_value("1000") "Height at which to start the attack.")
        (@arg hash_rate: -H --hash_rate +takes_value default_value("10") "Maximum hashes each node will perform each tick attempting to produce a block.")
        (@arg crypto_system: -S --crypto_system +takes_value possible_values(&CryptoSystemArg::variants())  "Name of the cryptosystem template to use.")
    )
    .get_matches()
}

pub fn main() -> Result<(), String> {
    log::set_max_level(LevelFilter::Info);
    env_logger::init();
    // SimpleLogger::new()
    //     .with_level(LevelFilter::Info)
    //     .init()
    //     .unwrap();
    let args = get_arg_matches();

    let n_total = value_t_or_exit!(args.value_of("nodes"), u16);
    let attacker_ratio = value_t_or_exit!(args.value_of("attacker_ratio"), f64);
    let attack_at_h = value_t_or_exit!(args.value_of("start_attack_at_h"), u32);
    let hash_rate = value_t_or_exit!(args.value_of("hash_rate"), u32);
    let crypto_system =
        value_t!(args, "crypto_system", CryptoSystemArg).unwrap_or_else(|e| e.exit());
    // let n_honest = value_t_or_exit!(args.value_of("honest-nodes"), u16);
    // let n_total = 75;
    let n_honest = ((n_total as f64) * (1. - attacker_ratio)) as u16;
    let n_attackers = n_total - n_honest;
    // let attack_starts_at = 1000;
    // let hash_rate = 100;
    let attack_starts_at = attack_at_h as u64;
    let atk_args = AttackArgs {
        n_honest,
        n_attackers,
        attack_starts_at,
        hash_rate,
    };
    match crypto_system {
        CryptoSystemArg::WeightedDag => mk_run_atk(DagCS {}, atk_args),
        CryptoSystemArg::WeightedChain => mk_run_atk(WeightedChainCS {}, atk_args),
        CryptoSystemArg::SimpleChain => mk_run_atk(SimpleCS {}, atk_args),
    }
    .map(|_s| ())
}

// fn(n1: u16, n2: u16, at: u128, hr: u32)

fn mk_run_atk<'a, CS: CSystemT<'a>>(_cs: CS, args: AttackArgs) -> Result<bool, String> {
    let start_at = args.attack_starts_at as u32 * 3;
    message_manager::MM::<'_, CS>::new(args).run_attack(start_at, 20)
}
