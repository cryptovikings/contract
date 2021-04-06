// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// const { hre, ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
	// Set ChainLink Data - https://docs.chain.link/docs/vrf-contracts#config
	const RINKEBY_VRF_COORDINATOR = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
	const RINKEBY_LINKTOKEN = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
	const RINKEBY_KEYHASH = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';

	const [deployer] = await hre.ethers.getSigners();

	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	console.log("Account balance:", (await deployer.getBalance()).toString());

	const Nornir = await hre.ethers.getContractFactory('Nornir');
	const nornir = await Nornir.deploy(RINKEBY_VRF_COORDINATOR, RINKEBY_LINKTOKEN, RINKEBY_KEYHASH);

	console.log('Token Address: ', nornir.address);
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});

exports.deployNornir = main;
