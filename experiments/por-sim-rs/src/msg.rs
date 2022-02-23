use crate::block::BlockT;
use crate::HashID;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Msg<B: Clone + BlockT> {
    /// chain_id, block
    MsgBlock(HashID, B),
    /// chain_id, block
    MsgPrivBlock(HashID, B),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
/// chain_id, block, is_private
pub enum MsgToNode<B: BlockT> {
    MsgBlock(HashID, B, bool),
}

#[cfg(test)]
mod tests {
    // use super::*;
    // use crate::block::Block;
}
