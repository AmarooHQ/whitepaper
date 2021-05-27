use crate::block::{Block, BlockT};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT = Block> {
    MsgBlock(B),
    MsgEcho(String),
}
