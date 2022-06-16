// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

import "ds-test/test.sol";

import "./AcuityAtomicSwap.sol";

contract AccountProxy {

    AcuityAtomicSwap acuityAtomicSwap;

    constructor (AcuityAtomicSwap _acuityAtomicSwap) {
        acuityAtomicSwap = _acuityAtomicSwap;
    }

    receive() payable external {
    }

    function depositStash(bytes32 assetId) payable external {
        acuityAtomicSwap.depositStash{value: msg.value}(assetId);
    }

    function withdrawStash(bytes32 assetId, uint value) external {
        acuityAtomicSwap.withdrawStash(assetId, value);
    }

    function unlockValue(address seller, bytes32 secret, uint256 timeout) external {
        acuityAtomicSwap.unlockValue(seller, secret, timeout);
    }
}

contract AcuityAtomicSwapTest is DSTest {
    AcuityAtomicSwap acuityAtomicSwap;
    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwap = new AcuityAtomicSwap();
        account0 = new AccountProxy(acuityAtomicSwap);
        account1 = new AccountProxy(acuityAtomicSwap);
        account2 = new AccountProxy(acuityAtomicSwap);
        account3 = new AccountProxy(acuityAtomicSwap);
    }

    function testControlDepositStashZeroValue() public {
        account0.depositStash{value: 50}(hex"1234");
    }

    function testFailDepositStashZeroValue() public {
        account0.depositStash{value: 0}(hex"1234");
    }

    function testDepositStash() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        account1.depositStash{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);
        assertEq(accounts[3], address(account1));
        assertEq(values[3], 40);

        account0.depositStash{value: 10}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 60);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);
        assertEq(accounts[3], address(account1));
        assertEq(values[3], 40);

        account0.depositStash{value: 1}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 61);
        assertEq(accounts[1], address(account2));
        assertEq(values[1], 60);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);
        assertEq(accounts[3], address(account1));
        assertEq(values[3], 40);
    }

    function testControlWithdrawNotEnough() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 50);
    }

    function testFailWithdrawNotEnough() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 51);
    }

    function testWithdraw() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = address(account0).balance;
        account0.withdrawStash(hex"1234", 2);
        assertEq(startBalance + 2, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);

        account1.depositStash{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 48);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 48);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);
        assertEq(accounts[3], address(account1));
        assertEq(values[3], 40);

        startBalance = address(account2).balance;
        account2.withdrawStash(hex"1234", 40);
        assertEq(startBalance + 40, address(account2).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);
        assertEq(accounts[3], address(account2));
        assertEq(values[3], 20);

        startBalance = address(account0).balance;
        account0.withdrawStash(hex"1234", 3);
        assertEq(startBalance + 3, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 4);
        assertEq(values.length, 4);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);
        assertEq(accounts[3], address(account2));
        assertEq(values[3], 20);

        startBalance = address(account2).balance;
        account2.withdrawStash(hex"1234", 20);
        assertEq(startBalance + 20, address(account2).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        startBalance = address(account3).balance;
        account3.withdrawStash(hex"1234", 45);
        assertEq(startBalance + 45, address(account3).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account0).balance;
        account0.withdrawStash(hex"1234", 45);
        assertEq(startBalance + 45, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = address(account1).balance;
        account1.withdrawStash(hex"1234", 40);
        assertEq(startBalance + 40, address(account1).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

/*

    function testControlLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwap.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, value);
    }

    function testFailLockSellNotBigEnough() public {
        uint256 value = 50;
        acuityAtomicSwap.addToOrder{value: value}(hex"1234", hex"1234");
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, value + 10);
    }

    function testControlLockSellAlreadyInUse() public {
        acuityAtomicSwap.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"3456", address(this), block.timestamp + 1000, 10);
    }

    function testFailLockSellAlreadyInUse() public {
        acuityAtomicSwap.addToOrder{value: 20}(hex"1234", hex"1234");
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hex"1234", address(this), block.timestamp + 1000, 10);
    }
*/

    function testLockStash() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwap.depositStash{value: 50}(assetId);
        acuityAtomicSwap.lockStash(address(account0), hashedSecret, timeout, hex"1234", value);

        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 40);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
    }

/*
    function testControlUnlockValueTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwap.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp + 1000, 40);
        acuityAtomicSwap.unlockValue(orderId, secret, block.timestamp + 1000);
    }

    function testFailUnlockValueTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwap.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp, 40);
        acuityAtomicSwap.unlockValue(orderId, secret, block.timestamp);
    }
*/

    function testUnlockValue() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwap.lockStash(address(account0), hashedSecret, timeout, hex"1234", value);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 50);
        uint256 startBalance = address(account0).balance;
        account0.unlockValue(address(this), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 40);
        assertEq(address(account0).balance, startBalance + 10);
    }

/*
    function testControlTimeoutValueNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwap.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp, 10);
        acuityAtomicSwap.timeoutValue(orderId, hashedSecret, address(this), block.timestamp);
    }

    function testFailTimeoutValueNotTimedOut() public {
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(this, bytes32(hex"1234"), bytes32(hex"1234"))));
        acuityAtomicSwap.addToOrder{value: 50}(hex"1234", hex"1234");
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        acuityAtomicSwap.lockValue(hex"1234", hex"1234", hashedSecret, address(this), block.timestamp + 1000, 10);
        acuityAtomicSwap.timeoutValue(orderId, hashedSecret, address(this), block.timestamp + 1000);
    }
*/
    function testTimeoutStash() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwap.lockStash(address(account0), hashedSecret, timeout, assetId, value);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(assetId, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);

        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 50);
        (accounts, values) = acuityAtomicSwap.getStashes(assetId, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }
}
