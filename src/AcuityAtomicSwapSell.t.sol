// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "ds-test/test.sol";

import "./AcuityAtomicSwapSell.sol";

contract AccountProxy {

    AcuityAtomicSwapSell acuityAtomicSwapSell;

    constructor (AcuityAtomicSwapSell _acuityAtomicSwapSell) {
        acuityAtomicSwapSell = _acuityAtomicSwapSell;
    }

    receive() payable external {
    }

    function unlockSell(address seller, bytes32 secret, uint256 timeout) external {
        acuityAtomicSwapSell.unlockSell(seller, secret, timeout);
    }
}

contract AcuityAtomicSwapSellTest is DSTest {
    AcuityAtomicSwapSell acuityAtomicSwapSell;
    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapSell = new AcuityAtomicSwapSell();
        account0 = new AccountProxy(acuityAtomicSwapSell);
        account1 = new AccountProxy(acuityAtomicSwapSell);
        account2 = new AccountProxy(acuityAtomicSwapSell);
        account3 = new AccountProxy(acuityAtomicSwapSell);
    }

    function testSetAcuAddress() public {
        acuityAtomicSwapSell.setAcuAddress(hex"1234");
        assertEq(acuityAtomicSwapSell.getAcuAddress(address(this)), hex"1234");
    }

/*

    function testControlLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwapSell.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, value + 10);
    }

    function testControlLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"3456", address(this), block.timestamp + 1000, 10);
    }

    function testFailLockSellAlreadyInUse() public {
        acuityAtomicSwapSell.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
    }
*/

    function testLockSell() public {
        bytes16 chainIdAdapterIdAssetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell{value: 50}(hex"1234", hashedSecret, address(account0), timeout);

        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), value);
    }

/*
    function testControlUnlockSellTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp + 1000, 40);
        acuityAtomicSwapSell.unlockSell(orderId, secret, block.timestamp + 1000);
    }

    function testFailUnlockSellTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp, 40);
        acuityAtomicSwapSell.unlockSell(orderId, secret, block.timestamp);
    }
*/

    function testUnlockSell() public {
        bytes16 chainIdAdapterIdAssetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell{value: 10}(hex"1234", hashedSecret, address(account0), timeout);
        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), value);

        assertEq(address(acuityAtomicSwapSell).balance, 50);
        uint256 startBalance = address(account0).balance;
        account0.unlockSell(address(this), secret, timeout);
        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), 0);
        assertEq(address(acuityAtomicSwapSell).balance, 40);
        assertEq(address(account0).balance, startBalance + 10);
    }

/*
    function testControlTimeoutSellNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp, 10);
        acuityAtomicSwapSell.timeoutSell(orderId, hashedSecret, address(this), block.timestamp);
    }

    function testFailTimeoutSellNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwapSell.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwapSell.lockSell(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp + 1000, 10);
        acuityAtomicSwapSell.timeoutSell(orderId, hashedSecret, address(this), block.timestamp + 1000);
    }
*/
    function testTimeoutSell() public {
        bytes16 chainIdAdapterIdAssetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell{value: 50}(chainIdAdapterIdAssetId, hashedSecret, address(account0), timeout);
        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), value);

        uint256 startBalance = address(account0).balance;
        acuityAtomicSwapSell.timeoutSell(chainIdAdapterIdAssetId, hashedSecret, address(account0), timeout);

        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
    }
}
