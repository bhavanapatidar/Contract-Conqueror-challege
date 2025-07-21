// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@title Contract Conqueror day1

contract BasicToken {
    /// @notice Token details
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 private _totalsupply;
    uint256 private immutable _cap;
    address public owner;
    bool public paused = false;
    

    /// @dev Balances and allowances
    mapping(address => uint256) private _balances;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    modifier onlyowner(){
        require(msg.sender == owner,"Not contract Owner");
        _; 
    }    

    // @dev Timestamp when each account's tokens unlock

    /// @notice Events for tracking state changes

    /// @notice Events for tracking state changes

    /// @dev Restrict function to only the owner

    /// @dev Restrict function if contract is paused

    /// @dev Restrict function if address is time-locked

    // / @notice Constructor to initialize name, symbol, cap, and initial supply
    // / @param _name Token name
    // / @param _symbol Token symbol
    // / @param initialSupply Initial mint amount (in whole tokens)
    // / @param maxCap Maximum supply cap (in whole tokens)
    constructor(uint256 initialSupply){
        owner = msg.sender;
        _mint(owner,initialSupply);
    }

    /// @notice Transfer tokens from sender to recipient
    function transfer(address to, uint256 amount) external{
        require(to != address(0), "Invalid address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }
    /// @notice Check balance of a specific address

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }


     /// @notice Pause token transfers and actions

    /// @notice Unpause token transfers and actions

    /// @notice Lock an address's tokens until a future time
    /// @param user The address to lock
    /// @param unlockTime The UNIX timestamp until which the address is locked    

    /// @notice Get the unlock timestamp for a user

    /// @notice Mint new tokens (only owner, capped)
    /// @param to The address to receive minted tokens
    /// @param amount The amount to mint (in whole tokens)
        

    /// @notice Burn tokens from caller's balance
    /// @param amount Amount to burn (in smallest unit)

    /// @notice Burn tokens from another account with approval
    /// @param account Address to burn from
    /// @param amount Amount to burn (in smallest unit)

    /// @notice Transfer tokens
    /// @notice Approve a spender
    /// @notice Transfer tokens using allowance
    /// @notice Get max token cap
    /// @notice Get total token supply
    function totalsupply() external view returns (uint256) {
        return _totalsupply;
    }
    /// @notice Get balance of an address
    /// @notice Get allowance from owner to spender
    /// @dev Internal mint function (only callable in constructor here)
    function _mint(address to, uint256 amount) internal{
        require(to != address(0), "Invalid address");
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    /// @dev Internal burn function
    /// @dev Internal transfer function
    /// @dev Internal approve function

}