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

    function deposit(bytes16 assetId) payable external {
        acuityAtomicSwapSell.deposit{value: msg.value}(assetId);
    }

    function withdraw(bytes16 assetId, uint value) external {
        acuityAtomicSwapSell.withdraw(assetId, value);
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

    function testDeposit() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.deposit{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        account1.deposit{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.deposit{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.deposit{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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

        account0.deposit{value: 10}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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

        account0.deposit{value: 1}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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
        account0.deposit{value: 50}(hex"1234");
        account0.withdraw(hex"1234", 50);
    }

    function testFailWithdrawNotEnough() public {
        account0.deposit{value: 50}(hex"1234");
        account0.withdraw(hex"1234", 51);
    }

    function testWithdraw() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.deposit{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = address(account0).balance;
        account0.withdraw(hex"1234", 2);
        assertEq(startBalance + 2, address(account0).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);

        account1.deposit{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.deposit{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 48);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.deposit{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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
        account2.withdraw(hex"1234", 40);
        assertEq(startBalance + 40, address(account2).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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
        account0.withdraw(hex"1234", 3);
        assertEq(startBalance + 3, address(account0).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
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
        account2.withdraw(hex"1234", 20);
        assertEq(startBalance + 20, address(account2).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        startBalance = address(account3).balance;
        account3.withdraw(hex"1234", 45);
        assertEq(startBalance + 45, address(account3).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account0).balance;
        account0.withdraw(hex"1234", 45);
        assertEq(startBalance + 45, address(account0).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = address(account1).balance;
        account1.withdraw(hex"1234", 40);
        assertEq(startBalance + 40, address(account1).balance);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(hex"1234", 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
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
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.deposit{value: 50}(assetId);
        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, address(account0), timeout, value);

        assertEq(acuityAtomicSwapSell.getDepositValue(assetId, address(this)), 40);
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
        bytes16 assetId = hex"1234";
        acuityAtomicSwapSell.deposit{value: 50}(assetId);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp + 1000;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(hex"1234", hashedSecret, address(account0), timeout, value);
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
        bytes16 assetId = hex"1234";
        acuityAtomicSwapSell.deposit{value: 50}(assetId);
        assertEq(acuityAtomicSwapSell.getDepositValue(assetId, address(this)), 50);

        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint256 timeout = block.timestamp;
        uint256 value = 10;

        acuityAtomicSwapSell.lockSell(assetId, hashedSecret, address(account0), timeout, value);
        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapSell.getDeposits(assetId, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        uint256 startBalance = address(account0).balance;
        acuityAtomicSwapSell.timeoutSell(assetId, hashedSecret, address(account0), timeout);

        assertEq(acuityAtomicSwapSell.getLockValue(address(this), hashedSecret, address(account0), timeout), 0);
        assertEq(address(acuityAtomicSwapSell).balance, 50);
        (accounts, values) = acuityAtomicSwapSell.getDeposits(assetId, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }
}
