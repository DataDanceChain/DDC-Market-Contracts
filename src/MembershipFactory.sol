// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Membership.sol";
import "./BaseFactory.sol";

contract MembershipFactory is BaseFactory {
    // 事件 - 减少indexed参数数量
    event MembershipDeployed(address contractAddress, string name, string symbol);

    // 使用create2部署新的Membership合约
    function deployMembership(string memory name, string memory symbol) public onlyOwner returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, block.timestamp));
        Membership newContract = new Membership{salt: salt}(name, symbol);
        _addDeployedContract(address(newContract));
        newContract.transferOwnership(msg.sender);
        emit MembershipDeployed(address(newContract), name, symbol);
        return address(newContract);
    }
}