const { ethers } = require("hardhat");

const stakeAddress = "0x329eb787fd15E0733fc5F8c2371F8365de2AA1Ff";
const ballAddress = "0x488D03966188487Bd1D65C863f07b298E7871282";

async function init() {
  const StakingRewards = await ethers.getContractFactory("StakingRewards");
  return StakingRewards.attach(stakeAddress);
}

async function ballApprove(targetContract, amount) {
  const Ball = await ethers.getContractFactory("Ball");
  const ballContract = Ball.attach(ballAddress);
  ballContract.approve(targetContract,amount);
}


async function fund(){
  const amount =  ethers.parseUnits("100000", 18);
  const Ball = await ethers.getContractFactory("Ball");
  const ballContract = Ball.attach(ballAddress);
  const tx1 = await ballContract.approve(stakeAddress,amount);
  await tx1.wait();
  const StakingRewards = await ethers.getContractFactory("StakingRewards");
  const contract =  StakingRewards.attach(stakeAddress);
  const tx = await contract.fund(amount);
  await tx.wait();
  console.log("fund exec completed!");
}

async function deposit(){
  const StakingRewards = await ethers.getContractFactory("StakingRewards");
  const contract =  StakingRewards.attach(stakeAddress);  
  const amount =  ethers.parseUnits("100", 18);
  const Ball = await ethers.getContractFactory("Ball");
  const ballContract = Ball.attach(ballAddress);
  const tx1 = await ballContract.approve(stakeAddress,amount);
  await tx1.wait();
  const tx = await contract.deposit(0,amount);
  await tx.wait();
  console.log("deposit exec completed!");
}


async function main() {
  fund();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
