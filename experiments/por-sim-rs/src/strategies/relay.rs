use crate::block::BlockT;
use crate::chain::*;
use crate::msg::*;
use crate::types::*;
use crate::CSystemT;
use conv::prelude::*;
use itertools::any;
use num::pow;
use std::fmt;
use std::fmt::Debug;
use std::fmt::Display;
use std::marker::PhantomData;

/// a strategy that runs at a network level based on incoming msgs
pub trait RelayStrategyT<'a, S: CSystemT<'a>> {
    type ResultsTy: Debug;
    type Params: Clone + Copy + Debug;
    fn init(c: &S::C, atk_start_h: Height, p: Self::Params) -> Self;
    /// Additional msgs that can be provided by attackers when certain conditions are met (e.g., selfish mining requires releasing withheld blocks if the honest network releases one)
    fn on_msg(&mut self, m: &MsgToNode<S::B>, chain: &S::C) -> Vec<MsgToNode<S::B>>;
    fn get_results(&self, c: &S::C) -> Option<(Self::ResultsTy, bool)>;
    fn should_stop_simulation(&self, ts: Timestamp, c: &S::C) -> bool;
    fn params_as_csv(&self) -> String;
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub struct DoubleSpendParams {
    attack_starts_at: Height,
    win_thres: Height,
}

impl DoubleSpendParams {
    pub fn new(attack_starts_at: Height, win_thres: Height) -> Self {
        DoubleSpendParams {
            attack_starts_at,
            win_thres,
        }
    }
}

#[derive(Debug, PartialEq)]
pub struct DoubleSpendStrat {
    params: DoubleSpendParams,
    atk_start_h: Height,
}

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for DoubleSpendStrat {
    type ResultsTy = bool;
    type Params = DoubleSpendParams;
    fn init(_: &S::C, atk_start_h: Height, params: Self::Params) -> Self {
        DoubleSpendStrat {
            params,
            atk_start_h,
        }
    }
    fn on_msg(&mut self, _msg_from: &MsgToNode<S::B>, _chain: &S::C) -> Vec<MsgToNode<S::B>> {
        vec![]
    }
    fn get_results(&self, c: &S::C) -> Option<(Self::ResultsTy, bool)> {
        let hs = c.get_heights_pub_priv();
        let fms = c.get_fork_measure_pub_priv();
        if fms.public < fms.private && hs.public >= self.atk_start_h + self.params.win_thres {
            Some((true, true))
        } else {
            None
        }
    }
    fn should_stop_simulation(&self, ts: Timestamp, c: &S::C) -> bool {
        if ts < self.params.attack_starts_at {
            false
        } else {
            let hs = c.get_heights_pub_priv();
            let fms = c.get_fork_measure_pub_priv();
            fms.public < fms.private && hs.public > self.atk_start_h + self.params.win_thres
        }
    }
    fn params_as_csv(&self) -> String {
        format!(
            "{}, {}",
            self.params.attack_starts_at, self.params.win_thres
        )
    }
}

#[derive(Debug, Default)]
struct Heights {
    private: Height,
    public: Height,
}

#[derive(Debug)]
pub struct SelfishMining<S> {
    params: SelfishMiningParams,
    /// for selfish mining longest chain
    priv_branch_len: u32,
    /// for selfish mining ethereum -- https://arxiv.org/pdf/1901.04620.pdf
    l_s: u32,
    l_h: u32,
    blocks_from_private: FxHashSet<HashID>,
    blocks_from_public: FxHashSet<HashID>,
    best_processed_h: Heights,
    atk_start_h: Height,
    _s: PhantomData<S>,
    // _r: PhantomData<W>,
}

#[derive(Debug, Clone, Copy)]
pub struct SelfishMiningResult {
    predicted_win_ratio_gamma_half: f64,
    predicted_win_ratio_gamma_near_one: f64,
    ratio_priv_blocks_in_chain: f64,
    ratio_priv_weight_in_chain: f64,
    avg_priv_weight_in_chain: f64,
    avg_pub_weight_in_chain: f64,
    ratio_priv_blocks_mined: f64,
    chain_priv_count: f64,
    chain_pub_count: f64,
    chain_other_count: f64,
    n_priv_blocks: f64,
    n_pub_blocks: f64,
    stale_priv_blocks: f64,
    stale_pub_blocks: f64,
    ratio_main_chain_priv: f64,
    ratio_main_chain_pub: f64,
    main_chain_priv_c: f64,
    main_chain_pub_c: f64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SmChainType {
    LongestChain,
    WeightedChain,
    WeightedDag,
}

impl Display for SmChainType {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}",
            match self {
                SmChainType::LongestChain => "LongestChain",
                SmChainType::WeightedChain => "WeightedChain",
                SmChainType::WeightedDag => "WeightedDag",
            }
        )
    }
}

