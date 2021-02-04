// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./AcuityAtomicSwapBuy.sol";

contract AcuityAtomicSwapBuyTest is DSTest {
    AcuityAtomicSwapBuy swap;

    function setUp() public {
        swap = new AcuityAtomicSwapBuy();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
