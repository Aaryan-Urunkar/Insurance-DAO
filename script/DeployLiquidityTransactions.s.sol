// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LiquidityInteractions} from "../src/LiquidityInteractions.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Name is Script {
    HelperConfig public helperConfig;

    constructor() {}

    function run() external returns(LiquidityInteractions){
        helperConfig = new HelperConfig();
        (address asset, address poolAddressesProvider) = helperConfig.activeConfig();
        vm.startBroadcast();
        LiquidityInteractions liquidityInteractions = new LiquidityInteractions(poolAddressesProvider , asset);
        vm.stopBroadcast();
        return liquidityInteractions;
    }
}
