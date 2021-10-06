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
        uint256 value = 50;
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        assertEq(address(acuityAtomicSwapSell).balance, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(address(this), hex"1234", hex"1234"), value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), value);
    }

    function testControlChangeOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234", value);
    }

    function testFailChangeOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.changeOrder(hex"1234", hex"1234", hex"5678", hex"1234", value + 1);
    }

    function testChangeOrder() public {
        uint256 value = 50;
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
        uint256 value = 50;
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
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234", value);
    }

    function testFailRemoveFromOrderNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.removeFromOrder(hex"1234", hex"1234", value + 1);
    }

    function testRemoveFromOrder() public {
        uint256 value = 50;
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
        uint256 value = 50;
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
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", block.timestamp + 1000, value + 10);
    }

    function testControlLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"3456", block.timestamp + 1000, 10);
    }

    function testFailLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", block.timestamp + 1000, 10);
    }

    function testLockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");

        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        assertEq(acuityAtomicSwapSell.getSellLock(orderId, hashedSecret, timeout), value);
    }

    function testControlUnlockSellTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, block.timestamp + 1000, 40);
        acuityAtomicSwapSell.unlockSell(orderId, secret, block.timestamp + 1000);
    }

    function testFailUnlockSellTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, block.timestamp, 40);
        acuityAtomicSwapSell.unlockSell(orderId, secret, block.timestamp);
    }

    function testUnlockSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getSellLock(orderId, hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        uint256 startBalance = address(this).balance;
        acuityAtomicSwapSell.unlockSell(orderId, secret, timeout);
        assertEq(acuityAtomicSwapSell.getSellLock(orderId, hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwapSell).balance, 40);
        assertEq(address(this).balance, startBalance + 10);
    }

    function testControlTimeoutSellNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(orderId, hashedSecret, block.timestamp);
    }

    function testFailTimeoutSellNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, block.timestamp + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(orderId, hashedSecret, block.timestamp + 1000);
    }

    function testTimeoutSell() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, timeout, value);
        assertEq(acuityAtomicSwapSell.getSellLock(orderId, hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 40);
        acuityAtomicSwapSell.timeoutSell(orderId, hashedSecret, timeout);
        assertEq(acuityAtomicSwapSell.getSellLock(orderId, hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
        assertEq(acuityAtomicSwapSell.getOrderValue(orderId), 50);
    }

}
