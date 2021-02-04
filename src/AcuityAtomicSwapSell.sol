// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract AcuityAtomicSwapSell {

    struct SellLock {
        bytes32 orderId;
        uint value;
        uint timeout;
    }

    mapping (bytes32 => uint) orderIdAmount;

    mapping (bytes32 => SellLock) hashedSecretSellLock;

    /**
     * @dev
     */
    event CreateOrder(address indexed seller, bytes32 indexed orderId, uint price, uint value);

    /**
     * @dev
     */
    event LockSell(bytes32 indexed orderId, bytes32 indexed hashedSecret, address indexed seller, uint value, uint timeout);

    /**
     * @dev
     */
    event UnlockSell(bytes32 indexed hashedSecret, address indexed dest, uint value, bytes32 secret);

    /**
     * @dev
     */
    event TimeoutSell(bytes32 indexed hashedSecret, bytes32 indexed orderId, uint value);

    /*
     * Called by seller.
     */
    function createOrder(uint price) payable external returns (bytes32 orderId) {
        // Get orderId.
        orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Get order.
        orderIdAmount[orderId] += msg.value;
        // Log info.
        emit CreateOrder(msg.sender, orderId, price, msg.value);
    }

    /*
     * Called by seller.
     */
    function lockSell(uint price, bytes32 hashedSecret, uint timeout, uint value) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Check there is enough.
        require (orderIdAmount[orderId] >= value, "Sell order not big enough.");
        // Move value.
        orderIdAmount[orderId] -= value;
        hashedSecretSellLock[hashedSecret].value = value;
        hashedSecretSellLock[hashedSecret].timeout = timeout;
        hashedSecretSellLock[hashedSecret].orderId = orderId;
        // Log info.
        emit LockSell(orderId, hashedSecret, msg.sender, value, timeout);
    }

    /*
     * Called by buyer.
     */
    function unlockSell(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretSellLock[hashedSecret].timeout < block.timestamp, "Lock timed out.");
        address _sender = msg.sender;
        uint value = hashedSecretSellLock[hashedSecret].value;
        delete hashedSecretSellLock[hashedSecret];
        assembly {
            pop(call(not(0), _sender, value, 0, 0, 0, 0))
        }
        // Log info.
        emit UnlockSell(hashedSecret, msg.sender, value, secret);
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(uint price, bytes32 hashedSecret) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        require (hashedSecretSellLock[hashedSecret].orderId == orderId, "Wrong orderId.");
        require (hashedSecretSellLock[hashedSecret].timeout >= block.timestamp, "Lock not timed out.");
        uint value = hashedSecretSellLock[hashedSecret].value;
        orderIdAmount[orderId] += value;
        delete hashedSecretSellLock[hashedSecret];
        // Log info.
        emit TimeoutSell(hashedSecret, orderId, value);
    }

}
