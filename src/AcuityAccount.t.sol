// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

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

    function testSetHotAccount() public {
        acuityAccount.setHotAccount(address(0x2345));
        assertEq(acuityAccount.getHotAccount(address(this)), address(0x2345));
    }

    function testGetAccounts() public {
        acuityAccount.setAcuAccount(hex"1234");
        acuityAccount.setHotAccount(address(0x2345));

        (bytes32 acuAccount, address hotAccount) = acuityAccount.getAccounts(address(this));
        assertEq(acuAccount, hex"1234");
        assertEq(hotAccount, address(0x2345));
    }

}
