// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

contract AcuityAtomicSwapBuy {

    struct BuyLock {
        address seller;     // address payment will be sent to
        uint48 value;        // value to send
        uint48 timeout;
    }

    mapping (bytes32 => BuyLock) hashedSecretBuyLock;

    /**
     * @dev
     */
    event LockBuy(uint256 indexed assetId, bytes16 indexed orderId, bytes32 indexed hashedSecret, address seller, uint256 value, uint256 timeout);

    /**
     * @dev
     */
    event UnlockBuy(bytes32 indexed hashedSecret, address indexed seller, uint256 value);

    /**
     * @dev
     */
    event TimeoutBuy(bytes32 indexed hashedSecret, address indexed buyer, uint256 value);

    /*
     * Called by buyer.
     */
    function lockBuy(uint256 assetId, bytes16 orderId, bytes32 hashedSecret, address seller, uint256 timeout) payable external {
        // Ensure hashed secret is not already in use.
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        require (lock.value == 0, "Hashed secret already in use.");
        // Store lock data.
        lock.seller = seller;
        lock.value = uint48(msg.value);
        lock.timeout = uint48(timeout);
        // Log info.
        emit LockBuy(assetId, orderId, hashedSecret, seller, msg.value, timeout);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        // Calculate hashed secret.
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        // Get lock data.
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint256 value = hashedSecretBuyLock[hashedSecret].value;
        // Check the caller is the seller.
        require (msg.sender == seller, "Lock can only be unlocked by seller.");
        // Delete lock.
        delete hashedSecretBuyLock[hashedSecret];
        // Send the funds.
        payable(seller).transfer(value);
        // Log info.
        emit UnlockBuy(hashedSecret, seller, value);
    }

    /*
     * Called by buyer if seller did not lock.
     */
    function timeoutBuy(bytes32 secret) external {
        // Calculate hashed secret.
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        // Check lock has timed out.
        require (hashedSecretBuyLock[hashedSecret].timeout <= block.timestamp, "Lock not timed out.");
        // Get lock value and delete lock.
        uint256 value = hashedSecretBuyLock[hashedSecret].value;
        delete hashedSecretBuyLock[hashedSecret];
        // Send the funds.
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
