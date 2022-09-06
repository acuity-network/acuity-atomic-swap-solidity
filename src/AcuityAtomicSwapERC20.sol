// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./AcuityAccount.sol";
import "./ERC20.sol";

contract AcuityAtomicSwapERC20 {

    /**
     * @dev Address of AcuityAccount contract.
     */
    AcuityAccount public immutable acuityAccount;

    /**
     * @dev Mapping of sell token address to buy assetId to linked list of accounts, starting with the largest.
     */
    mapping (address => mapping (bytes32 => mapping (address => address))) tokenAssetIdAccountLL;

    /**
     * @dev Mapping of sell token address to buy assetId to selling account to value.
     */
    mapping (address => mapping (bytes32 => mapping (address => uint))) tokenAssetIdAccountValue;

    /**
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev Value has been added to a stash.
     * @param token Address of token.
     * @param account Account adding to a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param value How much value has been added to the stash.
     */
    event StashAdd(address indexed token, address indexed account, bytes32 indexed assetId, uint256 value);

    /**
     * @dev Value has been removed from a stash.
     * @param token Address of token.
     * @param account Account removing from a stash.
     * @param assetId Asset the stash is to be sold for.
     * @param value How much value has been removed from the stash.
     */
    event StashRemove(address indexed token, address indexed account, bytes32 indexed assetId, uint256 value);

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
     */
    event BuyLock(address indexed token, address indexed sender, address indexed recipient, bytes32 hashedSecret, uint256 timeout, uint256 value, bytes32 lockId, bytes32 sellAssetId, uint256 sellPrice);

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
    event SellLock(address indexed token, address indexed sender, address indexed recipient, bytes32 hashedSecret, uint256 timeout, uint256 value, bytes32 lockId, bytes32 buyAssetId, bytes32 buyLockId);

    /**
     * @dev Lock has been declined by the recipient.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event DeclineByRecipient(address indexed token, address indexed sender, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has been unlocked by the sender.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Intrinisic lockId.
     * @param secret The secret used to unlock the value.
     */
    event UnlockBySender(address indexed token, address indexed sender, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been unlocked by the recipient.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Intrinisic lockId.
     * @param secret The secret used to unlock the value.
     */
    event UnlockByRecipient(address indexed token, address indexed sender, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been timed out.
     * @param token Address of token.
     * @param sender Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Intrinisic lockId.
     */
    event Timeout(address indexed token, address indexed sender, address indexed recipient, bytes32 lockId);

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
    error TokenTransferFailed(address token, address from, address to, uint value);

    /**
     * @dev Invalid proxy account.
     * @param account Account being proxied.
     * @param proxyAccount Invalid proxy account.
     */
    error InvalidProxy(address account, address proxyAccount);

    /**
     * @dev Check if account is proxy for msg.sender
     * @param account Account to check.
     */
    modifier checkProxy(address account) {
        if (acuityAccount.getProxyAccount(account) != msg.sender) {
            revert InvalidProxy(account, msg.sender);
        }
        _;
    }

    /**
     * @param _acuityAccount Address of AcuityAccount contract.
     */
    constructor (AcuityAccount _acuityAccount) {
        acuityAccount = _acuityAccount;
    }

    /**
     * @dev
     */
    function safeTransfer(address token, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed(token, address(this), to, value);
    }

    /**
     * @dev
     */
    function safeTransferFrom(address token, address from, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed(token, from, to, value);
    }

    /**
     * @dev Add value to stash be sold for a specific asset.
     * @param token Address of sell token.
     * @param account Account to add stash for.
     * @param assetId Asset the stash is to be sold for.
     * @param value Size of deposit to add. 0 will result in corrupted state.
     */
    function stashAdd(address token, address account, bytes32 assetId, uint value)
        internal
    {
        mapping (address => address) storage accountLL = tokenAssetIdAccountLL[token][assetId];
        mapping (address => uint) storage accountValue = tokenAssetIdAccountValue[token][assetId];
        // Get new total.
        uint currentValue = accountValue[account];
        uint total = currentValue + value;
        // Search for new previous.
        address prev = address(0);
        address next = accountLL[prev];
        while (accountValue[next] >= total) {
            prev = next;
            next = accountLL[prev];
        }
        // Is sender already in the list?
        if (currentValue > 0) {
            // Search for old previous.
            address oldPrev = prev;
            address oldNext = next;
            while (oldNext != account) {
                oldPrev = oldNext;
                oldNext = accountLL[oldPrev];
            }
            // Is it in a different position?
            if (prev != oldPrev) {
                // Remove sender from current position.
                accountLL[oldPrev] = accountLL[account];
                // Insert into linked list.
                accountLL[account] = next;
                accountLL[prev] = account;
            }
        }
        else {
            // Insert into linked list.
            accountLL[account] = next;
            accountLL[prev] = account;
        }
        // Update the value deposited.
        accountValue[account] = total;
        // Log info.
        emit StashAdd(token, account, assetId, value);
    }

    /**
     * @dev Remove value from stash be sold for a specific asset.
     * @param token Address of sell token.
     * @param account Account to add stash for.
     * @param assetId Asset the stash is to be sold for.
     * @param value Size of deposit to remove. Will revert if bigger than or equal to deposit value.
     */
    function stashRemove(address token, address account, bytes32 assetId, uint value)
        internal
    {
        mapping (address => address) storage accountLL = tokenAssetIdAccountLL[token][assetId];
        mapping (address => uint) storage accountValue = tokenAssetIdAccountValue[token][assetId];
        // Get new total. Will revert if value is bigger than current stash.
        uint total = accountValue[account] - value;
        // Search for old previous.
        address oldPrev = address(0);
        address oldNext = accountLL[oldPrev];
        while (oldNext != account) {
            oldPrev = oldNext;
            oldNext = accountLL[oldPrev];
        }
        // Is there still a stash?
        if (total > 0) {
            // Search for new previous.
            address prev = oldPrev;
            address next = oldNext;
            while (accountValue[next] >= total) {
                prev = next;
                next = accountLL[prev];
            }
            // Is it in a new position?
            if (prev != account) {
                // Remove sender from old position.
                accountLL[oldPrev] = accountLL[account];
                // Insert into new position.
                accountLL[account] = next;
                accountLL[prev] = account;
            }
        }
        else {
            // Remove sender from list.
            accountLL[oldPrev] = accountLL[account];
        }
        // Update the value deposited.
        accountValue[account] = total;
        // Log info.
        emit StashRemove(token, account, assetId, value);
    }

    /**
     * @dev Stash value to be sold for a specific asset.
     * @param sellToken Address of sell token.
     * @param assetId Asset the stash is to be sold for.
     * @param value Size of deposit.
     */
    function depositStash(address sellToken, bytes32 assetId, uint value)
        external
    {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Move the token.
        safeTransferFrom(sellToken, msg.sender, address(this), value);
        // Record the deposit.
        stashAdd(sellToken, msg.sender, assetId, value);
    }

    /**
     * @dev Move value from one stash to another.
     * @param sellToken Address of sell token.
     * @param assetIdFrom Asset the source stash is to be sold for.
     * @param assetIdTo Asset the destination stash is to be sold for.
     * @param value Value to move.
     */
    function moveStash(address sellToken, bytes32 assetIdFrom, bytes32 assetIdTo, uint value)
        external
    {
         // Move the deposit.
         stashRemove(sellToken, msg.sender, assetIdFrom, value);
         stashAdd(sellToken, msg.sender, assetIdTo, value);
     }

    /**
     * @dev Withdraw value from a stash.
     * @param sellToken Address of sell token.
     * @param assetId Asset the stash is to be sold for.
     * @param value Value to withdraw.
     */
    function withdrawStash(address sellToken, bytes32 assetId, uint value)
        external
    {
        // Remove the deposit.
        stashRemove(sellToken, msg.sender, assetId, value);
        // Send the funds back.
        safeTransfer(sellToken, msg.sender, value);
    }

    /**
     * @dev Withdraw all value from a stash.
     * @param sellToken Address of sell token.
     * @param assetId Asset the stash is to be sold for.
     */
    function withdrawStash(address sellToken, bytes32 assetId)
        external
    {
        uint value = tokenAssetIdAccountValue[sellToken][assetId][msg.sender];
        // Remove the deposit.
        stashRemove(sellToken, msg.sender, assetId, value);
        // Send the funds back.
        safeTransfer(sellToken, msg.sender, value);
    }

    /**
     * @dev Lock value.
     * @param recipient Account that can unlock the lock.
     * @param token Address of token to lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param sellAssetId assetId the value is paying for.
     * @param sellPrice Price the asset is being sold for.
     * @param value Value of token to lock.
     */
    function lockBuy(address token, address recipient, bytes32 hashedSecret, uint256 timeout, bytes32 sellAssetId, uint256 sellPrice, uint value)
        external
    {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into buy lock.
        safeTransferFrom(token, msg.sender, address(this), value);
        lockIdValue[lockId] = value;
        // Log info.
        emit BuyLock(token, msg.sender, recipient, hashedSecret, timeout, value, lockId, sellAssetId, sellPrice);
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
    function lockSell(address sellToken, address recipient, bytes32 hashedSecret, uint256 timeout, bytes32 stashAssetId, uint256 value, bytes32 buyLockId)
        external
    {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(sellToken, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        stashRemove(sellToken, msg.sender, stashAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
        emit SellLock(sellToken, msg.sender, recipient, hashedSecret, timeout, value, lockId, stashAssetId, buyLockId);
    }

    /**
     * @dev Lock stashed value.
     * @param sellToken Address of sell token.
     * @param sender Sender of the value (checked for proxy).
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will open.
     * @param stashAssetId Asset the stash is to be sold for.
     * @param value Value from the stash to lock.
     * @param buyLockId The buy lock this lock is responding to.
     */
    function lockSellProxy(address sellToken, address sender, address recipient, bytes32 hashedSecret, uint256 timeout, bytes32 stashAssetId, uint256 value, bytes32 buyLockId)
        external
        checkProxy(sender)
    {
        // Ensure value is nonzero.
        if (value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(sellToken, sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Move value into sell lock.
        stashRemove(sellToken, sender, stashAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
        emit SellLock(sellToken, sender, recipient, hashedSecret, timeout, value, lockId, stashAssetId, buyLockId);
    }

    /**
     * @dev Transfer value back to the sender (called by recipient).
     * @param token Address of token.
     * @param sender Sender of the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timeout of the lock.
     */
    function declineByRecipient(address token, address sender, bytes32 hashedSecret, uint256 timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, msg.sender, hashedSecret, timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
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
    function unlockBySender(address token, address recipient, bytes32 secret, uint256 timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, keccak256(abi.encodePacked(secret)), timeout));
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
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
    function unlockByRecipient(address token, address sender, bytes32 secret, uint256 timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, msg.sender, value);
        // Log info.
        emit UnlockByRecipient(token, sender, msg.sender, lockId, secret);
    }

    /**
     * @dev Transfer value from lock to recipient (called by recipient).
     * @param token Address of token.
     * @param sender Sender of the value.
     * @param recipient Receiver of the value (checked for proxy).
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlockByRecipientProxy(address token, address sender, address recipient, bytes32 secret, uint256 timeout)
        external
        checkProxy(recipient)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, recipient, keccak256(abi.encodePacked(secret)), timeout));
        // Check lock has not timed out.
        if (timeout <= block.timestamp) revert LockTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, recipient, value);
        // Log info.
        emit UnlockByRecipient(token, sender, recipient, lockId, secret);
    }

    /**
     * @dev Transfer value from lock back to sender's stash.
     * @param token Address of token.
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret recipient unlock the value.
     * @param timeout Timeout of the lock.
     */
    function timeoutStash(address token, address recipient, bytes32 hashedSecret, uint256 timeout, bytes32 stashAssetId)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Ensure lock has value
        if (value == 0) revert ZeroValue();
        // Delete lock.
        delete lockIdValue[lockId];
        // Return funds.
        stashAdd(token, msg.sender, stashAssetId, value);
        // Log info.
        emit Timeout(token, msg.sender, recipient, lockId);
    }

    /**
     * @dev Transfer value from lock back to sender's stash.
     * @param token Address of token.
     * @param sender Sender of the value (checked for proxy).
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret recipient unlock the value.
     * @param timeout Timeout of the lock.
     */
    function timeoutStashProxy(address token, address sender, address recipient, bytes32 hashedSecret, uint256 timeout, bytes32 stashAssetId)
        external
        checkProxy(sender)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, recipient, hashedSecret, timeout));
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Ensure lock has value
        if (value == 0) revert ZeroValue();
        // Delete lock.
        delete lockIdValue[lockId];
        // Return funds.
        stashAdd(token, sender, stashAssetId, value);
        // Log info.
        emit Timeout(token, sender, recipient, lockId);
    }

    /**
     * @dev Transfer value from lock back to sender.
     * @param token Address of token.
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function timeoutValue(address token, address recipient, bytes32 hashedSecret, uint256 timeout)
        external
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, msg.sender, value);
        // Log info.
        emit Timeout(token, msg.sender, recipient, lockId);
    }

    /**
     * @dev Transfer value from lock back to sender.
     * @param token Address of token.
     * @param sender Sender of the value (checked for proxy).
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function timeoutValueProxy(address token, address sender, address recipient, bytes32 hashedSecret, uint256 timeout)
        external
        checkProxy(sender)
    {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encode(token, sender, recipient, hashedSecret, timeout));
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut(lockId);
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer the value.
        safeTransfer(token, sender, value);
        // Log info.
        emit Timeout(token, sender, recipient, lockId);
    }

    /**
     * @dev Get a list of deposits for a specific asset.
     * @param token Address of token stashed.
     * @param assetId Asset the stash is to be sold for.
     * @param offset Number of deposits to skip from the start of the list.
     * @param limit Maximum number of deposits to return.
     */
    function getStashes(address token, bytes32 assetId, uint offset, uint limit)
        external
        view
        returns (address[] memory accounts, uint[] memory values)
    {
        mapping (address => address) storage accountLL = tokenAssetIdAccountLL[token][assetId];
        mapping (address => uint) storage accountValue = tokenAssetIdAccountValue[token][assetId];
        // Find first account after offset.
        address account = address(0);
        address next = accountLL[account];
        while (offset > 0) {
            if (next == address(0)) {
                break;
            }
            account = next;
            next = accountLL[account];
            --offset;
        }
        // Count how many accounts to return.
        uint _limit = 0;
        while (next != address(0) && _limit < limit) {
            next = accountLL[next];
            ++_limit;
        }
        // Allocate the arrays.
        accounts = new address[](_limit);
        values = new uint[](_limit);
        // Populate the arrays.
        for (uint i = 0; i < _limit; ++i) {
            account = accountLL[account];
            accounts[i] = account;
            values[i] = accountValue[account];
        }
    }

    /**
     * @dev Get value held in a stash.
     * @param token Address of token stashed.
     * @param assetId Asset the stash is to be sold for.
     * @param seller Owner of the stash.
     * @return value Value held in the stash.
     */
    function getStashValue(address token, bytes32 assetId, address seller)
        external
        view
        returns (uint256 value)
    {
        value = tokenAssetIdAccountValue[token][assetId][seller];
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
    function getLockValue(address token, address sender, address recipient, bytes32 hashedSecret, uint256 timeout)
        external
        view
        returns (uint256 value)
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
        returns (uint256 value)
    {
        value = lockIdValue[lockId];
    }

}
