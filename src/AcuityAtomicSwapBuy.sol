// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract AcuityAtomicSwapBuy {

    struct BuyLock {
        address seller;     // address payment will be sent to
        uint value;        // value to send
        uint timeout;
    }

    mapping (bytes32 => BuyLock) hashedSecretBuyLock;

    /**
     * @dev
     */
    event LockBuy(bytes32 indexed orderId, bytes32 indexed hashedSecret, address indexed seller, uint value, uint timeout);

    /**
     * @dev
     */
    event UnlockBuy(bytes32 indexed hashedSecret, address indexed seller, uint value);

    /**
     * @dev
     */
    event TimeoutBuy(bytes32 indexed hashedSecret, address indexed dest, uint value);

    /*
     * Called by buyer.
     */
    function lockBuy(bytes32 hashedSecret, address seller, uint timeout, bytes32 orderId) payable external {
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.value = msg.value;
        lock.timeout = timeout;
        // Log info.
        emit LockBuy(orderId, hashedSecret, seller, msg.value, timeout);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout < block.timestamp, "Lock timed out.");
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        assembly {
            pop(call(not(0), seller, value, 0, 0, 0, 0))
        }
        // Log info.
        emit UnlockBuy(hashedSecret, seller, value);
    }

    /*
     * Called by buyer if seller did not lock.
     */
    function timeoutBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout >= block.timestamp, "Lock not timed out.");
        address dest = msg.sender;
        uint value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        assembly {
            pop(call(not(0), dest, value, 0, 0, 0, 0))
        }
        // Log info.
        emit TimeoutBuy(hashedSecret, dest, value);
    }

    function getBuyLock(bytes32 hashedSecret) view external returns (address seller, uint value, uint timeout) {
        BuyLock storage buyLock = hashedSecretBuyLock[hashedSecret];
        seller = buyLock.seller;
        value = buyLock.value;
        timeout = buyLock.timeout;
    }

}
