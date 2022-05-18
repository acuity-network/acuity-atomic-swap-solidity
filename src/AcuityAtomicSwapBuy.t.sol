// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";


contract AccountProxy {

    AcuityAtomicSwapBuy acuityAtomicSwapBuy;

    constructor (AcuityAtomicSwapBuy _acuityAtomicSwapBuy) {
        acuityAtomicSwapBuy = _acuityAtomicSwapBuy;
    }

    receive() payable external {
    }

    function unlockBuy(address buyer, bytes32 secret, uint256 timeout) external {
        acuityAtomicSwapBuy.unlockBuy(buyer, secret, timeout);
    }
}


contract AcuityAtomicSwapBuyTest is DSTest {
    AcuityAtomicSwapBuy acuityAtomicSwapBuy;
    AccountProxy accountProxy;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapBuy = new AcuityAtomicSwapBuy();
        accountProxy = new AccountProxy(acuityAtomicSwapBuy);
    }

    function testControlLockBuyAlreadyInUse() public {
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hex"5678", timeout, hex"0000");
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hex"3456", timeout, hex"0000");
    }

    function testFailLockBuyAlreadyInUse() public {
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hex"5678", timeout, hex"0000");
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hex"5678", timeout, hex"0000");
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hashedSecret, timeout, hex"0000");
        assertEq(address(acuityAtomicSwapBuy).balance, 10);
        assertEq(acuityAtomicSwapBuy.getLock(address(this), seller, hashedSecret, timeout), 10);
    }

    function testUnlockBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"4b1694df15172648181bcb37868b25d3bd9ff95d0f10ec150f783802a81a07fb";
        bytes32 hashedSecret = hex"094cd46013683e3929f474bf04e9ff626a6d7332c195dfe014e4b4a3fbb3ea54";
        address seller = address(accountProxy);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: value}(seller, hashedSecret, timeout, hex"0000");

        assertEq(acuityAtomicSwapBuy.getLock(address(this), seller, hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 startBalance = seller.balance;
        accountProxy.unlockBuy(address(this), secret, timeout);
        assertEq(acuityAtomicSwapBuy.getLock(address(this), seller, hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, startBalance + value);
    }

    function testControlTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hashedSecret, block.timestamp, hex"0000");
        acuityAtomicSwapBuy.timeoutBuy(seller, hashedSecret, block.timestamp);
    }

    function testFailTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(seller, hashedSecret, block.timestamp + 1000, hex"0000");
        acuityAtomicSwapBuy.timeoutBuy(seller, hashedSecret, block.timestamp + 1000);
    }

    function testTimeoutBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp;
        acuityAtomicSwapBuy.lockBuy{value: value}(seller, hashedSecret, timeout, hex"0000");

        assertEq(acuityAtomicSwapBuy.getLock(address(this), seller, hashedSecret, timeout), value);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 sellerBalance = seller.balance;
        uint256 buyerBalance = address(this).balance;
        acuityAtomicSwapBuy.timeoutBuy(seller, hashedSecret, timeout);
        assertEq(acuityAtomicSwapBuy.getLock(address(this), seller, hashedSecret, timeout), 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, sellerBalance);
        assertEq(address(this).balance, buyerBalance + value);
    }

}
