// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";

contract AcuityAtomicSwapBuyTest is DSTest {
    AcuityAtomicSwapBuy acuityAtomicSwapBuy;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwapBuy = new AcuityAtomicSwapBuy();
    }

    function testLockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), timeout, hex"5678");

        (address lockSeller, uint lockValue, uint lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, 10);
        assertEq(lockTimeout, timeout);
    }

    function testUnlockBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint timeout = block.timestamp + 1000;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), timeout, hex"5678");

        (address lockSeller, uint lockValue, uint lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, 10);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, 10);
        uint startBalance = address(seller).balance;
        acuityAtomicSwapBuy.unlockBuy(secret);
        (lockSeller, lockValue, lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, address(0));
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, startBalance + 10);
    }

    function testTimeoutBuy() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = address(0x3456);
        uint timeout = block.timestamp;
        acuityAtomicSwapBuy.lockBuy{value: 10}(hashedSecret, payable(seller), timeout, hex"5678");

        (address lockSeller, uint lockValue, uint lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, seller);
        assertEq(lockValue, 10);
        assertEq(lockTimeout, timeout);

        assertEq(address(acuityAtomicSwapBuy).balance, 10);
        uint sellerBalance = address(seller).balance;
        uint buyerBalance = address(this).balance;
        acuityAtomicSwapBuy.timeoutBuy(secret);
        (lockSeller, lockValue, lockTimeout) = acuityAtomicSwapBuy.getBuyLock(hashedSecret);
        assertEq(lockSeller, address(0));
        assertEq(lockValue, 0);
        assertEq(lockTimeout, 0);
        assertEq(address(acuityAtomicSwapBuy).balance, 0);
        assertEq(address(seller).balance, sellerBalance);
        assertEq(address(this).balance, buyerBalance + 10);
    }

}
