// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract StakingRewards {
    IERC20 public immutable stakingToken;  // Token users stake
    IERC20 public immutable rewardsToken;  // Token users are rewarded with

    uint256 public duration;           // Duration of rewards distribution (seconds)
    uint256 public finishAt;           // Timestamp when rewards end
    uint256 public updatedAt;          // Last time rewardPerTokenStored was updated
    uint256 public rewardRate;         // Reward tokens distributed per second
    uint256 public rewardPerTokenStored; // Cumulative rewards per token staked

    mapping(address => uint256) public userRewardPerTokenPaid; // Snapshot of rewardPerTokenStored per user
    mapping(address => uint256) public rewards;                // Rewards accumulated but not claimed

    uint256 public totalSupply;        // Total staked tokens
    mapping(address => uint256) public balanceOf;  // User staking balances

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _stakingToken, address _rewardsToken, uint256 _duration) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        duration = _duration;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < finishAt ? block.timestamp : finishAt;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored
            + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return
            (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18
            + rewards[account];
    }

    // Stake tokens to participate in rewards
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    // Withdraw staked tokens
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(balanceOf[msg.sender] >= amount, "Withdraw amount exceeds balance");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    // Claim accumulated rewards
    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardsToken.transfer(msg.sender, reward), "Reward transfer failed");
        }
    }

    // Exit staking by withdrawing all and claiming rewards
    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    // Owner can notify contract of rewards and set rate
    function notifyRewardAmount(uint256 amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remaining = finishAt - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (amount + leftover) / duration;
        }

        require(rewardRate > 0, "Reward rate = 0");
        require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "Insufficient rewards");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }
}

//
