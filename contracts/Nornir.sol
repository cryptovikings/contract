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
	event VikingsMinted(uint256[]);
	event VikingReady(uint256 vikingId);
	event VikingGenerated(uint256 id, Viking vikingData);
	event NameChange(string name, uint256 id);

	// Constants
	uint16 public constant MAX_VIKINGS = 9873;
	uint16 public constant MAX_BULK = 50;
	address public constant TREASURY = 0xB2b8AA72D9CF3517f7644245Cf7bdc301E9F1c56;
	string public constant BASE_URI = 'http://localhost:8080/api/viking/';
	uint256 public constant LAUNCH_BLOCK = 18053667;

	// Interfaces
	IWeth public WETHContract;

	// Variables
	uint256 public vikingCount = 0;
	uint256 internal fee;
	bytes32 internal keyHash;
	address internal vrfCoordinator;

	// Structs
	struct Viking {
		string name; // Name of the Viking - Default of 'Viking #ID'
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
	mapping(bytes32 => bool) internal vikingNames;

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
		// Make sure the launch block has passed
		require(block.timestamp >= LAUNCH_BLOCK, 'Vikings not yet released');
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

		// An array of Viking IDs to pass to the VikingsMinted event
		uint256[] memory mintedIds = new uint256[](vikingsToMint);

		for (uint i = 0; i < vikingsToMint; i++) {
			uint256 id = totalSupply();

			// Mint the Viking
			_safeMint(msg.sender, id);

			// Set the Viking/Token URI
			_setTokenURI(id, id.toString());

			// Request Randomness
			requestIdToVikingId[
				requestRandomness(keyHash, fee, uint256(keccak256(abi.encode(vikingsToMint, block.timestamp))))
			] = id;

			mintedIds[i] = id;
		}

		emit VikingsMinted(mintedIds);

		WETHContract.transfer(address(TREASURY), mintPrice); // TODO: Add withdraw
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
		uint256 vikingId = requestIdToVikingId[requestId];

		vikingIdToRandomNumber[vikingId] = randomNumber;

		emit VikingReady(vikingId);
	}

	function generateViking(uint256 vikingId) public onlyOwner {
		uint256 randomNumber = vikingIdToRandomNumber[vikingId];

		// Set Viking stats
		vikings[vikingId] = Viking(
			// Weapon & Attack
			string(abi.encodePacked('Viking #', vikingId.toString())),
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

		vikingNames[keccak256(abi.encodePacked('Viking #', vikingId.toString()))] = true;

		emit VikingGenerated(vikingId, vikings[vikingId]);
	}

	function calculatePrice(uint256 qty) public pure returns (uint256) {
		uint256 price;

		if (qty >= 25) {
			price = 73000000000000000; // 0.073 ETH
		}
		else if (qty >= 10) {
			price = 87300000000000000; // 0.0873 ETH
		}
		else {
			price = 98730000000000000; // 0.09873 ETH
		}

		return price * qty;
	}

	// TODO: Maybe add a name limiting function
	function updateName(string memory newName, uint256 vikingId) public {
		// Check to see the sender owns the Viking
		require(msg.sender == ownerOf(vikingId), 'Only owner can change Viking name');
		// Check the vikingNames mapping for the new name
		require(!vikingNames[keccak256(abi.encodePacked(newName))], 'Name in use');

		// Delete the old Viking name mapping, making the name available
		delete vikingNames[keccak256(abi.encodePacked(vikings[vikingId].name))];

		// Update the Vikings name
		vikings[vikingId].name = newName;
		// Update the mapping to make the new name unavailable
		vikingNames[keccak256(abi.encodePacked(newName))] = true;

		emit NameChange(newName, vikingId);
	}

	// Withdraw Methods
	function withdraw() public payable onlyOwner {
		uint balance = address(this).balance;
		payable(TREASURY).transfer(balance);
	}

	function withdrawErc20(IERC20 token) public onlyOwner {
		token.transfer(TREASURY, token.balanceOf(address(this)));
	}

	// Overriding Functions
	function _baseURI() internal pure override returns (string memory) {
		return BASE_URI;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