#[derive(Debug, Clone, Copy)]
pub struct SelfishMiningParams {
    pub chain_type: SmChainType,
}

impl<'a, S: CSystemT<'a>> SelfishMining<S> {
    fn sync_pub_to_priv(b: &S::B, atk_chain: &S::C, include_latest: bool) -> Vec<MsgToNode<S::B>> {
        let mut pre_ret = atk_chain.find_pub_blocks_not_in_priv();
        if include_latest {
            pre_ret.push(b.clone());
        }
        let ret_blocks = pre_ret
            .into_iter()
            .map(|b1| MsgToNode::MsgBlock(atk_chain.get_chain_id(), b1, true))
            .collect();
        info!("[SM] sync pub->priv, returning: {:?}", ret_blocks);
        ret_blocks
    }

    fn sync_priv_to_pub(b: &S::B, atk_chain: &S::C, include_latest: bool) -> Vec<MsgToNode<S::B>> {
        let mut pre_ret = atk_chain.find_priv_blocks_not_in_pub();
        if include_latest {
            pre_ret.push(b.clone());
        }
        let ret_blocks = pre_ret
            .into_iter()
            .map(|b1| MsgToNode::MsgBlock(atk_chain.get_chain_id(), b1, false))
            .collect();
        info!("[SM] sync priv->pub, returning: {:?}", ret_blocks);
        ret_blocks
    }

    fn set_l_s_and_l_h_to_zero(&mut self) {
        self.l_h = 0;
        self.l_s = 0;
    }

    fn on_msg_selfish_ethereum(
        &mut self,
        msg_from: &MsgToNode<S::B>,
        atk_chain: &S::C,
    ) -> Vec<MsgToNode<S::B>> {
        let chain_id = atk_chain.get_chain_id();
        match msg_from {
            MsgToNode::MsgBlock(c_id, b, true) if *c_id == chain_id => {
                info!("priv block mined: {}", b);
                self.blocks_from_private.insert(b.get_hash());
                if self.best_processed_h.private >= b.get_height() {
                    // return vec![];
                } else {
                    self.best_processed_h.private = b.get_height();
                    self.l_s += 1;
                }
                // selfish pool mines a new block
                // new blocks should reference all priv uncles
                if self.l_s == 2 && self.l_h == 1 {
                    self.set_l_s_and_l_h_to_zero();
                    // publish private branch
                    Self::sync_priv_to_pub(&b, atk_chain, true)
                } else {
                    // keep mining on private
                    vec![]
                }
            }
            MsgToNode::MsgBlock(c_id, b, false) if *c_id == chain_id => {
                info!("pub block mined: {}", b);
                self.blocks_from_public.insert(b.get_hash());
                if self.best_processed_h.public >= b.get_height() {
                    // return vec![];
                } else {
                    self.best_processed_h.public = b.get_height();
                    self.l_h += 1;
                }
                // public miner refs all unreferenced public uncles
                if self.l_s < self.l_h {
                    self.set_l_s_and_l_h_to_zero();
                    // keep mining on this block
                    Self::sync_pub_to_priv(&b, atk_chain, true)
                } else if self.l_s == self.l_h {
                    // publish the "last" block of private branch
                    Self::sync_priv_to_pub(&b, atk_chain, false)
                } else if self.l_s == self.l_h + 1 {
                    // publish private branch
                    Self::sync_priv_to_pub(&b, atk_chain, false)
                } else {
                    // publish first unpublished block in private branch
                    // if the new block is mined on a public branch that is a prefix of the private branch
                    let best_priv_blocks = atk_chain.get_best_blocks(true);
                    let is_mined_on_prefix = any(best_priv_blocks, |b_priv| {
                        atk_chain.block_is_ancestor_of(b.prev(), b_priv.clone())
                    });
                    if is_mined_on_prefix {
                        self.l_s = self.l_s - self.l_h + 1;
                        self.l_h = 1;
                    }
                    // let max_priv_height = max(atk_chain
                    //     .find_first_priv_blocks_better_than_public()
                    //     .iter()
                    //     .map(|b| b.0.get_height()))
                    // .unwrap_or(u32::MAX);
                    let max_chain_weight =
                        atk_chain.get_chain_weight_at(b.prev()) + b.get_difficulty() * 2;
                    Self::sync_priv_to_pub(&b, atk_chain, false)
                        .into_iter()
                        .filter(|m| match m {
                            MsgToNode::MsgBlock(chain_id, pb, _) => {
                                // (pb.get_height() < b.get_height() + 2
                                //     && pb.get_difficulty() <= b.get_difficulty())
                                //     || (pb.get_difficulty() > b.get_difficulty()
                                //         && pb.get_height() < b.get_height() + 1)
                                atk_chain.get_chain_weight_at(pb.get_hash()) <= max_chain_weight
                            }
                        })
                        .collect()
                }
            }
            _ => vec![],
        }
    }

