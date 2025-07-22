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
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lockUntil; // timestamp

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event Mint(address indexed to, uint256 amount);
    event Locked(address indexed user, uint256 unlockTime);


        /// @dev Restrict function to only the owner

    modifier onlyowner(){
        require(msg.sender == owner,"Not contract Owner");
        _; 
    }

        /// @dev Restrict function if contract is paused

    modifier whenNotPaused(){
        require(!paused,"Contract is paused");
        _;
    }    

    // @dev Timestamp when each account's tokens unlock
     modifier notLocked(address user) {
        require(block.timestamp >= _lockUntil[user], "Tokens are time-locked");
        _;
    }
    // / @notice Constructor to initialize name, symbol, cap, and initial supply
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply,
        uint maxcap){
        name = _name;
        symbol = _symbol;    
        owner = msg.sender;
        _cap = maxcap * (10 ** uint256(decimals));
        _mint(owner,initialSupply * (10 ** uint256(decimals)));
    }

    /// @notice Transfer tokens from sender to recipient
      function transfer(address to, uint256 amount) external whenNotPaused notLocked(msg.sender) returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Check balance of a specific address

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }


     /// @notice Pause token transfers and actions
     function pause() external onlyowner{
        paused = true;
        emit Paused(msg.sender);
     }

    /// @notice Unpause token transfers and actions
    function unpause() external onlyowner{
        paused = false;
        emit Unpaused(msg.sender);

    }

    /// @notice Lock an address's tokens until a future time

    /// @param user The address to lock
    /// @param unlockTime The UNIX timestamp until which the address is locked    
 /// 🕒 Lock a user's tokens until a future timestamp
    function lockTokens(address user, uint256 unlockTime) external onlyowner {
        uint256 currentTime = block.timestamp + unlockTime;
        require(currentTime > block.timestamp, "Unlock time must be in future");
        _lockUntil[user] = currentTime;
        emit Locked(user, currentTime);
    }

    /// @notice Get the current block timestamp (in seconds since Unix epoch)
function getCurrentTimestamp() external view returns (uint256) {
    return block.timestamp;
}


   
    /// @notice Get the unlock timestamp for a user
     function getUnlockTime(address user) external view returns (uint256) {
        return _lockUntil[user];
    }

    /// @notice Mint new tokens (only owner, capped)
    function mint(address to, uint256 amount) external onlyowner whenNotPaused{
        uint256 amountWithDecimals = amount * (10 ** uint256(decimals));
        require(_totalsupply + amountWithDecimals <= _cap, "Exceeds cap");
        _mint(to, amount*(10 ** uint256(decimals)));
    }

      function cap() external view returns (uint256) {
        return _cap;
    }
    /// @param to The address to receive minted tokens
    /// @param amount The amount to mint (in whole tokens)
        

    /// @notice Burn tokens from caller's balance
    /// @param amount Amount to burn (in smallest unit)
    function burn(uint256 amount) external whenNotPaused{
        require(_balances[msg.sender] >= amount, "Insufficient balance to burn");
        _burn(msg.sender, amount);
    }

    /// @notice Burn tokens from another account with approval
    /// @param account Address to burn from
    /// @param amount Amount to burn (in smallest unit)
    function burnForm(address account, uint256 amount) external whenNotPaused{
        require(_allowances[account][msg.sender] >= amount, "Allowance exceeded");
        _allowances[account][msg.sender] -= amount;
        _burn(account, amount);

    }
    
    /// @notice Transfer tokens on behalf of another address
    function transferFrom(address from, address to, uint256 amount) external whenNotPaused returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "ERC20: insufficient allowance");

        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);

        return true;
    }

    /// @notice Transfer tokens
    /// @notice Approve a spender
     function approve(address spender, uint256 amount) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    /// @notice Transfer tokens using allowance
     function allowance(address tokenOwner, address spender) external view whenNotPaused returns (uint256) {
        return _allowances[tokenOwner][spender];
    }
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
        _totalsupply += amount;
        _balances[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
    /// @dev Internal burn function
    function _burn(address from, uint256 amount) internal{
        require(from != address(0), "Invalid address");
        require(_balances[from] >= amount, "ERC20: insufficient balance");
        _balances[from] -= amount;
        _totalsupply -= amount;
        emit Burn(from, amount);
        emit Transfer(from, address(0),amount);
    }
    /// @dev Internal transfer function
     function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from 0x0");
        require(to != address(0), "ERC20: transfer to 0x0");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    /// @dev Internal approve function
    function _approve(address tokenOwner, address spender, uint256 amount) internal{
        require(tokenOwner != address(0), "ERC20: approve from 0x0");
        require(spender != address(0), "ERC20: approve to 0x0");
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

}