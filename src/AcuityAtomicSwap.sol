// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

contract AcuityAtomicSwap {

    /**
     * @dev Mapping of assetId to linked list of accounts, starting with the largest.
     */
    mapping (bytes16 => mapping (address => address)) stashAssetIdAccountsLL;

    /**
     * @dev Mapping of assetId to selling address to value.
     */
    mapping (bytes16 => mapping (address => uint)) stashAssetIdAccountValue;

    /**
     * @dev
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev
     */
    event StashAdd(address account, bytes16 assetId, uint256 value);

    /**
     * @dev
     */
    event StashRemove(address account, bytes16 assetId, uint256 value);

    /**
     * @dev
     */
    event Lock(address from, address to, bytes32 hashedSecret, uint256 timeout, uint256 value, bytes32 sellAssetIdPrice);

    event Lock(address from, address to, bytes32 hashedSecret, uint256 timeout, uint256 value);


    /**
     * @dev
     */
    event Unlock(bytes32 indexed lockId, bytes32 secret);

    /**
     * @dev
     */
    event Timeout(bytes32 hashedSecret);

    /**
     * @dev
     */
    error ZeroValue();

    /**
     * @dev
     */
    error StashNotBigEnough();

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
     * @param assetId
     * @param value Size of deposit to add. Must be greater than 0.
     */
    function stashAdd(bytes16 assetId, uint value) internal {
        mapping (address => address) storage accountsLL = stashAssetIdAccountsLL[assetId];
        mapping (address => uint) storage accountValue = stashAssetIdAccountValue[assetId];
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
        emit StashAdd(msg.sender, assetId, value);
    }

    /**
     * @dev
     * @param assetId
     * @param value Size of deposit to remove. Must be bigger than or equal to deposit value.
     */
    function stashRemove(bytes16 assetId, uint value) internal {
        mapping (address => address) storage accountsLL = stashAssetIdAccountsLL[assetId];
        mapping (address => uint) storage accountValue = stashAssetIdAccountValue[assetId];
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
        emit StashRemove(msg.sender, assetId, value);
    }

    /**
     * @dev Stash funds to be sold for a specific asset.
     * @param assetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function depositStash(bytes16 assetId) external payable {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Records the deposit.
        stashAdd(assetId, msg.value);
    }

    /**
     * @dev Stash funds to be sold for a specific asset.
     * @param assetIdFrom 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param assetIdTo 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function moveStash(bytes16 assetIdFrom, bytes16 assetIdTo, uint value) external {
         // Check there is enough.
         if (stashAssetIdAccountValue[assetIdFrom][msg.sender] < value) revert StashNotBigEnough();
         // Move the deposit.
         stashRemove(assetIdFrom, value);
         stashAdd(assetIdTo, value);
     }

    /**
     * @dev Withdraw funds.
     * @param assetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param value Amount to withdraw.
     */
    function withdrawStash(bytes16 assetId, uint value) external {
        // Check there is enough.
        if (stashAssetIdAccountValue[assetId][msg.sender] < value) revert StashNotBigEnough();
        // Remove the deposit.
        stashRemove(assetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Withdraw all funds.
     * @param assetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function withdrawStash(bytes16 assetId) external {
        uint value = stashAssetIdAccountValue[assetId][msg.sender];
        // Remove the deposit.
        stashRemove(assetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Create a lock.
     * @param to Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param sellAssetIdPrice Sell order this lock is for (buyers only).
     */
    function lockValue(address to, bytes32 hashedSecret, uint256 timeout, bytes32 sellAssetIdPrice) payable external {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, to, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit Lock(msg.sender, to, hashedSecret, timeout, msg.value, sellAssetIdPrice);
    }

    /**
     * @dev Create a lock from stashed funds.
     * @param stashAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     */
    function lockStash(address to, bytes32 hashedSecret, uint256 timeout, bytes16 stashAssetId, uint256 value) external {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Check there is enough.
        if (stashAssetIdAccountValue[stashAssetId][msg.sender] < value) revert StashNotBigEnough();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, to, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        stashRemove(stashAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
        emit Lock(msg.sender, to, hashedSecret, timeout, value);
    }

    /**
     * @dev Called by "to".
     */
    function unlockValue(address from, bytes32 secret, uint256 timeout) external {
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(from, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Unlock(lockId, secret);
    }

    /**
     * @dev Called by "from" if "to" did not unlock.
     */
    function timeoutStash(address to, bytes32 hashedSecret, uint256 timeout, bytes16 stashAssetId) external {
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, to, hashedSecret, timeout));
        // Get lock value;
        uint256 value = lockIdValue[lockId];
        // Ensure lock has value
        if (lockIdValue[lockId] == 0) revert ZeroValue();
        // Delete lock.
        delete lockIdValue[lockId];
        // Return funds and delete lock.
        stashAdd(stashAssetId, value);
        // Log info.
        emit Timeout(lockId);
    }

    /**
     * @dev Called by "from" if "to" did not unlock.
     */
    function timeoutValue(address to, bytes32 hashedSecret, uint256 timeout) external {
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, to, hashedSecret, timeout));
        // Get lock value;
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Timeout(lockId);
    }

    /**
     * @dev Get a list of deposits for a specific asset.
     * @param assetId 4 bytes chainId, 4 bytes adapterId, 8 bytes tokenId
     * @param limit Maximum number of deposits to return.
     */
    function getStashes(bytes16 assetId, uint limit) view external returns (address[] memory accounts, uint[] memory values) {
        mapping (address => address) storage accountsLL = stashAssetIdAccountsLL[assetId];
        mapping (address => uint) storage accountValue = stashAssetIdAccountValue[assetId];
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
    function getStashValue(bytes16 assetId, address seller) view external returns (uint256 value) {
        value = stashAssetIdAccountValue[assetId][seller];
    }

    /**
     * @dev
     */
    function getLockValue(address from, address to, bytes32 hashedSecret, uint256 timeout) view external returns (uint256 value) {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(from, to, hashedSecret, timeout));
        value = lockIdValue[lockId];
    }

    /**
     * @dev
     */
    function getLockValue(bytes32 lockId) view external returns (uint256 value) {
        value = lockIdValue[lockId];
    }

}
