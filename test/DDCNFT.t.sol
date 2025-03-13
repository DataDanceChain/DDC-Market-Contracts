// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DDCNFT.sol";

contract DDCNFTTest is Test {
    DDCNFT public nft;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        nft = new DDCNFT("DDC NFT", "DDC");
    }
    
    function testInitialState() public {
        assertEq(nft.owner(), owner);
        assertEq(nft.name(), "DDC NFT");
        assertEq(nft.symbol(), "DDC");
    }
    
    function testMint() public {
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        nft.mint(1, keyHash);
        assertEq(nft.ownerOf(1), keyHash);
    }
    
    function testFailMintDuplicate() public {
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        nft.mint(1, keyHash);
        nft.mint(1, keyHash); // 应该失败
    }
    
    function testTransfer() public {
        bytes32 keyHash1 = keccak256(abi.encodePacked("key1"));
        bytes32 keyHash2 = keccak256(abi.encodePacked("key2"));
        string memory key = "key1";
        
        nft.mint(1, keyHash1);
        nft.transfer(keyHash2, 1, key);
        assertEq(nft.ownerOf(1), keyHash2);
    }
    
    function testFailTransferInvalidKey() public {
        bytes32 keyHash1 = keccak256(abi.encodePacked("key1"));
        bytes32 keyHash2 = keccak256(abi.encodePacked("key2"));
        string memory wrongKey = "wrongkey";
        
        nft.mint(1, keyHash1);
        nft.transfer(keyHash2, 1, wrongKey); // 应该失败
    }
    
    function testDestroy() public {
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        string memory key = "key1";
        
        nft.mint(1, keyHash);
        nft.destroy(1, key);
        vm.expectRevert("Token has been destroyed!");
        nft.ownerOf(1);
    }
    
    function testSetBaseURI() public {
        string memory newBaseURI = "https://api.example.com/token/";
        nft.setBaseURI(newBaseURI);
        
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        nft.mint(1, keyHash);
        assertEq(nft.tokenURI(1), string.concat(newBaseURI, "1"));
    }
    
    function testPause() public {
        nft.pause();
        vm.expectRevert("Contract is paused");
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        nft.mint(1, keyHash);
    }
    
    function testUnpause() public {
        nft.pause();
        nft.unpause();
        bytes32 keyHash = keccak256(abi.encodePacked("key1"));
        nft.mint(1, keyHash); // 应该成功
        assertEq(nft.ownerOf(1), keyHash);
    }
    
    function testTransferOwnership() public {
        address newOwner = address(0x3);
        nft.transferOwnership(newOwner);
        assertEq(nft.owner(), newOwner);
    }
}