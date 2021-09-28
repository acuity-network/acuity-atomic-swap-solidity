// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

contract AcuityAtomicSwapSell {

    struct SellLock {
        bytes16 orderId;
        uint64 value;
        uint48 timeout;
    }

    mapping (bytes32 => uint256) orderIdValue;

    mapping (bytes32 => SellLock) hashedSecretSellLock;

    /**
     * @dev
     */
    event AddToOrder(address seller, bytes32 assetIdPrice, bytes32 foreignAddress, uint256 value);

    /**
     * @dev
     */
    event RemoveFromOrder(address seller, bytes32 assetIdPrice, bytes32 foreignAddress, uint256 value);

    /**
     * @dev
     */
    event LockSell(bytes32 hashedSecret, bytes32 orderId, uint64 value, uint48 timeout);

    /**
     * @dev
     */
    event UnlockSell(bytes32 secret, address buyer);

    /**
     * @dev
     */
    event TimeoutSell(bytes32 hashedSecret);

    /*
     * Called by seller.
     * @param assetIdPrice 16 bytes foreign assetId, 16 bytes integer unit price denominated in smallest unit of foreign asset.
     * @param foreignAddress Address on the destination asset.
     */
    function addToOrder(bytes32 assetIdPrice, bytes32 foreignAddress) payable external {
        // Calculate orderId.
        bytes32 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, assetIdPrice, foreignAddress)));
        // Add value to order.
        orderIdValue[orderId] += msg.value;
        // Log info.
        emit AddToOrder(msg.sender, assetIdPrice, foreignAddress, msg.value);
    }

    /*
     * Called by seller.
     */
    function changeOrder(bytes32 oldAssetIdPrice, bytes32 oldForeignAddress,
        bytes32 newAssetIdPrice, bytes32 newForeignAddress, uint256 value) external
    {
        // Calculate orderIds.
        bytes32 oldOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, oldAssetIdPrice, oldForeignAddress)));
        bytes32 newOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, newAssetIdPrice, newForeignAddress)));
        // Check there is enough.
        require (orderIdValue[oldOrderId] >= value, "Sell order not big enough.");
        // Transfer value.
        orderIdValue[oldOrderId] -= value;
        orderIdValue[newOrderId] += value;
        // Log info.
        emit RemoveFromOrder(msg.sender, oldAssetIdPrice, oldForeignAddress, value);
        emit AddToOrder(msg.sender, newAssetIdPrice, newForeignAddress, value);
    }

    /*
     * Called by seller.
     */
    function changeOrder(bytes32 oldAssetIdPrice, bytes32 oldForeignAddress,
        bytes32 newAssetIdPrice, bytes32 newForeignAddress) external
    {
        // Calculate orderIds.
        bytes32 oldOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, oldAssetIdPrice, oldForeignAddress)));
        bytes32 newOrderId = bytes16(keccak256(abi.encodePacked(msg.sender, newAssetIdPrice, newForeignAddress)));
        // Get order value.
        uint256 value = orderIdValue[oldOrderId];
        // Delete old order.
        delete orderIdValue[oldOrderId];
        // Transfer value.
        orderIdValue[newOrderId] += value;
        // Log info.
        emit RemoveFromOrder(msg.sender, oldAssetIdPrice, oldForeignAddress, value);
        emit AddToOrder(msg.sender, newAssetIdPrice, newForeignAddress, value);
    }

    /*
     * Called by seller.
     */
    function removeFromOrder(bytes32 assetIdPrice, bytes32 foreignAddress, uint256 value) external {
        // Calculate orderId.
        bytes32 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, assetIdPrice, foreignAddress)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Remove value from order.
        orderIdValue[orderId] -= value;
        // Return the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit RemoveFromOrder(msg.sender, assetIdPrice, foreignAddress, value);
    }

    /*
     * Called by seller.
     */
    function removeFromOrder(bytes32 assetIdPrice, bytes32 foreignAddress) external {
        // Calculate orderId.
        bytes32 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, assetIdPrice, foreignAddress)));
        // Get order value.
        uint256 value = orderIdValue[orderId];
        // Delete order.
        delete orderIdValue[orderId];
        // Return the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit RemoveFromOrder(msg.sender, assetIdPrice, foreignAddress, value);
    }

    /*
     * Called by seller.
     */
    function lockSell(bytes32 hashedSecret, bytes32 assetIdPrice, bytes32 foreignAddress, uint256 value, uint256 timeout) external {
        // Calculate orderId.
        bytes32 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, assetIdPrice, foreignAddress)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Ensure hashed secret is not already in use.
        SellLock storage lock = hashedSecretSellLock[hashedSecret];
        require (lock.value == 0, "Hashed secret already in use.");
        // Move value into sell lock.
        orderIdValue[orderId] -= value;
        lock.orderId = bytes16(orderId);
        lock.value = uint64(value);
        lock.timeout = uint48(timeout);
        // Log info.
        emit LockSell(hashedSecret, orderId, uint64(value), uint48(timeout));
    }

    /*
     * Called by buyer.
     */
    function unlockSell(bytes32 secret) external {
        // Calculate hashed secret.
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        // Check sell lock has not timed out.
        require (hashedSecretSellLock[hashedSecret].timeout > block.timestamp, "Lock timed out.");
        // Get lock value and delete lock.
        uint256 value = hashedSecretSellLock[hashedSecret].value;
        delete hashedSecretSellLock[hashedSecret];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit UnlockSell(secret, msg.sender);
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(bytes32 hashedSecret, bytes32 assetIdPrice, bytes32 foreignAddress) external {
        // Calculate orderId.
        bytes32 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, assetIdPrice, foreignAddress)));
        // Check orderId is correct and lock has timed out.
        require (hashedSecretSellLock[hashedSecret].orderId == orderId, "Wrong orderId.");
        require (hashedSecretSellLock[hashedSecret].timeout <= block.timestamp, "Lock not timed out.");
        // Get lock value and delete lock.
        uint256 value = hashedSecretSellLock[hashedSecret].value;
        delete hashedSecretSellLock[hashedSecret];
        // Return funds to sell order.
        orderIdValue[orderId] += value;
        // Log info.
        emit TimeoutSell(hashedSecret);
    }

    function getOrderValue(address seller, bytes32 assetIdPrice, bytes32 foreignAddress) view external returns (uint256 value) {
        value = orderIdValue[bytes16(keccak256(abi.encodePacked(seller, assetIdPrice, foreignAddress)))];
    }

    function getOrderValue(bytes32 orderId) view external returns (uint256 value) {
        value = orderIdValue[orderId];
    }

    function getSellLock(bytes32 hashedSecret) view external returns (bytes32 orderId, uint256 value, uint256 timeout) {
        SellLock storage sellLock = hashedSecretSellLock[hashedSecret];
        orderId = sellLock.orderId;
        value = sellLock.value;
        timeout = sellLock.timeout;
    }

}
