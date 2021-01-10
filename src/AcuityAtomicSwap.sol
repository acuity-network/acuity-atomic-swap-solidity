// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract AcuityAtomicSwap {

    struct SellOrderLinked {
        address seller;     // access control
        uint amount;        // amount available
        bytes32 next;       // orderId of next sell order
    }

    struct BuyLockLinked {
        address seller;     // address payment will be sent to
        uint amount;        // amount to send
        bytes32 next;       // hashed secret of next buy lock for the order
    }

    mapping (bytes32 => SellOrderLinked) orderIdSellOrder;

    mapping (bytes32 => BuyLockLinked) hashedSecretBuyLock;

    mapping (bytes32 => bytes32) orderIdTopBuyLock;

    mapping (bytes32 => uint) hashedSecretSellLock;

    function createOrder(bytes32 nonce, uint price) payable external returns (bytes32 orderId) {
        orderId = keccak256(abi.encodePacked(nonce));

        SellOrderLinked storage order = orderIdSellOrder[orderId];
        order.seller = msg.sender;
        order.amount = msg.value;

        // log price
    }

    function lockBuy(bytes32 orderId, bytes32 hashedSecret, address seller) payable external {
        BuyLockLinked storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.amount = msg.value;

        orderIdTopBuyLock[orderId] = hashedSecret;

        // log buyer
    }

    function lockSell(bytes32 orderId, bytes32 hashedSecret, uint amount) external {
        orderIdSellOrder[orderId].amount -= amount;
        hashedSecretSellLock[hashedSecret] = amount;
    }

    function unlockSell(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address _sender = msg.sender;
        uint value = hashedSecretSellLock[hashedSecret];
        delete hashedSecretSellLock[hashedSecret];
        assembly {
            pop(call(not(0), _sender, value, 0, 0, 0, 0))
        }
    }

    function unlockBuy(bytes32 secret) external {
        bytes32 hashedSecret = keccak256(abi.encodePacked(secret));
        address seller = hashedSecretBuyLock[hashedSecret].seller;
        uint value = hashedSecretBuyLock[hashedSecret].amount;
        delete hashedSecretBuyLock[hashedSecret];
        assembly {
            pop(call(not(0), seller, value, 0, 0, 0, 0))
        }
    }

}
