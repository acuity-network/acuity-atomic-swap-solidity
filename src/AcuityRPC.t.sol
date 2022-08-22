// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "ds-test/test.sol";

import "./AcuityRPC.sol";

contract AcuityRPCTest is DSTest {
    AcuityRPC acuityRPC;

    function setUp() public {
        acuityRPC = new AcuityRPC();
    }

}
