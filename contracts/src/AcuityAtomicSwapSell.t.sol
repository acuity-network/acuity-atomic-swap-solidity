// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "ds-test/test.sol";

import "./AcuityAtomicSwapSell.sol";

contract AcuityAtomicSwapSellTest is DSTest {
    AcuityAtomicSwapSell acuityAtomicSwapSell;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapSell = new AcuityAtomicSwapSell();
    }

    function testCreateOrder() public {
        uint64 price = 5;
        uint64 value = 50;
        bytes32 orderId = acuityAtomicSwapSell.createOrder{value: value}(price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlLockSellNotBigEnough() public {
        uint64 price = 5;
        uint64 value = 50;
        acuityAtomicSwapSell.createOrder{value: value}(price);
        acuityAtomicSwapSell.lockSell(price, hex"1234", uint64(block.timestamp) + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint64 price = 5;
        uint64 value = 50;
        acuityAtomicSwapSell.createOrder{value: value}(price);
        acuityAtomicSwapSell.lockSell(price, hex"1234", uint64(block.timestamp) + 1000, value + 10);
    }

    function testLockSell() public {
        uint64 price = 5;
        bytes32 orderId = acuityAtomicSwapSell.createOrder{value: 50}(price);

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint64 timeout = uint64(block.timestamp) + 1000;
        uint64 value = 10;
        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        (bytes32 lockOrderId, uint64 lockValue, uint64 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);
    }

    function testControlUnlockSellTimedOut() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp) + 1000, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testFailUnlockSellTimedOut() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp), 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testUnlockSell() public {
        uint64 price = 5;
        bytes32 orderId = acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint64 timeout = uint64(block.timestamp) + 1000;
        uint64 value = 10;

        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        (bytes32 lockOrderId, uint64 lockValue, uint64 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        uint64 startBalance = uint64(address(this).balance);
        acuityAtomicSwapSell.unlockSell(secret);
        (lockOrderId, lockValue, lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, 0);
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 40);
        assertEq(uint64(address(this).balance), startBalance + 10);
    }

    function testControlTimeoutSellWrongOrderId() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp), 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testFailTimeoutSellWrongOrderId() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp), 10);
        acuityAtomicSwapSell.timeoutSell(price - 1, hashedSecret);
    }

    function testControlTimeoutSellNotTimedOut() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp), 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testFailTimeoutSellNotTimedOut() public {
        uint64 price = 5;
        acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, uint64(block.timestamp) + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testTimeoutSell() public {
        uint64 price = 5;
        bytes32 orderId = acuityAtomicSwapSell.createOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint64 timeout = uint64(block.timestamp);
        uint64 value = 10;

        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        (bytes32 lockOrderId, uint64 lockValue, uint64 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        acuityAtomicSwapSell.timeoutSell(5, hashedSecret);
        (lockOrderId, lockValue, lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, 0);
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 50);
    }

}
