use crate::block::BlockT;
use crate::chain::*;
use crate::msg::*;
use crate::types::*;
use crate::CSystemT;
use conv::prelude::*;
use std::collections::HashSet;
use std::marker::PhantomData;

/// a strategy that runs at a network level based on incoming msgs
pub trait RelayStrategyT<'a, S: CSystemT<'a>, W> {
    fn init(c: &S::C) -> Self;
    fn on_msg(&mut self, m: &MsgToNode<S::B>, chain: &S::C) -> Vec<MsgToNode<S::B>>;
    fn is_winning(&self, c: &S::C) -> W;
}

pub struct NullRelayStrat();

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S, bool> for NullRelayStrat {
    fn init(_: &<S as CSystemT<'a>>::C) -> Self {
        NullRelayStrat()
    }
    fn on_msg(&mut self, _msg_from: &MsgToNode<S::B>, _chain: &S::C) -> Vec<MsgToNode<S::B>> {
        vec![]
    }
    fn is_winning(&self, _: &S::C) -> bool {
        false
    }
}

pub struct SelfishMining<S> {
    // pub_height: Height,
    // priv_height: Height,
    priv_branch_len: u32,
    blocks_from_private: HashSet<HashID>,
    blocks_from_public: HashSet<HashID>,
    _s: PhantomData<S>,
    // _r: PhantomData<W>,
}

