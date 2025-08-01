// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnifiedTokenSwap
/// @notice Combines TokenA, TokenB, and Swap functionality in one contract

contract UnifiedTokenSwap {
    // ========== Token Structures ==========
    struct Token {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balanceOf;
        mapping(address => mapping(address => uint256)) allowance;
    }

    Token private tokenA;
    Token private tokenB;

    // ========== Admin and Swap Variables ==========
    address public owner;
    uint256 public exchangeRate; // tokenB per tokenA, scaled by 1e18

    // ========== Events ==========
    event Transfer(address indexed token, address indexed from, address indexed to, uint256 value);
    event Approval(address indexed token, address indexed owner, address indexed spender, uint256 value);
    event ExchangeRateUpdated(uint256 newRate);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ========== Modifiers ==========
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ========== Constructor ==========
    constructor(uint256 _initialRate) {
        require(_initialRate > 0, "Invalid rate");

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        // Initialize tokens
        tokenA.name = "TokenA";
        tokenA.symbol = "TKA";
        tokenA.decimals = 18;

        tokenB.name = "TokenB";
        tokenB.symbol = "TKB";
        tokenB.decimals = 18;

        exchangeRate = _initialRate;
        emit ExchangeRateUpdated(_initialRate);
    }

    // ========== Token Logic ==========
    function name(bool isTokenA) external view returns (string memory) {
        return isTokenA ? tokenA.name : tokenB.name;
    }

    function symbol(bool isTokenA) external view returns (string memory) {
        return isTokenA ? tokenA.symbol : tokenB.symbol;
    }

    function decimals(bool isTokenA) external view returns (uint8) {
        return isTokenA ? tokenA.decimals : tokenB.decimals;
    }

    function totalSupply(bool isTokenA) external view returns (uint256) {
        return isTokenA ? tokenA.totalSupply : tokenB.totalSupply;
    }

    function balanceOf(bool isTokenA, address user) external view returns (uint256) {
        return isTokenA ? tokenA.balanceOf[user] : tokenB.balanceOf[user];
    }

    function approve(bool isTokenA, address spender, uint256 amount) external returns (bool) {
        Token storage token = isTokenA ? tokenA : tokenB;
        token.allowance[msg.sender][spender] = amount;
        emit Approval(isTokenA ? address(this) : address(0), msg.sender, spender, amount);
        return true;
    }

    function allowance(bool isTokenA, address owner_, address spender) external view returns (uint256) {
        Token storage token = isTokenA ? tokenA : tokenB;
        return token.allowance[owner_][spender];
    }

    function transfer(bool isTokenA, address to, uint256 amount) external returns (bool) {
        Token storage token = isTokenA ? tokenA : tokenB;
        require(token.balanceOf[msg.sender] >= amount, "Insufficient balance");
        token.balanceOf[msg.sender] -= amount;
        token.balanceOf[to] += amount;
        emit Transfer(isTokenA ? address(this) : address(0), msg.sender, to, amount);
        return true;
    }

    function transferFrom(bool isTokenA, address from, address to, uint256 amount) external returns (bool) {
        Token storage token = isTokenA ? tokenA : tokenB;
        require(token.balanceOf[from] >= amount, "Insufficient balance");
        require(token.allowance[from][msg.sender] >= amount, "Not allowed");
        token.allowance[from][msg.sender] -= amount;
        token.balanceOf[from] -= amount;
        token.balanceOf[to] += amount;
        emit Transfer(isTokenA ? address(this) : address(0), from, to, amount);
        return true;
    }

    function mint(bool isTokenA, address to, uint256 amount) external onlyOwner {
        Token storage token = isTokenA ? tokenA : tokenB;
        token.balanceOf[to] += amount;
        token.totalSupply += amount;
        emit Transfer(isTokenA ? address(this) : address(0), address(0), to, amount);
    }

    // ========== Swap Logic ==========
    function setExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Zero rate");
        exchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }

    function swap(uint256 amountIn) external {
        require(amountIn > 0, "Zero input");

        // Check allowance and balance
        require(tokenA.balanceOf[msg.sender] >= amountIn, "Insufficient TokenA");
        require(tokenA.allowance[msg.sender][address(this)] >= amountIn, "TokenA not approved");

        uint256 amountOut = (amountIn * exchangeRate) / 1e18;
        require(tokenB.balanceOf[address(this)] >= amountOut, "Insufficient TokenB in contract");

        // Execute swap
        tokenA.balanceOf[msg.sender] -= amountIn;
        tokenA.allowance[msg.sender][address(this)] -= amountIn;
        tokenA.balanceOf[address(this)] += amountIn;

        tokenB.balanceOf[address(this)] -= amountOut;
        tokenB.balanceOf[msg.sender] += amountOut;

        emit SwapExecuted(msg.sender, amountIn, amountOut);
    }

    // ========== Admin ==========
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdraw(bool isTokenA, uint256 amount) external onlyOwner {
        Token storage token = isTokenA ? tokenA : tokenB;
        require(token.balanceOf[address(this)] >= amount, "Insufficient funds");
        token.balanceOf[address(this)] -= amount;
        token.balanceOf[msg.sender] += amount;
    }
}
