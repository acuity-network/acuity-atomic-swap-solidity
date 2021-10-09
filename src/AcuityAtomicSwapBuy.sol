// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

contract AcuityAtomicSwapBuy {

    mapping (bytes32 => uint256) buyLockIdValue;

    /**
     * @dev
     */
    event LockBuy(address buyer, address seller, bytes32 hashedSecret, uint256 timeout, uint256 value, bytes32 assetIdOrderId);

    /**
     * @dev
     */
    event UnlockBuy(address buyer, bytes32 secret, address seller);

    /**
     * @dev
     */
    event TimeoutBuy(address buyer, bytes32 secret);

    /*
     * Called by buyer.
     */
    function lockBuy(address seller, bytes32 hashedSecret, uint256 timeout, bytes32 assetIdOrderId) payable external {
        // Calculate buyLockId.
        bytes32 buyLockId = keccak256(abi.encodePacked(msg.sender, seller, hashedSecret, timeout));
        // Ensure buyLockId is not already in use.
        require (buyLockIdValue[buyLockId] == 0, "Buy lock already exists.");
        buyLockIdValue[buyLockId] = msg.value;
        // Log info.
        emit LockBuy(msg.sender, seller, hashedSecret, timeout, msg.value, assetIdOrderId);
    }

    /*
     * Called by seller.
     */
    function unlockBuy(address buyer, bytes32 secret, uint256 timeout) external {
        // Calculate buyLockId.
        bytes32 buyLockId = keccak256(abi.encodePacked(buyer, msg.sender, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value;
        uint256 value = buyLockIdValue[buyLockId];
        // Delete lock.
        delete buyLockIdValue[buyLockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit UnlockBuy(buyer, secret, msg.sender);
    }

    /*
     * Called by buyer if seller did not lock.
     */
    function timeoutBuy(address seller, bytes32 secret, uint256 timeout) external {
        // Check lock has timed out.
        require (timeout <= block.timestamp, "Lock not timed out.");
        // Calculate buyLockId.
        bytes32 buyLockId = keccak256(abi.encodePacked(msg.sender, seller, keccak256(abi.encodePacked(secret)), timeout));
        // Get lock value;
        uint256 value = buyLockIdValue[buyLockId];
        // Delete lock.
        delete buyLockIdValue[buyLockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
        emit TimeoutBuy(msg.sender, secret);
    }

    function getBuyLock(address buyer, address seller, bytes32 hashedSecret, uint256 timeout) view external returns (uint256 value) {
        value = buyLockIdValue[keccak256(abi.encodePacked(buyer, seller, hashedSecret, timeout))];
    }

    function getBuyLock(bytes32 buyLockId) view external returns (uint256 value) {
        value = buyLockIdValue[buyLockId];
    }
/*
    function getBuyLocks(bytes32[] calldata hashedSecrets) view external returns (BuyLock[] memory buyLocks) {
        buyLocks = new BuyLock[](hashedSecrets.length);

        for (uint i = 0; i < hashedSecrets.length; i++) {
            buyLocks[i] = hashedSecretBuyLock[hashedSecrets[i]];
        }
    }
*/
}
