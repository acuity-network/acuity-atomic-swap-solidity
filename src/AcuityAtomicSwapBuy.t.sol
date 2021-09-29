// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";


contract AccountProxy {

    AcuityAtomicSwapBuy acuityAtomicSwapBuy;

    constructor (AcuityAtomicSwapBuy _acuityAtomicSwapBuy) {
        acuityAtomicSwapBuy = _acuityAtomicSwapBuy;
    }

    receive() payable external {
    }

    function unlockBuy(bytes32 secret) external {
        acuityAtomicSwapBuy.unlockBuy(secret);
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
        acuityAtomicSwapBuy.lockBuy{value: 10}(hex"5678", hex"1234", payable(seller), timeout);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hex"3456", hex"1234", payable(seller), timeout);
    }

    function testFailLockBuyAlreadyInUse() public {
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hex"5678", hex"1234", payable(seller), timeout);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hex"5678", hex"1234", payable(seller), timeout);
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, hex"5678", payable(seller), timeout);
        assertEq(address(acuityAtomicSwapBuy).balance, 10);
        AcuityAtomicSwapBuy.BuyLock memory buyLock = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(buyLock.seller, seller);
        assertEq(buyLock.value, 10);
        assertEq(buyLock.timeout, timeout);
    }

    function testControlUnlockBuyNotSeller() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(accountProxy);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, hex"5678", payable(seller), block.timestamp + 1000);
        accountProxy.unlockBuy(secret);
    }

    function testFailUnlockBuyNotSeller() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(accountProxy);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, hex"5678", payable(seller), block.timestamp);
        acuityAtomicSwapBuy.unlockBuy(secret);
    }

    function testUnlockBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(accountProxy);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: value}(hashedSecret, hex"5678", payable(seller), timeout);

        AcuityAtomicSwapBuy.BuyLock memory buyLock = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(buyLock.seller, seller);
        assertEq(buyLock.value, value);
        assertEq(buyLock.timeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 startBalance = address(seller).balance;
        accountProxy.unlockBuy(secret);
        buyLock = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(buyLock.seller, address(0));
        assertEq(buyLock.value, 0);
        assertEq(buyLock.timeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, startBalance + value);
    }

    function testControlTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, hex"5678", payable(seller), block.timestamp);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testFailTimeoutBuyNotTimedOut() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, hex"5678", payable(seller), block.timestamp + 1000);
        acuityAtomicSwapBuy.timeoutBuy(secret);
    }

    function testTimeoutBuy() public {
        uint256 value = 10;
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint256 timeout = block.timestamp;
        acuityAtomicSwapBuy.lockBuy{value: value}(hashedSecret, hex"5678", payable(seller), timeout);

        AcuityAtomicSwapBuy.BuyLock memory buyLock = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(buyLock.seller, seller);
        assertEq(buyLock.value, value);
        assertEq(buyLock.timeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, value);
        uint256 sellerBalance = address(seller).balance;
        uint256 buyerBalance = address(this).balance;
        acuityAtomicSwapBuy.timeoutBuy(secret);
        buyLock = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(buyLock.seller, address(0));
        assertEq(buyLock.value, 0);
        assertEq(buyLock.timeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, sellerBalance);
        assertEq(address(this).balance, buyerBalance + value);
    }

}
