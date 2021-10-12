require('jsonc-require')
const vscodeSettings = require('./.vscode/settings.json')
const extraWords = vscodeSettings["cSpell.words"]
const ignoredWords = vscodeSettings["cSpell.ignoreWords"]
const flaggedWords = vscodeSettings["cSpell.flagWords"]
const ignoredRegex = vscodeSettings["cSpell.ignoreRegExpList"]

module.exports = {
    "plugins": ["latex2e"],
    "rules": {
        "write-good": false,
        "ginger": false, // grammar + spelling -- https://github.com/textlint-rule/textlint-rule-ginger
        "spelling": {  // https://github.com/tani/textlint-rule-spelling
            "language": "en",
            "suggestCorrections": false,
            "skipPatterns": [
                ...extraWords,
                ...ignoredWords,
                ...(ignoredRegex.map(r => `/${r}/g`)),
                "/_sag\\b/g",
                "/\\b[0-9]pt\\b/g",
                "/\\b[0-9]{2}\\b/g",
                "/\\b[0-9]+[xs]\\b/g",  // numbers with units
                "/\\b[0-9A-Za-z]_[0-9A-Za-z]?\\b/g",
                "/\\b[a-z]?[0-9A-Za-z]_[0-9A-Za-z]?\\b/g",
                "/\\b[A-Z]+(_[A-Z_]+)+\\b/g",
                "/\\b[0-9]+\\b/g",
                "Dapp", "dapp", "sharding",
                "/\\\\todo(DraftOnly)?\\{[a-zA-Z0-9 -,\\.;:!\\}/g",
                "TPS", "tx", "/[Tt]x(s)?/", "Ethereum", "https", "eth2", "ROI",
                "mempool", "sawtooth", "crypto", "GPUs", "XertroV", "ipfs", "DagCoin", "Acyclic",
                "msg678006", "php", "bitcointalk",
                "/\\b[0-9]+(nm|km|hg|em|pt|cm|rem|h|yrs|ex|p|a|b|D)\\b/",
                "atm", "mk", "those're", "subgraph", "pdf", "github",
                "wildbunny", "SHA256", "Ethash", "WeightOf", "ReflectedWeight", "Merkle",
                "/part[0-9]/",
                "/por_step/",
                "/\\bQm[A-Za-z0-9]{30,}\\b/",
                "/\\b[a-f0-9]{7,}\\b/",
                "/\\b[a-z_]+\\b/",
                "/Example_5/",
                "/_Trading_across_chains/",
                "EVM", "ETH", "BTC", "Eth", "step[0-9]", "SCs", "DEX",
                // "/^\\newcommand(.*)$/",
                "/=[A-Za-z{]{2,}/", "GL", "Refls", "MinBand", "/child[12]/", "Simplex",
                "TTS", "compare_", "N1", "Sharded", "T1",
                "BeaconBlock", "ShardBlob", "Bitfields", "Kusama", "phase0", "Dh",
                "s5", "Whitepaper", "USD", "_refl_",
                "paraInclusion",
                "candidateBacked",
                "BitcoinTalk",
                "/L[0-9]{2,}/",
                "2B_h", "EOS", "Solana", "Ittay", "Eyal", "Emin", "Sirer", "Trustless",
                "Petersburg", "SegWit", "s2", "TOC", "Incentivization",
                "ReflectedBlockWeight", "Ouroboros", "s10",
            ],
        },
        "en-max-word-count": {
            "max" : 40,
            "severity": "warning"
        },
        "sentence-length": {
            "max": 250,
            "severity": "warning"
        },
        "stop-words": {  // https://github.com/sapegin/textlint-rule-stop-words
            "defaultWords": false,
            "words": [
                ["dappchain", "dapp-chain"],
                ["dappchains", "dapp-chains"],
                ["dapp chain", "dapp-chain"],
                ["dapp chains", "dapp-chains"],
                ["root-token", "root token"],
                ["DApp", "dapp"],
                ["DApps", "dapps"],
                ["hte", "the"],
                ["teh", "the"],
                ["discreet", "discrete"],
                ["DOS", "DoS"],
                ["straight forward", "straightforward"],
                ["block produces", "block producers"],
                ["the affect"],
                ["N_{tiles}", "N_{\\text{tiles}}"],
                ["analyse"],  // british spelling, disallow but don't fix so we don't break quotes
                ["analysed"],
                ["analyses"],
                ["e.g. ", "e.g., "],
                ["i.e. ", "i.e., "],
                ["full-node", "full node"],
                ["full-nodes", "full nodes"],
                ["dut"],
                ["<=", "\\le"],
                [">=", "\\ge"],
                ["\\being{", "\\begin{"],
                ["re-write", "rewrite"],
            ]
        }
    }
}
