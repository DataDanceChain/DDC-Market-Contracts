// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DDCNFT {
    // 暂停状态
    bool private _paused;
    
    // 暂停事件
    event Paused(address account);
    event Unpaused(address account);
    // 合约所有者地址
    address private _owner;
    // 存储每个 token 对应的密钥哈希（代表当前拥有者）
    mapping(uint256 => bytes32) private _tokenKeyHashes;

    // 存储每个 token 是否已被销毁
    mapping(uint256 => bool) private _destroyedTokens;

    // 存储token的总数
    uint256 private _totalSupply;

    // Token name and symbol
    string private _name;
    string private _symbol;

    // 基础URI
    string private _baseURI = "";

    // ERC721 Metadata
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender; // 设置部署者为合约所有者
    }
    
    // 检查调用者是否为所有者的修饰符
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
    
    // 检查合约是否暂停的修饰符
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;    
    }
    
    // 获取当前所有者
    function owner() public view returns (address) {
        return _owner;
    }
    
    // 转移所有权
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // 暂停合约
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }
    
    // 恢复合约
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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
        require(_tokenKeyHashes[tokenId] != bytes32(0), "Token does not exist!");
        require(!_destroyedTokens[tokenId], "Token has been destroyed!");
        return bytes(_baseURI).length > 0 ? string.concat(_baseURI, tokenId.toString()) : "";
    }

    // 设置基础URI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    // ERC721 - Owner of a token
    function ownerOf(uint256 tokenId) public view returns (bytes32) {
        bytes32 ownerHash = _tokenKeyHashes[tokenId];
        require(ownerHash != bytes32(0), "Token does not exist!");
        return ownerHash;
    }

    // ERC721 - Transfer token
    function transfer(bytes32 toHash, uint256 tokenId, string memory key) public onlyOwner whenNotPaused {
        require(toHash != bytes32(0), "Invalid recipient hash");
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        require(_tokenKeyHashes[tokenId] == keyHash, "Not authorized");
        require(!_destroyedTokens[tokenId], "Token has been destroyed");
        _transfer(toHash, tokenId);
    }

    // 转账事件
    event Transfer(bytes32 indexed fromHash, bytes32 indexed toHash, uint256 indexed tokenId);
    // 销毁事件
    event TokenDestroyed(uint256 indexed tokenId, bytes32 indexed ownerHash);

    // Transfer logic (internal)
    function _transfer(bytes32 toHash, uint256 tokenId) internal {
        bytes32 fromHash = _tokenKeyHashes[tokenId];
        // 更新 token 所有者哈希
        _tokenKeyHashes[tokenId] = toHash;

        emit Transfer(fromHash, toHash, tokenId);
    }

    // 转移所有权事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Mint new token
    function mint(uint256 tokenId, bytes32 keyHash) public onlyOwner whenNotPaused {
        require(tokenId != 0, "Invalid token ID");
        require(keyHash != bytes32(0), "Invalid key hash");
        require(_tokenKeyHashes[tokenId] == bytes32(0), "Token already minted!");
        require(!_destroyedTokens[tokenId], "Token was previously destroyed");
        
        require(_totalSupply + 1 > _totalSupply, "Total supply overflow");
        _tokenKeyHashes[tokenId] = keyHash;
        unchecked {
            _totalSupply++;
        }
        emit Transfer(bytes32(0), keyHash, tokenId);
    }

    // Destroy token
    function destroy(uint256 tokenId, string memory key) public onlyOwner whenNotPaused {
        require(tokenId != 0, "Invalid token ID");
        require(bytes(key).length > 0, "Invalid key");
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        require(_tokenKeyHashes[tokenId] == keyHash, "Incorrect key or unauthorized!");
        require(!_destroyedTokens[tokenId], "Token already destroyed");
        
        require(_totalSupply > 0, "Total supply underflow");
        _destroyedTokens[tokenId] = true;
        unchecked {
            _totalSupply--;
        }
        emit TokenDestroyed(tokenId, keyHash);
        emit Transfer(keyHash, bytes32(0), tokenId);
    }

}
