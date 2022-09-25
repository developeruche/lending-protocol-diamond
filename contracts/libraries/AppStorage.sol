// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "../interfaces/IERC20.sol";


enum TroveStatus {
    DEFAULT,
    ACTIVE,
    LIQUIDATATED,
    CLOSED
}

struct Trove {
    TroveStatus status;
    uint256 ether_in;
    uint256 token_out;
    bool mount;
}

struct AppStorage {
    IERC20 protocol_token;
    uint256 ether_to_token;
    mapping(address => uint256) balances;
    mapping(address => Trove) troves;
    uint256 exchange_factor; // 1 ether => 1500 dollars => 1500 protocol token
}