#[derive(Debug, PartialEq)]
pub struct SelfishMiningResult {
    ratio_priv_blocks_in_chain: f64,
    ratio_priv_blocks_mined: f64,
}

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S, SelfishMiningResult> for SelfishMining<S> {
    fn init(_chain: &S::C) -> Self {
        SelfishMining {
            // pub_height: chain.get_any_best_block(false).1.height,
            // priv_height: chain.get_any_best_block(false).1.height,
            priv_branch_len: 0,
            blocks_from_private: Default::default(),
            blocks_from_public: Default::default(),
            _s: PhantomData,
        }
    }
    fn is_winning(&self, c: &S::C) -> SelfishMiningResult {
        /* win conditions for selfish mining:
         * - of blocks in the chain, blocks that were mined privately should
         * */
        let mut priv_count = 0.;
        let mut pub_count = 0.;
        let mut heads: HashSet<HashID> = c.get_best_blocks(false).clone();
        let mut seen: HashSet<HashID> = Default::default();
        loop {
            let h_vec: Vec<_> = heads.iter().filter(|h| !seen.contains(&h)).collect();
            if h_vec.len() == 0 {
                break;
            }
            let mut new_heads = HashSet::<HashID>::new();
            for id in h_vec {
                seen.insert(*id);
                if self.blocks_from_private.contains(id) {
                    priv_count += 1.;
                } else if self.blocks_from_public.contains(id) {
                    pub_count += 1.;
                }
                let b = S::C::get_cached_block(*id).unwrap();
                new_heads = new_heads
                    .union(&b.0.all_prev().into_iter().collect())
                    .cloned()
                    .collect();
            }
            heads = new_heads;
        }
        let ratio_priv_blocks_in_chain = priv_count / (priv_count + pub_count);
        let n_priv_blocks = self.blocks_from_private.len().value_as::<f64>().unwrap();
        let n_pub_blocks = self.blocks_from_public.len().value_as::<f64>().unwrap();
        let ratio_priv_blocks_mined = n_priv_blocks / (n_priv_blocks + n_pub_blocks);
        SelfishMiningResult {
            ratio_priv_blocks_in_chain,
            ratio_priv_blocks_mined,
        }
    }
    fn on_msg(&mut self, msg_from: &MsgToNode<S::B>, atk_chain: &S::C) -> Vec<MsgToNode<S::B>> {
        let h = atk_chain.get_heights_pub_priv();
        // delta_prev is always calculated before appending blocks to chains (i.e., before msgs are processed)
        let delta_prev = h.private - h.public;

        match msg_from {
            MsgToNode::MsgBlock(b, is_private) => {
                match is_private {
                    false => {
                        self.blocks_from_public.insert(b.get_hash());
                        // [SM] append block to pub chain -- recalc pub length.
                        // NB: -- this will happen when nodes process msgs (after this step),
                        // but worth noting in case we need to do calculations before then.
                        match delta_prev {
                            0 => {
                                // [SM] sync public and private chains
                                self.priv_branch_len = 0;
                                // return a msg that adds this block to the priv chain, too,
                                // so the chains stay in sync.
                                vec![MsgToNode::MsgBlock(b.clone(), true)]
                            }
                            1 => {
                                // [SM] publish last block of priv chain (there's only one)
                                /* Note: SM algorithm doesn't include privateBranchLen<-0 for this case.
                                 * IDK if that's correct or not.
                                 * self.priv_branch_len = 0;
                                 * */
                                // NB: we might have got multiple private heads, so iter over them and b'cast all
                                atk_chain
                                    .get_best_blocks(true)
                                    .iter()
                                    .map(|id| {
                                        MsgToNode::MsgBlock(
                                            S::C::get_cached_block(*id).unwrap().0.clone(),
                                            false,
                                        )
                                    })
                                    .collect()
                            }
                            2 => {
                                // [SM] publish all of private chain (should be 2 blocks)
                                self.priv_branch_len = 0;
                                /* NB: this is the same code as above. As long as chain's don't track
                                 * state, then we can just broadcast the latest best block (since the
                                 * parent block already exists in the block cache); i.e., we don't need
                                 * to broadcast the parents of our best priv block.
                                 * */
                                atk_chain
                                    .get_best_blocks(true)
                                    .iter()
                                    .map::<Vec<_>, _>(|id| {
                                        let b2 = S::C::get_cached_block(*id).unwrap().0.clone();
                                        let ps = b2.all_prev();
                                        let b1s = ps.iter().map(|p_id| {
                                            S::C::get_cached_block(*p_id).unwrap().0.clone()
                                        });
                                        b1s.into_iter()
                                            .chain(vec![b2].into_iter())
                                            .map(|b| MsgToNode::MsgBlock(b, false))
                                            .collect()
                                    })
                                    .collect::<Vec<_>>()
                                    .concat()
                            }
                            _ => {
                                // [SM] publish first unpublished block from private chain
                                /* NB: We only publish 1 priv block so that there are 2 heads of the
                                 * public chain: 1 honest, 1 selfish. Since we have >= 2 priv blocks
                                 * that are still unpublished, we can always out-pace them if need be.
                                 * */
                                atk_chain
                                    .find_first_priv_blocks_better_than_public()
                                    .iter()
                                    .map(|b| MsgToNode::MsgBlock(b.0.clone(), false))
                                    .collect()
                            }
                        }
                    }
                    true => {
                        self.blocks_from_private.insert(b.get_hash());
                        // [SM] append block to priv chain -- recalc priv length
                        self.priv_branch_len += 1;
                        if delta_prev == 0 && self.priv_branch_len == 2 {
                            // [SM] publish all priv chain
                            self.priv_branch_len = 0;
                            // NOTE: we just received a new private block, and the SM alg says (line 8)
                            // to append it to the private chain -- so this new block is the best priv block.
                            // Then, in this branch (line 11) we publish all the private chain, which means
                            // publishing this current block.

                            vec![
                                // atk_chain
                                //     .get_best_blocks(true)
                                //     .iter()
                                //     .map(|id| {
                                //         MsgToNode::MsgBlock(
                                //             S::C::get_cached_block(*id).unwrap().0.clone(),
                                //             false,
                                //         )
                                //     })
                                //     .collect(),
                                vec![MsgToNode::MsgBlock(b.clone(), false)],
                            ]
                            .concat()
                        } else {
                            vec![]
                        }
                    }
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block_metadata::BlockMD;
    use crate::cryptosystem::SimpleCS;
    use std::iter::FromIterator;

    fn create_sm<'a, S: CSystemT<'a>>() -> (SelfishMining<S>, S::C) {
        let genesis = S::B::genesis(0);
        let c = S::C::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, <SimpleCS as CSystemT>::C::DAA2_N_BLOCKS),
        );
        (SelfishMining::init(&c), c)
    }

    #[test]
    fn test_selfish_mining_pub_priv_priv_priv_pub_pub() -> Result<(), ChainErr> {
        let (mut sm, mut c) = create_sm::<SimpleCS>();

        // create a public block
        let b1 = c.draft_block(10, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b1.clone(), false), &c);
        assert_eq!(sm_msgs, vec![MsgToNode::MsgBlock(b1.clone(), true)]);
        // simulate the actions from msgs
        c.add_block(b1.clone(), false)?;
        c.add_block(b1.clone(), true)?;

        // create a private block (lead=1)
        let b2 = c.draft_block(20, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b2.clone(), true), &c);
        assert_eq!(sm_msgs, vec![]);
        c.add_block(b2.clone(), true)?;

        // another priv block (lead=2)
        let b3 = c.draft_block(30, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b3.clone(), true), &c);
        // -- NOTE, we should only see a msg on a private block when there are 2 valid heads (1 pub, 1 'priv')
        assert_eq!(
            sm_msgs,
            vec![],
            "don't publish on new priv block b/c we don't need to"
        );
        c.add_block(b3.clone(), true)?;

        // another priv block (lead=3)
        let b4 = c.draft_block(40, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b4.clone(), true), &c);
        assert_eq!(
            sm_msgs,
            vec![],
            "don't publish on new priv block b/c we don't need to"
        );
        c.add_block(b4.clone(), true)?;

        // add a public block (lead=2)
        let b5 = c.draft_block(41, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b5.clone(), false), &c);
        // since a public block was published we want to publish a competing priv block
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(b2.clone(), false)],
            "publish priv on new pub block"
        );
        c.add_block(b5.clone(), false)?;
        c.add_block(b2.clone(), false)?;

        // add a public block (lead=1)
        let b6 = c.draft_block(51, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b6.clone(), false), &c);
        // since a public block was published we want to publish a competing priv block
        assert_eq!(
            sm_msgs,
            vec![
                MsgToNode::MsgBlock(b3.clone(), false),
                MsgToNode::MsgBlock(b4.clone(), false)
            ],
            "publish ALL priv on new pub block with lead=1"
        );
        c.add_block(b6.clone(), false)?;
        c.add_block(b3.clone(), false)?;
        c.add_block(b4.clone(), false)?;

        assert_eq!(
            c.get_best_blocks(false),
            &HashSet::from_iter([b4.get_hash()].iter().cloned()),
            "previously private block is exclusively winning on public chain"
        );

        let w = sm.is_winning(&c);
        println!("W: {:?}", w);
        assert_eq!(
            w.ratio_priv_blocks_mined, 0.5,
            "50% of blocks mined were priv"
        );
        assert_eq!(
            w.ratio_priv_blocks_in_chain,
            3. / 4.,
            "75% of blocks in chain were priv"
        );

        Ok(())
    }

    #[test]
    fn test_selfish_mining_pub_priv_pub_priv() -> Result<(), ChainErr> {
        let (mut sm, mut c) = create_sm::<SimpleCS>();

        // create a public block
        let b1 = c.draft_block(10, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b1.clone(), false), &c);
        assert_eq!(sm_msgs, vec![MsgToNode::MsgBlock(b1.clone(), true)]);
        // simulate the actions from msgs
        c.add_block(b1.clone(), false)?;
        c.add_block(b1.clone(), true)?;

        // create a private block (lead=1)
        let b2 = c.draft_block(20, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b2.clone(), true), &c);
        assert_eq!(sm_msgs, vec![]);
        c.add_block(b2.clone(), true)?;

        // create a public block (lead=0, but fork)
        let b2a = c.draft_block(20, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b2a.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(b2.clone(), false)],
            "publish priv block so that we have 2 competing heads"
        );
        c.add_block(b2a.clone(), false)?;

        // another priv block (lead=0->1, resolves fork)
        let b3 = c.draft_block(30, true).test_set_work_bits(16);
        assert_eq!(
            b3.prev(),
            b2.get_hash(),
            "this private block should build on the private chain only."
        );
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(b3.clone(), true), &c);
        // -- NOTE, we should only see a msg on a private block when there are 2 valid heads (1 pub, 1 'priv')
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(b3.clone(), false)],
            "publish better priv block immediately to resolve fork"
        );
        c.add_block(b3.clone(), true)?;
        c.add_block(b3.clone(), false)?;

        assert_eq!(
            c.get_best_blocks(false),
            &HashSet::from_iter([b3.get_hash()].iter().cloned()),
            "previously private block is exclusively winning on public chain"
        );

        let w = sm.is_winning(&c);
        println!("W: {:?}", w);
        assert_eq!(
            w.ratio_priv_blocks_mined, 0.5,
            "50% of blocks mined were priv"
        );
        assert_eq!(
            w.ratio_priv_blocks_in_chain,
            2. / 3.,
            "66% of blocks in chain were priv"
        );

        Ok(())
    }
}
