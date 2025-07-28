// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MyERC1155
/// @notice Custom ERC1155 Token Contract without OpenZeppelin

contract MyERC1155 {
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _uris;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    modifier onlyApproved(address from) {
        require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not authorized");
        _;
    }

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

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external onlyApproved(from) {
        require(to != address(0), "Zero address");
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Insufficient balance");

        _balances[id][from] -= amount;
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyApproved(from) {
        require(ids.length == amounts.length, "Mismatched arrays");
        require(to != address(0), "Zero address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "Insufficient balance");
            _balances[id][from] -= amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    /// @dev Only contract owner should mint; for simplicity no access control
    function mint(address to, uint256 id, uint256 amount, string memory uri_) external {
        require(to != address(0), "Zero address");
        _balances[id][to] += amount;

        if (bytes(_uris[id]).length == 0) {
            _uris[id] = uri_;
            emit URI(uri_, id);
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, string[] calldata uris_) external {
        require(to != address(0), "Zero address");
        require(ids.length == amounts.length && ids.length == uris_.length, "Mismatched inputs");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            if (bytes(_uris[ids[i]]).length == 0) {
                _uris[ids[i]] = uris_[i];
                emit URI(uris_[i], ids[i]);
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function uri(uint256 id) public view returns (string memory) {
        return _uris[id];
    }

    /// Optional: ERC165 interface support
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0xd9b67a26; // ERC1155 interface ID
    }
}
