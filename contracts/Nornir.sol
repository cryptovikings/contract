// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol';
import 'interfaces/IWeth.sol';

contract Nornir is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBase {
	// Library Usage
	using Strings for uint256;

	// Events
	event VikingReady(uint256 vikingId);
	event VikingGenerated(uint256 id, Viking vikingData);

	// Constants
	uint16 public constant MAX_VIKINGS = 9873;
	uint16 public constant MAX_BULK = 50;
	address public constant TREASURY = 0xB2b8AA72D9CF3517f7644245Cf7bdc301E9F1c56;
	string public constant BASE_URI = 'http://localhost:8080/api/viking/';

	// Interfaces
	IWeth public WETHContract;

	// Variables
	uint256 public vikingCount = 0;
	// A figure set for blocks to pass before the price reduction begins
	// Polygon avg. block time = 2 second
	// 2 hours / 2 seconds = 3600
	uint16 internal pillageBuffer = 3600;

	uint256 public lastBroughtBlock = 12796958; // Return to internal for deployment
	uint256 internal fee;
	bytes32 internal keyHash;
	address internal vrfCoordinator;

	// Structs
	struct Viking {
		string name; // Name of the Viking - Default of "Viking #ID"
		uint256 weapon; // 0 - 99, indicating the weapon type
		uint256 attack; // 0 - 99, indicating attack stat + weapon condition
		uint256 shield; // 0 - 99, indicating the shieldtype
		uint256 defence; // 0 - 99, indicating defence stat + shield condition
		uint256 boots; // 0 - 99, indicating the bootstype
		uint256 speed; // 0 - 99, indicating speed stat + boots condition
		uint256 helmet; // 0 - 99, indicating the helmet type
		uint256 intelligence; // 0 - 99, indicating intelligence stat + helmet condition
		uint256 bottoms; // 0 - 99, indicating the bottoms type
		uint256 stamina; // 0 - 99, indicating stamina stat + bottoms condition
		uint256 appearance; // 8-digit number of 4 0-99 components, indicating body/top/face/beard types
	}

	// Mappings
	mapping(uint256 => Viking) public vikings;
	mapping(uint256 => uint256) public vikingIdToRandomNumber;
	mapping(bytes32 => uint256) internal requestIdToVikingId;

	constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash)
		VRFConsumerBase(_VRFCoordinator, _LinkToken)
		ERC721('Viking', 'VKNG')
	{
		// Set wETH data
		WETHContract = IWeth(address(0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa));

		// Set Chainlink data
		vrfCoordinator = _VRFCoordinator;
		keyHash = _keyHash;

		// Hardcode fee set to 0.0001 LINK
		fee = 0.1 * 10**15;
	}

	function mintViking(uint256 vikingsToMint) public {
		// Make sure sale isn't over
		require(totalSupply() < MAX_VIKINGS, 'Sale ended');
		// Make sure user is trying to mint within minting limits
		require(vikingsToMint > 0 && vikingsToMint <= MAX_BULK, 'Can only mint 1-50 Vikings');
		// Make sure users request to mint isn't over the maxiumum amout of Vikings
		require((totalSupply() + vikingsToMint) <= MAX_VIKINGS, 'Over MAX_VIKINGS limit');

		// Store how much it'll cost to mint
		uint256 mintPrice = calculatePrice(vikingsToMint);

		// Make sure enough WETH has been approved to send
		require(WETHContract.allowance(msg.sender, address(this)) >= mintPrice, 'Not enough WETH approved');

		// Transfer mintPrice from users wallet to contract
		require(WETHContract.transferFrom(msg.sender, address(this), mintPrice) == true, 'Not enough WETH for TX');

		// Update the last brought block number
		lastBroughtBlock = block.number;

		for (uint i = 0; i < vikingsToMint; i++) {
			uint256 id = totalSupply();

			// Mint the Viking
			_safeMint(msg.sender, id);

			// Set the Viking/Token URI
			_setTokenURI(id, id.toString());

			// Request Randomness
			requestIdToVikingId[
				requestRandomness(keyHash, fee, block.timestamp)
			] = id;
		}

		WETHContract.transfer(address(TREASURY), mintPrice); // TODO: Add withdraw
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
		uint256 vikingId = requestIdToVikingId[requestId];

		vikingIdToRandomNumber[vikingId] = randomNumber;

		emit VikingReady(vikingId);
	}

	// TODO: Make an onlyOwner function
	function generateViking(uint256 vikingId) public {
		uint256 randomNumber = vikingIdToRandomNumber[vikingId];

		// Set Viking stats
		vikings[vikingId] = Viking(
			// Weapon & Attack
			string(abi.encodePacked("Viking #", vikingId.toString())),
			(randomNumber % 100),
			(randomNumber % 10000) / 100,
			// Sheild & Defence
			(randomNumber % 10**6) / 10**4,
			(randomNumber % 10**8) / 10**6,
			// Boots & Speed
			(randomNumber % 10**10) / 10**8,
			(randomNumber % 10**12) / 10**10,
			// Helmet and Intelligence
			(randomNumber % 10**14) / 10**12,
			(randomNumber % 10**16) / 10**14,
			// Bottoms & Stamina
			(randomNumber % 10**18) / 10**16,
			(randomNumber % 10**20) / 10**18,
			// Appearance
			(randomNumber % 10**28) / 10**20
		);

		vikingCount++;

		emit VikingGenerated(vikingId, vikings[vikingId]);
	}

	function getPricing() public view returns (bool pillageStarted, uint256 curvePrice, uint256 pillagePrice) {
		// Get the current amount of minted Vikings
		uint256 currentSupply = totalSupply();
		require(currentSupply < MAX_VIKINGS, 'Sale ended');

		// Will store the base amount of the price reduction per curve level
		uint256 pillageStrength;

		// Get the amount of blocks from the last brought Viking and this block
		uint256 blockGap = block.number - lastBroughtBlock;
		// Set whether or not the pillage has started
		pillageStarted = blockGap > pillageBuffer;

		// Calculate the curve price and pillageStrength from the amount of Vikings sold
		// Pillage strength calculated with the 2 second block avg. of Polygon in mind
		if (currentSupply >= 9500) {
			curvePrice = 1000000000000000000; // 9500 - 9873: 1.00 ETH
			pillageStrength = 50000000000000; // 0.00005 ETH - Avg time: 5.55 hour
		} else if (currentSupply >= 9000) {
			curvePrice = 640000000000000000; // 9000 - 9500: 0.64 ETH
			pillageStrength = 40000000000000; // 0.00004 ETH - Avg time: 4.44 hours
		} else if (currentSupply >= 7500) {
			curvePrice = 320000000000000000; // 7500 - 9000: 0.32 ETH
			pillageStrength = 20000000000000; // 0.00002 ETH - Avg time: 4.44 hours
		} else if (currentSupply >= 3500) {
			curvePrice = 160000000000000000; // 3500 - 7000: 0.16 ETH
			pillageStrength = 20000000000000; // 0.00002 ETH - Avg time: 2.22 hours
		} else if (currentSupply >= 1500) {
			curvePrice = 80000000000000000; // 1500 - 3500: 0.08 ETH
			pillageStrength = 10000000000000; // 0.00001 ETH - Avg time: 2.22 hours
		} else if (currentSupply >= 500) {
			curvePrice = 40000000000000000; // 500 - 1500: 0.04 ETH
			pillageStrength = 10000000000000; // 0.00001 ETH - Avg time: 1.11 hours
		} else {
			curvePrice = 20000000000000000; // 0 - 500: 0.02 ETH
			pillageStrength = 10000000000000; // 0.00001 ETH - Avg time: 33.33 min
		}

		if (pillageStarted) {
			// Set the max pillage rate to half the price of the current curve
			uint256 maxPillage = curvePrice / 2;
			// Set the pillage force to start from the difference of the pillage start and block gap. Otherwise we'll drop price rapidly
			uint256 blockCount = blockGap - pillageBuffer;

			// Set the force of the pillage. Base pillage strength plus the amount of blocks pass since pillage start
			uint256 pillageForce = pillageStrength * blockCount;

			// If pillage force is above the max reduction set to max reduction
			if (pillageForce >= maxPillage) {
				pillagePrice = maxPillage;
			}
			else {
				pillagePrice = curvePrice - pillageForce;
			}
		}

		return (pillageStarted, curvePrice, pillagePrice);
	}

	function calculatePrice(uint256 qty) public view returns (uint256) {
		(bool pillageStarted, uint256 curvePrice, uint256 pillagePrice) = getPricing();

		if (pillageStarted) {
			return curvePrice * (qty - 1) + pillagePrice;
		}
		else {
			return curvePrice * qty;
		}
	}

	// Overriding Functions
	function _baseURI() internal pure override returns (string memory) {
		return BASE_URI;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721, ERC721URIStorage)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}
