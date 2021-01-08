// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract AcuityAtomicSwap {

    struct SellOrderLinked {
        address owner;
        uint amount;
        uint price;
        address next;
    }

    struct BuyLock {
        address seller;
        uint amount;
    }

    mapping (bytes32 => SellOrderLinked) orderIdSellOrder;

    mapping (bytes32 => BuyLock) hashedSecretBuyLock;

    mapping (bytes32 => uint) hashedSecretSellLock;

    function createOrder(bytes32 nonce, uint price) payable external returns (bytes32 orderId) {
        orderId = keccak256(abi.encodePacked(nonce));

        SellOrderLinked storage order = orderIdSellOrder[orderId];
        order.owner = msg.sender;
        order.amount = msg.value;
        order.price = price;
    }

    function lockBuy(bytes32 orderId, bytes32 hashedSecret, address seller) payable external {
        BuyLock storage lock = hashedSecretBuyLock[hashedSecret];
        lock.seller = seller;
        lock.amount = msg.value;
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
