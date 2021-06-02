use crate::block::BlockT;
use crate::types::HashID;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
// pub enum MsgToNode<B: Clone + BlockT> {
pub enum MsgToNode {
    // MsgBlock(B),
    // MsgPrivBlock(B),
    MsgCachedBlock(HashID, bool),
    // MsgEcho(String),
}

// #[derive(Debug, Clone, PartialEq, Eq, Hash)]
// pub enum MsgFromNode<B: Clone + BlockT> {
//     MsgBlock(B),
//     MsgPrivBlock(B),
//     // MsgEcho(String),
// }
