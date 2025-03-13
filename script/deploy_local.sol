// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Membership.sol";
import "../src/DDCNFT.sol";

contract DeployScript is Script {
    function run() external {
        // DDC链配置
        string memory rpcUrl = vm.envString("DDC_RPC_URL");
        uint256 chainId = vm.envUint("DDC_CHAIN_ID");
        uint256 gasPrice = 20 gwei;
        
        // 加载部署账户
        uint256 deployerPrivateKey = vm.envUint("DDC_PRIVATE_KEY");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        vm.txGasPrice(gasPrice);

        // 部署Membership合约
        Membership membership = new Membership(
            "DDC Membership",
            "DDCM"
        );
        console.log("Membership deployed at:", address(membership));

        // 部署DDCNFT合约
        DDCNFT ddcNFT = new DDCNFT(
            "DDC NFT",
            "DDC"
        );
        console.log("DDCNFT deployed at:", address(ddcNFT));

        vm.stopBroadcast();

        // 验证部署结果
        require(address(membership) != address(0), "Membership deployment failed");
        require(address(ddcNFT) != address(0), "DDCNFT deployment failed");
        require(membership.getOwner() == vm.addr(deployerPrivateKey), "Ownership verification failed");
        require(ddcNFT.owner() == vm.addr(deployerPrivateKey), "Ownership verification failed");
        
        // 链上验证
        bytes memory membershipCode = address(membership).code;
        bytes memory ddcNFTCode = address(ddcNFT).code;
        require(membershipCode.length > 0, "Membership contract code verification failed");
        require(ddcNFTCode.length > 0, "DDCNFT contract code verification failed");
        
    }
}