use crate::block::Block;
use crate::chain::Chain;
use log::{info, Level, LevelFilter, Metadata, Record};
use simple_logger::SimpleLogger;

mod block;
mod chain;
mod message_manager;
mod msg;
mod node;

pub fn main() -> Result<(), String> {
    SimpleLogger::new()
        .with_level(LevelFilter::Info)
        .init()
        .unwrap();
    let n_honest = 40;
    let n_attackers = 35;
    let attack_starts_at = 1000;
    let mut mm =
        message_manager::MM::<Block, Chain<Block>>::new(n_honest, n_attackers, attack_starts_at);
    mm.run_attack(attack_starts_at * 2, 20).unwrap();

    Ok(())
}
