// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Membership {
    // 状态变量
    mapping(bytes32 => bytes32) private _tokenOwners; // 存储token的所有者哈希
    uint256 private _totalSupply;
    address private owner;
    string private immutable _name; // 不可变的name字段
    string private immutable _symbol; // 不可变的symbol字段
    string private _baseURI; // 基础URI
    
    // 快照相关状态变量
    struct MemberSnapshot {
        mapping(bytes32 => bool) memberList;
        uint256 count;
    }
    mapping(uint256 => MemberSnapshot) private snapshots;
    uint256 private snapshotCount;
    
    // 事件
    event Transfer(bytes32 indexed from, bytes32 indexed to, bytes32 indexed tokenId);
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
        
        // 遍历当前的members映射，将所有有效成员添加到新快照中
        for (bytes32 tokenId in _tokenOwners) {
            if (_tokenOwners[tokenId] != bytes32(0)) {
                snapshots[currentId].memberList[tokenId] = true;
            }
        }
        
        snapshots[currentId].count = _totalSupply;
        emit SnapshotCreated(currentId);
        
        snapshotCount++;
        return currentId;
    }
    
    // 成员管理函数 (SBT风格)
    function mint(bytes32 addressHash) public onlyOwner {
        require(addressHash != bytes32(0), "Membership: invalid address hash");
        
        // 将地址哈希与name拼接后计算最终的tokenId
        bytes32 tokenId = keccak256(abi.encodePacked(addressHash, _name));
        require(_tokenOwners[tokenId] == bytes32(0), "Membership: token already exists");
        
        _tokenOwners[tokenId] = addressHash;
        _totalSupply++;
        
        emit Transfer(bytes32(0), addressHash, tokenId);
    }
    
    function destroy(bytes32 addressHash) public onlyOwner {
        require(addressHash != bytes32(0), "Membership: invalid address hash");
        
        // 将地址哈希与name拼接后计算最终的tokenId
        bytes32 tokenId = keccak256(abi.encodePacked(addressHash, _name));
        require(_tokenOwners[tokenId] == addressHash, "Membership: token does not exist or not owned by address");
        
        _tokenOwners[tokenId] = bytes32(0);
        _totalSupply--;
        
        emit Transfer(addressHash, bytes32(0), tokenId);
    }
    
    // 查询函数
    function ownerOf(bytes32 tokenId) public view returns (bytes32) {
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

    function tokenURI(bytes32 tokenId) public view returns (string memory) {
        require(_tokenOwners[tokenId] != bytes32(0), "Membership: token does not exist");
        return bytes(_baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }
    
    // 获取指定快照ID对应的成员快照
    function getMemberSnapshot(uint256 snapshotId) public view returns (mapping(bytes32 => bool) storage memberStatus, uint256 count) {
        require(snapshotId < snapshotCount, "Membership: invalid snapshot id");
        MemberSnapshot storage snapshot = snapshots[snapshotId];
        return (snapshot.memberList, snapshot.count);
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
        
        // 计算tokenId
        bytes32 tokenId = keccak256(abi.encodePacked(addressHash, _name));
        return snapshots[snapshotId].memberList[tokenId];
    }
}

