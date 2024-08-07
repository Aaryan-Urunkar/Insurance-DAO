// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import {MockPoolInherited} from "@aave/core-v3/contracts/mocks/helpers/MockPool.sol";
import {MockPoolAddressesProvider} from "../test/mocks/MockPoolAddressesProvider.sol";

contract HelperConfig is Script {


    struct NetworkConfig {
        address owner;
        address asset;
        address poolAddressesProvider;
    }

    NetworkConfig public activeConfig;
    constructor() {
        if(block.chainid == 11155111){
            activeConfig = getSepoliaETHConfig();
        } else {
            activeConfig = getAnvilETHConfig();
        }
    }

    function getSepoliaETHConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            owner: 0x653D51D80a904085e3Eb69f462B8139b718ae837,
            asset: 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357, //DAI
            poolAddressesProvider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
        });
    }

    function getAnvilETHConfig() public returns(NetworkConfig memory){
        vm.startBroadcast();
        ERC20Mock asset= new ERC20Mock();
        MockPoolAddressesProvider mock = new MockPoolAddressesProvider();
        MockPoolInherited mockPool = new MockPoolInherited(mock);
        vm.stopBroadcast();

        return NetworkConfig({
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            asset:address(asset) , 
            poolAddressesProvider : address(mockPool)
        });
    }

}
