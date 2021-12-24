// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

contract AcuityAtomicSwapSell {

    mapping (bytes32 => uint256) orderIdValue;

    mapping (bytes32 => uint256) sellLockIdValue;

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
    event UnlockSell(bytes16 orderId, bytes32 secret, address buyer);

    /**
     * @dev
     */
    event TimeoutSell(bytes16 orderId, bytes32 hashedSecret);

    /*
     * Called by seller.
     * @param chainIdAdapterIdAssetIdPrice 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId, 16 bytes integer unit price denominated in smallest unit of foreign asset.
     * @param foreignAddress Address on the destination asset.
     */
    function addToOrder(bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress) payable external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, chainIdAdapterIdAssetIdPrice, foreignAddress)));
        // Add value to order.
        orderIdValue[orderId] += msg.value;
        // Log info.
        emit AddToOrder(orderId, msg.sender, chainIdAdapterIdAssetIdPrice, foreignAddress, msg.value);
    }

    /*
     * Called by seller.
     */
    function changeOrder(bytes32 oldChainIdAdapterIdAssetIdPrice, bytes32 oldForeignAddress, bytes32 newChainIdAdapterIdAssetIdPrice, bytes32 newForeignAddress, uint256 value) external {
        // Calculate orderIds.
        bytes16 oldOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, oldChainIdAdapterIdAssetIdPrice, oldForeignAddress)));
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, newChainIdAdapterIdAssetIdPrice, newForeignAddress)));
        // Check there is enough.
        require (orderIdValue[oldOrderId] >= value, "Sell order not big enough.");
        // Transfer value.
        orderIdValue[oldOrderId] -= value;
        orderIdValue[newOrderId] += value;
        // Log info.
        emit RemoveFromOrder(oldOrderId, value);
        emit AddToOrder(newOrderId, msg.sender, newChainIdAdapterIdAssetIdPrice, newForeignAddress, value);
    }

    /*
     * Called by seller.
     */
    function changeOrder(bytes32 oldChainIdAdapterIdAssetIdPrice, bytes32 oldForeignAddress, bytes32 newChainIdAdapterIdAssetIdPrice, bytes32 newForeignAddress) external {
        // Calculate orderIds.
        bytes16 oldOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, oldChainIdAdapterIdAssetIdPrice, oldForeignAddress)));
        bytes16 newOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, newChainIdAdapterIdAssetIdPrice, newForeignAddress)));
        // Get order value.
        uint256 value = orderIdValue[oldOrderId];
        // Delete old order.
        delete orderIdValue[oldOrderId];
        // Transfer value.
        orderIdValue[newOrderId] += value;
        // Log info.
        emit RemoveFromOrder(oldOrderId, value);
        emit AddToOrder(newOrderId, msg.sender, newChainIdAdapterIdAssetIdPrice, newForeignAddress, value);
    }

    /*
     * Called by seller.
     */
    function removeFromOrder(bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress, uint256 value) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, chainIdAdapterIdAssetIdPrice, foreignAddress)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Remove value from order.
        orderIdValue[orderId] -= value;
        // Return the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit RemoveFromOrder(orderId, value);
    }

    /*
     * Called by seller.
     */
    function removeFromOrder(bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, chainIdAdapterIdAssetIdPrice, foreignAddress)));
        // Get order value.
        uint256 value = orderIdValue[orderId];
        // Delete order.
        delete orderIdValue[orderId];
        // Return the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit RemoveFromOrder(orderId, value);
    }

    /*
     * Called by seller.
     */
    function lockSell(bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress, bytes32 hashedSecret, address buyer, uint256 timeout, uint256 value) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, chainIdAdapterIdAssetIdPrice, foreignAddress)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Calculate sellLockId.
        bytes32 sellLockId = keccak256(abi.encodePacked(orderId, hashedSecret, buyer, timeout));
        // Ensure sellLockId is not already in use.
        require (sellLockIdValue[sellLockId] == 0, "Sell lock already exists.");
        // Move value into sell lock.
        orderIdValue[orderId] -= value;
        sellLockIdValue[sellLockId] = value;
        // Log info.
        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /*
     * Called by anyone.
     */
    function unlockSell(bytes16 orderId, bytes32 secret, address buyer, uint256 timeout) external {
        // Check sell lock has not timed out.
        require (timeout > block.timestamp, "Lock timed out.");
        // Calculate sellLockId.
        bytes32 sellLockId = keccak256(abi.encodePacked(orderId, keccak256(abi.encodePacked(secret)), buyer, timeout));
        // Get lock value;
        uint256 value = sellLockIdValue[sellLockId];
        // Delete lock.
        delete sellLockIdValue[sellLockId];
        // Send the funds.
        payable(buyer).transfer(value);
        // Log info.
        emit UnlockSell(orderId, secret, msg.sender);
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(bytes16 orderId, bytes32 hashedSecret, address buyer, uint256 timeout) external {
        // Check lock has timed out.
        require (timeout <= block.timestamp, "Lock not timed out.");
        // Calculate sellLockId.
        bytes32 sellLockId = keccak256(abi.encodePacked(orderId, hashedSecret, buyer, timeout));
        // Return funds to sell order and delete lock.
        orderIdValue[orderId] += sellLockIdValue[sellLockId];
        delete sellLockIdValue[sellLockId];
        // Log info.
        emit TimeoutSell(orderId, hashedSecret);
    }

    function getOrderValue(address seller, bytes32 chainIdAdapterIdAssetIdPrice, bytes32 foreignAddress) view external returns (uint256 value) {
        value = orderIdValue[bytes16(keccak256(abi.encodePacked(seller, chainIdAdapterIdAssetIdPrice, foreignAddress)))];
    }

    function getOrderValue(bytes16 orderId) view external returns (uint256 value) {
        value = orderIdValue[orderId];
    }

    function getSellLock(bytes16 orderId, bytes32 hashedSecret, address buyer, uint256 timeout) view external returns (uint256 value) {
        value = sellLockIdValue[keccak256(abi.encodePacked(orderId, hashedSecret, buyer, timeout))];
    }

    function getSellLock(bytes32 sellLockId) view external returns (uint256 value) {
        value = sellLockIdValue[sellLockId];
    }

}
