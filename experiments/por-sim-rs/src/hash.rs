#[inline]
pub fn hash_u128(data: u128) -> u128 {
    twox_hash::xxh3::hash128(&data.to_be_bytes()[..])
}

// md5: 6.82s user 0.36s system 99% cpu 7.179 total
// sha1: 5.89s user 0.31s system 99% cpu 6.204 total
// sha256: 6.04s user 0.25s system 99% cpu 6.287 total
// twox::xxh3::hash128: 1.54s user 0.30s system 99% cpu 1.841
// blake2b: 5.15s user 0.27s system 99% cpu 5.425 total
// blake2s: 6.11s user 0.34s system 99% cpu 6.452 total

// use crypto_hash::{digest, Algorithm};
// use std::convert::TryInto;
// let result = digest(Algorithm::SHA256, bs);
// u128::from_be_bytes(result[..16].try_into().unwrap())

// use blake2_rfc::blake2b::{blake2b, Blake2b};
// use blake2_rfc::blake2s::blake2s;
// use std::convert::TryInto;
// let r = blake2b(64, &[], bs);
// let r = blake2s(32, &[], bs);
// let r2 = &r.as_bytes()[..16];
// u128::from_be_bytes(r2.try_into().unwrap())
