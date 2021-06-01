use crate::block::{Block, BlockT};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT = Block> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum MsgToNode<'a, B: Clone + BlockT = Block> {
    MsgBlock(&'a B),
    MsgPrivBlock(&'a B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum MsgFromNode<B: Clone + BlockT = Block> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}
