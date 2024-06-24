// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const mintWar = await ethers.getContractFactory("MintWar");

  const token = "0x488D03966188487Bd1D65C863f07b298E7871282";
  const liquidity = "0x2950aeEB216B6BBC9344e58580bA8C4aF4C1E86c";
  const startTime = 1718978400;
  const endTime = 1719410400;
  const mintWarcontract = await mintWar.deploy(token,liquidity,startTime,endTime);

  await mintWarcontract.waitForDeployment();

  console.log(
    `deployed to ${mintWarcontract.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
