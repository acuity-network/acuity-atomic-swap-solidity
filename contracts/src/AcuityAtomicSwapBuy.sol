// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract AcuityAtomicSwapBuy {

    struct BuyLock {
        address seller;     // address payment will be sent to
        uint64 value;        // value to send
        uint32 timeout;
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
    function lockBuy(bytes32 hashedSecret, address seller, uint256 timeout, bytes16 orderId) payable external {
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.value = uint64(msg.value);
        lock.timeout = uint32(timeout);
        // Log info.
        emit LockBuy(orderId, hashedSecret, seller, msg.value, timeout);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        require (hashedSecretBuyLock[hashedSecret].timeout > block.timestamp, "Lock timed out.");
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint256 value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        // Send the funds. Cast value to uint128 for Solang compatibility.
        payable(seller).transfer(uint128(value));
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
        // Send the funds. Cast value to uint128 for Solang compatibility.
        payable(msg.sender).transfer(uint128(value));
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
