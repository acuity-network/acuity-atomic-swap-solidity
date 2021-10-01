// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "ds-test/test.sol";

import "./AcuityAtomicSwapSell.sol";

contract AcuityAtomicSwapSellTest is DSTest {
    AcuityAtomicSwapSell acuityAtomicSwapSell;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapSell = new AcuityAtomicSwapSell();
    }

    function testAddToOrder() public {
        uint64 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlChangeOrderNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234", value);
    }

    function testFailChangeOrderNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234", value + 1);
    }

    function testChangeOrder() public {
        uint64 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"5678"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234", 10);
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"5678", hex"1234"), 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), 10);
    }

    function testChangeOrderNoValue() public {
        uint64 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"5678"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234");
        assertEq(address(this).balance, startBalance);
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"5678", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(newOrderId), value);
    }

    function testControlRemoveFromOrderNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234", value);
    }

    function testFailRemoveFromOrderNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234", value + 1);
    }

    function testRemoveFromOrder() public {
        uint64 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234", 10);
        assertEq(address(this).balance, startBalance + 10);
        assertEq(address(acuityAtomicSwapSell).balance, value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value - 10);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value - 10);
    }

    function testRemoveFromOrderNoValue() public {
        uint64 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234");
        assertEq(address(this).balance, startBalance + value);
        assertEq(address(acuityAtomicSwapSell).balance, 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), 0);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 0);
    }

    function testControlLockSellNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value * 1e9}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", value, uint32(block.timestamp) + 1000);
    }

    function testFailLockSellNotBigEnough() public {
        uint64 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value * 1e9}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", value + 10, uint32(block.timestamp) + 1000);
    }

    function testControlLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20 * 1e9}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", 10, uint32(block.timestamp) + 1000);
        acuityAtomicSwapSell.lockSell(hex"3456", hex"1234", hex"1234", 10, uint32(block.timestamp) + 1000);
    }

    function testFailLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20 * 1e9}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", 10, uint32(block.timestamp) + 1000);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", 10, uint32(block.timestamp) + 1000);
    }

    function testLockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint32 timeout = uint32(block.timestamp) + 1000;
        uint64 value = 10;
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", value, timeout);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40 * 1e9);
        AcuityAtomicSwapSell.SellLock memory sellLock = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(sellLock.orderId, orderId);
        assertEq(sellLock.value, value);
        assertEq(sellLock.timeout, timeout);
    }

    function testControlUnlockSellTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 40, uint32(block.timestamp) + 1000);
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testFailUnlockSellTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 40, uint32(block.timestamp));
        acuityAtomicSwapSell.unlockSell(secret);
    }

    function testUnlockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint32 timeout = uint32(block.timestamp) + 1000;
        uint64 value = 10;

        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", value, timeout);
        AcuityAtomicSwapSell.SellLock memory sellLock = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(sellLock.orderId, orderId);
        assertEq(sellLock.value, value);
        assertEq(sellLock.timeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50 * 1e9);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.unlockSell(secret);
        sellLock = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(sellLock.orderId, 0);
        assertEq(sellLock.value, 0);
        assertEq(sellLock.timeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 40 * 1e9);
        assertEq(address(this).balance, startBalance + 10 * 1e9);
    }

    function testControlTimeoutSellWrongOrderId() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 10, uint32(block.timestamp));
        acuityAtomicSwapSell.timeoutSell(hashedSecret, hex"1234", hex"1234");
    }

    function testFailTimeoutSellWrongOrderId() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 10, uint32(block.timestamp));
        acuityAtomicSwapSell.timeoutSell(hashedSecret, hex"5678", hex"1234");
    }

    function testControlTimeoutSellNotTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 10, uint32(block.timestamp));
        acuityAtomicSwapSell.timeoutSell(hashedSecret, hex"1234", hex"1234");
    }

    function testFailTimeoutSellNotTimedOut() public {
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", 10, uint32(block.timestamp) + 1000);
        acuityAtomicSwapSell.timeoutSell(hashedSecret, hex"1234", hex"1234");
    }

    function testTimeoutSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50 * 1e9}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint32 timeout = uint32(block.timestamp);
        uint64 value = 10;

        acuityAtomicSwapSell.lockSell(hashedSecret, hex"1234", hex"1234", value, timeout);
        AcuityAtomicSwapSell.SellLock memory sellLock = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(sellLock.orderId, orderId);
        assertEq(sellLock.value, value);
        assertEq(sellLock.timeout, timeout);

        assertEq(address(acuityAtomicSwapSell).balance, 50 * 1e9);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40 * 1e9);
        acuityAtomicSwapSell.timeoutSell(hashedSecret, hex"1234", hex"1234");
        sellLock = acuityAtomicSwapSell.getSellLock(hashedSecret);
        assertEq(sellLock.orderId, 0);
        assertEq(sellLock.value, 0);
        assertEq(sellLock.timeout, 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50 * 1e9);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 50 * 1e9);
    }

}
