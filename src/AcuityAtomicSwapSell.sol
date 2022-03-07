// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

contract AcuityAtomicSwapSell {

    /**
     * @dev Mapping of selling address to ACU address.
     */
    mapping (address => bytes32) addressAcuAddress;

    /**
     * @dev Mapping of assetId (to buy) to linked list of accounts, starting with the largest.
     */
    mapping (bytes16 => mapping (address => address)) chainIdAdapterIdAssetIdAccountsLL;

    /**
     * @dev Mapping of assetId (to buy) to selling address to value.
     */
    mapping (bytes16 => mapping(address => uint)) chainIdAdapterIdAssetIdAccountValue;

    /**
     * @dev
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev
     */
    event AddToOrder(bytes16 orderId, address seller, bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress, uint256 value);

    /**
     * @dev
     */
    event RemoveFromOrder(bytes16 orderId, uint256 value);

    /**
     * @dev
     */
    event LockSell(bytes16 orderId, bytes32 hashedSecret, uint256 timeout, uint256 value);

    /**
     * @dev
     */
    event UnlockSell(bytes16 orderId, bytes32 secret);

    /**
     * @dev
     */
    event TimeoutSell(bytes16 orderId, bytes32 hashedSecret);

    /**
     * @dev
     */
    function setAcuAddress(bytes32 acuAddress) external {
        addressAcuAddress[msg.sender] = acuAddress;
    }

    function addDeposit(bytes16 chainIdAdapterIdAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = chainIdAdapterIdAssetIdAccountsLL[chainIdAdapterIdAssetId];
        mapping (address => uint) storage accountValue = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId];
        // Get total.
        uint total = accountValue[msg.sender] + value;
        // Search for new previous.
        address prev = address(0);
        while (accountValue[accountsLL[prev]] > total) {
            prev = accountsLL[prev];
        }
        bool replace = false;
        // Is sender already in the list?
        if (accountValue[msg.sender] > 0) {
            // Search for old previous.
            address oldPrev = address(0);
            while (accountsLL[prev] != msg.sender) {
                prev = accountsLL[prev];
            }
            // Is it in the same position?
            if (prev == oldPrev) {
                replace = true;
            }
            else {
                // Remove sender from current position.
                accountsLL[oldPrev] = accountsLL[msg.sender];
            }
        }
        if (!replace) {
            // Insert into linked list.
            accountsLL[msg.sender] = accountsLL[prev];
            accountsLL[prev] = msg.sender;
        }
        // Update the value deposited.
        accountValue[msg.sender] = total;
    }

    function removeDeposit(bytes16 chainIdAdapterIdAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = chainIdAdapterIdAssetIdAccountsLL[chainIdAdapterIdAssetId];
        mapping (address => uint) storage accountValue = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId];
        // Get total.
        uint total = accountValue[msg.sender] - value;
        // Search for new previous.
        address prev = address(0);
        while (accountValue[accountsLL[prev]] > total) {
            prev = accountsLL[prev];
        }
        bool replace = false;
        // Search for old previous.
        address oldPrev = address(0);
        while (accountsLL[prev] != msg.sender) {
            prev = accountsLL[prev];
        }
        // Is it in a different position?
        if (prev != oldPrev) {
            // Remove sender from current position.
            accountsLL[oldPrev] = accountsLL[msg.sender];
            // Insert into linked list.
            accountsLL[msg.sender] = accountsLL[prev];
            accountsLL[prev] = msg.sender;
        }
        // Update the value deposited.
        accountValue[msg.sender] = total;
    }

    /**
     * @dev Deposit funds to be sold for a specific asset.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     */
    function deposit(bytes16 chainIdAdapterIdAssetId) external payable {
        addDeposit(chainIdAdapterIdAssetId, msg.value);
    }

    /**
     * @dev Create a sell lock. Called by seller.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     */
    function lockSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout, uint256 value) external {
        // Check there is enough.
        require (chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId][msg.sender] >= value, "Sell order not big enough.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Ensure lockId is not already in use.
        require (lockIdValue[lockId] == 0, "Sell lock already exists.");
        // Move value into sell lock.
        removeDeposit(chainIdAdapterIdAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
//        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /**
     * Called by buyer.
     */
    function unlockSell(address seller, bytes32 secret, uint256 timeout) external {
        // Check sell lock has not timed out.
        require (timeout > block.timestamp, "Lock timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(seller, keccak256(abi.encodePacked(secret)), msg.sender, timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
//        emit UnlockSell(orderId, secret);
    }

    /**
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout) external {
        // Check lock has timed out.
        require (timeout <= block.timestamp, "Lock not timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Return funds and delete lock.
        addDeposit(chainIdAdapterIdAssetId, lockIdValue[lockId]);
        delete lockIdValue[lockId];
        // Log info.
//        emit TimeoutSell(orderId, hashedSecret);
    }

    /**
     * @dev
     */
    function getAcuAddress(address seller) view external returns (bytes32 acuAddress) {
        acuAddress = addressAcuAddress[seller];
    }

    /**
     * @dev
     */
    function getOrderValue(address seller, bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress) view external returns (uint256 value) {
//        value = orderIdValue[bytes16(keccak256(abi.encodePacked(seller, chainIdAdapterIdAssetIdPrice, foreignAddress)))];
    }

    /**
     * @dev
     */
    function getOrderValue(bytes16 orderId) view external returns (uint256 value) {
//        value = orderIdValue[orderId];
    }

    /**
     * @dev
     */
    function getSellLock(bytes16 orderId, bytes32 hashedSecret, address buyer, uint256 timeout) view external returns (uint256 value) {
//        value = lockIdValue[keccak256(abi.encodePacked(orderId, hashedSecret, buyer, timeout))];
    }

    /**
     * @dev
     */
    function getSellLock(bytes32 lockId) view external returns (uint256 value) {
//        value = lockIdValue[lockId];
    }

}
