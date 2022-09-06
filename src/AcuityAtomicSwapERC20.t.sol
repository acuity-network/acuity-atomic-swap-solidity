// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "ds-test/test.sol";

import "./AcuityAccount.sol";
import "./AcuityAtomicSwapERC20.sol";
import "./ERC20.sol";

contract AccountProxy {

    AcuityAccount acuityAccount;
    AcuityAtomicSwapERC20 acuityAtomicSwapERC20;

    constructor (AcuityAccount _acuityAccount, AcuityAtomicSwapERC20 _acuityAtomicSwapERC20) {
        acuityAccount = _acuityAccount;
        acuityAtomicSwapERC20 = _acuityAtomicSwapERC20;
    }

    function setProxyAccount(address proxyAccount) external {
        acuityAccount.setProxyAccount(proxyAccount);
    }

    function depositStash(address sellToken, bytes32 assetId, uint value) payable external {
        acuityAtomicSwapERC20.depositStash(sellToken, assetId, value);
    }

    function withdrawStash(address sellToken, bytes32 assetId, uint value) external {
        acuityAtomicSwapERC20.withdrawStash(sellToken, assetId, value);
    }

    function withdrawStashAll(address sellToken, bytes32 assetId) external {
        acuityAtomicSwapERC20.withdrawStashAll(sellToken, assetId);
    }

    function lockSellProxy(address sellToken, address sender, address recipient, bytes32 hashedSecret, uint timeout, bytes32 stashAssetId, uint value, bytes32 buyLockId)
        external
    {
        acuityAtomicSwapERC20.lockSellProxy(sellToken, sender, recipient, hashedSecret, timeout, stashAssetId, value, buyLockId);
    }

    function unlockByRecipient(address token, address sender, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.unlockByRecipient(token, sender, secret, timeout);
    }

    function unlockByRecipientProxy(address token, address sender, address recipient, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.unlockByRecipientProxy(token, sender, recipient, secret, timeout);
    }

    function declineByRecipient(address token, address sender, bytes32 hashedSecret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.declineByRecipient(token, sender, hashedSecret, timeout);
    }

    function timeoutStashProxy(address token, address sender, address recipient, bytes32 hashedSecret, uint timeout, bytes32 stashAssetId)
        external
    {
        acuityAtomicSwapERC20.timeoutStashProxy(token, sender, recipient, hashedSecret, timeout, stashAssetId);
    }

    function timeoutValueProxy(address token, address sender, address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.timeoutValueProxy(token, sender, recipient, hashedSecret, timeout);
    }

}

contract DummyToken is ERC20 {

    mapping (address => uint) balances;

    constructor(address[] memory accounts) {
        for (uint i = 0; i < accounts.length; i++) {
            balances[accounts[i]] = 1000;
        }
    }

    function name() external view returns (string memory) {}
    function symbol() external view returns (string memory) {}
    function decimals() external view returns (uint8) {}
    function totalSupply() external view returns (uint) {}
    function balanceOf(address owner) external view returns (uint) {
        return balances[owner];
    }
    function transfer(address to, uint value) external returns (bool success) {
        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }
    function transferFrom(address from, address to, uint value) external returns (bool success) {
        balances[from] -= value;
        balances[to] += value;
        return true;
    }
    function approve(address spender, uint value) external returns (bool) {}
    function allowance(address owner, address spender) external view returns (uint remaining) {}
}

