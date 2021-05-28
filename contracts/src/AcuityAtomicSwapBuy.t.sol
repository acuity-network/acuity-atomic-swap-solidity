// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";

contract AcuityAtomicSwapBuyTest is DSTest {
    AcuityAtomicSwapBuy acuityAtomicSwapBuy;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapBuy = new AcuityAtomicSwapBuy();
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), timeout, hex"5678");
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
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), block.timestamp + 1000, hex"5678");
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.unlockBuy(secret);
    }

    function testFailUnlockBuyTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), block.timestamp, hex"5678");
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.unlockBuy(secret);
    }

    function testUnlockBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: value}(hashedSecret, payable(seller), timeout, hex"5678");

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
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), block.timestamp, hex"5678");
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testFailTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), block.timestamp + 1000, hex"5678");
        acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testTimeoutBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp;
        acuityAtomicSwapBuy.lockBuy{value: value}(hashedSecret, payable(seller), timeout, hex"5678");

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