    fn on_msg_selfish_longest_chain(
        &mut self,
        msg_from: &MsgToNode<S::B>,
        atk_chain: &S::C,
    ) -> Vec<MsgToNode<S::B>> {
        // delta_prev is always calculated before appending blocks to chains (i.e., before msgs are processed)
        let h = atk_chain.get_heights_pub_priv();
        let delta_prev = h.private - h.public;
        let chain_id = atk_chain.get_chain_id();

        match msg_from {
            MsgToNode::MsgBlock(c_id, b, is_private) if *c_id == chain_id => {
                match is_private {
                    false => {
                        self.blocks_from_public.insert(b.get_hash());
                        // [SM] append block to pub chain -- recalc pub length.
                        // NB: -- this will happen when nodes process msgs (after this step),
                        // but worth noting in case we need to do calculations before then.
                        let msgs_out: Vec<_> = match delta_prev {
                            0 => {
                                debug!("[SM] pub / Δprev=0");
                                // [SM] sync public and private chains
                                self.priv_branch_len = 0;
                                // return a msg that adds this block to the priv chain, too,
                                // so the chains stay in sync.
                                Self::sync_pub_to_priv(b, atk_chain, true)
                            }
                            1 => {
                                info!("[SM] pub / Δprev=1");
                                // [SM] publish last block of priv chain (there's only one)
                                /* Note: SM algorithm doesn't include privateBranchLen<-0 for this case.
                                 * That's correct because the 'private' fork still exists
                                 * */

                                Self::sync_priv_to_pub(b, atk_chain, false)
                            }
                            2 => {
                                info!("[SM] pub / Δprev=2");
                                // [SM] publish all of private chain (should be 2 blocks)
                                self.priv_branch_len = 0;

                                Self::sync_priv_to_pub(b, atk_chain, false)
                            }
                            _ => {
                                info!("[SM] pub / Δprev>2");
                                // [SM] publish first unpublished block from private chain
                                /* NB: We only publish 1 priv block so that there are 2 heads of the
                                 * public chain: 1 honest, 1 selfish. Since we have >= 2 priv blocks
                                 * that are still unpublished, we can always out-pace them if need be.
                                 * */
                                atk_chain
                                    .find_first_priv_blocks_better_than_public()
                                    .iter()
                                    .map(|b| MsgToNode::MsgBlock(chain_id, b.0.clone(), false))
                                    .collect()
                            }
                        };
                        msgs_out
                    }
                    true => {
                        info!("[SM] priv");
                        self.blocks_from_private.insert(b.get_hash());
                        // [SM] append block to priv chain -- recalc priv length
                        self.priv_branch_len += 1;
                        if delta_prev == 0 && self.priv_branch_len == 2 {
                            debug!("[SM] priv / Δprev=0");
                            // [SM] publish all priv chain
                            self.priv_branch_len = 0;
                            // NOTE: we just received a new private block, and the SM alg says (line 8)
                            // to append it to the private chain -- so this new block is the best priv block.
                            // Then, in this branch (line 11) we publish all the private chain, which means
                            // publishing this current block.

                            Self::sync_priv_to_pub(b, atk_chain, true)
                        } else {
                            vec![]
                        }
                    }
                }
            }
            _ => vec![],
        }
    }
}

