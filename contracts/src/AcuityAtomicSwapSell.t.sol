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
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlChangeOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"5678", value);
    }

    function testFailChangeOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"5678", value + 1);
    }

    function testChangeOrder() public {
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"5678"))));
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"5678", 10);
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"5678"), 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), 10);
    }

    function testChangeOrderNoValue() public {
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"5678"))));
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"5678");
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"5678"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), value);
    }

    function testControlRemoveFromOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", value);
    }

    function testFailRemoveFromOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", value + 1);
    }

    function testRemoveFromOrder() public {
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(hex"1234", 10);
        assertEq(address(this).balance, startBalance + 10);
        assertEq(address(acuityAtomicSwapSell).balance, value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
    }

    function testRemoveFromOrderNoValue() public {
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(hex"1234");
        assertEq(address(this).balance, startBalance + value);
        assertEq(address(acuityAtomicSwapSell).balance, 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234"), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
    }

    function testControlLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", block.timestamp + 1000, value + 10);
    }

    function testControlLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"3456", block.timestamp + 1000, 10);
    }

    function testFailLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", block.timestamp + 1000, 10);
    }

    function testLockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        (bytes32 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);
    }

    function testControlUnlockSellTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp + 1000, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testFailUnlockSellTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp, 40);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testUnlockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, timeout, value);
        (bytes32 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
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
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(hex"1234", hashedSecret);
    }

    function testFailTimeoutSellWrongOrderId() public {
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(hex"5678", hashedSecret);
    }

    function testControlTimeoutSellNotTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(hex"1234", hashedSecret);
    }

    function testFailTimeoutSellNotTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, block.timestamp + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(hex"1234", hashedSecret);
    }

    function testTimeoutSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, timeout, value);
        (bytes32 lockOrderId, uint256 lockValue, uint256 lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, orderId);
        assertEq(lockValue, value);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        acuityAtomicSwapSell.timeoutSell(hex"1234", hashedSecret);
        (lockOrderId, lockValue, lockTimeout) = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(lockOrderId, 0);
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 50);
    }

}
