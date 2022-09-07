// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "ds-test/test.sol";

import "./AcuityAccount.sol";
import "./AcuityAtomicSwap.sol";

contract AccountProxy {

    AcuityAccount acuityAccount;
    AcuityAtomicSwap acuityAtomicSwap;

    constructor (AcuityAccount _acuityAccount, AcuityAtomicSwap _acuityAtomicSwap) {
        acuityAccount = _acuityAccount;
        acuityAtomicSwap = _acuityAtomicSwap;
    }

    receive() payable external {}

    function setProxyAccount(address proxyAccount) external {
        acuityAccount.setProxyAccount(proxyAccount);
    }

    function depositStash(bytes32 assetId) payable external {
        acuityAtomicSwap.depositStash{value: msg.value}(assetId);
    }

    function withdrawStash(bytes32 assetId, uint value) external {
        acuityAtomicSwap.withdrawStash(assetId, value);
    }

    function withdrawStashAll(bytes32 assetId) external {
        acuityAtomicSwap.withdrawStashAll(assetId);
    }

    function lockSellProxy(address sender, address recipient, bytes32 hashedSecret, uint timeout, bytes32 stashAssetId, uint value, bytes32 buyLockId)
        external
    {
        acuityAtomicSwap.lockSellProxy(sender, recipient, hashedSecret, timeout, stashAssetId, value, buyLockId);
    }

    function unlockByRecipient(address sender, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwap.unlockByRecipient(sender, secret, timeout);
    }

    function unlockByRecipientProxy(address sender, address recipient, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwap.unlockByRecipientProxy(sender, recipient, secret, timeout);
    }

    function declineByRecipient(address sender, bytes32 hashedSecret, uint timeout) external {
        acuityAtomicSwap.declineByRecipient(sender, hashedSecret, timeout);
    }

    function timeoutStashProxy(address sender, address recipient, bytes32 hashedSecret, uint timeout, bytes32 stashAssetId)
        external
    {
        acuityAtomicSwap.timeoutStashProxy(sender, recipient, hashedSecret, timeout, stashAssetId);
    }

    function timeoutValueProxy(address sender, address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        acuityAtomicSwap.timeoutValueProxy(sender, recipient, hashedSecret, timeout);
    }

}

