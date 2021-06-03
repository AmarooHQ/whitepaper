use crate::block::BlockT;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
// pub enum MsgToNode<B: Clone + BlockT> {
pub enum MsgToNode<B: BlockT> {
    MsgBlock(B, bool),
}

#[cfg(test)]
mod tests {
    // use super::*;
    // use crate::block::Block;
}
