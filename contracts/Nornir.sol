// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '../interfaces/IWeth.sol';
import '../interfaces/INornirResolver.sol';
import '../libraries/NornirStructs.sol';

/**
 * Main Nornir Contract serving the CryptoVikings collection
 *
 * Implements minting functionality, involving a multi-part procedure of Viking representation breakdown + storage based on a VRF-provided number
 */
contract Nornir is
	ERC721,
	ERC721Enumerable,
	ERC721URIStorage,
	Ownable,
	VRFConsumerBase
{
	using Strings for uint256;

	/** Events - all of these are for facilitating the generation/resolution procedure which occurs on mint, as well as front end user feedback for the same */
	event VikingsMinted(uint256[]);
	event VikingReady(uint256 vikingId);
	event VikingGenerated(uint256 vikingId);
	event VikingResolved(uint256 vikingId, NornirStructs.VikingStats stats, NornirStructs.VikingComponents components, NornirStructs.VikingConditions conditions);
	event VikingComplete(uint256 vikingId);
	event NameChange(uint256 id, string name);

	uint16 public constant MAX_VIKINGS = 9873;
	uint16 public constant MAX_BULK = 50;
	uint16 public constant MAX_OWNER_MINTS = 40;

	// TODO polygon addresses
	// address public constant TREASURY = 0x10073Fb6D644113469bD8e30404BCaD6715388ff;
	// address public constant WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

	// TODO mumbai addresses
	address public constant TREASURY = 0xCD6a2Db199c378B07C889D44B61Cb5867Ff5Ae41;
	address public constant WETH_ADDRESS = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

	/* Contracts to be instantiated for internal use */
	IWeth public wETHContract;
	INornirResolver public nornirResolverContract;

	// TODO polygon launch block
	// uint256 public launchBlock = 19498000;

	// TODO mumbai launch block
	uint256 public launchBlock = 18879857;

	// TODO live baseURI
	// string public baseURI = 'https://api.cryptovikings.io/viking/';

	// TODO test baseURI
	string public baseURI = 'http://localhost:8080/viking/';

	bool public mintingPaused = false;
	bool public presaleActive = false;
	uint256 public generatedVikingCount = 0;
	uint256 public resolvedVikingCount = 0;
	uint256 public ownerMintedCount = 0;

	/* VRF info */
	uint256 internal fee;
	bytes32 internal keyHash;
	address internal vrfCoordinator;

	/* Mapping of tokenId => VikingStats for on-chain storage of the VRF-derived numerical Viking representation */
	mapping(uint256 => NornirStructs.VikingStats) public vikingStats;
	/* Mapping of tokenId => VikingComponents for on-chain storage of the VikingStats-derived Viking Component Names */
	mapping(uint256 => NornirStructs.VikingComponents) public vikingComponents;
	/* Mapping of tokenId => VikingConditions for on-chain storage of the VikingStats-derived Viking Item Condition Names */
	mapping(uint256 => NornirStructs.VikingConditions) public vikingConditions;
	/* Mapping of tokenId => VRF-provided randomNumber for facilitating a breakup of the generation procedure */
	mapping(uint256 => uint256) public vikingIdToRandomNumber;
	/* Mapping of VRF requestId => tokenId for facilitating a breakup of the generation procedure */
	mapping(bytes32 => uint256) internal requestIdToVikingId;
	/* Mapping of name => boolean for facilitating unique-name validation */
	mapping(bytes32 => bool) internal vikingNames;
	/** Mapping of address => boolean for whitelisting wallets for presale */
	mapping(address => bool) internal presaleWhitelist;

	/**
	 * Constructor - set up our external contracts and configure ourselves for VRF usage
	 */
	constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash) VRFConsumerBase(_VRFCoordinator, _LinkToken) ERC721('Viking', 'VKNG') {
		wETHContract = IWeth(WETH_ADDRESS);

		vrfCoordinator = _VRFCoordinator;
		keyHash = _keyHash;

		fee = 0.1 * 10**15;
	}

	/**
	 * Regular mint method for external users
	 *
	 * @param count the number of Vikings to mint
	 */
	function mintViking(uint256 count) public {
		doMint(count, false);
	}

	/**
	 * Protected mint method for Contract owner
	 *
	 * @param count the number of Vikings to mint
	 */
	function ownerMintViking(uint256 count) public onlyOwner {
		doMint(count, true);
	}

	/**
	 * Retrieve all Viking information for a given Token ID at once
	 */
	function getVikingData(uint256 vikingId) public view returns (NornirStructs.VikingStats memory, NornirStructs.VikingComponents memory, NornirStructs.VikingConditions memory) {
		return (vikingStats[vikingId], vikingComponents[vikingId], vikingConditions[vikingId]);
	}

	/**
	 * Calculate the price of minting a given number of Vikings
	 *
	 * Implements the per-NFT bulk-buy discount
	 *
	 * @param qty the number of Vikings to get the price for
	 */
	function calculatePrice(uint256 qty) public view returns (uint256) {
		require(qty > 0 && qty <= MAX_BULK, 'Can only price 1-50 Vikings');

		if (presaleActive && totalSupply() < 500) {
			return 50000000000000000 * qty; // 0.05 WETH each
		}

		if (qty >= 25) {
			return 65000000000000000 * qty; // 0.065 WETH each
		}

		if (qty >= 10) {
			return 75000000000000000 * qty; // 0.075 WETH each
		}

		return 85000000000000000 * qty; // 0.085 WETH each
	}

	/**
	 * Validate a given Viking Name
	 *
	 * Names must be:
	 *   - max of 25 characters
	 *   - alhpanumeric
	 *   - no leading or trailing spaces
	 *   - no internal contiguous spaces
	 */
	function validateName(string memory str) public pure returns (bool) {
		bytes memory b = bytes(str);
		if (b.length < 1) return false;
		if (b.length > 25) return false; // Cannot be longer than 25 characters
		if (b[0] == 0x20) return false; // Cannot have leading space
		if (b[b.length - 1] == 0x20) return false; // Cannot have trailing space

		bytes1 lastChar = b[0];

		for (uint256 i; i < b.length; i++) {
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if (
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			) return false;

			lastChar = char;
		}

		return true;
	}

	/**
	 * Viking name change method - only the current owner can change the name and the name must be valid
	 */
	function changeName(uint256 vikingId, string memory newName) public {
		require(msg.sender == ownerOf(vikingId), 'Sender does not own Viking');
		require(validateName(newName) == true, 'Name is invalid');
		require(!vikingNames[keccak256(abi.encodePacked(newName))], 'Name is not unique');

		delete vikingNames[keccak256(abi.encodePacked(vikingStats[vikingId].name))];

		vikingStats[vikingId].name = newName;
		vikingNames[keccak256(abi.encodePacked(newName))] = true;

		emit NameChange(vikingId, newName);
	}

	/**
	 * Check if minting is live
	 */
	function isLaunched() public view returns (bool) {
		return block.number >= launchBlock;
	}

	/**
	 * Protected method for toggling mintingPaused
	 */
	function togglePaused() public onlyOwner {
		mintingPaused = !mintingPaused;
	}

	/**
	 * Protected method for toggling the presale
	 */
	function togglePresale() public onlyOwner {
		presaleActive = !presaleActive;
	}

	/**
	 * Protected method for changing the baseURI, facilitating future migrations of the CryptoVikings metadata
	 */
	function changeBaseURI(string memory newURI) public onlyOwner {
		baseURI = newURI;
	}

	/**
	 * Protected method for whitelisting a wallet address
	 */
	function whitelist(address wallet) public onlyOwner {
		presaleWhitelist[wallet] = true;
	}

	/**
	 * Protected method for changing the launch block, facilitating tweaks towards an intended launch time
	 *
	 * Block may not be changed if launch has already passed
	 */
	function changeLaunchBlock(uint256 newBlock) public onlyOwner {
		require(!isLaunched(), 'CryptoVikings already launched');

		launchBlock = newBlock;
	}

	/**
	 * Protected method for changing the NornirResolver Contract, facilitating improvements/changes/fixes to resolution
     *
	 * Resolver is not set in constructor and is required for validateMint(), so this must be called at least once
	 */
	function changeNornirResolver(address _nornirResolver) public onlyOwner {
	    nornirResolverContract = INornirResolver(_nornirResolver);
	}

	/**
	 * Protected withdraw method
	 */
	function withdraw() public payable onlyOwner {
		uint256 balance = address(this).balance;
		payable(TREASURY).transfer(balance);
	}

	/**
	 * Protected ERC-20 withdraw method
	 */
	function withdrawErc20(IERC20 token) public onlyOwner {
		token.transfer(TREASURY, token.balanceOf(address(this)));
	}

	/**
	 * Abstracted mint require block
	 *
	 * @param count the number of Vikings to mint
	 * @param isOwner whether or not we're validating an owner mint
	 */
	function validateMint(uint256 count, bool isOwner) internal view {
		// generic requires for both presale and full sale
		require(presaleActive || block.number >= launchBlock, 'Vikings not yet released');
		require(!mintingPaused, 'Minting is paused');
		require(address(nornirResolverContract) != address(0), 'NornirResolver not set');
		require(totalSupply() < MAX_VIKINGS, 'Vikings sold out');

		if (presaleActive) {
			// specific requires for presale
			require(totalSupply() < 500, 'Presale sold out');
			require(presaleWhitelist[msg.sender], 'Wallet not whitelisted');
			require(balanceOf(msg.sender) < 5, 'Wallet already has 5 Vikings');
			require(count > 0 && count <= 5, 'Can only mint 1-5 Vikings');
			require(balanceOf(msg.sender) + count <= 5, 'Mint exceeds 5 Vikings');
		}
		else {
			// specific requires for full sale
			require(count > 0 && count <= MAX_BULK, 'Can only mint 1-50 Vikings');
			require(totalSupply() + count <= MAX_VIKINGS, 'Mint exceeds MAX_VIKINGS limit');
		}

		if (isOwner) {
			// specific requires for owner mints
			require(ownerMintedCount < MAX_OWNER_MINTS, 'Max owner mints reached');
			require(ownerMintedCount + count <= MAX_OWNER_MINTS, 'Mint exceeds MAX_OWNER_MINTS');
		}
	}

	/**
	 * Abstracted mint procedure
	 *
	 * Actions payment, mints the NFT(s), and requests randomness from VRF for each minted token
	 *
	 * @param count the number of Vikings to mint
	 * @param isOwner whether or not we're actioning an owner mint
	 */
	function doMint(uint256 count, bool isOwner) internal {
		validateMint(count, isOwner);

		uint256 price = calculatePrice(count);

		// if not owner, action payment
		if (!isOwner) {
			require(wETHContract.allowance(msg.sender, address(this)) >= price, 'Not enough WETH approved');
			require(wETHContract.transferFrom(msg.sender, address(this), price) == true, 'Not enough WETH for TX');
		}

		// iterate over count, minting tokens and requesting randomness in sequence
		uint256[] memory mintedIds = new uint256[](count);

		for (uint256 i = 0; i < count; i++) {
			uint256 id = totalSupply();

			_safeMint(msg.sender, id);

			_setTokenURI(id, id.toString());

			requestIdToVikingId[requestRandomness(keyHash, fee)] = id;

			mintedIds[i] = id;

			if (isOwner) {
				ownerMintedCount++;
			}
		}

		if (!isOwner) {
			wETHContract.transfer(address(TREASURY), price);
		}

		emit VikingsMinted(mintedIds);
	}

	/**
	 * VRF fulfillRandomness() override
	 *
	 * Associates the received random number with a token ID using the requestId as a connector before prompting the API to begin generation via VikingReady
	 *
	 * @param requestId the VRF request ID
	 * @param randomNumber the supplied random number
	 */
	function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
		uint256 vikingId = requestIdToVikingId[requestId];

		vikingIdToRandomNumber[vikingId] = randomNumber;

		emit VikingReady(vikingId);
	}

	/**
	 * Protected Viking generation - step 1 of the generation/resolution procedure
     *
	 * For the given token ID, retrieve the random number and break it down into a VikingStats
	 *
	 * @param vikingId the token ID to generate a VikingStats for
	 */
	function generateViking(uint256 vikingId) public onlyOwner {
		require(vikingIdToRandomNumber[vikingId] != 0, 'Viking not minted');
		require(vikingStats[vikingId].appearance == 0, 'Viking already generated');

		uint256 randomNumber = vikingIdToRandomNumber[vikingId];

		vikingStats[vikingId] = NornirStructs.VikingStats(
			string(abi.encodePacked('Viking #', vikingId.toString())),
			(randomNumber % 100),
			(randomNumber % 10000) / 100,
			(randomNumber % 10**6) / 10**4,
			(randomNumber % 10**8) / 10**6,
			(randomNumber % 10**10) / 10**8,
			(randomNumber % 10**12) / 10**10,
			(randomNumber % 10**14) / 10**12,
			(randomNumber % 10**16) / 10**14,
			(randomNumber % 10**18) / 10**16,
			(randomNumber % 10**20) / 10**18,
			(randomNumber % 10**28) / 10**20
		);

		// in normal operation, this should match totalSupply()
		generatedVikingCount++;

		vikingNames[
			keccak256(abi.encodePacked('Viking #', vikingId.toString()))
		] = true;

		emit VikingGenerated(vikingId);
	}

	/**
	 * Protected Viking component/condition resolution procedure, calling out to the NornirResolver Contract - step 2 of the generation/resolution procedure
	 *
	 * For the given token ID, resolve all component names and item conditions using the existing associated VikingStats
	 *
	 * @param vikingId the token ID to resolve VikingComponents and VikingConditions for
	 */
	function resolveViking(uint256 vikingId) public onlyOwner {
		require(vikingStats[vikingId].appearance != 0, 'Viking not generated');
		require(bytes(vikingComponents[vikingId].weapon).length == 0, 'components already resolved');
		require(bytes(vikingConditions[vikingId].weapon).length == 0, 'Conditions already resolved');

		vikingConditions[vikingId] = nornirResolverContract.resolveConditions(vikingStats[vikingId]);
		vikingComponents[vikingId] = nornirResolverContract.resolveComponents(vikingStats[vikingId], vikingConditions[vikingId]);

		// in normal operation, this should match generatedVikingCount
		resolvedVikingCount++;

		emit VikingResolved(vikingId, vikingStats[vikingId], vikingComponents[vikingId], vikingConditions[vikingId]);
	}

	/**
	 * Protected Viking completion procedure = step 3 of the generation/resolution procedure
	 *
	 * Just emits an event that the front end can pick up to complete the walkthrough UX and enable the reveal
	 *
	 * @param vikingId the token ID to emit a completion event for
	 */
	function completeViking(uint256 vikingId) public onlyOwner {
		emit VikingComplete(vikingId);
	}

	/** ERC-721 overrides */
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
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

	/**
	 * Override isApprovedForAll as a convenience for auto-allowing OpenSea's Polygon proxy Contract
	 */
	function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
	}
}
