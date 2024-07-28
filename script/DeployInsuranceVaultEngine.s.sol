// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {InsuranceVaultEngine} from "../src/main/InsuranceVaultEngine.sol";
import {InsuranceVault} from "../src/main/InsuranceVault.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployInsuranceVaultEngine is Script{
    function run() external returns (InsuranceVaultEngine engine) {
        HelperConfig helper = new HelperConfig();
        ( address owner, address asset, ) = helper.activeConfig();

        address insuranceVaultAddress = DevOpsTools.get_most_recent_deployment("InsuranceVault", block.chainid);

        vm.startBroadcast(owner);
        engine = new InsuranceVaultEngine( insuranceVaultAddress, asset);
        vm.stopBroadcast();
        
    }
}