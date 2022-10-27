// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "ds-test/test.sol";

import "./AcuityAtomicSwap.sol";

contract AccountProxy {

    AcuityAtomicSwap acuityAtomicSwap;

    constructor (AcuityAtomicSwap _acuityAtomicSwap) {
        acuityAtomicSwap = _acuityAtomicSwap;
    }

    receive() payable external {}

    function unlock(address creator, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwap.unlock(creator, secret, timeout);
    }

    function decline(address creator, bytes32 hashedSecret, uint timeout) external {
        acuityAtomicSwap.decline(creator, hashedSecret, timeout);
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

    function testControlLockBuyLockAlreadyExists() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"3456", block.timestamp + 1, hex"1234", 1);
    }

    function testFailLockBuyLockAlreadyExists() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encode(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockBuy{value: value}(address(account0), hashedSecret, timeout, hex"1234", 1);
        bytes32 lockId = keccak256(abi.encode(address(this), address(account0), hashedSecret, timeout));
        assertEq(acuityAtomicSwap.getLockValue(lockId), value);
    }

    function testControlLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.lockSell{value: value}(address(account0), hex"1234", block.timestamp + 1, hex"1234", hex"1234");
        acuityAtomicSwap.lockSell{value: value}(address(account0), hex"3456", block.timestamp + 1, hex"1234", hex"1234");
    }

    function testFailLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.lockSell{value: value}(address(account0), hex"1234", block.timestamp + 1, hex"1234", hex"1234");
        acuityAtomicSwap.lockSell{value: value}(address(account0), hex"1234", block.timestamp + 1, hex"1234", hex"1234");
    }

    function testLockSell() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encode(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        bytes32 lockId = keccak256(abi.encode(address(this), address(account0), hashedSecret, timeout));
        assertEq(acuityAtomicSwap.getLockValue(lockId), value);
    }

    function testControlDeclineLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.decline(address(this), hashedSecret, timeout);
    }

    function testFailDeclineLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.decline(address(this), hashedSecret, timeout);
        account0.decline(address(this), hashedSecret, timeout);
    }

    function testDecline() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        bytes32 lockId = keccak256(abi.encode(address(this), address(account0), hashedSecret, timeout));
        assertEq(acuityAtomicSwap.getLockValue(lockId), value);

        assertEq(address(acuityAtomicSwap).balance, value);
        uint startBalance = address(this).balance;
        account0.decline(address(this), hashedSecret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(lockId), 0);
        assertEq(address(acuityAtomicSwap).balance, 0);
        assertEq(address(this).balance, startBalance + value);
    }

    function testControlUnlockLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlock(address(this), secret, timeout);
    }

    function testFailUnlockLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlock(address(this), secret, timeout);
        account0.unlock(address(this), secret, timeout);
    }

    function testControlUnlockTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlock(address(this), secret, timeout);
    }

    function testFailUnlockTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlock(address(this), secret, timeout);
    }

    function testUnlock() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        bytes32 lockId = keccak256(abi.encode(address(this), address(account0), hashedSecret, timeout));
        assertEq(acuityAtomicSwap.getLockValue(lockId), value);

        assertEq(address(acuityAtomicSwap).balance, value);
        uint startBalance = address(account0).balance;
        account0.unlock(address(this), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(lockId), 0);
        assertEq(address(acuityAtomicSwap).balance, 0);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlRetrieveLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
    }

    function testFailRetrieveLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
    }

    function testControlRetrieveNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
    }

    function testFailRetrieveNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
    }

    function testRetrieve() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        bytes32 lockId = keccak256(abi.encode(address(this), address(account0), hashedSecret, timeout));
        assertEq(acuityAtomicSwap.getLockValue(lockId), value);
        uint startBalance = address(this).balance;
        acuityAtomicSwap.retrieve(address(account0), hashedSecret, timeout);
        assertEq(address(this).balance, startBalance + value);
    }

}
