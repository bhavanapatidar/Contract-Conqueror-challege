// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.20;  
  
/// @title OZFullERC20Token  
/// @notice ERC20 token with Mintable, Burnable, Pausable, Capped, and Timelock features  
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";  
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";  
import "@openzeppelin/contracts/security/Pausable.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";  
  
contract OZFullERC20Token is ERC20Capped, ERC20Burnable, Pausable, Ownable {  
    /// @dev Per-address transfer timelock  
    mapping(address => uint256) private _lockUntil;  
  
    event Locked(address indexed user, uint256 unlockTime);  
  
    /// @notice Constructor  
    /// @param name Token name  
    /// @param symbol Token symbol  
    /// @param initialSupply Initial supply in tokens (not wei)  
    /// @param capSupply Max cap in tokens (not wei)  
    constructor(  
        string memory name,  
        string memory symbol,  
        uint256 initialSupply,  
        uint256 capSupply  
    )  
        ERC20(name, symbol)  
        ERC20Capped(capSupply * 1e18)  
        Ownable(msg.sender)  
    {  
        _mint(msg.sender, initialSupply * 1e18);  
    }  
  
    // -----------------------------------------  
    // ✅ Mint  
    // -----------------------------------------  
  
    /// @notice Mint new tokens (owner only)  
    /// @param to Address to receive minted tokens  
    /// @param amount Amount in whole tokens  
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {  
        _mint(to, amount * 1e18);  
    }  
  
    // -----------------------------------------  
    // ✅ Pause & Unpause  
    // -----------------------------------------  
  
    function pause() external onlyOwner {  
        _pause();  
    }  
  
    function unpause() external onlyOwner {  
        _unpause();  
    }  
  
    // -----------------------------------------  
    // ✅ Timelock  
    // -----------------------------------------  
  
    /// @notice Lock transfers for an address until a specific time  
    /// @param user The address to lock  
    /// @param unlockTime UNIX timestamp  
    function lockTokens(address user, uint256 unlockTime) external onlyOwner {  
        require(unlockTime > block.timestamp, "Unlock time must be in future");  
        _lockUntil[user] = unlockTime;  
        emit Locked(user, unlockTime);  
    }  
  
    /// @notice Get unlock timestamp of a user  
    function getUnlockTime(address user) external view returns (uint256) {  
        return _lockUntil[user];  
    }  
  
    // -----------------------------------------  
    // ✅ Internal Overrides  
    // -----------------------------------------  
  
    /// @dev Override _beforeTokenTransfer to enforce pause + lock  
    function _beforeTokenTransfer(  
        address from,  
        address to,  
        uint256 amount  
    ) internal {  
        if (from != address(0)) { // not mint  
            require(!paused(), "ERC20Pausable: token transfer while paused");  
            require(block.timestamp >= _lockUntil[from], "ERC20Timelock: tokens are locked");  
        }  
    }  
  
    /// @dev Override _update to resolve conflict between ERC20 and ERC20Capped  
    function _update(address from, address to, uint256 value)  
        internal  
        override(ERC20, ERC20Capped)  
    {  
        super._update(from, to, value);  
    }  
}  