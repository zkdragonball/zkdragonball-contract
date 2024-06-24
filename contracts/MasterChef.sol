// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRewarder.sol";


contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        IRewarder rewarder;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _lpToken,IRewarder _rewarder)  {
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        rewarder : _rewarder
        }));

    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add( IERC20 _lpToken, IRewarder _rewarder) public onlyOwner {
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            rewarder : _rewarder
        }));
    }

      // Update the rewarder for a specific pool. Can only be called by the owner.
    function updateRewarder(uint256 _pid, IRewarder _rewarder) public onlyOwner {
        require(_pid < poolInfo.length, "updateRewarder: pool does not exist");
        PoolInfo storage pool = poolInfo[_pid];
        pool.rewarder = _rewarder;
    }

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    function tokenPerBlock(uint256 _pid) external view returns (uint256 ) {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) != address(0)) {
            return pool.rewarder.tokenPerBlock();
        }
        return 0;
    }

     function pending(uint256 _pid, address _user) external view returns (uint256 ) {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) != address(0)) {
            return pool.rewarder.pendingTokens(_user);
        }
        return 0;
    }


    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        if(address(pool.rewarder) != address(0)){ 
            IRewarder _rewarder = pool.rewarder;
            require(_rewarder.checkBalance(msg.sender), "Insufficient rewards");
            _rewarder.onReward(msg.sender, user.amount); 
        }
        emit Deposit(msg.sender, _pid, _amount);
    }


    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");
        if(_amount>0){
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        if (address(pool.rewarder) != address(0)) { 
            IRewarder _rewarder = pool.rewarder;
            require(_rewarder.checkBalance(msg.sender), "Insufficient rewards");
            _rewarder.onReward(msg.sender, user.amount); 
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
    }

}