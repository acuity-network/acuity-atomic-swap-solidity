// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

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
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlChangeOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.changeOrder(0, price, price + 1, value);
    }

    function testFailChangeOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.changeOrder(0, price, price + 1, value + 1);
    }

    function testChangeOrder() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        uint256 newPrice = 4;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), newPrice)));
        acuityAtomicSwapSell.changeOrder(0, price, newPrice, 10);
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, newPrice), 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), 10);
    }

    function testChangeOrderNoValue() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        uint256 newPrice = 4;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), newPrice)));
        acuityAtomicSwapSell.changeOrder(0, price, newPrice);
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, newPrice), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), value);
    }

    function testControlRemoveFromOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.removeFromOrder(0, price, value);
    }

    function testFailRemoveFromOrderNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.removeFromOrder(0, price, value + 1);
    }

    function testRemoveFromOrder() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(0, price, 10);
        assertEq(address(this).balance, startBalance + 10);
        assertEq(address(acuityAtomicSwapSell).balance, value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
    }

    function testRemoveFromOrderNoValue() public {
        uint256 price = 5;
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(0, price);
        assertEq(address(this).balance, startBalance + value);
        assertEq(address(acuityAtomicSwapSell).balance, 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), 0, price), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
    }

    function testControlLockSellNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.lockSell(0, price, hex"1234", block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 price = 5;
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(0, price);
        acuityAtomicSwapSell.lockSell(0, price, hex"1234", block.timestamp + 1000, value + 10);
    }

    function testControlLockSellAlreadyInUse() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 20}(0, price);
        acuityAtomicSwapSell.lockSell(0, price, hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(0, price, hex"3456", block.timestamp + 1000, 10);
    }

    function testFailLockSellAlreadyInUse() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 20}(0, price);
        acuityAtomicSwapSell.lockSell(0, price, hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(0, price, hex"1234", block.timestamp + 1000, 10);
    }

    function testLockSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        (bytes16 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);
    }

    function testControlUnlockSellTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp + 1000, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testFailUnlockSellTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testUnlockSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, timeout, value);
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
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(0, price, hashedSecret);
    }

    function testFailTimeoutSellWrongOrderId() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(0, price - 1, hashedSecret);
    }

    function testControlTimeoutSellNotTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(0, price, hashedSecret);
    }

    function testFailTimeoutSellNotTimedOut() public {
        uint256 price = 5;
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, block.timestamp + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(0, price, hashedSecret);
    }

    function testTimeoutSell() public {
        uint256 price = 5;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, uint256(0), price)));
        acuityAtomicSwapSell.addToOrder{value: 50}(0, price);
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(0, price, hashedSecret, timeout, value);
        (bytes16 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        acuityAtomicSwapSell.timeoutSell(0, 5, hashedSecret);
        (lockOrderId, lockValue, lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, 0);
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 50);
    }

}
