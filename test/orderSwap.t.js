const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Order Swap ", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  // Fixture for deploying the Web3CXI token contract
  async function deployWeb3TokenFixture() {
    // Get the first signer (account) as the owner
    const [owner, web3holder] = await hre.ethers.getSigners();

    // Deploy the ERC20 token contract (Web3CXI)
    const erc20Token = await hre.ethers.getContractFactory("Web3Token");
    const web3token = await erc20Token.deploy();
    const amount = ethers.parseUnits("500", 18);
    await web3token.transfer(web3holder, amount);

    // Return the deployed token contract and owner
    return { web3token, web3holder };
  }
  async function deployGuzTokenFixture() {
    // Get the first signer (account) as the owner
    const [owner, web3holder, Guzholder] = await hre.ethers.getSigners();

    // Deploy the ERC20 token contract (Web3CXI)
    const erc20Token = await hre.ethers.getContractFactory("GuzToken");
    const guztoken = await erc20Token.deploy();
    const amount = ethers.parseUnits("500", 18);
    await guztoken.transfer(Guzholder, amount);

    // Return the deployed token contract and owner
    return { guztoken, Guzholder };
  }
  async function deployOrderSwapFixture() {
    // Load the token fixture to get the deployed token contract
    const { guztoken, Guzholder } = await loadFixture(deployGuzTokenFixture);
    const { web3token, web3holder } = await loadFixture(deployWeb3TokenFixture);

    const [owner] = await hre.ethers.getSigners();

    const orderSwap = await hre.ethers.getContractFactory("OrderSwap");
    const orderSwapAddress = await orderSwap.deploy();

    // Return the deployed contracts and other relevant data
    return {
      owner,
      orderSwapAddress,
      guztoken,
      Guzholder,
      web3token,
      web3holder,
    };
  }

  describe("Swap", function () {
    it("Should deposit token web3 for swap", async function () {
      const { orderSwapAddress, guztoken, Guzholder, web3token, web3holder } =
        await loadFixture(deployOrderSwapFixture);

      const Web3depositAmount = ethers.parseUnits("100", 18);
      const expectedGuzAmount = ethers.parseUnits("20", 18);
      // setting deadline for 1 hour
      const deadline = (await time.latest()) + 3600;

      // approving contract to spend
      await web3token
        .connect(web3holder)
        .approve(orderSwapAddress, Web3depositAmount);
      await orderSwapAddress
        .connect(web3holder)
        .deposit(
          web3token,
          guztoken,
          Web3depositAmount,
          expectedGuzAmount,
          deadline
        );
      expect(await web3token.balanceOf(orderSwapAddress)).to.equal(
        Web3depositAmount
      );
    });

    it("Should trade   web3 for guz  ", async function () {
      const { orderSwapAddress, guztoken, Guzholder, web3token, web3holder } =
        await loadFixture(deployOrderSwapFixture);

      const Web3depositAmount = ethers.parseUnits("100", 18);
      const expectedGuzAmount = ethers.parseUnits("20", 18);

      const deadline = Math.floor(Date.now() / 1000) + 60 * 10 + 1000000000;

      // approving contract to spend
      await web3token
        .connect(web3holder)
        .approve(orderSwapAddress, Web3depositAmount);

      await orderSwapAddress
        .connect(web3holder)
        .deposit(
          web3token,
          guztoken,
          Web3depositAmount,
          expectedGuzAmount,
          deadline
        );

      await guztoken
        .connect(Guzholder)
        .approve(orderSwapAddress, expectedGuzAmount);

      await orderSwapAddress.connect(Guzholder).trade(guztoken);

      expect(await web3token.balanceOf(Guzholder)).to.equal(Web3depositAmount);
    });
  });
});
