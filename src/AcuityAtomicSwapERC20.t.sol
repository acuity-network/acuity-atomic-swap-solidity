// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "ds-test/test.sol";

import "./AcuityAtomicSwapERC20.sol";
import "./ERC20.sol";

contract AccountProxy {

    AcuityAtomicSwapERC20 acuityAtomicSwapERC20;

    constructor (AcuityAtomicSwapERC20 _acuityAtomicSwapERC20) {
        acuityAtomicSwapERC20 = _acuityAtomicSwapERC20;
    }

    function unlockByRecipient(address token, address sender, bytes32 secret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.unlockByRecipient(token, sender, secret, timeout);
    }

    function declineByRecipient(address token, address sender, bytes32 hashedSecret, uint timeout)
        external
    {
        acuityAtomicSwapERC20.declineByRecipient(token, sender, hashedSecret, timeout);
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
    AcuityAtomicSwapERC20 acuityAtomicSwapERC20;
    DummyToken dummyToken;
    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapERC20 = new AcuityAtomicSwapERC20();
        account0 = new AccountProxy(acuityAtomicSwapERC20);
        account1 = new AccountProxy(acuityAtomicSwapERC20);
        account2 = new AccountProxy(acuityAtomicSwapERC20);
        account3 = new AccountProxy(acuityAtomicSwapERC20);

        address[] memory accounts = new address[](5);
        accounts[0] = address(this);
        accounts[1] = address(account0);
        accounts[2] = address(account1);
        accounts[3] = address(account2);
        accounts[4] = address(account3);
        dummyToken = new DummyToken(accounts);
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
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 50, hex"1234");
    }

    function testFailLockSellZeroValue() public {
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", 0, hex"1234");
    }

    function testControlLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"3456", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testFailLockSellLockAlreadyExists() public {
        uint value = 50;
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hex"1234", block.timestamp + 1, hex"1234", value, hex"1234");
    }

    function testLockSell() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");

        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);
    }

    function testControlDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        account0.declineByRecipient(address(dummyToken), address(this), hashedSecret, timeout);
    }

    function testFailDeclineByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        account0.declineByRecipient(address(dummyToken), address(this), hashedSecret, timeout);
        account0.declineByRecipient(address(dummyToken), address(this), hashedSecret, timeout);
    }

    function testDeclineByRecipient() public {
        bytes32 assetId = hex"1234";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 10);
        uint startBalance = dummyToken.balanceOf(address(this));
        account0.declineByRecipient(address(dummyToken), address(this), hashedSecret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 0);
        assertEq(dummyToken.balanceOf(address(this)), startBalance + value);
    }

    function testControlUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testFailUnlockBySenderLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testControlUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testFailUnlockBySenderTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
    }

    function testUnlockBySender() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 10);
        uint startBalance = dummyToken.balanceOf(address(account0));
        acuityAtomicSwapERC20.unlockBySender(address(dummyToken), address(account0), secret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 0);
        assertEq(dummyToken.balanceOf(address(account0)), startBalance + 10);
    }

    function testControlUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testFailUnlockByRecipientLockNotFound() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testControlUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testFailUnlockByRecipientTimedOut() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
    }

    function testUnlockByRecipient() public {
        bytes32 assetId = hex"1234";
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 10);
        uint startBalance = dummyToken.balanceOf(address(account0));
        account0.unlockByRecipient(address(dummyToken), address(this), secret, timeout);
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), 0);
        assertEq(dummyToken.balanceOf(address(acuityAtomicSwapERC20)), 0);
        assertEq(dummyToken.balanceOf(address(account0)), startBalance + 10);
    }

    function testControlTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueLockNotFound() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testControlTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testFailTimeoutValueNotTimedOut() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp + 1;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, 10, hex"1234");
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
    }

    function testTimeoutValue() public {
        bytes32 assetId = hex"1234";

        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        uint timeout = block.timestamp;
        uint value = 10;

        acuityAtomicSwapERC20.lockSell(address(dummyToken), address(account0), hashedSecret, timeout, assetId, value, hex"1234");
        assertEq(acuityAtomicSwapERC20.getLockValue(address(dummyToken), address(this), address(account0), hashedSecret, timeout), value);

        uint startBalance = dummyToken.balanceOf(address(this));
        acuityAtomicSwapERC20.timeoutValue(address(dummyToken), address(account0), hashedSecret, timeout);
        assertEq(dummyToken.balanceOf(address(this)), startBalance + value);
    }

}
