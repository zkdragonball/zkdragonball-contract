// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function deployMasterChef(){
  const MasterChef = await hre.ethers.getContractFactory("MasterChef");
  const _rewardToken = '0x488D03966188487Bd1D65C863f07b298E7871282';
  const _rewarder = '0x0000000000000000000000000000000000000000';
  const MasterChefContact = await MasterChef.deploy(
    _rewardToken,
    _rewarder
  );
  return MasterChefContact.target;
  
}

async function deployRewardManager(_MCM) {
  const RewardManager = await hre.ethers.getContractFactory("RewardManager");
  const _rewardToken = '0x488D03966188487Bd1D65C863f07b298E7871282';
  const _lpToken = '0x488D03966188487Bd1D65C863f07b298E7871282';
  const _tokenPerBlock = hre.ethers.parseUnits("10", 18);;

  const RewardManagerContact = await RewardManager.deploy(
    _rewardToken,
    _lpToken,
    _tokenPerBlock,
    _MCM
  );
  return RewardManagerContact.target;
}

async function setMCMReward(_MCM,_Reward) {
  const MasterChef = await ethers.getContractFactory("MasterChefV2");
  const MasterChefContact = MasterChef.attach(_MCM);
  const tx = await MasterChefContact.updateRewarder(0,_Reward);
  await tx.wait();
  console.log("setMCMReward exec completed!");
}

async function main() {
  // const MSM = await deployMasterChef(); 
  // console.log("MSM:",MSM)
  // const reward =await deployRewardManager(MSM);
  // console.log("reward:",reward)
  const MCM = '0x031cE676c5637FC20a53869476cec5e1e1116124';
  const Reward = '0x1d9DaAB1e24d9326AB798bdB2a4d2A4745472DEd';
  setMCMReward(MCM,Reward);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});






