// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const { keccak256 } = require("keccak256");

async function main() {

  const users = [
    { address: "0xD08c8e6d78a1f64B1796d6DC3137B19665cb6F1F", amount: 10 },
    { address: "0xb7D15753D3F76e7C892B63db6b4729f700C01298", amount: 15 },
    { address: "0xf69b4a11e27ECF2cB850D47405F1deD44BE5359B", amount: 20 },
    { address: "0x2950aeEB216B6BBC9344e58580bA8C4aF4C1E86c", amount: 30 },
  ];

  const elements = users.map((x) =>
    hre.ethers.solidityPackedKeccak256(
    ['address', 'uint256'],
    [x.address, x.amount]
  ));

  const merkleTree = new MerkleTree(elements, keccak256, { sort: true });
  const merkleRoot = merkleTree.getHexRoot();
  const startTime = Math.floor(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 24;
  const tokenAddress = "0x488D03966188487Bd1D65C863f07b298E7871282";

  console.log("args",merkleRoot,tokenAddress,"|",startTime,"|",endTime)
  
  const airdrop = await ethers.getContractFactory("MerkleAirdrop");
  const airdropContract = await airdrop.deploy(merkleRoot,tokenAddress,startTime,endTime);
  await airdropContract.waitForDeployment();

  console.log(
    `deployed to ${airdropContract.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
