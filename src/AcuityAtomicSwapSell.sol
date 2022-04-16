// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract AcuityAtomicSwapSell {

    /**
     * @dev Mapping of selling address to ACU address.
     */
    mapping (address => bytes32) addressAcuAddress;

    /**
     * @dev
     */
    mapping (bytes32 => uint256) lockIdValue;

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

    /**
     * @dev Create a sell lock. Called by seller.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     */
    function lockSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout) external payable {
        // Ensure value is not 0.
        require(msg.value > 0, "Value to lock must be greater than 0.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Ensure lockId is not already in use.
        require(lockIdValue[lockId] == 0, "Sell lock already exists.");
        lockIdValue[lockId] = msg.value;
        // Log info.
//        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /**
     * Called by buyer before lock has timed out.
     */
    function unlockSell(address seller, bytes32 secret, uint256 timeout) external {
        // Check sell lock has not timed out.
        require(timeout > block.timestamp, "Lock timed out.");
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
    function timeoutSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout) external {
        // Check lock has timed out.
        require(timeout <= block.timestamp, "Lock not timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));

        require(lockIdValue[lockId] > 0, "Lock does not exist.");

        // Return funds and delete lock.
//        addDeposit(chainIdAdapterIdAssetId, lockIdValue[lockId]);
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
