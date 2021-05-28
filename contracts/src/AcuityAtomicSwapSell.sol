// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract AcuityAtomicSwapSell {

    struct SellLock {
        bytes32 orderId;
        uint128 value;
        uint128 timeout;
    }

    mapping (bytes32 => uint256) orderIdValue;

    mapping (bytes32 => SellLock) hashedSecretSellLock;

    /**
     * @dev
     */
    event CreateOrder(address indexed seller, bytes32 indexed orderId, uint256 price, uint256 value);

    /**
     * @dev
     */
    event LockSell(bytes32 indexed orderId, bytes32 indexed hashedSecret, address indexed seller, uint256 value, uint256 timeout);

    /**
     * @dev
     */
    event UnlockSell(bytes32 indexed hashedSecret, address indexed dest, uint256 value, bytes32 secret);

    /**
     * @dev
     */
    event TimeoutSell(bytes32 indexed hashedSecret, bytes32 indexed orderId, uint256 value);

    /*
     * Called by seller.
     */
    function createOrder(uint256 price) payable external returns (bytes32 orderId) {
        // Get orderId.
        orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Get order.
        orderIdValue[orderId] += msg.value;
        // Log info.
        emit CreateOrder(msg.sender, orderId, price, msg.value);
    }

    /*
     * Called by seller.
     */
    function lockSell(uint256 price, bytes32 hashedSecret, uint256 timeout, uint256 value) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Check there is enough.
        require (orderIdValue[orderId] >= value, "Sell order not big enough.");
        // Move value.
        orderIdValue[orderId] -= value;
        hashedSecretSellLock[hashedSecret].value = uint64(value);
        hashedSecretSellLock[hashedSecret].timeout = uint64(timeout);
        hashedSecretSellLock[hashedSecret].orderId = orderId;
        // Log info.
        emit LockSell(orderId, hashedSecret, msg.sender, value, timeout);
    }

    /*
     * Called by buyer.
     */
    function unlockSell(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretSellLock[hashedSecret].timeout > block.timestamp, "Lock timed out.");
        uint256 value = hashedSecretSellLock[hashedSecret].value;
        delete hashedSecretSellLock[hashedSecret];
        payable(msg.sender).transfer(value);
        // Log info.
        emit UnlockSell(hashedSecret, msg.sender, value, secret);
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(uint256 price, bytes32 hashedSecret) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        require (hashedSecretSellLock[hashedSecret].orderId == orderId, "Wrong orderId.");
        require (hashedSecretSellLock[hashedSecret].timeout <= block.timestamp, "Lock not timed out.");
        uint256 value = hashedSecretSellLock[hashedSecret].value;
        orderIdValue[orderId] += value;
        delete hashedSecretSellLock[hashedSecret];
        // Log info.
        emit TimeoutSell(hashedSecret, orderId, value);
    }

    function getOrderValue(address seller, uint256 price) view external returns (uint256 value) {
        value = orderIdValue[keccak256(abi.encodePacked(seller, price))];
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
