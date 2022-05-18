// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract AcuityAtomicSwapSell {

    /**
     * @dev Mapping of buyAssetId to linked list of accounts, starting with the largest.
     */
    mapping (bytes16 => mapping (address => address)) buyAssetIdAccountsLL;

    /**
     * @dev Mapping of buyAssetId to selling address to value.
     */
    mapping (bytes16 => mapping (address => uint)) buyAssetIdAccountValue;

    /**
     * @dev
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev
     */
    event StashAdd(address account, bytes16 buyAssetId, uint256 value);

    /**
     * @dev
     */
    event StashRemove(address account, bytes16 buyAssetId, uint256 value);

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
    error ZeroValue();

    /**
     * @dev
     */
    error DepositNotBigEnough();

    /**
     * @dev
     */
    error LockAlreadyExists(bytes32 lockId);

    /**
     * @dev
     */
    error LockTimedOut();

    /**
     * @dev
     */
    error LockNotTimedOut();

    /**
     * @dev
     * @param buyAssetId
     * @param value Size of deposit to add. Must be greater than 0.
     */
    function stashAdd(bytes16 buyAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = buyAssetIdAccountsLL[buyAssetId];
        mapping (address => uint) storage accountValue = buyAssetIdAccountValue[buyAssetId];
        // Get new total.
        uint total = accountValue[msg.sender] + value;
        // Search for new previous.
        address prev = address(0);
        while (accountValue[accountsLL[prev]] >= total) {
            prev = accountsLL[prev];
        }
        bool replace = false;
        // Is sender already in the list?
        if (accountValue[msg.sender] > 0) {
            // Search for old previous.
            address oldPrev = address(0);
            while (accountsLL[oldPrev] != msg.sender) {
                oldPrev = accountsLL[oldPrev];
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
        // Log info.
        emit StashAdd(msg.sender, buyAssetId, value);
    }

    /**
     * @dev
     * @param buyAssetId
     * @param value Size of deposit to remove. Must be bigger than or equal to deposit value.
     */
    function stashRemove(bytes16 buyAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = buyAssetIdAccountsLL[buyAssetId];
        mapping (address => uint) storage accountValue = buyAssetIdAccountValue[buyAssetId];
        // Get new total.
        uint total = accountValue[msg.sender] - value;
        // Search for old previous.
        address oldPrev = address(0);
        while (accountsLL[oldPrev] != msg.sender) {
            oldPrev = accountsLL[oldPrev];
        }
        // Remove sender from current position.
        accountsLL[oldPrev] = accountsLL[msg.sender];
        // Is it in a different position?
        if (total > 0) {        // TODO: check this
            // Search for new previous.
            address prev = address(0);
            while (accountValue[accountsLL[prev]] >= total) {
                prev = accountsLL[prev];
            }
            // Insert into linked list.
            accountsLL[msg.sender] = accountsLL[prev];
            accountsLL[prev] = msg.sender;
        }
        // Update the value deposited.
        accountValue[msg.sender] = total;
        // Log info.
        emit StashRemove(msg.sender, buyAssetId, value);
    }

    /**
     * @dev Deposit funds to be sold for a specific asset.
     * @param buyAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function depositStash(bytes16 buyAssetId) external payable {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Records the deposit.
        stashAdd(buyAssetId, msg.value);
    }

    /**
     * @dev Deposit funds to be sold for a specific asset.
     * @param buyAssetIdFrom 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param buyAssetIdTo 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function moveStash(bytes16 buyAssetIdFrom, bytes16 buyAssetIdTo, uint value) external {
         // Check there is enough.
         if (buyAssetIdAccountValue[buyAssetIdFrom][msg.sender] < value) revert DepositNotBigEnough();
         // Move the deposit.
         stashRemove(buyAssetIdFrom, value);
         stashAdd(buyAssetIdTo, value);
     }

    /**
     * @dev Withdraw funds.
     * @param buyAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param value Amount to withdraw.
     */
    function withdrawStash(bytes16 buyAssetId, uint value) external {
        // Check there is enough.
        if (buyAssetIdAccountValue[buyAssetId][msg.sender] < value) revert DepositNotBigEnough();
        // Remove the deposit.
        stashRemove(buyAssetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Withdraw all funds.
     * @param buyAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function withdrawStash(bytes16 buyAssetId) external {
        uint value = buyAssetIdAccountValue[buyAssetId][msg.sender];
        // Remove the deposit.
        stashRemove(buyAssetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Create a sell lock. Called by seller.
     * @param buyAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function lockSell(bytes32 hashedSecret, address buyer, uint256 timeout, bytes16 buyAssetId, uint256 value) external {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Check there is enough.
        if (buyAssetIdAccountValue[buyAssetId][msg.sender] < value) revert DepositNotBigEnough();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        stashRemove(buyAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
//        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /**
     * @dev Create a sell lock. Called by seller.
     */
    function lockSell(bytes32 hashedSecret, address buyer, uint256 timeout) payable external {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        lockIdValue[lockId] = msg.value;
        // Log info.
//        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /**
     * Called by buyer before lock has timed out.
     */
    function unlockSell(address seller, bytes32 secret, uint256 timeout) external {
        // Check sell lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut();
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
     * Called by seller after lock has timed out (if buyer did not reveal secret).
     */
    function timeoutSell(bytes32 hashedSecret, address buyer, uint256 timeout, bytes16 buyAssetId) external {
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        require(lockIdValue[lockId] > 0, "Lock does not exist.");
        // Return funds and delete lock.
        stashAdd(buyAssetId, lockIdValue[lockId]);
        delete lockIdValue[lockId];
        // Log info.
//        emit TimeoutSell(orderId, hashedSecret);
    }

    /**
     * Called by seller after lock has timed out (if buyer did not reveal secret).
     */
    function timeoutSell(bytes32 hashedSecret, address buyer, uint256 timeout) external {
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        require(lockIdValue[lockId] > 0, "Lock does not exist.");
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Return funds and delete lock.
        delete lockIdValue[lockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
//        emit TimeoutSell(orderId, hashedSecret);
    }

    /**
     * @dev Get a list of deposits for a specific asset.
     * @param buyAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param limit Maximum number of deposits to return.
     */
    function getDeposits(bytes16 buyAssetId, uint limit) view external returns (address[] memory accounts, uint[] memory values) {
        mapping (address => address) storage accountsLL = buyAssetIdAccountsLL[buyAssetId];
        mapping (address => uint) storage accountValue = buyAssetIdAccountValue[buyAssetId];
        // Count how many accounts to return.
        address account = address(0);
        uint _limit = 0;
        while (accountsLL[account] != address(0) && _limit < limit) {
            account = accountsLL[account];
            _limit++;
        }
        // Allocate the arrays.
        accounts = new address[](_limit);
        values = new uint[](_limit);
        // Populate the array.
        account = accountsLL[address(0)];
        for (uint i = 0; i < _limit; i++) {
            accounts[i] = account;
            values[i] = accountValue[account];
            account = accountsLL[account];
        }
    }

    /**
     * @dev
     */
    function getDepositValue(bytes16 buyAssetId, address seller) view external returns (uint256 value) {
        value = buyAssetIdAccountValue[buyAssetId][seller];
    }

    /**
     * @dev
     */
    function getLockValue(address seller, bytes32 hashedSecret, address buyer, uint256 timeout) view external returns (uint256 value) {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(seller, hashedSecret, buyer, timeout));
        value = lockIdValue[lockId];
    }

    /**
     * @dev
     */
    function getLockValue(bytes32 lockId) view external returns (uint256 value) {
        value = lockIdValue[lockId];
    }

}
