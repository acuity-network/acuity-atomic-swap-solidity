// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "ds-test/test.sol";

import "./AcuityAtomicSwap.sol";

contract AccountProxy {

    AcuityAtomicSwap acuityAtomicSwap;

    constructor (AcuityAtomicSwap _acuityAtomicSwap) {
        acuityAtomicSwap = _acuityAtomicSwap;
    }

    receive() payable external {
    }

}

contract AcuityAtomicSwapTest is DSTest {
    AcuityAtomicSwap acuityAtomicSwap;
    AccountProxy accountProxy;

    receive() external payable {}

    function setUp() public {
        acuityAtomicSwap = new AcuityAtomicSwap();
        accountProxy = new AccountProxy(acuityAtomicSwap);
    }

    function testSellerLockValue() public {
        bytes32 secret = hex"1234";
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address to = address(0x3456);
        uint256 timeout = block.timestamp + 1000;
        acuityAtomicSwap.sellerLockValue{value: 10}(to, hashedSecret, timeout);
        assertEq(address(acuityAtomicSwap).balance, 10);
        assertEq(acuityAtomicSwap.getLock(address(this), to, hashedSecret, timeout), 10);
    }
}
