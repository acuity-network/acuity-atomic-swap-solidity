// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./ERC20.sol";

contract AcuityIntraChainERC20 {

    struct Order {
        address account;
        uint96 price;
    }

    /**
     * @dev Mapping of selling ERC20 contract address to buying ERC20 contract address to linked list of sell orders, starting with the lowest selling price.
     */
    mapping (address => mapping (address => mapping (bytes32 => bytes32))) sellBuyOrderLL;

    mapping (address => mapping (address => mapping (bytes32 => uint256))) sellBuyOrderValue;

    /**
     * @dev
     */
    error TokenTransferFailed();

    /**
     * @dev
     */
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed();
    }

    /**
     * @dev
     */
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed();
    }

    function encodeOrder(address account, uint96 sellPrice) internal pure returns (bytes32 order) {
        order = bytes32(bytes20(account)) | bytes32(bytes12(sellPrice));
    }

    function decodeOrder(bytes32 order) internal pure returns (address account, uint96 sellPrice) {

    }

    function addSellOrder(address sellToken, address buyToken, uint96 sellPrice, uint value) external {
        safeTransferFrom(sellToken, msg.sender, address(this), value);

        bytes32 order = encodeOrder(msg.sender, sellPrice);

        mapping (bytes32 => bytes32) storage orderLL = sellBuyOrderLL[sellToken][buyToken];
        mapping (bytes32 => uint256) storage orderValue = sellBuyOrderValue[sellToken][buyToken];

        // Does this order already exist?
        if (orderValue[order] > 0) {
            orderValue[order] += value;
            return;
        }

        bytes32 prev = 0;
        bytes32 next = orderLL[prev];
        while (next != 0) {
            (, uint96 nextSellPrice) = decodeOrder(next);

            if (nextSellPrice > sellPrice) {
                break;
            }

            prev = next;
            next = orderLL[prev];
        }

        // Insert into linked list.
        orderLL[prev] = order;
        orderLL[order] = next;
        orderValue[order] = value;
    }

    function removeSellOrder(address sellToken, address buyToken, uint sellPrice, uint value) external {

    }

    function removeSellOrder(address sellToken, address buyToken, uint sellPrice) external {

    }

    function buy(address sellToken, address buyToken, uint buyValue) external {
        // Linked list of sell orders for this pair, starting with the lowest price.
        mapping (bytes32 => bytes32) storage orderLL = sellBuyOrderLL[sellToken][buyToken];
        // Sell value of each sell order for this pair.
        mapping (bytes32 => uint256) storage orderValue = sellBuyOrderValue[sellToken][buyToken];
        // Accumulator of how much of the sell token the buyer will receive.
        uint sellValue = 0;
        // Get the lowest sell order.
        bytes32 order = orderLL[0];
        while (order != 0) {
            (address sellAccount, uint96 sellPrice) = decodeOrder(order);
            uint orderSellValue = orderValue[order];
            uint matchedSellValue = (buyValue * 1 ether) / sellPrice;

            if (orderSellValue > matchedSellValue) {
                // Partial buy.
                orderValue[order] -= matchedSellValue;
                // Transfer value.
                sellValue += matchedSellValue;
                safeTransferFrom(buyToken, msg.sender, sellAccount, buyValue);
                break;
            }
            else {
                // Full buy.
                uint matchedBuyValue = (orderSellValue * sellPrice) / 1 ether;
                buyValue -= matchedBuyValue;
                bytes32 next = orderLL[order];
                // Delete the sell order.
                orderLL[0] = next;
                delete orderLL[order];
                delete orderValue[order];
                order = next;
                // Transfer value.
                sellValue += orderSellValue;
                safeTransferFrom(buyToken, msg.sender, sellAccount, matchedBuyValue);
            }
        }

        if (sellValue > 0) {
            safeTransfer(sellToken, msg.sender, sellValue);
        }
    }

}
