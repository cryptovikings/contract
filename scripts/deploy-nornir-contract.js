// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// const { hre, ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
	const chain = 'mumbai';

	// Set ChainLink Data - https://docs.chain.link/docs/vrf-contracts#config
	const ChainLinkData = {
		rinkeby: {
			vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
			linkToken: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
			keyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
		},
		mumbai: {
			vrfCoordinator: '0x8C7382F9D8f56b33781fE506E897a4F1e2d17255',
			linkToken: '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
			keyHash: '0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4',
		},
		polygon: {
			vrfCoordinator: '0x3d2341ADb2D31f1c5530cDC622016af293177AE0',
			linkToken: '0xb0897686c545045aFc77CF20eC7A532E3120E0F1',
			keyHash: '0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da',
		},
	};

	const [deployer] = await hre.ethers.getSigners();

	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	console.log("Account balance:", (await deployer.getBalance()).toString());

	const Nornir = await hre.ethers.getContractFactory('Nornir');

	const nornir = await Nornir.deploy(
		ChainLinkData[chain].vrfCoordinator,
		ChainLinkData[chain].linkToken,
		ChainLinkData[chain].keyHash
	);

	console.log('Token Address: ', nornir.address);
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});

exports.deployNornir = main;
