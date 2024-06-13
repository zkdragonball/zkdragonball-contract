// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Powcc {
    
    using SafeMath for uint256;
    
    address public _tokenAddress = 0x55d398326f99059fF775485246999027B3197955; //生产
    //address public _tokenAddress = 0xB757D676C60348942e40CCA2535e4B64930eFe87; //测试
    address public _developWallet = 0xf15aB624b928D216a31e7Cdff7BAE180781E36dc; // 投研钱包 
    address public _boundsWallet = 0xd69254840F2F8C7871F31fDf77a1bD3E1a35a5e9;  // 波比
    address public _marketWallet = 0x1B8dc6D0f5E46bc80aD6A30BAb732F6d91f105c9; // 做市商
    address public _machineWallet = 0xC685732FC25BFb9DC3383BD157d4419c488B5885;  // 矿机
    address public _managerWallet = 0xa097906bD0C582B45a66535CbDCb8dF6Eb56FD64; // 管理

    address public _admin = 0x6C7e7fbFa69f4B5A5Ade1C27BC74fa4290a3b8A3;

    //10%投研 ，25%波比 ，15%做市商， 40% 矿机 ,10% 管理）
    uint256 public _baseRate = 1000; // 总体占比
    uint256 public _developRate = 100; // 投研占比
    uint256 public _boundsRate = 250 ;  // 波比占比
    uint256 public _marketRate = 150;    // 做市商占比
    uint256 public _machineRate = 400;  // 矿机占比
    uint256 public _managerRate = 100;  //管理占比
     
    IERC20 _token = IERC20(_tokenAddress);
    
    uint256[] _prices = [500 ether, 1500 ether, 4000 ether]; 

    event Buyed(address indexed user, uint256 price, uint256 count);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can call this function");
        _;
    }

    function buy(uint256 price, uint256 count)
    public
    checkAmount(price)
    {
        uint256 amount = price * count;
        _token.transferFrom(msg.sender, address(this), amount);
        uint256 developReward = amount.mul(_developRate).div(_baseRate);
        if(developReward>0){
            _token.transfer(_developWallet, developReward);
        }
        uint256 boundsReward = amount.mul(_boundsRate).div(_baseRate);
        if(boundsReward>0){
            _token.transfer(_boundsWallet, boundsReward);
        }
        uint256 marketReward = amount.mul(_marketRate).div(_baseRate);
        if(marketReward>0){
            _token.transfer(_marketWallet, marketReward);
        }
        uint256 machineReward = amount.mul(_machineRate).div(_baseRate);
        if(machineReward>0){
            _token.transfer(_machineWallet, machineReward);
        }
        uint256 managerReward = amount.mul(_managerRate).div(_baseRate);
        if(managerReward>0){
            _token.transfer(_managerWallet, managerReward);
        }
        emit Buyed(msg.sender, price, count);
    }

    modifier checkAmount(uint256 price) {
        require(checkPrice(price) , "price is wrong");
        _;
    }

    function checkPrice(uint256 price) public view returns(bool) {
        bool flag = false;
        for(uint256 indx = 0; indx < _prices.length; indx++) {
            if(price == _prices[indx]){
                flag = true;
                break;
            }
        }
        return flag;
    }

    function changeTokenAddress(address token) external onlyAdmin {
        _tokenAddress = token;
    }

    function addNewPrice(uint256 price) external onlyAdmin {
        _prices.push(price);
    }
    
    function modifyPrice(uint256 index, uint256 price) external onlyAdmin {
        _prices[index] = price;
    }

    function getPrice(uint256 index) public view returns(uint256) {
        return _prices[index];
    }

    function changeDevelopWallet(address wallet) external onlyAdmin {
        _developWallet = wallet;
    }

    function changeBoundsWallet(address wallet) external onlyAdmin {
        _boundsWallet = wallet;
    }

    function changeMarketWallet(address wallet) external onlyAdmin {
        _marketWallet = wallet;
    }

    function changeMachineWallet(address wallet) external onlyAdmin {
        _machineWallet = wallet;
    }

    function changeManagerWallet(address wallet) external onlyAdmin {
        _managerWallet = wallet;
    }

    function changeDevelopRate(uint256 rate) external onlyAdmin {
        _developRate = rate;
    }

    function changeBoundsRate(uint256 rate) external onlyAdmin {
        _boundsRate = rate;
    }

    function changeMarketRate(uint256 rate) external onlyAdmin {
        _marketRate = rate;
    }

    function changeMachineRate(uint256 rate) external onlyAdmin {
        _machineRate = rate;
    }

     function changeManagerRate(uint256 rate) external onlyAdmin {
        _managerRate = rate;
    }

}