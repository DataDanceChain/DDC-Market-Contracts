// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KeyHashNFT {
    // 存储每个 token 对应的密钥哈希（代表当前拥有者）
    mapping(uint256 => bytes32) private _tokenKeyHash;

    // 存储每个 token 是否已被销毁
    mapping(uint256 => bool) private _tokenDestroyed;

    // 存储每个 token 的批准地址
    mapping(uint256 => bytes32) private _tokenApprovals;

    // 存储每个账户的批准所有token的地址
    mapping(bytes32 => mapping(bytes32 => bool)) private _operatorApprovals;

    // 存储token的总数
    uint256 private _totalSupply;

    // Token name and symbol
    string private _name;
    string private _symbol;

    // ERC721 Metadata
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ERC721 Metadata - Name
    function name() public view returns (string memory) {
        return _name;
    }

    // ERC721 Metadata - Symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // ERC721 - Token URI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(!_tokenDestroyed[tokenId], "Token has been destroyed!");
        return string(abi.encodePacked("https://myapi.com/token/", uint2str(tokenId)));
    }

    // ERC721 - Balance of owner
    function balanceOf(bytes32 ownerHash) public view returns (uint256) {
        require(ownerHash != bytes32(0), "Owner hash is zero");
        uint256 count = 0;
        for (uint256 i = 1; i <= _totalSupply; i++) {
            if (_tokenKeyHash[i] == ownerHash) {
                count++;
            }
        }
        return count;
    }

    // ERC721 - Owner of a token
    function ownerOf(uint256 tokenId) public view returns (bytes32) {
        bytes32 ownerHash = _tokenKeyHash[tokenId];
        require(ownerHash != bytes32(0), "Token does not exist!");
        return ownerHash;
    }

    // ERC721 - Transfer token
    function transferFrom(bytes32 fromHash, bytes32 toHash, uint256 tokenId, bytes32 keyHash) public {
        require(fromHash == ownerOf(tokenId), "Not the owner");
        _transfer(fromHash, toHash, tokenId, keyHash);
    }

    // ERC721 - Safe Transfer token
    function safeTransferFrom(bytes32 fromHash, bytes32 toHash, uint256 tokenId, bytes32 keyHash) public {
        _safeTransfer(fromHash, toHash, tokenId, keyHash);
    }

    // ERC721 - Approve address for a token
    function approve(bytes32 toHash, uint256 tokenId) public {
        bytes32 ownerHash = ownerOf(tokenId);
        require(toHash != ownerHash, "Cannot approve to the current owner");
        _approve(toHash, tokenId);
    }

    // ERC721 - Set approval for all tokens
    function setApprovalForAll(bytes32 operatorHash, bool approved) public {
        _operatorApprovals[msg.sender][operatorHash] = approved;
    }

    // ERC721 - Get approved address for a token
    function getApproved(uint256 tokenId) public view returns (bytes32) {
        require(!_tokenDestroyed[tokenId], "Token has been destroyed!");
        return _tokenApprovals[tokenId];
    }

    // ERC721 - Check if operator is approved for all tokens
    function isApprovedForAll(bytes32 ownerHash, bytes32 operatorHash) public view returns (bool) {
        return _operatorApprovals[ownerHash][operatorHash];
    }

    // Transfer logic (internal)
    function _transfer(bytes32 fromHash, bytes32 toHash, uint256 tokenId, bytes32 keyHash) internal {
        require(!_tokenDestroyed[tokenId], "Token has been destroyed!");
        require(_tokenKeyHash[tokenId] == keyHash, "Incorrect key or unauthorized!");
        
        // 更新 token 所有者哈希
        _tokenKeyHash[tokenId] = toHash;

        emit Transfer(fromHash, toHash, tokenId);
    }

    // Safe transfer logic (internal)
    function _safeTransfer(bytes32 fromHash, bytes32 toHash, uint256 tokenId, bytes32 keyHash) internal {
        _transfer(fromHash, toHash, tokenId, keyHash);
        require(_checkOnERC721Received(fromHash, toHash, tokenId), "Transfer to non ERC721Receiver implementer");
    }

    // Approve token (internal)
    function _approve(bytes32 toHash, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = toHash;
        emit Approval(ownerOf(tokenId), toHash, tokenId);
    }

    // Helper function to check if contract supports ERC721Receiver (for safeTransfer)
    function _checkOnERC721Received(bytes32 fromHash, bytes32 toHash, uint256 tokenId) private returns (bool) {
        // 如果目标是合约，可以检查是否实现 `onERC721Received`（这里只是示意）
        return true;
    }

    // Helper function to convert uint to string (for tokenURI)
    function uint2str(uint256 _i) private pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        str = string(bstr);
    }

    // Mint new token
    function mint(uint256 tokenId, bytes32 keyHash) public {
        require(_tokenKeyHash[tokenId] == bytes32(0), "Token already minted!");
        _tokenKeyHash[tokenId] = keyHash; // 直接设置拥有者为 mint 时的哈希值
        _totalSupply++;
        emit Transfer(bytes32(0), bytes32(0), tokenId); // 通过 Transfer 事件表示 mint 操作
    }

    // Destroy token
    function destroy(uint256 tokenId, bytes32 keyHash) public {
        require(ownerOf(tokenId) == keyHash, "Incorrect key or unauthorized!");
        _tokenDestroyed[tokenId] = true;
    }

    // Events
    event Transfer(bytes32 indexed fromHash, bytes32 indexed toHash, uint256 indexed tokenId);
    event Approval(bytes32 indexed ownerHash, bytes32 indexed approvedHash, uint256 indexed tokenId);
}
