// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DDCNFT.sol";
import "./BaseFactory.sol";

contract DDCNFTFactory is BaseFactory {
    // 事件 - 减少indexed参数数量
    event DDCNFTDeployed(address contractAddress, string name, string symbol);

    // 使用create2部署新的DDCNFT合约
    function deployDDCNFT(string memory name, string memory symbol) public onlyOwner returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, block.timestamp));
        DDCNFT newContract = new DDCNFT{salt: salt}(name, symbol);
        _addDeployedContract(address(newContract));
        newContract.transferOwnership(msg.sender);
        emit DDCNFTDeployed(address(newContract), name, symbol);
        return address(newContract);
    }
}