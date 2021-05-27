use crate::block::Block;
use crate::chain::Chain;
use futures::prelude::*;
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

    let mut mm = message_manager::MM::<Block, Chain<Block>>::new(100);
    mm.tick_many(1000).unwrap();

    Ok(())
}
