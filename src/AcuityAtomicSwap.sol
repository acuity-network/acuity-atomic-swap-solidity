// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

contract AcuityAtomicSwap {

    /**
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint) lockIdValue;

    /**
     * @dev Value has been locked with sell asset info.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which sender can retrieve the value.
     * @param value Value being locked.
     * @param sellAssetId assetId the buyer is buying
     * @param sellPrice Unit price the buyer is paying for the asset.
     */
    event LockBuy(address indexed sender, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 sellAssetId, uint sellPrice);

    /**
     * @dev Value has been locked.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which sender can retrieve the value.
     * @param value Value being locked.
     * @param buyAssetId The asset of the buy lock this lock is responding to.
     * @param buyLockId The buy lock this lock is responding to.
     */
    event LockSell(address indexed sender, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 buyAssetId, bytes32 buyLockId);

    /**
     * @dev Lock has been declined by the recipient.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event Decline(address indexed sender, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has been unlocked by the recipient.
     * @param sender Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Intrinisic lockId.
     * @param secret The secret used to unlock the value.
     */
    event Unlock(address indexed sender, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been retrieved from a timed-out lock.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event Retrieve(address indexed sender, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has already been locked with this lockId.
     * @param lockId Lock already locked.
     */
    error LockAlreadyExists(bytes32 lockId);

    /**
     * @dev Lock does not exist.
     * @param lockId Lock that does not exist.
     */
    error LockNotFound(bytes32 lockId);

    /**
     * @dev The lock has already timed out.
     * @param lockId Lock timed out.
     */
    error LockTimedOut(bytes32 lockId);

    /**
     * @dev The lock has not timed out yet.
     * @param lockId Lock not timed out.
     */
    error LockNotTimedOut(bytes32 lockId);

    /**
     * @dev Lock value to buy from a sell order.
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param sellAssetId assetId the buyer is buying
     * @param sellPrice Unit price the buyer is paying for the asset.
     */
    function lockBuy(address recipient, bytes32 hashedSecret, uint timeout, bytes32 sellAssetId, uint sellPrice)
        external
        payable
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into buy lock.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit LockBuy(msg.sender, recipient, hashedSecret, timeout, msg.value, sellAssetId, sellPrice);
    }

    /**
     * @dev Lock value to sell to a buy lock.
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param buyAssetId The asset of the buy lock this lock is responding to.
     * @param buyLockId The buy lock this lock is responding to.
     */
    function lockSell(address recipient, bytes32 hashedSecret, uint timeout, bytes32 buyAssetId, bytes32 buyLockId)
        external
        payable
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit LockSell(msg.sender, recipient, hashedSecret, timeout, msg.value, buyAssetId, buyLockId);
    }

    /**
     * @dev Transfer value back to the sender (called by recipient).
     * @param sender Sender of the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timeout of the lock.
     */
    function decline(address sender, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(sender, msg.sender, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value back to the sender.
        payable(sender).transfer(value);
        // Log info.
        emit Decline(sender, msg.sender, lockId);
    }

    /**
     * @dev Transfer value from lock to recipient (called by recipient).
     * @param sender Sender of the value.
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlock(address sender, bytes32 secret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(sender, msg.sender, keccak256(abi.encode(secret)), timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Unlock(sender, msg.sender, lockId, secret);
    }

    /**
     * @dev Transfer value from expired lock back to sender.
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function retrieve(address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Retrieve(msg.sender, recipient, lockId);
    }

    /**
     * @dev Get value locked.
     * @param lockId Lock to examine.
     * @return value Value held in the lock.
     */
    function getLockValue(bytes32 lockId)
        external
        view
        returns (uint value)
    {
        value = lockIdValue[lockId];
    }

}
