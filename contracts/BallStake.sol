// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IReward.sol";
import "./BoringERC20.sol";


contract BallStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. BALL to distribute per block.
        uint256 lastRewardBlock;    // Last block number that BALL distribution occurs.
        uint256 accBallPerShare;  // Accumulated BALL per share, times 1e12. See below.
        IRewarder rewarder;
    }

    // The BALL token
    IERC20 public Ball;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Ball mining starts.
    uint256 public startBlock;
    uint256 public perBlock = 0;           //ball tokens rewards per block

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _Ball,
        uint256 _BallPerBlock,
        uint256 _startBlock,
        IRewarder _rewarder
    ) {
        Ball = _Ball;
        startBlock = _startBlock;
        perBlock = _BallPerBlock;

        // Sanity check if we add a rewarder
        if (address(_rewarder) != address(0)) {
            _rewarder.onBallReward(address(0), 0);
        }

        // staking pool
        poolInfo.push(PoolInfo({
        lpToken : _Ball,
        allocPoint : 1000,
        lastRewardBlock : startBlock,
        accBallPerShare : 0,
        rewarder : _rewarder
        }));

        totalAllocPoint = 1000;

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // DO NOT add the same LP token more than once
    function checkPoolDuplicate(IERC20 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _lpToken, "MasterChefV2::add: existing pool");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, IRewarder _rewarder) public onlyOwner {
        checkPoolDuplicate(_lpToken);

        if (_withUpdate) {
            massUpdatePools();
        }

        // Sanity check if we add a rewarder
        if (address(_rewarder) != address(0)) {
            _rewarder.onBallReward(address(0), 0);
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accBallPerShare : 0,
        rewarder : _rewarder
        }));
        updateStakingPool();
    }

    // Update the given pool's Ball allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            updateStakingPool();
        }

        if (overwrite) {
            _rewarder.onBallReward(address(0), 0);
            // sanity check
            poolInfo[_pid].rewarder = _rewarder;
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    function setBallPerBlock(uint256 _BallPerBlock) public virtual onlyOwner {
        massUpdatePools();
        perBlock = _BallPerBlock;
    }

    // View function to see pending BALL on frontend.
    function pendingBall(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBallPerShare = pool.accBallPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockReward = mintable(pool.lastRewardBlock);
            uint256 BallReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
            accBallPerShare = accBallPerShare.add(BallReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBallPerShare).div(1e12).sub(user.rewardDebt);
    }

    function pendingReward(uint256 _pid, address _user)
    external
    view
    returns (
        address bonusTokenAddress,
        string memory bonusTokenSymbol,
        uint256 pendingBonusToken
    ) {
        PoolInfo storage pool = poolInfo[_pid];
        // If it's a double reward farm, we return info about the bonus token
        if (address(pool.rewarder) != address(0)) {
            bonusTokenAddress = address(pool.rewarder.rewardToken());
            bonusTokenSymbol = BoringERC20.safeSymbol(IERC20(pool.rewarder.rewardToken()));
            pendingBonusToken = pool.rewarder.pendingTokens(_user);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = mintable(pool.lastRewardBlock);
        uint256 BallReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        Ball.transfer(address(this), BallReward);
        pool.accBallPerShare = pool.accBallPerShare.add(BallReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function mintable(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber <= block.number, "Schedule::mintable: blockNumber overflow");
        uint256 blocksMinted = block.number.sub(blockNumber); // 当前区块到给定区块号之间的区块数量
        uint256 _mintable = blocksMinted.mul(perBlock); // 总的可铸造代币量
        return _mintable;
    }


    // Deposit LP tokens to MasterChefV2.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid != 0, "MasterChefV2::deposit: _pid can only be farm pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBallPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeBallTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBallPerShare).div(1e12);

        // Interactions
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onBallReward(msg.sender, user.amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChefV2.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid != 0, "MasterChefV2::withdraw: _pid can only be farm pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "MasterChefV2::withdraw: _amount not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBallPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeBallTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);

            // Interactions
            IRewarder _rewarder = pool.rewarder;
            if (address(_rewarder) != address(0)) {
                _rewarder.onBallReward(msg.sender, user.amount);
            }

            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBallPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake BALL tokens to MasterChefV2
    function enterStaking(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBallPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeBallTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBallPerShare).div(1e12);

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw BALL tokens from MasterChefV2.
    function leaveStaking(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "MasterChefV2::leaveStaking: _amount not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accBallPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeBallTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBallPerShare).div(1e12);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe Ball transfer function, just in case if rounding error causes pool to not have enough BALL.
    function safeBallTransfer(address _to, uint256 _amount) internal {
        uint256 BallBalance = Ball.balanceOf(address(this));
        if (_amount > BallBalance) {
            Ball.transfer(_to, BallBalance);
        } else {
            Ball.transfer(_to, _amount);
        }
    }
}