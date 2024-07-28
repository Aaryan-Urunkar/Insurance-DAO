// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {Operations} from "../src/Operations.sol";
import {InsuranceVault} from "../src/main/InsuranceVault.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployOperations is Script{

    //0x34c82ddc4bfb17e34d1e7ebed0e6cd9f03d70a3d9cc25f325ea5ef6f79672ffd6ee8065131a9f2446bd4e84737ce79d1adb1d1b9a7acb893435f58a01803b17344f5944ec81cae5df18947389afe068a82366c4dd1330df7d1d6af6346f3bb499c98f54339648f685f58398fb4f53ca1ae90463df06757709ab2b7997c912289038a6cab898353ea7d71c071e223c79b8f3d84e5efd955a2e3924fbc8aa298c704f541a0e3fc6102639943a4483f1568ee

    function run(bytes memory _encryptedSecretsURLs) external returns (Operations) {
        HelperConfig helper = new HelperConfig();
        ( address owner, address asset, ) = helper.activeConfig();

        address insuranceVaultAddress = DevOpsTools.get_most_recent_deployment("InsuranceVault", block.chainid);

        vm.startBroadcast(owner);
        Operations operations = new Operations( insuranceVaultAddress, asset, _encryptedSecretsURLs);
        vm.stopBroadcast();
        return operations;
    }
}