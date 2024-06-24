// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRewarder.sol";
import "./IMasterChef.sol";

contract RewardManager is Ownable,IRewarder {
    using SafeMath for uint256;

    IERC20 public immutable override rewardToken;
    IERC20 public immutable lpToken;
    IMasterChef public immutable MCM;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accTokenPerShare;
        uint256 lastRewardBlock;
    }

    /// @notice Info of the poolInfo.
    PoolInfo public poolInfo;
    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    uint256 public override tokenPerBlock;
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    event OnReward(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);

    modifier onlyMCM() {
        require(msg.sender == address(MCM), "onlyMCM: only MasterChef V2 can call this function");
        _;
    }

    constructor(
        IERC20 _rewardToken,
        IERC20 _lpToken,
        uint256 _tokenPerBlock,
        IMasterChef _MCM
    ) {
        rewardToken = _rewardToken;
        lpToken = _lpToken;
        tokenPerBlock = _tokenPerBlock;
        MCM = _MCM;
        poolInfo = PoolInfo({lastRewardBlock: block.number, accTokenPerShare: 0});
    }

    /// @notice Update reward variables of the given poolInfo.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;

        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = lpToken.balanceOf(address(MCM));

            if (lpSupply > 0) {
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 tokenReward = blocks.mul(tokenPerBlock);
                pool.accTokenPerShare = pool.accTokenPerShare.add((tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply));
            }
            pool.lastRewardBlock = block.number;
            poolInfo = pool;
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerBlock The number of tokens to distribute per block
    function setRewardRate(uint256 _tokenPerBlock) external onlyOwner {
        updatePool();
        uint256 oldRate = tokenPerBlock;
        tokenPerBlock = _tokenPerBlock;
        emit RewardRateUpdated(oldRate, _tokenPerBlock);
    }

    //  function getTokenPerBlock() external view returns (uint256) {
    //     return tokenPerBlock;
    // }

    /// @notice Function called by MasterChefMojito whenever staker claims JOE harvest. Allows staker to also receive a 2nd reward token.
    /// @param _user Address of user
    /// @param _lpAmount Number of LP tokens the user has
    function onReward(address _user, uint256 _lpAmount) external override onlyMCM {
        updatePool();
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 pending;
        // if user had deposited
        if (user.amount > 0) {
            pending = (user.amount.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
            uint256 balance = rewardToken.balanceOf(address(this));
            if (pending > balance) {
                rewardToken.transfer(_user, balance);
            } else {
                rewardToken.transfer(_user, pending);
            }
        }
        user.amount = _lpAmount;
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION;
        emit OnReward(_user, pending);
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return pending reward for a given user.
    function pendingTokens(address _user) public view override returns (uint256 pending) {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(MCM));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 tokenReward = blocks.mul(tokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
        }

        pending = (user.amount.mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
    }

    function checkBalance(address _user) external view returns (bool){
        uint256 pending = pendingTokens(_user);
        uint256 totalRewards = rewardToken.balanceOf(address(this));
        return totalRewards >= pending;
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() public onlyOwner {
        rewardToken.transfer(address(msg.sender), rewardToken.balanceOf(address(this)));
    }
}