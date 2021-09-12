// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../libraries/NornirStructs.sol';

contract NornirResolver {

    function resolveConditions(NornirStructs.VikingStats memory vikingStats) external pure returns (NornirStructs.VikingConditions memory) {
        return NornirStructs.VikingConditions(
			resolveClothesCondition(vikingStats.speed),
			resolveClothesCondition(vikingStats.stamina),
			resolveItemCondition(vikingStats.intelligence),
			resolveItemCondition(vikingStats.defence),
			resolveItemCondition(vikingStats.attack)
		);
    }

    function resolveComponents(NornirStructs.VikingStats memory vikingStats, NornirStructs.VikingConditions memory vikingConditions) external pure returns (NornirStructs.VikingComponents memory) {
        return NornirStructs.VikingComponents(
			resolveBeard(vikingStats.appearance / 1000000),
			resolveBody((vikingStats.appearance / 10000) % 100),
			resolveFace((vikingStats.appearance / 100) % 100),
			resolveTop(vikingStats.appearance % 100),
			resolveBoots(vikingStats.boots, vikingConditions.boots),
			resolveBottoms(vikingStats.bottoms, vikingConditions.bottoms),
			resolveHelmet(vikingStats.helmet, vikingConditions.helmet),
			resolveShield(vikingStats.shield, vikingConditions.shield),
			resolveWeapon(vikingStats.weapon, vikingConditions.weapon)
		);
    }

    function resolveClothesCondition(uint256 statistic) internal pure returns (string memory) {
		// 10%
        if (statistic <= 9) {
            return 'Standard';
        }

        // 40%
        if (statistic <= 49) {
            return 'Ragged';
        }

        // 25%
        if (statistic <= 74) {
            return 'Rough';
        }

        // 15%
        if (statistic <= 89) {
            return 'Used';
        }

        // 7%
        if (statistic <= 96) {
            return 'Good';
        }

        // 3%
        return 'Perfect';
	}

	function resolveItemCondition(uint256 statistic) internal pure returns (string memory) {
		// 10%
        if (statistic <= 9) {
            return 'None';
        }

        // 40%
        if (statistic <= 49) {
            return 'Destroyed';
        }

        // 25%
        if (statistic <= 74) {
            return 'Battered';
        }

        // 15%
        if (statistic <= 89) {
            return 'War Torn';
        }

        // 7%
        if (statistic <= 96) {
            return 'Battle Ready';
        }

        // 3%
        return 'Flawless';
	}

	/* NB: Beard is unique as it's the first 2 digits of 'appearance', thus ranged 10-99 */
	function resolveBeard(uint256 selector) internal pure returns (string memory) {
		// 20%
        if (selector <= 27) {
            return 'Stubble';
        }

        // 20%
        if (selector <= 45) {
            return 'Trim';
        }

        // 20%
        if (selector <= 63) {
            return 'Bushy';
        }

        // 10%
        if (selector <= 72) {
            return 'Beaded';
        }

        // 10%
        if (selector <= 81) {
            return 'Straggly';
        }

        // 10%
        if (selector <= 90) {
            return 'Goatee';
        }

        // ~6.7%
        if (selector <= 96) {
            return 'Sophisticated';
        }

        // ~3.3%
        return 'Slick';
	}

	function resolveBody(uint256 selector) internal pure returns (string memory) {
		// 20%
        if (selector <= 19) {
            return 'Base 1';
        }

        // 20%
        if (selector <= 39) {
            return 'Base 2';
        }

        // 20%
        if (selector <= 59) {
            return 'Base 3';
        }

        // 10%
        if (selector <= 69) {
            return 'Inked';
        }

        // 10%
        if (selector <= 79) {
            return 'Tatted';
        }

        // 5%
        if (selector <= 84) {
            return 'Devil';
        }

        // 5%
        if (selector <= 89) {
            return 'Zombie (Green)';
        }

        // 4%
        if (selector <= 93) {
            return 'Pigman';
        }

        // 3%
        if (selector <= 96) {
            return 'Robot';
        }

        // 2%
        if (selector <= 98) {
            return 'Zombie (Blue)';
        }

        // 1%
        return 'Wolfman';
	}

	function resolveFace(uint256 selector) internal pure returns (string memory) {
		 // 15%
        if (selector <= 14) {
            return 'Smirk';
        }

        // 15%
        if (selector <= 29) {
            return 'Stern';
        }

        // 13%
        if (selector <= 42) {
            return 'Worried';
        }

        // 12%
        if (selector <= 54) {
            return 'Angry';
        }

        // 10%
        if (selector <= 64) {
            return 'Singer';
        }

        // 10%
        if (selector <= 74) {
            return 'Grin';
        }

        // 10%
        if (selector <= 84) {
            return 'Fangs';
        }

        // 7%
        if (selector <= 91) {
            return 'Patch';
        }

        // 5%
        if (selector <= 96) {
            return 'Cyclops';
        }

        // 3%
        return 'Cool';
	}

	function resolveTop(uint256 selector) internal pure returns (string memory) {
		/* Tattered - 30% overall */
        // 6%
        if (selector <= 5) {
            return 'Tattered (Blue)';
        }

        // 6%
        if (selector <= 11) {
            return 'Tattered (Dark Grey)';
        }

        // 6%
        if (selector <= 17) {
            return 'Tattered (Light Grey)';
        }

        // 6%
        if (selector <= 23) {
            return 'Tattered (Purple)';
        }

        // 4%
        if (selector <= 27) {
            return 'Tattered (Red)';
        }

        // 2%
        if (selector <= 29) {
            return 'Tattered (Yellow)';
        }

        /* Tank Top - 20% overall */
        // 4%
        if (selector <= 33) {
            return 'Tank Top (Blue)';
        }

        // 4%
        if (selector <= 37) {
            return 'Tank Top (Dark Grey)';
        }

        // 4%
        if (selector <= 41) {
            return 'Tank Top (Green)';
        }

        // 3%
        if (selector <= 44) {
            return 'Tank Top (Light Grey)';
        }

        // 3%
        if (selector <= 47) {
            return 'Tank Top (Pink)';
        }

        // 2%
        if (selector <= 49) {
            return 'Tank Top (Red)';
        }

        /* Vest - 20% overall */
        // 5%
        if (selector <= 54) {
            return 'Vest (Blue)';
        }

        // 5%
        if (selector <= 59) {
            return 'Vest (Green)';
        }

        // 5%
        if (selector <= 64) {
            return 'Vest (Pink)';
        }

        // 3%
        if (selector <= 67) {
            return 'Vest (White)';
        }

        // 2%
        if (selector <= 69) {
            return 'Vest (Yellow)';
        }

        /* Winter Jacket - 15% overall */
        // 3%
        if (selector <= 72) {
            return 'Winter Jacket (Blue)';
        }

        // 3%
        if (selector <= 75) {
            return 'Winter Jacket (Dark Grey)';
        }

        // 3%
        if (selector <= 78) {
            return 'Winter Jacket (Green)';
        }

        // 2%
        if (selector <= 80) {
            return 'Winter Jacket (Light Grey)';
        }

        // 2%
        if (selector <= 82) {
            return 'Winter Jacket (Pink)';
        }

        // 2%
        if (selector <= 84) {
            return 'Winter Jacket (Purple)';
        }

        /* Fitted Shirt - 10% overall */
        // 2%
        if (selector <= 86) {
            return 'Fitted Shirt (Blue)';
        }

        // 2%
        if (selector <= 88) {
            return 'Fitted Shirt (Green)';
        }

        // 2%
        if (selector <= 90) {
            return 'Fitted Shirt (Grey)';
        }

        // 2%
        if (selector <= 92) {
            return 'Fitted Shirt (Pink)';
        }

        // 1%
        if (selector <= 93) {
            return 'Fitted Shirt (Red)';
        }

        // 1%
        if (selector <= 94) {
            return 'Fitted Shirt (Yellow)';
        }

        /* Strapped - 5% */
        return 'Strapped';
	}

	function resolveBoots(uint256 selector, string memory condition) internal pure returns (string memory) {
		if (strEqual(condition, 'Standard')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Leather';
        }

        // 25%
        if (selector <= 59) {
            return 'Laced';
        }

        // 20%
        if (selector <= 79) {
            return 'Sandals';
        }

        // 12%
        if (selector <= 91) {
            return 'Tailored';
        }

        // 8%
        return 'Steel Capped';
	}

	function resolveBottoms(uint256 selector, string memory condition) internal pure returns (string memory) {
		if (strEqual(condition, 'Standard')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Shorts';
        }

        // 25%
        if (selector <= 59) {
            return 'Buckled';
        }

        // 20%
        if (selector <= 79) {
            return 'Patchwork';
        }

        // 12%
        if (selector <= 91) {
            return 'Short Shorts';
        }

        // 8%
        return 'Kingly';
	}

	function resolveHelmet(uint256 selector, string memory condition) internal pure returns (string memory) {
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Cap';
        }

        // 25%
        if (selector <= 59) {
            return 'Horned';
        }

        // 20%
        if (selector <= 79) {
            return 'Headband';
        }

        // 12%
        if (selector <= 91) {
            return 'Spiky';
        }

        // 8%
        return 'Bejeweled';
	}

	function resolveShield(uint256 selector, string memory condition) internal pure returns (string memory) {
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Wooden';
        }

        // 25%
        if (selector <= 59) {
            return 'Ornate';
        }

        // 20%
        if (selector <= 79) {
            return 'Reinforced';
        }

        // 12%
        if (selector <= 91) {
            return 'Scutum';
        }

        // 8%
        return 'Bones';
	}

	function resolveWeapon(uint256 selector, string memory condition) internal pure returns (string memory) {
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Plank';
        }

        // 25%
        if (selector <= 59) {
            return 'Axe';
        }

        // 20%
        if (selector <= 79) {
            return 'Sword';
        }

        // 15%
        if (selector <= 89) {
            return 'Trident';
        }

        // 6%
        if (selector <= 95) {
            return 'Bat';
        }

        // 4%
        return 'Hammer';
	}

	function strEqual(string memory a, string memory b) internal pure returns (bool) {
		return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
	}

}
