pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "hardhat/console.sol";

contract Nornir is ERC721, VRFConsumerBase {

	event RandomNumberCreated(bytes32 requestId, uint256 randomNumber);

	uint16 public constant MAX_VIKINGS = 9873;

	address internal vrfCoordinator;
	bytes32 internal keyHash;
	uint256 internal fee;
	uint256 internal lastBroughtBlock;

	struct Viking {
		uint256 strength; // Unattached
		uint256 speed; // Shoes
		uint256 stamina; // Top
		uint256 attack; // Weapon
		uint256 defence; // Sheild
		uint256 intelligence; // Unattached
		string name;
	}

	Viking[] public vikings;

	// Mappings
	mapping(bytes32 => string) requestToVikingName;
	mapping(bytes32 => address) requestToSender;
	mapping(bytes32 => uint256) requestToTokenId;

	constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash)
		public
		VRFConsumerBase(_VRFCoordinator, _LinkToken)
		ERC721('Viking', 'VKNG')
	{
		vrfCoordinator = _VRFCoordinator;
		keyHash = _keyHash;

		// Hardcode fee set to 0.1 LINK
		fee = 0.1 * 10**18;
	}

	function requestRandomViking(uint256 userProvidedSeed, string memory _name) public returns (bytes32) {
		// bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
		bytes32 requestId = 0x7465737400000000000000000000000000000000000000000000000000000000;

		requestToVikingName[requestId] = _name;

		requestToSender[requestId] = msg.sender;

		return requestId;
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
		// Emit an event for the random number. Just for intrigue sake
		emit RandomNumberCreated(requestId, randomNumber);

		uint256 newId = vikings.length;

		// Create random trait values from the random number
		uint256 strength = (randomNumber % 100);
		uint256 speed = ((randomNumber % 10000) / 100);
		uint256 stamina = ((randomNumber % 1000000) / 10000);
		uint256 attack = ((randomNumber % 100000000) / 1000000);
		uint256 defence = ((randomNumber % 10000000000) / 100000000);
		uint256 intelligence = ((randomNumber % 1000000000000) / 10000000000);

		// Add the new viking to the vikings collction
		vikings.push(
			Viking(
				strength,
				speed,
				stamina,
				attack,
				defence,
				intelligence,
				requestToVikingName[requestId]
			)
		);

		// Mint the Viking
		_safeMint(requestToSender[requestId], newId);
		// Update the last brought block number
		lastBroughtBlock = block.number;
	}

	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner not approved'
		);

		_setTokenURI(tokenId, _tokenURI);
	}

	function setLastBroughtBlock(uint256 _blockNumber) public {
		lastBroughtBlock = _blockNumber;
	}

	function calculatePrice() public view returns (uint256) {
		// Get the current amount of minted Vikings
		uint currentSupply = totalSupply();

		console.log(currentSupply);

		require(currentSupply < MAX_VIKINGS, "Sale ended");

		// Will store the price for the Viking to be brought
		uint256 price;
		// Will store the base amount of the price reduction per bonding curve level
		uint256 pillageStrength;
		// A figure set for block to pass before the price reduction begins
		uint16 pillageStart = 540;
		// Get the amount of blocks from the last brought Viking and this block
		uint256 blockGap = lastBroughtBlock - block.number;

		// Calculate the current price and pillageStrength from the amount of Vikings sold
		if (currentSupply >= 9500) {
			price = 1000000000000000000; // 9500 - 9873: 1.00 ETH
			pillageStrength = 4000000000000000; // 0.0004 ETH
		} else if (currentSupply >= 9000) {
			price = 640000000000000000; // 9000 - 9500: 0.64 ETH
			pillageStrength = 400000000000000; // 0.0004 ETH
		} else if (currentSupply >= 7500) {
			price = 320000000000000000; // 7500 - 9000: 0.32 ETH
			pillageStrength = 200000000000000; // 0.0002 ETH
		} else if (currentSupply >= 3500) {
			price = 160000000000000000; // 3500 - 7000: 0.16 ETH
			pillageStrength = 200000000000000; // 0.0002 ETH
		} else if (currentSupply >= 1500) {
			price = 80000000000000000; // 1500 - 3500: 0.08 ETH
			pillageStrength = 100000000000000; // 0.0001 ETH
		} else if (currentSupply >= 500) {
			price = 40000000000000000; // 500 - 1500: 0.04 ETH
			pillageStrength = 100000000000000; // 0.0001 ETH
		} else {
			price = 20000000000000000; // 0 - 500: 0.02 ETH
			pillageStrength = 100000000000000; // 0.0001 ETH
		}

		// Check to see if the pillage should start
		if (blockGap > pillageStart) {
			// Set the max pillage rate to half the price of the current curve
			uint256 maxPillage = price / 2;
			// Set the pillage force to start from the difference of the pillage start and block gap. Otherwise we'll drop price rapidly
			uint256 blockCount = blockGap - pillageStart;

			// Set the force of the pillage. Base pillage strength plus the amount of blocks pass since pillage start
			uint256 pillageForce = pillageStrength * blockCount;

			// If pillage force is above the max reduction set to max reduction
			if (pillageForce >= maxPillage) {
				price = maxPillage;
			}
			else {
				price = pillageForce;
			}
		}

		return price;
	}
}
