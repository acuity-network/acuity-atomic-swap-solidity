// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./AcuityAtomicSwapSell.sol";

contract AcuityAtomicSwapSellTest is DSTest {
    AcuityAtomicSwapSell swap;

    function setUp() public {
        swap = new AcuityAtomicSwapSell();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
