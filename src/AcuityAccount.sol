// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

contract AcuityAccount {

    /**
     * @dev Mapping of account to ACU account.
     */
    mapping (address => bytes32) accountAcuAccount;

    /**
     * @dev Mapping of account to hot account.
     */
    mapping (address => address) accountHotAccount;

    /**
     * @dev ACU account has been set for an account.
     * @param account Account that has set its ACU account.
     * @param acuAccount ACU account that has been set for account.
     */
    event AcuAccountSet(address indexed account, bytes32 indexed acuAccount);

    /**
     * @dev Hot account has been set for an account.
     * @param account Account that has set its Hot account.
     * @param hotAccount Hot account that has been set for account.
     */
    event HotAccountSet(address indexed account, address indexed hotAccount);

    /**
     * @dev Set Acu account for sender.
     * @param acuAccount ACU account to set for sender.
     */
    function setAcuAccount(bytes32 acuAccount) external {
        accountAcuAccount[msg.sender] = acuAccount;
        emit AcuAccountSet(msg.sender, acuAccount);
    }

    /**
     * @dev Set hot account for sender.
     * @param hotAccount Hot account to set for sender.
     */
    function setHotAccount(address hotAccount) external {
        accountHotAccount[msg.sender] = hotAccount;
        emit HotAccountSet(msg.sender, hotAccount);
    }

    /**
     * @dev Get ACU account for account.
     * @param account Account to get ACU account for.
     * @return acuAccount ACU account for account.
     */
    function getAcuAccount(address account) view external returns (bytes32 acuAccount) {
        acuAccount = accountAcuAccount[account];
    }

    /**
     * @dev Get hot account for account.
     * @param account Account to get hot account for.
     * @return hotAccount Hot account for account.
     */
    function getHotAccount(address account) view external returns (address hotAccount) {
        hotAccount = accountHotAccount[account];
    }

    /**
     * @dev Get accounts for account.
     * @param account Account to get accounts for.
     * @return acuAccount ACU account for account.
     * @return hotAccount Hot account for account.
     */
    function getAccounts(address account) view external returns (bytes32 acuAccount, address hotAccount) {
        acuAccount = accountAcuAccount[account];
        hotAccount = accountHotAccount[account];
    }

}
