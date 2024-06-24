// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const RewardManager = await hre.ethers.getContractFactory("RewardManager");
  const _rewardToken = '0x488D03966188487Bd1D65C863f07b298E7871282';
  const _lpToken = '0x488D03966188487Bd1D65C863f07b298E7871282';
  const _tokenPerBlock = hre.ethers.parseUnits("10", 18);;
  const _MCM = '0x7FA25892CC3206e65049E383d384f6411F4B94E6';
  

  const RewardManagerContact = await RewardManager.deploy(
    _rewardToken,
    _lpToken,
    _tokenPerBlock,
    _MCM
  );


  console.log(
    `deployed to ${RewardManagerContact.target}`
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});






