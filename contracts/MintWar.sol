// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './TransferHelper.sol';

contract MintWar is ReentrancyGuard,Ownable{
  using SafeMath for uint256;

  uint256 public constant PRECISION = 100000;
  address public treasury;
  address public liquidity;
  address public token;
  uint256 public minFee;
  mapping(address => uint256) public accountTotalMint;
  mapping(address => uint256) public accountSuccessMint;
  mapping(address => uint256) public accountFailMint;
  mapping(address => uint256) public pointsOf;
  mapping(address => bool) public isClaimed;
  uint256 public totalPoints;

  uint256 public totalSuccessValue;
  uint256 public totalFailValue;
  uint256 public totalMintValue;

  uint256 public totalMintTimes;
  uint256 public totalSuccessMints;
  uint256 public totalFailMints;

  uint256 public maxPointsPerMint;
  bool public mintEnd;
  uint256 public mintStartAt;
  uint256 public mintEndAt;

  event Mint(address account,bool success,uint256 value,uint256 rate,uint256 points);
  event EndWar();
  event Claim(address account, uint256 value);

  constructor(address _token, address _liquidity, uint256 _mintStartAt, uint256 _mintEndAt) {
    treasury = msg.sender;
    liquidity = _liquidity;
    token = _token;
    minFee = 0.001e18;
    maxPointsPerMint = 10000e18;
    require(_mintStartAt>block.timestamp && _mintEndAt>_mintStartAt, "Mint time error");
    mintStartAt = _mintStartAt;
    mintEndAt = _mintEndAt;
  }

  function mint(uint256 rate) external payable nonReentrant{
    require(block.timestamp >= mintStartAt, "Mint not started");
    require(block.timestamp<mintEndAt && !mintEnd, "Mint ended");
    require(msg.sender == tx.origin , "Must from EOA");
    require(rate>0 && rate<=PRECISION, "Invalid rate");
    require(msg.value>=minFee, "insufficient fee");
    uint256 points = msg.value.mul(PRECISION).div(rate);
    require(points<=maxPointsPerMint, "max points exceeded");
    accountTotalMint[msg.sender] += msg.value;
    totalMintValue += msg.value;
    totalMintTimes += 1;
    if (_random() < rate) {
      totalSuccessMints += 1;
      totalSuccessValue += msg.value;
      accountSuccessMint[msg.sender] += msg.value;

      totalPoints += points;
      pointsOf[msg.sender] += points;

      emit Mint(msg.sender, true, msg.value, rate, points);
    } else {
      totalFailMints += 1;
      totalFailValue += msg.value;
      accountFailMint[msg.sender] += msg.value;

      emit Mint(msg.sender, false, msg.value, rate, 0);
    }
  }

  function endWar() external {
    require(!mintEnd, "Claim started");
    _endWar();    
  }

  function _endWar() private {
    require(mintEndAt<block.timestamp, "Mint War not ended");
    if(mintEnd){
      return;
    }

    mintEnd = true;
    uint256 treasuryFee = totalMintValue.mul(50).div(100);  //treasury
    uint256 liquidityFee = totalMintValue.mul(50).div(100); //liquidity

    TransferHelper.safeTransferETH(treasury, treasuryFee);
    TransferHelper.safeTransferETH(liquidity, liquidityFee);
    emit EndWar();
  }

  function claim() external nonReentrant{
    require(mintEndAt<block.timestamp, "Mint War not ended");
    require(!isClaimed[msg.sender], "Account claimed");
    _endWar();

    uint256 claimAmount = getAccountClaimableAmount(msg.sender);
    require(claimAmount>0, "Insufficient claimable amount");
    TransferHelper.safeTransfer(token, msg.sender, claimAmount);
    isClaimed[msg.sender] = true;

    emit Claim(msg.sender, claimAmount);
  }

  function getAccountClaimableAmount(address account) public view returns(uint256){
    if(totalPoints == 0){
      return 0;
    }
    uint256 tokenMintTotal = IERC20(token).totalSupply().div(5);
    return tokenMintTotal * pointsOf[account]/totalPoints;
  }

  function _random() private view returns(uint256){
    uint256 random = uint256(keccak256(abi.encodePacked(msg.sender,blockhash(block.number-1),block.timestamp,totalMintTimes,totalMintValue)));
    return random % PRECISION;
  }

  function updateMintTime(uint256 _mintStartAt, uint256 _mintEndAt) external onlyOwner {
    require(_mintStartAt > block.timestamp && _mintEndAt > _mintStartAt, "Invalid mint time");
    mintStartAt = _mintStartAt;
    mintEndAt = _mintEndAt;
  }  
}