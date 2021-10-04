// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

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
    event LockBuy(bytes32 hashedSecret, bytes32 assetIdOrderId, address seller, uint64 value, uint32 timeout, address buyer);

    /**
     * @dev
     */
    event UnlockBuy(bytes32 hashedSecret);

    /**
     * @dev
     */
    event TimeoutBuy(bytes32 hashedSecret, address buyer);

    /*
     * Called by buyer.
     */
    function lockBuy(bytes32 hashedSecret, bytes32 assetIdOrderId, address seller, uint32 timeout) payable external {
        // Ensure hashed secret is not already in use.
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        require (lock.value == 0, "Hashed secret already in use.");
        uint64 lockValue = uint64(msg.value / 1e9);
        // Store lock data.
        lock.seller = seller;
        lock.value = lockValue;
        lock.timeout = timeout;
        // Log info.
        emit LockBuy(hashedSecret, assetIdOrderId, seller, lockValue, timeout, msg.sender);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(bytes32 secret) external {
        // Calculate hashed secret.
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        // Get lock data.
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint256 value = uint256(hashedSecretBuyLock[hashedSecret].value) * 1e9;
        // Check the caller is the seller.
        require (msg.sender == seller, "Lock can only be unlocked by seller.");
        // Delete lock.
        delete hashedSecretBuyLock[hashedSecret];
        // Send the funds.
        payable(seller).transfer(value);
        // Log info.
        emit UnlockBuy(hashedSecret);
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
        uint256 value = uint256(hashedSecretBuyLock[hashedSecret].value) * 1e9;
        delete hashedSecretBuyLock[hashedSecret];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit TimeoutBuy(hashedSecret, msg.sender);
    }

    function getBuyLock(bytes32 hashedSecret) view external returns (BuyLock memory buyLock) {
        buyLock = hashedSecretBuyLock[hashedSecret];
    }

    function getBuyLocks(bytes32[] calldata hashedSecrets) view external returns (BuyLock[] memory buyLocks) {
        buyLocks = new BuyLock[](hashedSecrets.length);

        for (uint i = 0; i < hashedSecrets.length; i++) {
            buyLocks[i] = hashedSecretBuyLock[hashedSecrets[i]];
        }
    }

}
