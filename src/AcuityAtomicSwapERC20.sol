// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract AcuityAtomicSwapERC20 {

    /**
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint) lockIdValue;

    /**
     * @dev Value has been locked with sell asset info.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which sender can retrieve the value.
     * @param value Value being locked.
     * @param lockId Intrinisic lockId.
     * @param sellAssetId assetId the value is paying for.
     * @param sellPrice Price the asset is being sold for.
     * @param foreignAddress Address of the buyer on the sell blockchain.
     */
    event BuyLock(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 lockId, bytes32 sellAssetId, uint sellPrice, bytes32 foreignAddress);

    /**
     * @dev Value has been locked.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which sender can retrieve the value.
     * @param value Value being locked.
     * @param lockId Intrinisic lockId.
     * @param buyAssetId The asset of the buy lock this lock is responding to.
     * @param buyLockId The buy lock this lock is responding to.
     */
    event SellLock(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 lockId, bytes32 buyAssetId, bytes32 buyLockId);

    /**
     * @dev Lock has been declined by the recipient.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event DeclineByRecipient(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has been unlocked by the sender.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Intrinisic lockId.
     * @param secret The secret used to unlock the value.
     */
    event UnlockBySender(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been unlocked by the recipient.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Intrinisic lockId.
     * @param secret The secret used to unlock the value.
     */
    event UnlockByRecipient(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been timed out.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event Timeout(ERC20 indexed token, address indexed sender, address indexed recipient, bytes32 lockId);

    /**
     * @dev No value was provided.
     */
    error ZeroValue();

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
     * @dev
     */
    error TokenTransferFailed(ERC20 token, address from, address to, uint value);

    /**
     * @dev Ensure value is nonzero.
     * @param value Value to ensure not zero.
     */
    modifier notZero(uint value) {
        if (value == 0) revert ZeroValue();
        _;
    }

    /**
     * @dev
     */
    function safeTransfer(ERC20 token, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed(token, address(this), to, value);
    }

    /**
     * @dev
     */
    function safeTransferFrom(ERC20 token, address from, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed(token, from, to, value);
    }

    /**
     * @dev Lock value.
     * @param recipient Account that can unlock the lock.
     * @param token Address of token to lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param sellAssetId assetId the value is paying for.
     * @param sellPrice Price the asset is being sold for.
     * @param foreignAddress Address of the buyer on the sell blockchain.
     * @param value Value of token to lock.
     */
    function lockBuy(ERC20 token, address recipient, bytes32 hashedSecret, uint timeout, bytes32 sellAssetId, uint sellPrice, bytes32 foreignAddress, uint value)
        external
        notZero(value)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into buy lock.
        safeTransferFrom(token, msg.sender, address(this), value);
        lockIdValue[lockId] = value;
        // Log info.
        emit BuyLock(token, msg.sender, recipient, hashedSecret, timeout, value, lockId, sellAssetId, sellPrice, foreignAddress);
    }

    /**
     * @dev Lock stashed value.
     * @param sellToken Address of sell token.
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param stashAssetId Asset the stash is to be sold for.
     * @param value Value from the stash to lock.
     * @param buyLockId The buy lock this lock is responding to.
     */
    function lockSell(ERC20 sellToken, address recipient, bytes32 hashedSecret, uint timeout, bytes32 stashAssetId, uint value, bytes32 buyLockId)
        external
        notZero(value)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(sellToken, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        safeTransferFrom(sellToken, msg.sender, address(this), value);
        lockIdValue[lockId] = value;
        // Log info.
        emit SellLock(sellToken, msg.sender, recipient, hashedSecret, timeout, value, lockId, stashAssetId, buyLockId);
    }

    /**
     * @dev Transfer value back to the sender (called by recipient).
     * @param token Address of token.
     * @param sender Sender of the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timeout of the lock.
     */
    function declineByRecipient(ERC20 token, address sender, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, msg.sender, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value back to the sender.
        safeTransfer(token, sender, value);
        // Log info.
        emit DeclineByRecipient(token, sender, msg.sender, lockId);
    }

    /**
     * @dev Transfer value from lock to recipient (called by sender).
     * @param token Address of token.
     * @param recipient Recipient of the value.
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlockBySender(ERC20 token, address recipient, bytes32 secret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, recipient, value);
        // Log info.
        emit UnlockBySender(token, msg.sender, recipient, lockId, secret);
    }

    /**
     * @dev Transfer value from lock to recipient (called by recipient).
     * @param token Address of token.
     * @param sender Sender of the value.
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlockByRecipient(ERC20 token, address sender, bytes32 secret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, msg.sender, value);
        // Log info.
        emit UnlockByRecipient(token, sender, msg.sender, lockId, secret);
    }

    /**
     * @dev Transfer value from lock back to sender.
     * @param token Address of token.
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function timeoutValue(ERC20 token, address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, msg.sender, value);
        // Log info.
        emit Timeout(token, msg.sender, recipient, lockId);
    }

    /**
     * @dev Get value locked.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which sender can retrieve the value.
     * @return value Value held in the lock.
     */
    function getLockValue(ERC20 token, address sender, address recipient, bytes32 hashedSecret, uint timeout)
        external
        view
        returns (uint value)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, recipient, hashedSecret, timeout));
        value = lockIdValue[lockId];
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
