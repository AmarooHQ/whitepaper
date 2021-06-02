use crate::block::BlockT;
#[cfg(test)]
use crate::types::HashID;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    // MsgEcho(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
// pub enum MsgToNode<B: Clone + BlockT> {
pub enum MsgToNode<B: BlockT> {
    MsgBlock(B),
    MsgPrivBlock(B),
    #[cfg(test)]
    MsgCachedBlock(HashID, bool),
    // MsgEcho(String),
}

// #[derive(Debug, Clone, PartialEq, Eq, Hash)]
// pub enum MsgFromNode<B: Clone + BlockT> {
//     MsgBlock(B),
//     MsgPrivBlock(B),
//     // MsgEcho(String),
// }

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::Block;

    #[test]
    fn cached_block() {
        let _a = MsgToNode::<Block>::MsgCachedBlock(1, false);
    }
}
