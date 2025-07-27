// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnifiedNFT (Day 15–18)
/// @notice Full-featured NFT: ERC721, Metadata, Whitelist, Delayed Reveal
contract UnifiedNFT {
    string public name;
    string public symbol;
    address public owner;
    uint256 public totalSupply;

    string private baseURI;
    string private notRevealedURI;
    bool public revealed;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => bool) private whitelist;

    /// Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Whitelisted(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event Revealed();

    /// Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _notRevealedURI
    ) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        notRevealedURI = _notRevealedURI;
        owner = msg.sender;
        revealed = false;
    }

    // -------------------------
    // NFT CORE LOGIC
    // -------------------------

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Zero address not allowed");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "Token doesn't exist");
        return _owner;
    }

    function approve(address to, uint256 tokenId) public {
        address _tokenOwner = ownerOf(tokenId);
        require(msg.sender == _tokenOwner, "Not token owner");
        require(to != _tokenOwner, "Cannot approve current owner");

        _tokenApprovals[tokenId] = to;
        emit Approval(_tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf(tokenId) == from, "Not token owner");
        require(to != address(0), "Cannot transfer to zero address");
        require(msg.sender == from || msg.sender == _tokenApprovals[tokenId], "Not approved");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    // -------------------------
    // MINTING
    // -------------------------

    /// @notice Mint a new NFT (only for whitelisted)
    function safeMint() public onlyWhitelisted {
        require(msg.sender != address(0), "Zero address");

        uint256 tokenId = totalSupply + 1;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender] += 1;
        totalSupply = tokenId;

        emit Transfer(address(0), msg.sender, tokenId);
    }

    /// @notice Owner-only mint (used for testing or airdrops)
    function safeMintTo(address to) public onlyOwner {
        require(to != address(0), "Zero address");

        uint256 tokenId = totalSupply + 1;
        _owners[tokenId] = to;
        _balances[to] += 1;
        totalSupply = tokenId;

        emit Transfer(address(0), to, tokenId);
    }

    // -------------------------
    // METADATA & REVEAL
    // -------------------------

    /// @notice Returns metadata URI (changes after reveal)
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");

        if (!revealed) {
            return notRevealedURI;
        }

        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    function setBaseURI(string memory _base) public onlyOwner {
        baseURI = _base;
    }

    function setNotRevealedURI(string memory _uri) public onlyOwner {
        notRevealedURI = _uri;
    }

    function reveal() public onlyOwner {
        revealed = true;
        emit Revealed();
    }

    // -------------------------
    // WHITELIST CONTROL
    // -------------------------

    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
        emit Whitelisted(user);
    }

    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
        emit RemovedFromWhitelist(user);
    }

    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }

    // -------------------------
    // UTIL
    // -------------------------

    /// @dev uint to string (for tokenURI)
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory bStr = new bytes(digits);
        while (_i != 0) {
            digits -= 1;
            bStr[digits] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        str = string(bStr);
    }
}
