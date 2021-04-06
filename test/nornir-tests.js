const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = require("chai");

describe("Nornir Contract", function() {
	let Nornir;
	let nornir;

	before(async function () {
		// Set ChainLink Data - https://docs.chain.link/docs/vrf-contracts#config
		const RINKEBY_VRF_COORDINATOR = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
		const RINKEBY_LINKTOKEN = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
		const RINKEBY_KEYHASH = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';

		Nornir = await ethers.getContractFactory("Nornir");
		nornir = await Nornir.deploy(RINKEBY_VRF_COORDINATOR, RINKEBY_LINKTOKEN, RINKEBY_KEYHASH);
	});

	describe("Total Supply", function() {
		it("Should return 0", async function () {
			expect(await nornir.totalSupply()).to.equal(0);
		});
	});

	describe("Last Block Brought", function() {
		it("Should return 0", async function () {
			const lastBroughtBlock = await nornir.lastBroughtBlock();

			const zero = BigNumber.from('0');

			expect(lastBroughtBlock).to.equal(zero);
		});

		it("Should return 8366175", async function () {
			const blockNumber = BigNumber.from('8366175');

			await nornir.setLastBroughtBlock(blockNumber);

			const lastBroughtBlock = await nornir.lastBroughtBlock();

			expect(lastBroughtBlock).to.equal(blockNumber);
		});
	});

	describe("Price", function() {
		it("Should return 20000000000000000", async function () {
			const price = await nornir.calculatePrice();
			const expectedPrice = BigNumber.from('20000000000000000');


			expect(price).to.equal(expectedPrice);
		});

		it("Should return between first level pillage price", async function () {
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
});


