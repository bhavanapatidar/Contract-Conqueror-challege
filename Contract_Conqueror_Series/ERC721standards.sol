// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MetadataNFT
/// @notice Basic NFT collection with metadata and safeMint function
contract MetadataNFT {
    string public name;
    string public symbol;
    string private baseURI;
    uint256 public totalSupply;
    address public owner;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        owner = msg.sender;
    }

    /// @notice Returns balance of a specific owner
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Zero address");
        return _balances[_owner];
    }

    /// @notice Returns the owner of a token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "Token doesn't exist");
        return _owner;
    }

    /// @notice Returns metadata URI for a token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    /// @notice Internal mint function (only callable by owner)
    function safeMint(address to) public onlyOwner {
        require(to != address(0), "Mint to zero address");

        uint256 tokenId = totalSupply + 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        totalSupply = tokenId;

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Change base URI
    function setBaseURI(string memory _base) public onlyOwner {
        baseURI = _base;
    }

    /// @dev Converts uint to string (for tokenURI)
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
