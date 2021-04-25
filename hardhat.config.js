require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
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
				url: process.env.MUMBAI_URL,
				blockNumber: 8366188
			},
			accounts: [{
				privateKey: process.env.SECRET,
				balance: '100000000000000000000'
			}]
		},
		mumbai: {
			url: process.env.MUMBAI_URL,
			accounts: [process.env.SECRET],
			gasPrice: 1000000000
		}
	},
	solidity: {
		version: "0.8.4",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
};
