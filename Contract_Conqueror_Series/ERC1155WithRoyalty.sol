// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MyERC1155WithRoyalty
/// @notice ERC1155 implementation with EIP-2981 royalty support, no OpenZeppelin

contract MyERC1155WithRoyalty {
    // Token balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token URIs
    mapping(uint256 => string) private _uris;

    // Royalty info per tokenId
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction; // in basis points (out of 10,000)
    }
    mapping(uint256 => RoyaltyInfo) private _royalties;

    // Events
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    // Modifier to check operator
    modifier onlyApproved(address from) {
        require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not authorized");
        _;
    }

    // Balance functions
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "Zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Mismatched arrays");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    // Operator approvals
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // Transfers
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external onlyApproved(from) {
        require(to != address(0), "Zero address");
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Insufficient balance");

        _balances[id][from] -= amount;
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyApproved(from) {
        require(to != address(0), "Zero address");
        require(ids.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            require(_balances[id][from] >= amount, "Insufficient balance");

            _balances[id][from] -= amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    // Minting
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory uri_,
        address royaltyReceiver,
        uint96 royaltyFee // e.g., 500 = 5%
    ) external {
        require(to != address(0), "Zero address");
        require(royaltyFee <= 10000, "Fee too high"); // max 100%

        _balances[id][to] += amount;

        if (bytes(_uris[id]).length == 0) {
            _uris[id] = uri_;
            emit URI(uri_, id);
        }

        if (_royalties[id].receiver == address(0)) {
            _royalties[id] = RoyaltyInfo(royaltyReceiver, royaltyFee);
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function uri(uint256 id) public view returns (string memory) {
        return _uris[id];
    }

    // Royalty lookup per EIP-2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / 10000;
        return (royalty.receiver, royaltyAmount);
    }

    // ERC165: interface support check
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0xd9b67a26 || // ERC1155
            interfaceId == 0x2a55205a;   // ERC2981
    }
}
