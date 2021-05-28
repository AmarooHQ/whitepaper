use crate::block::Block;
use crate::chain::Chain;
use log::LevelFilter;
use simple_logger::SimpleLogger;

mod block;
mod chain;
mod hash;
mod message_manager;
mod msg;
mod node;

pub fn main() -> Result<(), String> {
    SimpleLogger::new()
        .with_level(LevelFilter::Info)
        .init()
        .unwrap();
    let n_total = 75;
    let n_honest = 40;
    let n_attackers = n_total - n_honest;
    let attack_starts_at = 500;
    let mining_attempts_per_tick = 100;
    let mut mm = message_manager::MM::<Block, Chain<Block>>::new(
        n_honest,
        n_attackers,
        attack_starts_at,
        mining_attempts_per_tick,
    );
    mm.run_attack(attack_starts_at * 3, 20).unwrap();

    Ok(())
}