contract AcuityAtomicSwapERC20Test is DSTest {
    AcuityAccount acuityAccount;
    AcuityAtomicSwapERC20 acuityAtomicSwapERC20;
    DummyToken dummyToken;
    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;

    receive() external payable {}

    function setUp() public {
        acuityAccount = new AcuityAccount();
        acuityAtomicSwapERC20 = new AcuityAtomicSwapERC20(acuityAccount);
        account0 = new AccountProxy(acuityAccount, acuityAtomicSwapERC20);
        account1 = new AccountProxy(acuityAccount, acuityAtomicSwapERC20);
        account2 = new AccountProxy(acuityAccount, acuityAtomicSwapERC20);
        account3 = new AccountProxy(acuityAccount, acuityAtomicSwapERC20);

        address[] memory accounts = new address[](5);
        accounts[0] = address(this);
        accounts[1] = address(account0);
        accounts[2] = address(account1);
        accounts[3] = address(account2);
        accounts[4] = address(account3);
        dummyToken = new DummyToken(accounts);
    }

    function testControlDepositStashZeroValue() public {
        account0.depositStash(address(dummyToken), hex"1234", 50);
    }

    function testFailDepositStashZeroValue() public {
        account0.depositStash(address(dummyToken), hex"1234", 0);
    }

    function testDepositStash() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash(address(dummyToken), hex"1234", 50);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        account1.depositStash(address(dummyToken), hex"1234", 40);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash(address(dummyToken), hex"1234", 60);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash(address(dummyToken), hex"1234", 45);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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

        account0.depositStash(address(dummyToken), hex"1234", 10);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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

        account0.depositStash(address(dummyToken), hex"1234", 1);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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
        account0.depositStash(address(dummyToken), hex"1234", 50);
        account0.withdrawStash(address(dummyToken), hex"1234", 50);
    }

    function testFailWithdrawStashNotZero() public {
        account0.depositStash(address(dummyToken), hex"1234", 50);
        account0.withdrawStash(address(dummyToken), hex"1234", 0);
    }

    function testControlWithdrawStashNotEnough() public {
        account0.depositStash(address(dummyToken), hex"1234", 50);
        account0.withdrawStash(address(dummyToken), hex"1234", 50);
    }

    function testFailWithdrawStashNotEnough() public {
        account0.depositStash(address(dummyToken), hex"1234", 50);
        account0.withdrawStash(address(dummyToken), hex"1234", 51);
    }

    function testWithdrawStash() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash(address(dummyToken), hex"1234", 50);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStash(address(dummyToken), hex"1234", 2);
        assertEq(startBalance + 2, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);

        account1.depositStash(address(dummyToken), hex"1234", 40);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 48);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account2.depositStash(address(dummyToken), hex"1234", 60);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 48);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        account3.depositStash(address(dummyToken), hex"1234", 45);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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

        startBalance = dummyToken.balanceOf(address(account2));
        account2.withdrawStash(address(dummyToken), hex"1234", 40);
        assertEq(startBalance + 40, dummyToken.balanceOf(address(account2)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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

        startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStash(address(dummyToken), hex"1234", 3);
        assertEq(startBalance + 3, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
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

        startBalance = dummyToken.balanceOf(address(account2));
        account2.withdrawStash(address(dummyToken), hex"1234", 20);
        assertEq(startBalance + 20, dummyToken.balanceOf(address(account2)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        startBalance = dummyToken.balanceOf(address(account3));
        account3.withdrawStash(address(dummyToken), hex"1234", 45);
        assertEq(startBalance + 45, dummyToken.balanceOf(address(account3)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStash(address(dummyToken), hex"1234", 45);
        assertEq(startBalance + 45, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = dummyToken.balanceOf(address(account1));
        account1.withdrawStash(address(dummyToken), hex"1234", 40);
        assertEq(startBalance + 40, dummyToken.balanceOf(address(account1)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

    function testWithdrawStashAll() public {
        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account0.depositStash(address(dummyToken), hex"1234", 50);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        uint startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance + 50, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        account1.depositStash(address(dummyToken), hex"1234", 40);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        account2.depositStash(address(dummyToken), hex"1234", 60);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        account3.depositStash(address(dummyToken), hex"1234", 45);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        startBalance = dummyToken.balanceOf(address(account2));
        account2.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance + 60, dummyToken.balanceOf(address(account2)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = dummyToken.balanceOf(address(account2));
        account2.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance, dummyToken.balanceOf(address(account2)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        startBalance = dummyToken.balanceOf(address(account3));
        account3.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance + 45, dummyToken.balanceOf(address(account3)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = dummyToken.balanceOf(address(account0));
        account0.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance, dummyToken.balanceOf(address(account0)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        startBalance = dummyToken.balanceOf(address(account1));
        account1.withdrawStashAll(address(dummyToken), hex"1234");
        assertEq(startBalance + 40, dummyToken.balanceOf(address(account1)));
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 50);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

    function testControlLockBuyZeroValue() public {
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 1, 1);
    }

    function testFailLockBuyZeroValue() public {
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 1, 0);
    }

    function testControlLockBuyLockAlreadyExists() public {
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 1, 1);
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"3456", block.timestamp + 1, hex"1234", 1, 1);
    }

    function testFailLockBuyLockAlreadyExists() public {
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 1, 1);
        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 1, 1);
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockBuy(address(dummyToken), address(account0), hashedSecret, timeout, hex"1234", 1, value);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlLockSellZeroValue() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellZeroValue() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value + 1, hex"1234");
    }

    function testControlLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value * 2);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"3456", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value * 2);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testLockSell() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, hex"1234", value, hex"1234");

        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 40);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlLockSellProxyInvalidProxy() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyInvalidProxy() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testControlLockSellProxyZeroValue() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyZeroValue() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellProxyNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyNotBigEnough() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value + 1, hex"1234");
    }

    function testControlLockSellProxyLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value * 2);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"3456", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellProxyLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.depositStash(address(dummyToken), hex"1234", value * 2);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testLockSellProxy() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        acuityAccount.setProxyAccount(address(account1));
        account1.lockSellProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, hex"1234", value, hex"1234");

        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 40);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);
    }

    function testDeclineByRecipient() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        uint startBalance = dummyToken.balanceOf(address(this));
        account0.declineByRecipient(address(dummyToken), address(this), hashedSecret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 40);
        assertEq(dummyToken.balanceOf(address(this)), startBalance + value);
    }

    function testControlUnlockBySenderTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testFailUnlockBySenderTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testUnlockBySender() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        uint startBalance = dummyToken.balanceOf(address(account0));
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 40);
        assertEq(dummyToken.balanceOf(address(account0)), startBalance + 10);
    }

    function testControlUnlockByRecipientTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testFailUnlockByRecipientTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testUnlockByRecipient() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        uint startBalance = dummyToken.balanceOf(address(account0));
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 40);
        assertEq(dummyToken.balanceOf(address(account0)), startBalance + 10);
    }

    function testControlUnlockByRecipientProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(dummyToken), address(this), address(account0), secret, timeout);
    }

    function testFailUnlockByRecipientProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.unlockByRecipientProxy(address(dummyToken), address(this), address(account0), secret, timeout);
    }

    function testControlUnlockByRecipientProxyTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(dummyToken), address(this), address(account0), secret, timeout);
    }

    function testFailUnlockByRecipientProxyTimedOut() public {
        bytes16 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 10);
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(dummyToken), address(this), address(account0), secret, timeout);
    }

    function testUnlockByRecipientProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        uint startBalance = dummyToken.balanceOf(address(account0));
        account0.setProxyAccount(address(account1));
        account1.unlockByRecipientProxy(address(dummyToken), address(this), address(account0), secret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 40);
        assertEq(dummyToken.balanceOf(address(account0)), startBalance + 10);
    }

    function testControlTimeoutStashNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutStash(address(dummyToken), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutStash(address(dummyToken), address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashZeroValue() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutStash(address(dummyToken), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashZeroValue() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 0, hex"1234");
        acuityAtomicSwapERC20.timeoutStash(address(dummyToken), address(account0), hashedSecret, timeout, assetId);
    }

    function testTimeoutStash() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        acuityAtomicSwapERC20.timeoutStash(address(dummyToken), address(account0), hashedSecret, timeout, assetId);

        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }

    function testControlTimeoutStashProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashProxyNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testControlTimeoutStashProxyZeroValue() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testFailTimeoutStashProxyZeroValue() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 0, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);
    }

    function testTimeoutStashProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutStashProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout, assetId);

        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 50);
        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 50);
    }

    function testControlTimeoutValueNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testTimeoutValue() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        uint startBalance = dummyToken.balanceOf(address(this));
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
        assertEq(dummyToken.balanceOf(address(this)), startBalance + value);
    }

    function testControlTimeoutValueProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueProxyInvalidProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account1.timeoutValueProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueProxyNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueProxyNotTimedOut() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout);
    }

    function testTimeoutValueProxy() public {
        bytes16 assetId = hex"1234";
        acuityAtomicSwapERC20.depositStash(address(dummyToken), assetId, 50);
        assertEq(acuityAtomicSwapERC20.getStashValue(address(dummyToken), assetId, address(this)), 50);

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), assetId, 0, 50);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(values[0], 40);

        uint startBalance = dummyToken.balanceOf(address(this));
        acuityAccount.setProxyAccount(address(account1));
        account1.timeoutValueProxy(address(dummyToken), address(this), address(account0), hashedSecret, timeout);
        assertEq(dummyToken.balanceOf(address(this)), startBalance + value);
    }

    function testGetStashes() public {
        account0.depositStash(address(dummyToken), hex"1234", 50);
        account1.depositStash(address(dummyToken), hex"1234", 40);
        account2.depositStash(address(dummyToken), hex"1234", 60);
        account3.depositStash(address(dummyToken), hex"1234", 45);

        (address[] memory accounts, uint[] memory values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 3);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(values[0], 60);
        assertEq(accounts[1], address(account0));
        assertEq(values[1], 50);
        assertEq(accounts[2], address(account3));
        assertEq(values[2], 45);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 4);
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

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 0, 5);
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

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 1, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 1, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 1, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 1, 3);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 1, 4);
        assertEq(accounts.length, 3);
        assertEq(values.length, 3);
        assertEq(accounts[0], address(account0));
        assertEq(values[0], 50);
        assertEq(accounts[1], address(account3));
        assertEq(values[1], 45);
        assertEq(accounts[2], address(account1));
        assertEq(values[2], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 2, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 2, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 2, 2);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 2, 3);
        assertEq(accounts.length, 2);
        assertEq(values.length, 2);
        assertEq(accounts[0], address(account3));
        assertEq(values[0], 45);
        assertEq(accounts[1], address(account1));
        assertEq(values[1], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 3, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 3, 1);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 3, 2);
        assertEq(accounts.length, 1);
        assertEq(values.length, 1);
        assertEq(accounts[0], address(account1));
        assertEq(values[0], 40);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 4, 0);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);

        (accounts, values) = acuityAtomicSwapERC20.getStashes(address(dummyToken), hex"1234", 4, 1);
        assertEq(accounts.length, 0);
        assertEq(values.length, 0);
    }

}
