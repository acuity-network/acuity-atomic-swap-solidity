// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract AcuityAtomicSwapBuy {

    struct BuyLock {
        address payable seller;     // address payment will be sent to
        uint128 value;        // value to send
        uint128 timeout;
    }

    mapping (bytes32 => BuyLock) hashedSecretBuyLock;

    /**
     * @dev
     */
    event LockBuy(bytes16 indexed orderId, bytes32 indexed hashedSecret, address indexed seller, uint256 value, uint256 timeout);

    /**
     * @dev
     */
    event UnlockBuy(bytes32 indexed hashedSecret, address indexed seller, uint256 value);

    /**
     * @dev
     */
    event TimeoutBuy(bytes32 indexed hashedSecret, address indexed dest, uint256 value);

    /*
     * Called by buyer.
     */
    function lockBuy(bytes32 hashedSecret, address payable seller, uint256 timeout, bytes16 orderId) payable external {
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.value = uint64(msg.value);
        lock.timeout = uint64(timeout);
        // Log info.
        emit LockBuy(orderId, hashedSecret, seller, uint256(msg.value), timeout);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout > block.timestamp, "Lock timed out.");
        address payable seller = hashedSecretBuyLock[hashedSecret].seller;
        uint256 value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        seller.transfer(value);
        // Log info.
        emit UnlockBuy(hashedSecret, seller, value);
    }

    /*
     * Called by buyer if seller did not lock.
     */
    function timeoutBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout <= block.timestamp, "Lock not timed out.");
        uint256 value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        payable(msg.sender).transfer(value);
        // Log info.
        emit TimeoutBuy(hashedSecret, msg.sender, value);
    }

    function getBuyLock(bytes32 hashedSecret) view external returns (address seller, uint256 value, uint256 timeout) {
        BuyLock storage buyLock = hashedSecretBuyLock[hashedSecret];
        seller = buyLock.seller;
        value = buyLock.value;
        timeout = buyLock.timeout;
    }

}
