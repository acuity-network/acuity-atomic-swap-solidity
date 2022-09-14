// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "ds-test/test.sol";

import "./AcuityAccount.sol";
import "./AcuityAtomicSwap.sol";

contract AccountProxy {

    AcuityAtomicSwap acuityAtomicSwap;

    constructor (AcuityAtomicSwap _acuityAtomicSwap) {
        acuityAtomicSwap = _acuityAtomicSwap;
    }

    receive() payable external {}

    function unlockByRecipient(address sender, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwap.unlockByRecipient(sender, secret, timeout);
    }

    function declineByRecipient(address sender, bytes32 hashedSecret, uint timeout) external {
        acuityAtomicSwap.declineByRecipient(sender, hashedSecret, timeout);
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

    function testControllockBuyZeroValue() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
    }

    function testFaillockBuyZeroValue() public {
        acuityAtomicSwap.lockBuy{value: 0}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
    }

    function testControllockBuyLockAlreadyExists() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"3456", block.timestamp + 1, hex"1234", 1);
    }

    function testFaillockBuyLockAlreadyExists() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
    }

    function testlockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockBuy{value: value}(address(account0), hashedSecret, timeout, hex"1234", 1);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.declineByRecipient(address(this), hashedSecret, timeout);
    }

    function testFailDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.declineByRecipient(address(this), hashedSecret, timeout);
        account0.declineByRecipient(address(this), hashedSecret, timeout);
    }

    function testDeclineByRecipient() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, value);
        uint startBalance = address(this).balance;
        account0.declineByRecipient(address(this), hashedSecret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 0);
        assertEq(address(this).balance, startBalance + value);
    }

    function testControlUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testFailUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testControlUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testFailUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testUnlockBySender() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 10);
        uint startBalance = address(account0).balance;
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 0);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testFailUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testControlUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testFailUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testUnlockByRecipient() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, value);
        uint startBalance = address(account0).balance;
        account0.unlockByRecipient(address(this), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 0);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell{value: 10}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testTimeoutValue() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell{value: value}(address(account0), hashedSecret, timeout, assetId, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
        uint startBalance = address(this).balance;
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
        assertEq(address(this).balance, startBalance + value);
    }

}
