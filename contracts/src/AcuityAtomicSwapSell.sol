// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract AcuityAtomicSwapSell {

    struct SellLock {
        bytes16 orderId;
        uint64 value;
        uint32 timeout;
    }

    mapping (bytes16 => uint256) orderIdValue;

    mapping (bytes32 => SellLock) hashedSecretSellLock;

    /**
     * @dev
     */
    event AddToOrder(address indexed seller, bytes16 indexed orderId, uint256 price, uint256 value);

    /**
     * @dev
     */
    event RemoveFromOrder(address indexed seller, bytes16 indexed orderId, uint256 price, uint256 value);

    /**
     * @dev
     */
    event LockSell(bytes16 indexed orderId, bytes32 indexed hashedSecret, address indexed seller, uint256 value, uint256 timeout);

    /**
     * @dev
     */
    event UnlockSell(bytes32 indexed hashedSecret, address indexed dest, uint256 value, bytes32 secret);

    /**
     * @dev
     */
    event TimeoutSell(bytes32 indexed hashedSecret, bytes16 indexed orderId, uint256 value);

    /*
     * Called by seller.
     */
    function addToOrder(uint256 price) payable external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, price)));
        // Add value to order.
        orderIdValue[orderId] += msg.value;
        // Log info.
        emit AddToOrder(msg.sender, orderId, price, msg.value);
    }

    /*
     * Called by seller.
     */
    function removeFromOrder(uint256 price, uint256 value) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, price)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Remove value from order.
        orderIdValue[orderId] -= value;
        // Return the funds. Cast value to uint128 for Solang compatibility.
        payable(msg.sender).transfer(uint128(value));
        // Log info.
        emit RemoveFromOrder(msg.sender, orderId, price, value);
    }

    /*
     * Called by seller.
     */
    function lockSell(uint256 price, bytes32 hashedSecret, uint256 timeout, uint256 value) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, price)));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Ensure hashed secret is not already in use.
        SellLock storage lock = hashedSecretSellLock[hashedSecret];
        require (lock.value == 0, "Hashed secret already in use.");
        // Move value into sell lock.
        orderIdValue[orderId] -= value;
        lock.orderId = orderId;
        lock.value = uint64(value);
        lock.timeout = uint32(timeout);
        // Log info.
        emit LockSell(orderId, hashedSecret, msg.sender, value, timeout);
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
        // Send the funds. Cast value to uint128 for Solang compatibility.
        payable(msg.sender).transfer(uint128(value));
        // Log info.
        emit UnlockSell(hashedSecret, msg.sender, value, secret);
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(uint256 price, bytes32 hashedSecret) external {
        // Calculate orderId.
        bytes16 orderId = bytes16(keccak256(abi.encodePacked(msg.sender, price)));
        // Check orderId is correct and lock has timed out.
        require (hashedSecretSellLock[hashedSecret].orderId == orderId, "Wrong orderId.");
        require (hashedSecretSellLock[hashedSecret].timeout <= block.timestamp, "Lock not timed out.");
        // Get lock value and delete lock.
        uint256 value = hashedSecretSellLock[hashedSecret].value;
        delete hashedSecretSellLock[hashedSecret];
        // Return funds to sell order.
        orderIdValue[orderId] += value;
        // Log info.
        emit TimeoutSell(hashedSecret, orderId, value);
    }

    function getOrderValue(address seller, uint256 price) view external returns (uint256 value) {
        value = orderIdValue[bytes16(keccak256(abi.encodePacked(seller, price)))];
    }

    function getOrderValue(bytes16 orderId) view external returns (uint256 value) {
        value = orderIdValue[orderId];
    }

    function getSellLock(bytes32 hashedSecret) view external returns (bytes16 orderId, uint256 value, uint256 timeout) {
        SellLock storage sellLock = hashedSecretSellLock[hashedSecret];
        orderId = sellLock.orderId;
        value = sellLock.value;
        timeout = sellLock.timeout;
    }

}
