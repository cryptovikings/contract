// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Structs required by both Nornir and NornirResolver implemented in a library for sharing
 */
library NornirStructs {

	/** VikingStats - a store for the VRF-derived numerical representation of a Viking */
    struct VikingStats {
		string name;
		uint256 boots;
		uint256 bottoms;
		uint256 helmet;
		uint256 shield;
		uint256 weapon;
		uint256 attack;
		uint256 defence;
		uint256 intelligence;
		uint256 speed;
		uint256 stamina;
		uint256 appearance;
	}

	/** VikingComponents - a store for the VikingStats-derived resolved Component asset names for a Viking */
	struct VikingComponents {
		string beard;
		string body;
		string face;
		string top;
		string boots;
		string bottoms;
		string helmet;
		string shield;
		string weapon;
	}

	/** VikingConditions - a store for the VikingStats-derived resolved Component Condition names for a Viking's Clothes + Items */
	struct VikingConditions {
		string boots;
		string bottoms;
		string helmet;
		string shield;
		string weapon;
	}
}
