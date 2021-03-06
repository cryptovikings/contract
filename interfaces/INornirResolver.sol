// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../libraries/NornirStructs.sol';

/**
 * Nornir Resolver Interface, describing the public API of the NornirResolver Contract
 */
interface INornirResolver {
    function resolveConditions(NornirStructs.VikingStats memory vikingStats) external pure returns (NornirStructs.VikingConditions memory);
    function resolveComponents(NornirStructs.VikingStats memory vikingStats, NornirStructs.VikingConditions memory vikingConditions) external pure returns (NornirStructs.VikingComponents memory);
}
