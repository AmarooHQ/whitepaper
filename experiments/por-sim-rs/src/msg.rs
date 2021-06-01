use crate::block::{Block, BlockT};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum MsgToNode<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum MsgFromNode<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}
