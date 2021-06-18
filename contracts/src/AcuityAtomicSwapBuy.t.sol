// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";

contract AcuityAtomicSwapBuyTest is DSTest {
    AcuityAtomicSwapBuy acuityAtomicSwapBuy;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapBuy = new AcuityAtomicSwapBuy();
    }

    function testControlLockBuyAlreadyInUse() public {
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"1234", hex"5678", payable(seller), timeout);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"1234", hex"3456", payable(seller), timeout);
    }

    function testFailLockBuyAlreadyInUse() public {
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"1234", hex"5678", payable(seller), timeout);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"1234", hex"5678", payable(seller), timeout);
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"5678", hashedSecret, payable(seller), timeout);
        assertEq(address(acuityAtomicSwapBuy).balance, 10);
        (address lockSeller, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, 10);
        assertEq(lockTimeout, timeout);
    }

    function testControlUnlockBuyTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"5678", hashedSecret, payable(seller), block.timestamp + 1000);
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.unlockBuy(secret);
    }

    function testFailUnlockBuyTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"5678", hashedSecret, payable(seller), block.timestamp);
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.unlockBuy(secret);
    }

    function testUnlockBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: value}(0, hex"5678", hashedSecret, payable(seller), timeout);

        (address lockSeller, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 startBalance = address(seller).balance;
        acuityAtomicSwapBuy.unlockBuy(secret);
        (lockSeller, lockValue, lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, address(0));
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, startBalance + value);
    }

    function testControlTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"5678", hashedSecret, payable(seller), block.timestamp);
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testFailTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(0, hex"5678", hashedSecret, payable(seller), block.timestamp + 1000);
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testTimeoutBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp;
        acuityAtomicSwapBuy.lockBuy{value: value}(0, hex"5678", hashedSecret, payable(seller), timeout);

        (address lockSeller, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 sellerBalance = address(seller).balance;
        uint256 buyerBalance = address(this).balance;
        acuityAtomicSwapBuy.timeoutBuy(secret);
        (lockSeller, lockValue, lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, address(0));
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, sellerBalance);
        assertEq(address(this).balance, buyerBalance + value);
    }

}
