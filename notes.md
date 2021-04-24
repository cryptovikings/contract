# Notes

## Mythology Ties

### Nornir

Used for the contract name.

> The Norns (Old Norse: norn, plural: **nornir**) in Norse mythology are female beings who rule the destiny of gods and men. They roughly correspond to other controllers of humans' destiny, such as the Fates, elsewhere in European mythology.

### Max Vikings

The Max Viking count is set to **9873**.

[Article](https://skjalden.com/important-numbers-norse-mythology/)

## Code

### ChainLink Data

```javascript
const RINKEBY_VRF_COORDINATOR = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
const RINKEBY_LINKTOKEN = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
const RINKEBY_KEYHASH = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';
```

### Compiling Issues

I had to drop OpenZeppelin's package version down to `3.4.1`. The Solidity versions of OpenZeppelin and ChainLink weren't compatible.

We need to keep an eye on when ChainLink up their VRF contract to `0.8.0`. We can then use the latest package version of OpenZeppelin, update the Solidity version of the main contract, and also update the compiler versions.

When this is done, we need to make the following changes to the contract...

\- `import "@openzeppelin/contracts/token/ERC721/ERC721.sol";`

\+ `import "@openzeppelin/contracts/token/ERC721/extensions/ERC721.sol";`

\- `contract Nornir is ERC721, VRFConsumerBase {`

\+ `contract Nornir is ERC721URIStorage, VRFConsumerBase {`

### HardHat Etherscan

HardHat plugin to verify contract. [Docs](https://github.com/nomiclabs/hardhat/tree/master/packages/hardhat-etherscan)

`npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"`

`npx hardhat verify --network rinkeby DEPLOYED_CONTRACT_ADDRESS "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B" "0x01BE23585060835E02B77ef475b0Cc51aA1e0709" "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311"`

## Bonding Curve

This covers the sale idea. In short, a dipping bonding curve.

We will be taking a standard bonding curve and looking to add an idea on top which blends the projects subject matter and gamification.

Each Viking available to be minted will start at the current bonding curves price. After a certain amount of blocks passing a price reduction will commence. This price reduction will continue until a viking is worth half it's initial value.

The initial bonding curve will be as so:

| Levels          | Quantity | Price (ETH) | Value |
|-----------------|----------|-------------|-------|
| `9500` - `9873` | `373`    | `1.00`      | `373` |
| `9000` - `9500` | `500`    | `0.64`      | `320` |
| `7000` - `9000` | `2000`   | `0.32`      | `640` |
| `3500` - `7000` | `3500`   | `0.16`      | `560` |
| `1500` - `3500` | `2000`   | `0.08`      | `160` |
| `500`  - `1500` | `1000`   | `0.04`      | `40`  |
| `0`    - `500`  | `500`    | `0.02`      | `10`  |

This bonding curve maxes out at `2103 ETH`. However, each Viking has the possibility to drop 50% of value before being minted. This takes the minimum value of a sell out to `1051.5 ETH`.

### The Pillage

To keep it tied in with the Viking theme we shall call this dipping process "The Pillage".

Once a Viking has been brought the block number it was brought on shall be stored, we will be using this as our base for "The Pillage". After X amount of blocks have passed The Pillage will start. Every block after The Pillage starts will take value from the Viking's price. This will price continue to drop until either it's brought, and the process starts again with the new block, or it sits at it's max pillage value (half).

I'd place forward that The Pillage starts after `540` blocks (`avg. block time 13.27 seconds * 540 = 1.9905 hours`).

Across each level of the bonding curve the curve and The Pillage will look like so:

| Level 1       |              |
|---------------|--------------|
| Price         | `0.02 ETH`   |
| Drop p/Block  | `0.0001 ETH` |
| Min Price     | `0.01 ETH`   |
| Blocks to Min | `100`        |
| Avg. Time     | `22.11 min`  |

| Level 2       |              |
|---------------|--------------|
| Price         | `0.04 ETH`   |
| Drop p/Block  | `0.0001 ETH` |
| Min Price     | `0.02 ETH`   |
| Blocks to Min | `200`        |
| Avg. Time     | `44.23 min`  |

| Level 3       |              |
|---------------|--------------|
| Price         | `0.08 ETH`   |
| Drop p/Block  | `0.0001 ETH` |
| Min Price     | `0.04 ETH`   |
| Blocks to Min | `400`        |
| Avg. Time     | `1.47 hours` |

| Level 4       |              |
|---------------|--------------|
| Price         | `0.16 ETH`   |
| Drop p/Block  | `0.0002 ETH` |
| Min Price     | `0.08 ETH`   |
| Blocks to Min | `400`        |
| Avg. Time     | `1.47 hours` |

| Level 5       |              |
|---------------|--------------|
| Price         | `0.32 ETH`   |
| Drop p/Block  | `0.0002 ETH` |
| Min Price     | `0.16 ETH`   |
| Blocks to Min | `800`        |
| Avg. Time     | `2.94 hours` |

| Level 6       |              |
|---------------|--------------|
| Price         | `0.64 ETH`   |
| Drop p/Block  | `0.0004 ETH` |
| Min Price     | `0.32 ETH`   |
| Blocks to Min | `800`        |
| Avg. Time     | `2.94 hours` |

| Level 7       |              |
|---------------|--------------|
| Price         | `1.00 ETH`   |
| Drop p/Block  | `0.0004 ETH` |
| Min Price     | `0.5 ETH`    |
| Blocks to Min | `1250`       |
| Avg. Time     | `4.6 hours`  |



# Polygon Pillage

| Level 1       |               |
|---------------|---------------|
| Price         | `0.02`        |
| Min Price     | `0.01`        |
| Drop p/Block  | `0.00001`     |
| Blocks to Min | `1000`        |
| Avg. Time     | `33.33 min`   |

| Level 2       |               |
|---------------|---------------|
| Price         | `0.04`        |
| Min Price     | `0.02`        |
| Drop p/Block  | `0.00001`     |
| Blocks to Min | `2000`        |
| Avg. Time     | `1.11 hours`  |

| Level 3       |               |
|---------------|---------------|
| Price         | `0.08`        |
| Min Price     | `0.04`        |
| Drop p/Block  | `0.00001`     |
| Blocks to Min | `4000`        |
| Avg. Time     | `2.22 hours`  |

| Level 3       |               |
|---------------|---------------|
| Price         | `0.16`        |
| Min Price     | `0.08`        |
| Drop p/Block  | `0.00002`     |
| Blocks to Min | `4000`        |
| Avg. Time     | `2.22 hours`  |

| Level 5       |               |
|---------------|---------------|
| Price         | `0.32`        |
| Min Price     | `0.16`        |
| Drop p/Block  | `0.00002`     |
| Blocks to Min | `8000`        |
| Avg. Time     | `4.44 hours`  |

| Level 6       |               |
|---------------|---------------|
| Price         | `0.64`        |
| Min Price     | `0.32`        |
| Drop p/Block  | `0.00004`     |
| Blocks to Min | `8000`        |
| Avg. Time     | `4.44 hours`  |

| Level 7       |               |
|---------------|---------------|
| Price         | `1.00`        |
| Min Price     | `0.5`         |
| Drop p/Block  | `0.00005`     |
| Blocks to Min | `10,000`      |
| Avg. Time     | `5.55 hours`  |
