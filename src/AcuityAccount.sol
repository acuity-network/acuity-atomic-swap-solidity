// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract AcuityAccount {

    /**
     * @dev Mapping of account to ACU account.
     */
    mapping (address => bytes32) accountAcuAccount;

    /**
     * @dev
     */
    event AcuAccountSet(address account, bytes32 acuAccount);

    /**
     * @dev
     */
    function setAcuAccount(bytes32 acuAccount) external {
        accountAcuAccount[msg.sender] = acuAccount;
        emit AcuAccountSet(msg.sender, acuAccount);
    }

    /**
     * @dev
     */
    function getAcuAccount(address account) view external returns (bytes32 acuAccount) {
        acuAccount = accountAcuAccount[account];
    }

}
