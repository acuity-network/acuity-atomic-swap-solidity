// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

contract AcuityAccount {

    /**
     * @dev Mapping of account to ACU account.
     */
    mapping (address => bytes32) accountAcuAccount;

    /**
     * @dev Mapping of account to proxy account.
     */
    mapping (address => address) accountProxyAccount;

    /**
     * @dev ACU account has been set for an account.
     * @param account Account that has set its ACU account.
     * @param acuAccount ACU account that has been set for account.
     */
    event AcuAccountSet(address indexed account, bytes32 indexed acuAccount);

    /**
     * @dev Proxy account has been set for an account.
     * @param account Account that has set its Proxy account.
     * @param proxyAccount Proxy account that has been set for account.
     */
    event ProxyAccountSet(address indexed account, address indexed proxyAccount);

    /**
     * @dev Set Acu account for sender.
     * @param acuAccount ACU account to set for sender.
     */
    function setAcuAccount(bytes32 acuAccount)
        external
    {
        accountAcuAccount[msg.sender] = acuAccount;
        emit AcuAccountSet(msg.sender, acuAccount);
    }

    /**
     * @dev Set proxy account for sender.
     * @param proxyAccount Proxy account to set for sender.
     */
    function setProxyAccount(address proxyAccount)
        external
    {
        accountProxyAccount[msg.sender] = proxyAccount;
        emit ProxyAccountSet(msg.sender, proxyAccount);
    }

    /**
     * @dev Get ACU account for account.
     * @param account Account to get ACU account for.
     * @return acuAccount ACU account for account.
     */
    function getAcuAccount(address account)
        external
        view
        returns (bytes32 acuAccount)
    {
        acuAccount = accountAcuAccount[account];
    }

    /**
     * @dev Get proxy account for account.
     * @param account Account to get proxy account for.
     * @return proxyAccount Proxy account for account.
     */
    function getProxyAccount(address account)
        external
        view
        returns (address proxyAccount)
    {
        proxyAccount = accountProxyAccount[account];
    }

    /**
     * @dev Get accounts for account.
     * @param account Account to get accounts for.
     * @return acuAccount ACU account for account.
     * @return proxyAccount Proxy account for account.
     */
    function getAccounts(address account)
        external
        view
        returns (bytes32 acuAccount, address proxyAccount)
    {
        acuAccount = accountAcuAccount[account];
        proxyAccount = accountProxyAccount[account];
    }

}
