// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title BasicERC721
/// @notice Basic ERC721-compliant NFT implementation (without OpenZeppelin)
contract BasicERC721 {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _owners;

    // Mapping from owner to number of owned tokens
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Events per ERC721 standard
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @notice Returns the owner of a token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    /// @notice Returns the number of tokens owned by `owner`
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Zero address not allowed");
        return _balances[owner];
    }

    /// @notice Approve another address to transfer the given token ID
    function approve(address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(msg.sender == owner, "Not token owner");
        require(to != owner, "Approval to current owner");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @notice Get approved address for a token ID
    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /// @notice Transfers a token from one address to another
    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(owner == from, "Not token owner");
        require(msg.sender == owner || msg.sender == _tokenApprovals[tokenId], "Not approved");

        require(to != address(0), "Cannot transfer to zero address");

        _balances[from] -= 1;
        _balances[to] += 1;

        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    /// @notice Mints a new NFT token
    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "Cannot mint to zero address");
        require(_owners[tokenId] == address(0), "Token already exists");

        _balances[to] += 1;
        _owners[tokenId] = to;
        totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }
}
