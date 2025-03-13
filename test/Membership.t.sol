// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Membership.sol";

contract MembershipTest is Test {
    Membership public membership;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        membership = new Membership("DDC Membership", "DDCM");
    }
    
    function testInitialState() public {
        assertEq(membership.getOwner(), owner);
        assertEq(membership.name(), "DDC Membership");
        assertEq(membership.symbol(), "DDCM");
        assertEq(membership.totalSupply(), 0);
    }
    
    function testMint() public {
        bytes32 addressHash = keccak256(abi.encodePacked("address1"));
        uint256 tokenId = 1;
        
        vm.expectEmit(true, true, true, false);
        
        membership.mint(tokenId, addressHash);
        assertEq(membership.ownerOf(tokenId), addressHash);
        assertEq(membership.totalSupply(), 1);
    }
    
    function testFailMintDuplicate() public {
        bytes32 addressHash = keccak256(abi.encodePacked("address1"));
        uint256 tokenId = 1;
        membership.mint(tokenId, addressHash);
        membership.mint(tokenId, addressHash); // 应该失败
    }
    
    function testDestroy() public {
        bytes32 addressHash = keccak256(abi.encodePacked("address1"));
        uint256 tokenId = 1;
        
        membership.mint(tokenId, addressHash);
        
        vm.expectEmit(true, true, true, false);
        
        membership.destroy(tokenId, addressHash);
        assertEq(membership.totalSupply(), 0);
        vm.expectRevert("Membership: token does not exist");
        membership.ownerOf(tokenId);
    }
    
    function testCreateSnapshot() public {
        bytes32 addressHash1 = keccak256(abi.encodePacked("address1"));
        bytes32 addressHash2 = keccak256(abi.encodePacked("address2"));
        
        membership.mint(1, addressHash1);
        membership.mint(2, addressHash2);
        
        vm.expectEmit(true, false, false, false);
        
        uint256 snapshotId = membership.createSnapshot();
        assertTrue(membership.isMemberInSnapshot(snapshotId, addressHash1));
        assertTrue(membership.isMemberInSnapshot(snapshotId, addressHash2));
        
        bytes32[] memory members = membership.getMemberSnapshot(snapshotId);
        assertEq(members.length, 2);
        assertEq(membership.getLatestSnapshotId(), 0);
    }
    
    function testIsMemberInSnapshot() public {
        bytes32 addressHash = keccak256(abi.encodePacked("address1"));
        membership.mint(1, addressHash);
        
        uint256 snapshotId = membership.createSnapshot();
        assertTrue(membership.isMemberInSnapshot(snapshotId, addressHash));
        
        // 测试非成员
        bytes32 nonMemberHash = keccak256(abi.encodePacked("nonmember"));
        assertFalse(membership.isMemberInSnapshot(snapshotId, nonMemberHash));
    }
    
    function testSetBaseURI() public {
        string memory newBaseURI = "https://api.example.com/member/";
        membership.setBaseURI(newBaseURI);
        
        uint256 tokenId = 1;
        bytes32 addressHash = keccak256(abi.encodePacked("address1"));
        membership.mint(tokenId, addressHash);
        assertEq(membership.tokenURI(tokenId), string.concat(newBaseURI, vm.toString(tokenId)));
    }
    
    function testTransferOwnership() public {
        address newOwner = address(0x3);
        
        vm.expectEmit(true, true, false, false);
        
        membership.transferOwnership(newOwner);
        assertEq(membership.getOwner(), newOwner);
    }
    
    function testFailTransferOwnershipToZeroAddress() public {
        membership.transferOwnership(address(0)); // 应该失败
    }
}