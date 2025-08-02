// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SimpleSwap {
    address public owner;
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public rate; // number of TokenB per TokenA, e.g., rate=2 means 1 A = 2 B

    event Swap(address indexed user, uint256 amountA, uint256 amountB);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event WithdrawTokens(address indexed token, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _tokenA, address _tokenB, uint256 _rate) {
        owner = msg.sender;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rate = _rate; // e.g., 2 means get 2 B for every 1 A
    }

    function updateRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Rate must be positive");
        emit RateUpdated(rate, _newRate);
        rate = _newRate;
    }

    /// @notice Swap specified amount of TokenA to TokenB according to rate
    function swapAToB(uint256 amountA) external {
        require(amountA > 0, "Amount must be positive");
        uint256 amountB = amountA * rate;
        require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient TokenB in contract");

        // Pull user's TokenA
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        // Send TokenB to user
        require(tokenB.transfer(msg.sender, amountB), "TokenB transfer failed");

        emit Swap(msg.sender, amountA, amountB);
    }

    /// @notice Owner can withdraw any ERC20 tokens from the contract
    function withdrawTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
        emit WithdrawTokens(token, to, amount);
    }
}
