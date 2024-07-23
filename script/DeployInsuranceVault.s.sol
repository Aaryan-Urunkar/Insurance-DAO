// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InsuranceVault} from "../src/InsuranceVault.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Name is Script {
    HelperConfig public helperConfig;

    constructor() {}

    function run() external returns(InsuranceVault){
        helperConfig = new HelperConfig();
        ( address asset , ) = helperConfig.activeConfig();

        vm.startBroadcast();
        InsuranceVault vault = new InsuranceVault(asset);
        vm.stopBroadcast();
        return vault;
    }
}
