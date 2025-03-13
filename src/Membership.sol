// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Membership {
    // 状态变量
    mapping(uint256 => bytes32) private _tokenOwners; // 存储token的所有者哈希
    uint256[] private _mintedTokens; // 存储已铸造的tokenId
    uint256 private _totalSupply;
    address private owner;
    string private _name; // 不可变的name字段
    string private _symbol; // 不可变的symbol字段
    string private _baseURI; // 基础URI
    
    // 快照相关状态变量
    struct MemberSnapshot {
        mapping(bytes32 => bool) memberList;    // 用于O(1)时间复杂度的成员查询
        bytes32[] members;                      // 用于存储所有成员地址
        uint256 count;                         // 成员总数
    }
    mapping(uint256 => MemberSnapshot) private snapshots;
    uint256 private snapshotCount;
    
    // 事件
    event Transfer(bytes32 indexed from, bytes32 indexed to, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SnapshotCreated(uint256 indexed snapshotId);
    
    // 构造函数
    constructor(string memory name_, string memory symbol_) {
        require(bytes(name_).length > 0, "Membership: name cannot be empty");
        require(bytes(symbol_).length > 0, "Membership: symbol cannot be empty");
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Membership: caller is not the owner");
        _;
    }
    
    // 所有权管理
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Membership: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    // 创建新的快照
    function createSnapshot() public onlyOwner returns (uint256) {
        uint256 currentId = snapshotCount;
        
        // 只遍历已铸造的token
        for (uint256 i = 0; i < _mintedTokens.length; i++) {
            uint256 tokenId = _mintedTokens[i];
            bytes32 ownerHash = _tokenOwners[tokenId];
            if (ownerHash != bytes32(0)) {
                snapshots[currentId].memberList[ownerHash] = true;
                snapshots[currentId].members.push(ownerHash);
            }
        }
        
        snapshots[currentId].count = _totalSupply;
        emit SnapshotCreated(currentId);
        
        snapshotCount++;
        return currentId;
    }
    
    // 成员管理函数 (SBT风格)
    function mint(uint256 tokenId, bytes32 addressHash) public onlyOwner {
        require(addressHash != bytes32(0), "Membership: invalid address hash");
        require(tokenId != 0, "Membership: invalid token id");
        require(_tokenOwners[tokenId] == bytes32(0), "Membership: token already exists");
        
        // 检查溢出
        require(_totalSupply + 1 > _totalSupply, "Membership: total supply overflow");
        _tokenOwners[tokenId] = addressHash;
        _mintedTokens.push(tokenId);
        unchecked {
            _totalSupply++;
        }
        
        emit Transfer(bytes32(0), addressHash, tokenId);
    }
    
    function destroy(uint256 tokenId, bytes32 addressHash) public onlyOwner {
        require(addressHash != bytes32(0), "Membership: invalid address hash");
        require(tokenId != 0, "Membership: invalid token id");
        require(_tokenOwners[tokenId] == addressHash, "Membership: token does not exist or not owned by address");
        
        // 检查下溢
        require(_totalSupply > 0, "Membership: total supply underflow");
        _tokenOwners[tokenId] = bytes32(0);
        // 从_mintedTokens中移除tokenId
        for (uint256 i = 0; i < _mintedTokens.length; i++) {
            if (_mintedTokens[i] == tokenId) {
                _mintedTokens[i] = _mintedTokens[_mintedTokens.length - 1];
                _mintedTokens.pop();
                break;
            }
        }
        unchecked {
            _totalSupply--;
        }
        
        emit Transfer(addressHash, bytes32(0), tokenId);
    }
    
    // 查询函数
    function ownerOf(uint256 tokenId) public view returns (bytes32) {
        bytes32 ownerHash = _tokenOwners[tokenId];
        require(ownerHash != bytes32(0), "Membership: token does not exist");
        return ownerHash;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 元数据查询函数
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_tokenOwners[tokenId] != bytes32(0), "Membership: token does not exist");
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId)) : "";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }
    
    // 获取指定快照ID对应的成员快照
    function getMemberSnapshot(uint256 snapshotId) public view returns (bytes32[] memory) {
        require(snapshotId < snapshotCount, "Membership: invalid snapshot id");
        return snapshots[snapshotId].members;
    }
    
    // 获取最新的快照ID
    function getLatestSnapshotId() public view returns (uint256) {
        require(snapshotCount > 0, "Membership: no snapshot available");
        return snapshotCount - 1;
    }
    
    // 查询地址是否在指定快照中
    function isMemberInSnapshot(uint256 snapshotId, bytes32 addressHash) public view returns (bool) {
        require(snapshotId < snapshotCount, "Membership: invalid snapshot id");
        require(addressHash != bytes32(0), "Membership: invalid address hash");
        
        return snapshots[snapshotId].memberList[addressHash];
    }
}