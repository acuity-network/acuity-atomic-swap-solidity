// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract AcuityAtomicSwap {

    struct BuyLock {
        address seller;     // address payment will be sent to
        uint amount;        // amount to send
        uint timeout;
    }

    struct SellLock {
        bytes32 orderId;
        uint amount;
        uint timeout;
    }

    mapping (bytes32 => uint) orderIdAmount;

    mapping (bytes32 => BuyLock) hashedSecretBuyLock;

    mapping (bytes32 => SellLock) hashedSecretSellLock;

    /*
     * Called by seller.
     */
    function createOrder(uint price) payable external returns (bytes32 orderId) {
        // Get orderId.
        orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Get order.
        orderIdAmount[orderId] += msg.value;
        // log info
    }

    /*
     * Called by buyer.
     */
    function lockBuy(bytes32 hashedSecret, address seller, uint timeout, bytes32 orderId) payable external {
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.amount = msg.value;
        lock.timeout = timeout;
        // log info
    }

    /*
     * Called by seller.
     */
    function lockSell(uint price, bytes32 hashedSecret, uint timeout, uint amount) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        // Check there is enough.
        require (orderIdAmount[orderId] >= amount, "Sell order not big enough.");
        // Move amount.
        orderIdAmount[orderId] -= amount;
        hashedSecretSellLock[hashedSecret].amount = amount;
        hashedSecretSellLock[hashedSecret].timeout = timeout;
        hashedSecretSellLock[hashedSecret].orderId = orderId;
    }

    /*
     * Called by buyer.
     */
    function unlockSell(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretSellLock[hashedSecret].timeout < block.timestamp, "Lock timed out.");
        address _sender = msg.sender;
        uint value = hashedSecretSellLock[hashedSecret].amount;
        delete hashedSecretSellLock[hashedSecret];
        assembly {
            pop(call(not(0), _sender, value, 0, 0, 0, 0))
        }
    }

    /*
     * Called by seller if buyer did not reveal secret.
     */
    function timeoutSell(uint price, bytes32 hashedSecret) external {
        // Get orderId.
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, price));
        require (hashedSecretSellLock[hashedSecret].orderId == orderId, "Wrong orderId.");
        require (hashedSecretSellLock[hashedSecret].timeout >= block.timestamp, "Lock not timed out.");
        orderIdAmount[orderId] += hashedSecretSellLock[hashedSecret].amount;
        delete hashedSecretSellLock[hashedSecret];
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout < block.timestamp, "Lock timed out.");
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint value = hashedSecretBuyLock[hashedSecret].amount;
        delete hashedSecretBuyLock[hashedSecret];
        assembly {
            pop(call(not(0), seller, value, 0, 0, 0, 0))
        }
    }

    /*
     * Called by buyer if seller did not lock.
     */
    function timeoutBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout >= block.timestamp, "Lock not timed out.");
        address dest = msg.sender;
        uint value = hashedSecretBuyLock[hashedSecret].amount;
        delete hashedSecretBuyLock[hashedSecret];
        assembly {
            pop(call(not(0), dest, value, 0, 0, 0, 0))
        }
    }

}
