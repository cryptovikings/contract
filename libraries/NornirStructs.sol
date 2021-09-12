// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NornirStructs {
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

	struct VikingConditions {
		string boots;
		string bottoms;
		string helmet;
		string shield;
		string weapon;
	}
}
