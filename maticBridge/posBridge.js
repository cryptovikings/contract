const MaticPOSClient = require('@maticnetwork/maticjs').MaticPOSClient;
const Network = require('@maticnetwork/meta/network');
const HDWalletProvider = require('@truffle/hdwallet-provider');

require('dotenv').config();

function getAccount() {
	if (!process.env.PRIVATE_KEY || !process.env.FROM) {
		throw new Error('Please set the PRIVATE_KEY/FROM env vars')
	}
	return { privateKey: process.env.PRIVATE_KEY, from: process.env.FROM }
}

async function main(_network = 'testnet', _version = 'mumbai') {
	const network = new Network(_network, _version);

	const { from } = getAccount();

	const maticPOSClient = new MaticPOSClient({
		network: _network,
		version: _version,
		parentProvider: new HDWalletProvider(process.env.PRIVATE_KEY, `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`),
		maticProvider: network.Matic.RPC,
	});

	await maticPOSClient.depositEtherForUser(from, '10000000000000000000', {
		from,
		gasPrice: "10000000000",
	});
}

main()
	.then(_ => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});


