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

	// describe("Mints", function() {
	// 	it("Mint a Viking", async function () {
	// 		await nornir.requestRandomViking('1234', 'Fisher Price');
	// 		const vikingCount = await nornir.totalSupply();
	// 		const expectedCount = BigNumber.from('1');

	// 		console.log(vikingCount);
	// 		// nornir.getTotalSupply();
	// 		expect(await vikingCount).to.equal(expectedCount);

	// 	});
	// });

	// describe("Price", function() {
	// 	it("Should return 20000000000000000", async function () {
	// 		const price = await nornir.calculatePrice();
	// 		const expectedPrice = BigNumber.from('20000000000000000');

	// 		console.log({price, expectedPrice});


	// 		expect(price).to.equal(expectedPrice);
	// 	});
	// });

	describe("Total Supply", function() {
		it("Should return 0", async function () {

			// console.log(nornir);
			// nornir.totalSupply();
			expect(await nornir.totalSupply()).to.equal(0);

		});
	});
});
