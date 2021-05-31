use crate::block::*;
use crate::chain::fork_rules::*;
use crate::chain::Chain;
use clap::{value_t_or_exit, App, Arg, ArgMatches, SubCommand};
use log::LevelFilter;
use simple_logger::SimpleLogger;

#[macro_use]
extern crate clap;
#[macro_use]
extern crate derive_new;

mod block;
mod chain;
mod hash;
mod message_manager;
mod msg;
mod node;

fn get_arg_matches<'a>() -> ArgMatches<'a> {
    // App::new("Blockchain PoW + PoR simulator.")
    //     .version("0.1.0")
    //     .arg(
    //         Arg::with_name("nodes")
    //             .short("n")
    //             .value_name("NUMBER")
    //             .help("Number of nodes in total.")
    //             .takes_value(true)
    //             .default_value("75"),
    //     )
    //     .get_matches()
    clap_app!(sim =>
        (about: "Blockchain PoW + PoR simulator")
        (version: "0.1.0")
        (@arg NUMBER: -n --nodes +takes_value "Number of nodes in total.")
    )
    .get_matches()
}

type B = DagBlock;

pub fn main() -> Result<(), String> {
    SimpleLogger::new()
        .with_level(LevelFilter::Info)
        .init()
        .unwrap();
    // let args = get_arg_matches();

    // let n_total = value_t_or_exit!(args.value_of("nodes"), u16);
    // let n_honest = value_t_or_exit!(args.value_of("honest-nodes"), u16);
    let n_total = 75;
    let n_honest = 40;
    let n_attackers = n_total - n_honest;
    let attack_starts_at = 1000;
    let mining_attempts_per_tick = 100;
    let mut mm = message_manager::MM::<B, HeaviestChain<_>, Chain<_, _>>::new(
        n_honest,
        n_attackers,
        attack_starts_at,
        mining_attempts_per_tick,
    );
    mm.run_attack((attack_starts_at * 3) as u32, 20).unwrap();

    Ok(())
}
