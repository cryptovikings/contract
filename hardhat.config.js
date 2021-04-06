require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
	const accounts = await ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "hardhat",
	networks: {
		hardhat: {
			forking: {
				url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
				blockNumber: 8366188
			},
			accounts: [{
				privateKey: process.env.SECRET,
				balance: '100000000000000000000'
			}]
		},
		ropsten: {
			url: process.env.ROPSTEN_URL,
			accounts: [process.env.SECRET]
		},
		kovan: {
			url: process.env.KOVAN_URL,
			accounts: [process.env.SECRET]
		},
		rinkeby: {
			url: process.env.RINKEBY_URL,
			accounts: [process.env.SECRET]
		}
	},
	solidity: {
		compilers: [
			{
				version: "0.8.0"
			},
			{
				version: "0.6.12"
			}
		]
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY
	}
};
