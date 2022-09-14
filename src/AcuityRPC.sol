// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract AcuityRPC {

    function getStaticTokenMetadata(ERC20 token) view external returns (string memory name, string memory symbol, uint8 decimals) {
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    function getTokenBalances(address owner, ERC20[] calldata tokens) view external returns (uint[] memory values) {
        values = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            values[i] = tokens[i].balanceOf(owner);
        }
    }

    function getTokenAllowances(address owner, address spender, ERC20[] calldata tokens) view external returns (uint[] memory values) {
        values = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            values[i] = tokens[i].allowance(owner, spender);
        }
    }
}
