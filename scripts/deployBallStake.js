// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
   const ballStake = await hre.ethers.getContractFactory("BallStake");

  const ball = '0xf717f64ec396293E8623D54309D4Dc80D7d1952c';
  const ballPerBlock = hre.ethers.parseUnits("1000", 18);
  const startBlock =  41212113;
  const rewarder = '0x0000000000000000000000000000000000000000';
  console.log(ballPerBlock)

  const ballStakeContract = await ballStake.deploy(
    ball,
    ballPerBlock,
    startBlock,
    rewarder
  );


  console.log(
    `deployed to ${ballStakeContract.target}`
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