contract AcuityAtomicSwapTest is DSTest {
    AcuityAccount acuityAccount;
    AcuityAtomicSwap acuityAtomicSwap;
    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;

    receive() external payable {}

    function setUp() public {
        acuityAccount = new AcuityAccount();
        acuityAtomicSwap = new AcuityAtomicSwap(acuityAccount);
        account0 = new AccountProxy(acuityAccount, acuityAtomicSwap);
        account1 = new AccountProxy(acuityAccount, acuityAtomicSwap);
        account2 = new AccountProxy(acuityAccount, acuityAtomicSwap);
        account3 = new AccountProxy(acuityAccount, acuityAtomicSwap);
    }

    function testControlDepositStashZeroValue() public {
        account0.depositStash{value: 50}(hex"1234");
    }

    function testFailDepositStashZeroValue() public {
        account0.depositStash{value: 0}(hex"1234");
    }

    function testDepositStash() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        account1.depositStash{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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

    function testControlWithdrawStashNotZero() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 50);
    }

    function testFailWithdrawStashNotZero() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 0);
    }

    function testControlWithdrawStashNotEnough() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 50);
    }

    function testFailWithdrawStashNotEnough() public {
        account0.depositStash{value: 50}(hex"1234");
        account0.withdrawStash(hex"1234", 51);
    }

    function testWithdrawStash() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = address(account0).balance;
        account0.withdrawStash(hex"1234", 2);
        assertEq(startBalance + 2, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);

        account1.depositStash{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 48);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
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
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account0).balance;
        account0.withdrawStash(hex"1234", 45);
        assertEq(startBalance + 45, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = address(account1).balance;
        account1.withdrawStash(hex"1234", 40);
        assertEq(startBalance + 40, address(account1).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

    function testWithdrawStashAll() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash{value: 50}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = address(account0).balance;
        account0.withdrawStashAll(hex"1234");
        assertEq(startBalance + 50, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account1.depositStash{value: 40}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        account2.depositStash{value: 60}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account3.depositStash{value: 45}(hex"1234");
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        startBalance = address(account2).balance;
        account2.withdrawStashAll(hex"1234");
        assertEq(startBalance + 60, address(account2).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account0).balance;
        account0.withdrawStashAll(hex"1234");
        assertEq(startBalance, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account2).balance;
        account2.withdrawStashAll(hex"1234");
        assertEq(startBalance, address(account2).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = address(account3).balance;
        account3.withdrawStashAll(hex"1234");
        assertEq(startBalance + 45, address(account3).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = address(account0).balance;
        account0.withdrawStashAll(hex"1234");
        assertEq(startBalance, address(account0).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = address(account1).balance;
        account1.withdrawStashAll(hex"1234");
        assertEq(startBalance + 40, address(account1).balance);
        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

    function testControlLockBuyZeroValue() public {
        acuityAtomicSwap.lockBuy{value: 1}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
    }

    function testFailLockBuyZeroValue() public {
        acuityAtomicSwap.lockBuy{value: 0}(address(account0), hex"1234", block.timestamp + 1, hex"1234", 1);
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
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockBuy{value: value}(address(account0), hashedSecret, timeout, hex"1234", 1);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlLockSellZeroValue() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellZeroValue() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value + 1, hex"1234");
    }

    function testControlLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value * 2}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"3456", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value * 2}(hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwap.lockSell(address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testLockSell() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.depositStash{value: 50}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, hex"1234", value, hex"1234");

        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 40);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlLockSellProxyInvalidProxy() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyInvalidProxy() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellProxyZeroValue() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyZeroValue() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellProxyNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value + 1, hex"1234");
    }

    function testControlLockSellProxyLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value * 2}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        account1.lockSellProxy(address(this), address(account0), hex"3456", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwap.depositStash{value: value * 2}(hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        account1.lockSellProxy(address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testLockSellProxy() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.depositStash{value: 50}(assetId);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(this), address(account0), hashedSecret, timeout, hex"1234", value, hex"1234");

        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 40);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        account0.declineByRecipient(address(this), hashedSecret, timeout);
    }

    function testFailDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        account0.declineByRecipient(address(this), hashedSecret, timeout);
        account0.declineByRecipient(address(this), hashedSecret, timeout);
    }

    function testDeclineByRecipient() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 50);
        uint startBalance = address(this).balance;
        account0.declineByRecipient(address(this), hashedSecret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 40);
        assertEq(address(this).balance, startBalance + value);
    }

    function testControlUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testFailUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testControlUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testFailUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
    }

    function testUnlockBySender() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 50);
        uint startBalance = address(account0).balance;
        acuityAtomicSwap.unlockBySender(address(account0), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 40);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testFailUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testControlUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testFailUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(this), secret, timeout);
    }

    function testUnlockByRecipient() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 50);
        uint startBalance = address(account0).balance;
        account0.unlockByRecipient(address(this), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 40);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlUnlockByRecipientProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testFailUnlockByRecipientProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testControlUnlockByRecipientProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testFailUnlockByRecipientProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testControlUnlockByRecipientProxyTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testFailUnlockByRecipientProxyTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.depositStash{value: 10}(assetId);
        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
    }

    function testUnlockByRecipientProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwap).balance, 50);
        uint startBalance = address(account0).balance;
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(this), address(account0), secret, timeout);
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 40);
        assertEq(address(account0).balance, startBalance + 10);
    }

    function testControlTimeoutStashLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);
        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);
    }

    function testTimeoutStash() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        acuityAtomicSwap.timeoutStash(address(account0), hashedSecret, timeout, assetId);

        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 50);
        (accounts, values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }

    function testControlTimeoutStashProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashProxyNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testTimeoutStashProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(this), address(account0), hashedSecret, timeout, assetId);

        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwap).balance, 50);
        (accounts, values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }

    function testControlTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
    }

    function testTimeoutValue() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        uint startBalance = address(this).balance;
        acuityAtomicSwap.timeoutValue(address(account0), hashedSecret, timeout);
        assertEq(address(this).balance, startBalance + value);
    }

    function testControlTimeoutValueProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueProxyInvalidProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueProxyLockNotFound() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueProxyNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueProxyNotTimedOut() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
    }

    function testTimeoutValueProxy() public {
        bytes32 assetId = hex"1234";
        acuityAtomicSwap.depositStash{value: 50}(assetId);
        assertEq(acuityAtomicSwap.getStashValue(assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwap.lockSell(address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwap.getLockValue(address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        uint startBalance = address(this).balance;
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(this), address(account0), hashedSecret, timeout);
        assertEq(address(this).balance, startBalance + value);
    }

    function testGetStashes() public {
        account0.depositStash{value: 50}(hex"1234");
        account1.depositStash{value: 40}(hex"1234");
        account2.depositStash{value: 60}(hex"1234");
        account3.depositStash{value: 45}(hex"1234");

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwap.getStashes(hex"1234", 0, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 3);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 4);
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

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 0, 5);
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

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 1, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 1, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 1, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 1, 3);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 1, 4);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 2, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 2, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 2, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 2, 3);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 3, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 3, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 3, 2);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 4, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwap.getStashes(hex"1234", 4, 1);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

}
