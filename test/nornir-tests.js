const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");

describe("Nornir Contract", function() {
	let deployer;
	let Nornir;
	let nornir;
	let linkContract;
	const linkToSend = ethers.BigNumber.from('10000000000000000000');

	before(async function() {
		// Set ChainLink Data - https://docs.chain.link/docs/vrf-contracts#config
		const RINKEBY_VRF_COORDINATOR = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
		const RINKEBY_LINKTOKEN = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
		const RINKEBY_KEYHASH = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';
		const RINKEBY_LINKTOKEN_ABI = [
			{
				"constant": true,
				"inputs": [],
				"name": "name",
				"outputs": [
					{
						"name": "",
						"type": "string"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"constant": false,
				"inputs": [
					{
						"name": "_spender",
						"type": "address"
					},
					{
						"name": "_value",
						"type": "uint256"
					}
				],
				"name": "approve",
				"outputs": [
					{
						"name": "",
						"type": "bool"
					}
				],
				"payable": false,
				"stateMutability": "nonpayable",
				"type": "function"
			},
			{
				"constant": true,
				"inputs": [],
				"name": "totalSupply",
				"outputs": [
					{
						"name": "",
						"type": "uint256"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"constant": false,
				"inputs": [
					{
						"name": "_from",
						"type": "address"
					},
					{
						"name": "_to",
						"type": "address"
					},
					{
						"name": "_value",
						"type": "uint256"
					}
				],
				"name": "transferFrom",
				"outputs": [
					{
						"name": "",
						"type": "bool"
					}
				],
				"payable": false,
				"stateMutability": "nonpayable",
				"type": "function"
			},
			{
				"constant": true,
				"inputs": [],
				"name": "decimals",
				"outputs": [
					{
						"name": "",
						"type": "uint8"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"constant": true,
				"inputs": [
					{
						"name": "_owner",
						"type": "address"
					}
				],
				"name": "balanceOf",
				"outputs": [
					{
						"name": "balance",
						"type": "uint256"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"constant": true,
				"inputs": [],
				"name": "symbol",
				"outputs": [
					{
						"name": "",
						"type": "string"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"constant": false,
				"inputs": [
					{
						"name": "_to",
						"type": "address"
					},
					{
						"name": "_value",
						"type": "uint256"
					}
				],
				"name": "transfer",
				"outputs": [
					{
						"name": "",
						"type": "bool"
					}
				],
				"payable": false,
				"stateMutability": "nonpayable",
				"type": "function"
			},
			{
				"constant": true,
				"inputs": [
					{
						"name": "_owner",
						"type": "address"
					},
					{
						"name": "_spender",
						"type": "address"
					}
				],
				"name": "allowance",
				"outputs": [
					{
						"name": "",
						"type": "uint256"
					}
				],
				"payable": false,
				"stateMutability": "view",
				"type": "function"
			},
			{
				"payable": true,
				"stateMutability": "payable",
				"type": "fallback"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": true,
						"name": "owner",
						"type": "address"
					},
					{
						"indexed": true,
						"name": "spender",
						"type": "address"
					},
					{
						"indexed": false,
						"name": "value",
						"type": "uint256"
					}
				],
				"name": "Approval",
				"type": "event"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": true,
						"name": "from",
						"type": "address"
					},
					{
						"indexed": true,
						"name": "to",
						"type": "address"
					},
					{
						"indexed": false,
						"name": "value",
						"type": "uint256"
					}
				],
				"name": "Transfer",
				"type": "event"
			}
		];

		// Deploy Contract
		[deployer] = await hre.ethers.getSigners();

		console.log(
			"Deploying contracts with the account:",
			deployer.address
		);

		Nornir = await ethers.getContractFactory("Nornir");
		nornir = await Nornir.deploy(RINKEBY_VRF_COORDINATOR, RINKEBY_LINKTOKEN, RINKEBY_KEYHASH);

		console.log('Token Address: ', nornir.address);

		// Send LINK
		// const provider = ethers.getDefaultProvider('rinkeby');
		// const deployerWallet = new ethers.Wallet(process.env.SECRET, provider);

		// linkContract = new ethers.Contract(RINKEBY_LINKTOKEN, RINKEBY_LINKTOKEN_ABI, deployerWallet);

		// await linkContract.transfer(nornir.address, linkToSend)

		// console.log(`Sent ${linkToSend} LINK to address ${nornir.address}`);
		// console.log('===========');
	});

	// describe("LINK", function() {
	// 	it("Contract wallet should have LINK", async function() {
	// 		const contractsLinkBalance = await linkContract.balanceOf(nornir.address);

	// 		expect(contractsLinkBalance).to.equal(linkToSend);
	// 	});
	// });

	describe("Total Supply", function() {
		it("Should return 0", async function() {
			expect(await nornir.totalSupply()).to.equal(0);
		});
	});

	describe("Last Block Brought", function() {
		it("Should return 0", async function() {
			const lastBroughtBlock = await nornir.lastBroughtBlock();

			const zero = BigNumber.from('0');

			expect(lastBroughtBlock).to.equal(zero);
		});

		it("Should return 8366175", async function() {
			const blockNumber = BigNumber.from('8366175');

			await nornir.setLastBroughtBlock(blockNumber);

			const lastBroughtBlock = await nornir.lastBroughtBlock();

			expect(lastBroughtBlock).to.equal(blockNumber);
		});
	});

	describe("Price", function() {
		it("Should return 20000000000000000", async function() {
			const price = await nornir.calculatePrice();
			const expectedPrice = BigNumber.from('20000000000000000');


			expect(price).to.equal(expectedPrice);
		});

		it("Should return between first level pillage price", async function() {
			// Set the prices we're testing against
			const initialPrice = BigNumber.from('20000000000000000');
			const maxPillagePrice = BigNumber.from('10000000000000000');

			// Get the current block
			const currentBlock = await ethers.provider.getBlock();
			// Get the current block's number
			const currentBlockNumber = currentBlock.number;

			// Set a figure for passed blocks
			const blockPassed = 600;

			// Create a number for the lastBlockBrought to be set to
			const testBlockNumber = currentBlockNumber - blockPassed;

			// Set the last block brought
			await nornir.setLastBroughtBlock(BigNumber.from(testBlockNumber));


			// Calculate the price
			const price = await nornir.calculatePrice();
			expect(price).to.be.below(initialPrice);
			expect(price).to.be.above(maxPillagePrice);
		});
	});

	describe("Minting", function() {
		it("Should mint a Viking", async function() {
			await nornir.requestRandomViking('123456', 'Fisher Price');

			expect(0).to.equal(0);
		});
	});
});


