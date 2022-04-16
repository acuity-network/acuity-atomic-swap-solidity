// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract AcuityAtomicSwapBuy {

    /**
     * @dev Mapping of lockId to locked value.
     */
    mapping (bytes32 => uint256) lockIdValue;

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
     * @dev Called by buyer.
     */
    function lockBuy(address seller, bytes32 hashedSecret, uint256 timeout) payable external {
        // Ensure lock has value.
        require(msg.value != 0, "Lock must have value.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, seller, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        require(lockIdValue[lockId] == 0, "Buy lock already exists.");
        // Store lock value.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit LockBuy(msg.sender, seller, hashedSecret, timeout, msg.value);
    }

    /**
     * @dev Called by seller. Can be called even when the lock is expired.
     */
    function unlockBuy(address buyer, bytes32 secret, uint256 timeout) external {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(buyer, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
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
        require(timeout <= block.timestamp, "Lock not timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, seller, hashedSecret, timeout));
        // Get lock value;
        uint256 value = lockIdValue[lockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit TimeoutBuy(lockId);
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
