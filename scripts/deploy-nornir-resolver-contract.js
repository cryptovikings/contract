const hre = require('hardhat');

async function main() {
	const [deployer] = await hre.ethers.getSigners();

	console.log(
		"Deploying Contract with the account:",
		deployer.address
	);

	console.log("Account balance:", (await deployer.getBalance()).toString());

	const NornirResolver = await hre.ethers.getContractFactory('NornirResolver');

	const nornirResolver = await NornirResolver.deploy();

	console.log("NornirResolver Address:", nornirResolver.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

exports.deployNornirResolver = main;
