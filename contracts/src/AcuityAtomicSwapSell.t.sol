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

    function testAddToOrder() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, price)));
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlRemoveFromOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        acuityAtomicSwapSell.removeFromOrder(price, value);
    }

    function testFailRemoveFromOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        acuityAtomicSwapSell.removeFromOrder(price, value + 1);
    }

    function testRemoveFromOrder() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, price)));
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(price, value);
        assertEq(address(this).balance, startBalance + value);
        assertEq(address(acuityAtomicSwapSell).balance, 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), price), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
    }

    function testControlLockSellNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        acuityAtomicSwapSell.lockSell(price, hex"1234", block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(price);
        acuityAtomicSwapSell.lockSell(price, hex"1234", block.timestamp + 1000, value + 10);
    }

    function testLockSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(price);

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;
        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        (bytes16 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);
    }

    function testControlUnlockSellTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp + 1000, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testFailUnlockSellTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testUnlockSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        (bytes16 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.unlockSell(secret);
        (lockOrderId, lockValue, lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, 0);
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 40);
        assertEq(address(this).balance, startBalance + 10);
    }

    function testControlTimeoutSellWrongOrderId() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testFailTimeoutSellWrongOrderId() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(price - 1, hashedSecret);
    }

    function testControlTimeoutSellNotTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testFailTimeoutSellNotTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(price, hashedSecret, block.timestamp + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(price, hashedSecret);
    }

    function testTimeoutSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(price, hashedSecret, timeout, value);
        (bytes16 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
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
