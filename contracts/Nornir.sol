// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "interfaces/IWeth.sol";

contract Nornir is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBase {

	// Events
	event VikingMinted(uint256 id);

	// Constants
	uint16 public constant MAX_VIKINGS = 9873;
	uint16 public constant MAX_BULK = 50;
	address public constant TREASURY = 0xB2b8AA72D9CF3517f7644245Cf7bdc301E9F1c56;

	// Interfaces
	IWeth WETHContract;

	// Variables
	// A figure set for block to pass before the price reduction begins
	// Up'd for the sake of Polygon. Will calculate propely soon
	uint16 internal pillageStart = 3000;

	uint256 public lastBroughtBlock = 12796958; // Return to internal for deployment
	uint256 internal fee;
	bytes32 internal keyHash;
	address internal vrfCoordinator;

	// Structs
	struct Viking {
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
	Viking[] public vikings;

	// Mappings
	mapping(bytes32 => address) requestToSender;

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

	function balanceWETH() public view returns (uint256) {
		return WETHContract.balanceOf(msg.sender);
	}

	function mintViking(uint256 vikingsToMint) public payable {
		uint256 mintPrice;
		require(totalSupply() < MAX_VIKINGS, 'Sale ended');
		require(vikingsToMint > 0 && vikingsToMint <= MAX_BULK, 'You can only mint between 1 to 50 Vikings per TX');
		require((totalSupply() + vikingsToMint) <= MAX_VIKINGS, 'Over MAX_VIKINGS limit');

		if (vikingsToMint > 1) {
			mintPrice = calculateBulkPrice(vikingsToMint);
		}
		else {
			mintPrice = calculatePrice();
		}

		require(WETHContract.transferFrom(msg.sender, address(this), mintPrice) == true, "Not enough WETH");

		WETHContract.transfer(address(TREASURY), mintPrice);

		for (uint i = 0; i < vikingsToMint; i++) {
			bytes32 requestId = requestRandomness(keyHash, fee, block.timestamp);
			requestToSender[requestId] = msg.sender;
		}
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
		uint256 newId = vikings.length;

		// Set Viking stats
		vikings.push(
			Viking(
				// Weapon & Attack
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
			)
		);

		// Mint the Viking
		_safeMint(requestToSender[requestId], newId);

		// Update the last brought block number
		lastBroughtBlock = block.number;

		emit VikingMinted(newId);
	}

	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner not approved'
		);

		_setTokenURI(tokenId, _tokenURI);
	}

	function calculatePrice() public view returns (uint256) {
		// Get the current amount of minted Vikings
		uint currentSupply = totalSupply();

		require(currentSupply < MAX_VIKINGS, "Sale ended");

		// Will store the price for the Viking to be brought
		uint256 price;
		// Will store the base amount of the price reduction per bonding curve level
		uint256 pillageStrength;
		// Get the amount of blocks from the last brought Viking and this block
		uint256 blockGap = block.number - lastBroughtBlock;

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
				price-= pillageForce;
			}
		}

		return price;
	}

	function calculateBulkPrice(uint256 qty) public view returns (uint256) {
		// Get the current amount of minted Vikings
		uint currentSupply = totalSupply();

		require(currentSupply < MAX_VIKINGS, "Sale ended");

		// Will store the bulk price for the Viking to be brought
		uint256 bulkPrice;
		// Will store the current curve price for the Viking to be brought
		uint256 curvePrice;
		// Will store the pillaged price if pillage started
		uint256 pillagedPrice = 0;

		// Get the amount of blocks from the last brought Viking and this block
		uint256 blockGap = block.number - lastBroughtBlock;

		// Calculate the current price and pillageStrength from the amount of Vikings sold
		if (currentSupply >= 9500) {
			curvePrice = 1000000000000000000; // 9500 - 9873: 1.00 ETH
		} else if (currentSupply >= 9000) {
			curvePrice = 640000000000000000; // 9000 - 9500: 0.64 ETH
		} else if (currentSupply >= 7500) {
			curvePrice = 320000000000000000; // 7500 - 9000: 0.32 ETH
		} else if (currentSupply >= 3500) {
			curvePrice = 160000000000000000; // 3500 - 7000: 0.16 ETH
		} else if (currentSupply >= 1500) {
			curvePrice = 80000000000000000; // 1500 - 3500: 0.08 ETH
		} else if (currentSupply >= 500) {
			curvePrice = 40000000000000000; // 500 - 1500: 0.04 ETH
		} else {
			curvePrice = 20000000000000000; // 0 - 500: 0.02 ETH
		}

		// Check to see if the pillage started
		if (blockGap > pillageStart) {
			// Get the price of the pillaged Viking
			pillagedPrice = calculatePrice();
			bulkPrice = curvePrice * (qty - 1) + pillagedPrice;
		}
		else {
			bulkPrice = curvePrice * qty;
		}

		return bulkPrice;
	}

	// Overriding Functions
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
