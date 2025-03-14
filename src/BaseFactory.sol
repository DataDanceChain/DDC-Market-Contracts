// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseFactory {
    // 合约所有者地址
    address private _owner;

    // 存储已部署的合约地址
    address[] private _deployedContracts;

    // 事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    // 检查调用者是否为所有者的修饰符
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
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

    // 获取已部署合约数量
    function getDeployedContractsCount() public view returns (uint256) {
        return _deployedContracts.length;
    }

    // 获取指定索引的已部署合约地址
    function getDeployedContractAt(uint256 index) public view returns (address) {
        require(index < _deployedContracts.length, "Index out of bounds");
        return _deployedContracts[index];
    }

    // 获取所有已部署合约地址
    function getAllDeployedContracts() public view returns (address[] memory) {
        return _deployedContracts;
    }

    // 内部函数：添加已部署的合约地址
    function _addDeployedContract(address contractAddress) internal {
        _deployedContracts.push(contractAddress);
    }
}