impl<'a, S: CSystemT<'a>> RelayStrategyT<'a, S> for SelfishMining<S> {
    type ResultsTy = SelfishMiningResult;
    type Params = SelfishMiningParams;
    fn init(_chain: &S::C, atk_start_h: Height, params: Self::Params) -> Self {
        SelfishMining {
            params,
            // pub_height: chain.get_any_best_block(false).1.height,
            // priv_height: chain.get_any_best_block(false).1.height,
            priv_branch_len: 0,
            l_s: 0,
            l_h: 0,
            blocks_from_private: Default::default(),
            blocks_from_public: Default::default(),
            best_processed_h: Heights {
                private: 0,
                public: 0,
            },
            atk_start_h,
            _s: PhantomData,
        }
    }

    fn on_msg(&mut self, msg_from: &MsgToNode<S::B>, atk_chain: &S::C) -> Vec<MsgToNode<S::B>> {
        let ret_msgs = match self.params.chain_type {
            // these will be heights
            SmChainType::LongestChain => self.on_msg_selfish_longest_chain(msg_from, atk_chain),
            SmChainType::WeightedChain => {
                panic!("need to properly implement WeightedChain selfish mining")
            }
            SmChainType::WeightedDag => {
                // panic!("need to properly implement WeightedDag selfish mining")
                self.on_msg_selfish_ethereum(msg_from, atk_chain);
                unimplemented!("Ethereum selfish mining not fully implemented (i.e., doesn't work)")
            }
        };
        info!("SM on_msg returning: {:?}", ret_msgs);
        ret_msgs
    }

    fn get_results(&self, c: &S::C) -> Option<(Self::ResultsTy, bool)> {
        /* win conditions for selfish mining:
         * - of blocks in the chain, blocks that were mined privately should
         * */
        let mut chain_priv_count = 0.;
        let mut chain_pub_count = 0.;
        let mut chain_other_count = 0.;
        let mut chain_pub_weight = 0.;
        let mut chain_priv_weight = 0.;
        let mut _chain_other_weight = 0.;

        let mut heads: SeenBlocks = c.get_best_blocks(false).clone();
        let mut seen: SeenBlocks = Default::default();
        loop {
            let h_vec: Vec<_> = heads.iter().filter(|h| !seen.contains(&h)).collect();
            if h_vec.len() == 0 {
                break;
            }
            let mut new_heads: SeenBlocks = Default::default();
            for id in h_vec {
                seen.insert(*id);
                let b = S::C::get_cached_block(&*id).unwrap();
                if self.blocks_from_private.contains(id) {
                    chain_priv_count += 1.;
                    chain_priv_weight += b.1.weight.value_as::<f64>().unwrap();
                } else if self.blocks_from_public.contains(id) {
                    chain_pub_count += 1.;
                    chain_pub_weight += b.1.weight.value_as::<f64>().unwrap();
                } else {
                    chain_other_count += 1.;
                    _chain_other_weight += b.1.weight.value_as::<f64>().unwrap();
                }
                new_heads = new_heads
                    .union(&b.0.all_prev().into_iter().collect())
                    .cloned()
                    .collect();
            }
            heads = new_heads;
        }

        let mut main_chain_priv_c = 0.;
        let mut main_chain_pub_c = 0.;
        let mut _main_chain_other_c = 0.;
        let mut main_chain_b = c.select_best_block(false);
        loop {
            if self.blocks_from_private.contains(&main_chain_b) {
                main_chain_priv_c += 1.;
            } else if self.blocks_from_public.contains(&main_chain_b) {
                main_chain_pub_c += 1.;
            } else {
                _main_chain_other_c += 1.;
            }
            let next_main_chain_b = S::C::get_cached_block(&main_chain_b).unwrap().0.prev();
            if next_main_chain_b == main_chain_b {
                break;
            }
            main_chain_b = next_main_chain_b;
        }

        let total_chain_count = chain_priv_count + chain_pub_count;
        let total_w = chain_priv_weight + chain_pub_weight;
        let n_priv_blocks = self.blocks_from_private.len().value_as::<f64>().unwrap();
        let n_pub_blocks = self.blocks_from_public.len().value_as::<f64>().unwrap();
        let n_total_blocks = n_priv_blocks + n_pub_blocks;
        let ratio_priv_blocks_in_chain = chain_priv_count / total_chain_count;
        let ratio_priv_weight_in_chain = chain_priv_weight / total_w;
        let avg_priv_weight_in_chain = chain_priv_weight / n_priv_blocks;
        let avg_pub_weight_in_chain = chain_pub_weight / n_pub_blocks;
        let ratio_priv_blocks_mined = n_priv_blocks / n_total_blocks;
        let stale_priv_blocks = n_priv_blocks - chain_priv_count;
        let stale_pub_blocks = n_pub_blocks - chain_pub_count;

        let total_main_chain_c = main_chain_priv_c + main_chain_pub_c;
        let ratio_main_chain_priv = main_chain_priv_c / total_main_chain_c;
        let ratio_main_chain_pub = main_chain_pub_c / total_main_chain_c;

        let alpha = ratio_priv_blocks_mined;
        let gamma = 0.5;
        let predicted_win_ratio_gamma_half =
            (alpha * pow(1. - alpha, 2) * (4. * alpha + gamma * (1. - 2. * alpha)) - pow(alpha, 3))
                / (1. - alpha * (1. + (2. - alpha) * alpha));
        let gamma = 0.99;
        let predicted_win_ratio_gamma_near_one =
            (alpha * pow(1. - alpha, 2) * (4. * alpha + gamma * (1. - 2. * alpha)) - pow(alpha, 3))
                / (1. - alpha * (1. + (2. - alpha) * alpha));

        // add a little error margin to claiming success
        let success = ratio_priv_blocks_in_chain > (ratio_priv_blocks_mined + 0.005)
            && predicted_win_ratio_gamma_half - ratio_priv_blocks_in_chain < 0.03;

        // todo: predicted_win_ratio seems to be about 0.01 to 0.015 higher than the observed ratio.
        // Not sure if this is because of an implementation error (mb) or if it's tolerable error.

        Some((
            SelfishMiningResult {
                predicted_win_ratio_gamma_half,
                predicted_win_ratio_gamma_near_one,
                ratio_priv_blocks_in_chain,
                ratio_priv_weight_in_chain,
                avg_priv_weight_in_chain,
                avg_pub_weight_in_chain,
                ratio_priv_blocks_mined,
                chain_priv_count,
                chain_pub_count,
                chain_other_count,
                n_priv_blocks,
                n_pub_blocks,
                stale_priv_blocks,
                stale_pub_blocks,
                ratio_main_chain_priv,
                ratio_main_chain_pub,
                main_chain_priv_c,
                main_chain_pub_c,
            },
            success,
        ))
    }
    fn should_stop_simulation(&self, _ts: Timestamp, _c: &S::C) -> bool {
        // never stop selfish mining
        false
    }
    fn params_as_csv(&self) -> String {
        format!("{}", self.params.chain_type)
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
        let net_args = NetworkArgs::new(10);
        let c = S::C::new(
            genesis.clone(),
            BlockMD::mk_genesis_md(&genesis, net_args.daa2_n_blocks),
            net_args,
        );
        (
            SelfishMining::init(
                &c,
                0,
                SelfishMiningParams {
                    chain_type: SmChainType::LongestChain,
                },
            ),
            c,
        )
    }

    #[test]
    fn test_selfish_mining_pub_priv_priv_priv_pub_pub() -> Result<(), ChainErr> {
        let (mut sm, mut c) = create_sm::<SimpleCS>();
        let chain_id = c.get_chain_id();

        // create a public block
        let b1 = c.draft_block(10, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b1.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b1.clone(), true)]
        );
        // simulate the actions from msgs
        c.add_block(b1.clone(), false)?;
        c.add_block(b1.clone(), true)?;

        // create a private block (lead=1)
        let b2 = c.draft_block(20, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b2.clone(), true), &c);
        assert_eq!(sm_msgs, vec![]);
        c.add_block(b2.clone(), true)?;

        // another priv block (lead=2)
        let b3 = c.draft_block(30, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b3.clone(), true), &c);
        // -- NOTE, we should only see a msg on a private block when there are 2 valid heads (1 pub, 1 'priv')
        assert_eq!(
            sm_msgs,
            vec![],
            "don't publish on new priv block b/c we don't need to"
        );
        c.add_block(b3.clone(), true)?;

        // another priv block (lead=3)
        let b4 = c.draft_block(40, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b4.clone(), true), &c);
        assert_eq!(
            sm_msgs,
            vec![],
            "don't publish on new priv block b/c we don't need to"
        );
        c.add_block(b4.clone(), true)?;

        // add a public block (lead=2)
        let b5 = c.draft_block(41, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b5.clone(), false), &c);
        // since a public block was published we want to publish a competing priv block
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b2.clone(), false)],
            "publish priv on new pub block"
        );
        c.add_block(b5.clone(), false)?;
        c.add_block(b2.clone(), false)?;

        // add another priv block then pub block
        let b5a = c.draft_block(45, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b5a.clone(), true), &c);
        assert_eq!(sm_msgs, vec![]);
        c.add_block(b5a.clone(), true)?;

        let b5b = c.draft_block(45, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b5b.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b3.clone(), false)]
        );
        c.add_block(b3.clone(), false)?;
        c.add_block(b5b.clone(), false)?;

        // add a public block (lead=1)
        let b6 = c.draft_block(51, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b6.clone(), false), &c);
        // since a public block was published we want to publish a competing priv block
        // todo!("see todo in pub/2 branch");
        assert_eq!(
            sm_msgs,
            vec![
                MsgToNode::MsgBlock(chain_id, b4.clone(), false),
                MsgToNode::MsgBlock(chain_id, b5a.clone(), false)
            ],
            "publish ALL priv on new pub block with lead=1"
        );
        c.add_block(b6.clone(), false)?;
        c.add_block(b4.clone(), false)?;
        c.add_block(b5a.clone(), false)?;

        assert_eq!(
            c.get_best_blocks(false),
            &FxHashSet::from_iter([b5a.get_hash()].iter().cloned()),
            "previously private block is exclusively winning on public chain"
        );

        let w = sm.get_results(&c).unwrap();
        println!("W: {:?}", w);
        assert_eq!(
            w.0.ratio_priv_blocks_mined, 0.5,
            "50% of blocks mined were priv"
        );
        assert_eq!(
            w.0.ratio_priv_blocks_in_chain,
            4. / 5.,
            "80% of blocks in chain were priv"
        );

        Ok(())
    }

    #[test]
    fn test_selfish_mining_pub_priv_pub_priv() -> Result<(), ChainErr> {
        let (mut sm, mut c) = create_sm::<SimpleCS>();
        let chain_id = c.get_chain_id();

        // create a public block
        let b1 = c.draft_block(10, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b1.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b1.clone(), true)],
            "public block relayed to private chain"
        );
        // simulate the actions from msgs
        c.add_block(b1.clone(), false)?;
        c.add_block(b1.clone(), true)?;
        println!("Added b1 to both chains");

        // create a private block (lead=1)
        let b2 = c.draft_block(20, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b2.clone(), true), &c);
        assert_eq!(sm_msgs, vec![], "no new msgs on this priv block");
        c.add_block(b2.clone(), true)?;
        println!("Added b2 to priv chain");

        // create a public block (lead=0, but fork)
        let b2a = c.draft_block(20, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b2a.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b2.clone(), false)],
            "publish priv block so that we have 2 competing heads"
        );
        c.add_block(b2a.clone(), false)?;
        println!("Added b2a to pub chain");

        assert_eq!(
            c.get_chain_heads(false).contains_key(&b2.get_hash()),
            false,
            "public chain should not know about b2 yet"
        );

        // another priv block (lead=0->1, resolves fork)
        let b3 = c.draft_block(30, true).test_set_work_bits(16);
        assert_eq!(
            b3.prev(),
            b2.get_hash(),
            "this private block should build on the private chain only."
        );
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b3.clone(), true), &c);
        // -- NOTE, we should only see a msg on a private block when there are 2 valid heads (1 pub, 1 'priv')
        assert_eq!(
            sm_msgs,
            vec![
                MsgToNode::MsgBlock(chain_id, b2.clone(), false),
                MsgToNode::MsgBlock(chain_id, b3.clone(), false)
            ],
            "publish better priv block immediately to resolve fork"
        );
        c.add_block(b2.clone(), false)?;
        c.add_block(b3.clone(), true)?;
        c.add_block(b3.clone(), false)?;
        println!("Added b2 to pub chain + b3 to both chains");

        assert_eq!(
            c.get_best_blocks(false),
            &FxHashSet::from_iter([b3.get_hash()].iter().cloned()),
            "previously private block is exclusively winning on public chain"
        );

        let w = sm.get_results(&c).unwrap();
        println!("W: {:?}", w);
        assert_eq!(
            w.0.ratio_priv_blocks_mined, 0.5,
            "50% of blocks mined were priv"
        );
        assert_eq!(
            w.0.ratio_priv_blocks_in_chain,
            2. / 3.,
            "66% of blocks in chain were priv"
        );

        Ok(())
    }

    #[test]
    fn test_selfish_mining_priv_pub_pub() -> Result<(), ChainErr> {
        let (mut sm, mut c) = create_sm::<SimpleCS>();
        let chain_id = c.get_chain_id();

        // create a private block
        let b2 = c.draft_block(20, true).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b2.clone(), true), &c);
        assert_eq!(sm_msgs, vec![], "no new msgs on this priv block");
        c.add_block(b2.clone(), true)?;
        println!("Added b2 to priv chain");

        // create a public block (lead=0, but fork)
        let b2a = c.draft_block(20, false).test_set_work_bits(16);
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b2a.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![MsgToNode::MsgBlock(chain_id, b2.clone(), false)],
            "publish priv block so that we have 2 competing heads"
        );
        c.add_block(b2a.clone(), false)?;
        println!("Added b2a to pub chain");

        assert_eq!(
            c.get_chain_heads(false).contains_key(&b2.get_hash()),
            false,
            "public chain should not know about b2 yet"
        );
        assert_eq!(
            c.get_chain_heads(true).contains_key(&b2a.get_hash()),
            false,
            "priv chain should not know about b2a yet"
        );

        // another pub block (wins fork)
        let b3a = c.draft_block(30, false).test_set_work_bits(16);
        assert_eq!(
            b3a.prev(),
            b2a.get_hash(),
            "this pub block should build on the pub chain only."
        );
        let sm_msgs = sm.on_msg(&MsgToNode::MsgBlock(chain_id, b3a.clone(), false), &c);
        assert_eq!(
            sm_msgs,
            vec![
                MsgToNode::MsgBlock(chain_id, b2a.clone(), true),
                MsgToNode::MsgBlock(chain_id, b3a.clone(), true)
            ],
            "publish pub blocks to priv chain b/c pub won"
        );
        c.add_block(b2a.clone(), true)?;
        c.add_block(b3a.clone(), true)?;
        println!("Added b2a,b3a to priv chains");

        assert_eq!(
            c.get_best_blocks(true),
            &FxHashSet::from_iter([b3a.get_hash()].iter().cloned()),
            "pub block is exclusively"
        );

        Ok(())
    }

    #[test]
    #[ignore]
    fn sm_weighted_chain() {
        unimplemented!("Need to implement sm_weighted_chain.");
    }

    #[test]
    #[ignore]
    fn sm_weighted_dag() {
        unimplemented!("Need to implement sm_weighted_dag.");
    }
}
