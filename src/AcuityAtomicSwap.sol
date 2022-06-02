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
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev Value has been added to a stash.
     * @param account Account adding to a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param value How much value has been added to the stash.
     */
    event StashAdd(address account, bytes16 assetId, uint256 value);

    /**
     * @dev Value has been removed from a stash.
     * @param account Account removing from a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param value How much value has been removed from the stash.
     */
    event StashRemove(address account, bytes16 assetId, uint256 value);

    /**
     * @dev Value has been locked with sell asset info.
     * @param from Account that locked the value.
     * @param to Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which "from" can retrieve the value.
     * @param value Value being locked.
     * @param sellAssetIdPrice 16 bytes assetId the value is paying for. 16 bytes price the asset is being sold for.
     */
    event Lock(address from, address to, bytes32 hashedSecret, uint256 timeout, uint256 value, bytes32 sellAssetIdPrice);

    /**
     * @dev Value has been locked.
     * @param from Account that locked the value.
     * @param to Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which "from" can retrieve the value.
     * @param value Value being locked.
     */
    event Lock(address from, address to, bytes32 hashedSecret, uint256 timeout, uint256 value);


    /**
     * @dev Value has been unlocked.
     * @param lockId The lockId of the value that has been unlocked.
     * @param secret The secret used to unlock the value.
     */
    event Unlock(bytes32 indexed lockId, bytes32 secret);

    /**
     * @dev Value has been timed out.
     * @param lockId The lockId of the value that has been timed out.
     */
    event Timeout(bytes32 indexed lockId);

    /**
     * @dev No value was provided.
     */
    error ZeroValue();

    /**
     * @dev The stash is not big enough.
     */
    error StashNotBigEnough();

    /**
     * @dev Value has already been locked with this lockId.
     * @param lockId lockId of the value already locked.
     */
    error LockAlreadyExists(bytes32 lockId);

    /**
     * @dev The lock has already timed out.
     */
    error LockTimedOut();

    /**
     * @dev The lock has not timed out yet.
     */
    error LockNotTimedOut();

    /**
     * @dev Add value to stash be sold for a specific asset.
     * @param assetId Asset the stash is to be sold for.
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
     * @dev Remove value from stash be sold for a specific asset.
     * @param assetId Asset the stash is to be sold for.
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
     * @dev Stash value to be sold for a specific asset.
     * @param assetId Asset the stash is to be sold for.
     */
    function depositStash(bytes16 assetId) external payable {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Records the deposit.
        stashAdd(assetId, msg.value);
    }

    /**
     * @dev Move value from one stash to another.
     * @param assetIdFrom Asset the source stash is to be sold for.
     * @param assetIdTo Asset the destination stash is to be sold for.
     * @param value Value to move.
     */
    function moveStash(bytes16 assetIdFrom, bytes16 assetIdTo, uint value) external {
         // Check there is enough.
         if (stashAssetIdAccountValue[assetIdFrom][msg.sender] < value) revert StashNotBigEnough();
         // Move the deposit.
         stashRemove(assetIdFrom, value);
         stashAdd(assetIdTo, value);
     }

    /**
     * @dev Withdraw value from a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param value Value to withdraw.
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
     * @dev Withdraw all value from a stash.
     * @param assetId Asset the stash is to be sold for.
     */
    function withdrawStash(bytes16 assetId) external {
        uint value = stashAssetIdAccountValue[assetId][msg.sender];
        // Remove the deposit.
        stashRemove(assetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Lock value.
     * @param to Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param sellAssetIdPrice Sell order this lock is for.
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
     * @dev Lock stashed value.
     * @param to Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param stashAssetId Asset the stash is to be sold for.
     * @param value Value from the stash to lock.
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
     * @param assetId Asset the stash is to be sold for.
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
     * @dev Get value held in a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param seller Owner of the stash.
     * @return value Value held in the stash.
     */
    function getStashValue(bytes16 assetId, address seller) view external returns (uint256 value) {
        value = stashAssetIdAccountValue[assetId][seller];
    }

    /**
     * @dev Get value locked.
     * @param from Account that locked the value.
     * @param to Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which "from" can retrieve the value.
     * @return value Value held in the lock.
     */
    function getLockValue(address from, address to, bytes32 hashedSecret, uint256 timeout) view external returns (uint256 value) {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(from, to, hashedSecret, timeout));
        value = lockIdValue[lockId];
    }

    /**
    * @dev Get value locked.
    * @param lockId Lock to examine.
    * @return value Value held in the lock.
     */
    function getLockValue(bytes32 lockId) view external returns (uint256 value) {
        value = lockIdValue[lockId];
    }

}
