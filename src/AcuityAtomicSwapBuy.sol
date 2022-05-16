// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract AcuityAtomicSwapBuy {

    /**
     * @dev Mapping of lockId to locked value.
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev Mapping of seller to linked list of locks, starting with the largest.
     */
    mapping(address => mapping(bytes32 => bytes32)) sellerLockIdsLL;

    /**
     * @dev
     */
    event LockBuy(address buyer, address seller, bytes32 hashedSecret, uint256 timeout, uint256 value);

    /**
     * @dev
     */
    event UnlockBuy(bytes32 lockId);

    /**
     * @dev
     */
    event TimeoutBuy(bytes32 lockId);

    /**
     * @dev
     */
    error ZeroValue();

    /**
     * @dev
     */
    error LockAlreadyExists(bytes32 lockId);

    /**
     * @dev
     */
    error LockNotTimedOut();

    /**
     * @dev Called by buyer.
     */
    function lockBuy(address seller, bytes32 hashedSecret, uint256 timeout) payable external {
        // Ensure value is nonzero.
        if (msg.value == 0) revert ZeroValue();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, seller, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Store lock value.
        lockIdValue[lockId] = msg.value;
        // Get linked list of seller's lockIds.
        mapping(bytes32 => bytes32) storage lockIdsLL = sellerLockIdsLL[seller];
        // Search for correct place to insert lockId.
        bytes32 prev = 0;
        while (msg.value < lockIdValue[lockIdsLL[prev]]) {
            prev = lockIdsLL[prev];
        }
        // Insert lockId into linked list.
        lockIdsLL[lockId] = lockIdsLL[prev];
        lockIdsLL[prev] = lockId;
        // Log info.
        emit LockBuy(msg.sender, seller, hashedSecret, timeout, msg.value);
    }

    /**
     * @dev Remove lock from linked list and delete value.
     */
    function removeLock(address seller, bytes32 lockId) internal {
        // Get linked list of seller's lockIds.
        mapping(bytes32 => bytes32) storage lockIdsLL = sellerLockIdsLL[seller];
        // Find the previous lock.
        bytes32 prev = 0;
        while (lockIdsLL[prev] != 0) {
            if (lockIdsLL[prev] == lockId) {
                // Remove the lock from the list.
                lockIdsLL[prev] = lockIdsLL[lockId];
                break;
            }
            prev = lockIdsLL[prev];
        }
        // Remove the lock.
        delete lockIdsLL[lockId];
        delete lockIdValue[lockId];
    }

    /**
     * @dev Called by seller.
     */
    function unlockBuy(address buyer, bytes32 secret, uint256 timeout) external {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(buyer, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        removeLock(msg.sender, lockId);
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit UnlockBuy(lockId);
    }

    /**
     * @dev Called by buyer if seller did not lock.
     */
    function timeoutBuy(address seller, bytes32 hashedSecret, uint256 timeout) external {
        // Check lock has timed out.
        if (timeout > block.timestamp) revert LockNotTimedOut();
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, seller, hashedSecret, timeout));
        // Get lock value;
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        removeLock(seller, lockId);
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit TimeoutBuy(lockId);
    }

    /**
     * @dev
     */
    function getLocks(address seller, uint limit) view external returns (bytes32[] memory lockIds) {
        // Get linked list of seller's lockIds.
        mapping(bytes32 => bytes32) storage lockIdsLL = sellerLockIdsLL[seller];
        // Count how many lockIds to return.
        uint _limit = 0;
        bytes32 prev = 0;
        while (lockIdsLL[prev] != 0 && _limit < limit) {
            prev = lockIdsLL[prev];
            _limit++;
        }
        // Allocate the array.
        lockIds = new bytes32[](_limit);
        // Populate the array.
        prev = 0;
        for (uint i = 0; i < _limit; i++) {
            lockIds[i] = lockIdsLL[prev];
            prev = lockIdsLL[prev];
        }
    }

    /**
     * @dev
     */
    function getLock(address buyer, address seller, bytes32 hashedSecret, uint256 timeout) view external returns (uint256 value) {
        value = lockIdValue[keccak256(abi.encodePacked(buyer, seller, hashedSecret, timeout))];
    }

    /**
     * @dev
     */
    function getLock(bytes32 lockId) view external returns (uint256 value) {
        value = lockIdValue[lockId];
    }

}
