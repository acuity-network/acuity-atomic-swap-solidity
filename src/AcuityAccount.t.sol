// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "ds-test/test.sol";

import "./AcuityAccount.sol";

contract AcuityAccountTest is DSTest {
    AcuityAccount acuityAccount;

    function setUp() public {
        acuityAccount = new AcuityAccount();
    }

    function testSetAcuAccount() public {
        acuityAccount.setAcuAccount(hex"1234");
    }

}
