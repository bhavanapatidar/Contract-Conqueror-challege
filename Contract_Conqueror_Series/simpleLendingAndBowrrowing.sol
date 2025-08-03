// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleLending {
    IERC20 public token;
    address public owner;
    uint256 public interestRate; // e.g., 5 = 5%
    uint256 public collateralFactor; // e.g., 150 means 150% collateral required

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 repaid);
    event Withdrawn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token, uint256 _interestRate, uint256 _collateralFactor) {
        token = IERC20(_token);
        owner = msg.sender;
        interestRate = _interestRate;
        collateralFactor = _collateralFactor;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    // User can borrow up to 'deposited / collateralFactor' value
    function borrow(uint256 amount) external {
        uint256 maxBorrow = deposits[msg.sender] * 1e18 / collateralFactor;
        require(amount > 0 && amount <= maxBorrow, "Amount too high or zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient liquidity");
        borrows[msg.sender] += amount;
        require(token.transfer(msg.sender, amount), "Borrow token transfer failed");
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(amount > 0 && borrows[msg.sender] >= amount, "Invalid repay");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        borrows[msg.sender] -= amount;
        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        uint256 requiredCollateral = (borrows[msg.sender] * collateralFactor) / 1e18;
        require(deposits[msg.sender] >= amount, "Not enough deposited");
        require(deposits[msg.sender] - amount >= requiredCollateral, "Collateral locked");
        deposits[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Withdraw transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    // Owner can update rates
    function setInterestRate(uint256 _rate) external onlyOwner {
        interestRate = _rate;
    }

    function setCollateralFactor(uint256 _factor) external onlyOwner {
        collateralFactor = _factor;
    }
}
