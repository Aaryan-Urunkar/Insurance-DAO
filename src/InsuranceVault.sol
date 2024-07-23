// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {InsuranceVaultEngine} from "./InsuranceVaultEngine.sol";
import {ERC4626Strategy} from "./imports/ERC4626Strategy.sol";
import {LiquidityInteractions} from "./LiquidityInteractions.sol";

/**
 * @author  Aaryan Urunkar
 * @title   InsuranceVault
 * @dev     The asset this vault stores is WETH
 * @notice  A vault for policy claimers to deposit their premiums and to withdraw them
 */
contract InsuranceVault is ERC4626Strategy, Ownable {
    InsuranceVaultEngine private s_insuranceVaultEngine;
    IERC20 public s_asset;
    LiquidityInteractions private s_liquidityInteractions;

    constructor(address _asset) ERC4626(IERC20(_asset)) ERC20("Vault Insurance Token", "dVIT") Ownable(msg.sender) {
        s_asset = IERC20(_asset);
    }

    /**
     * @notice Can only be called by the deployer of this vault and that too only once
     * @param _engine Address of an associate InsuranceVaultEngine
     * @param _poolAddressesProvider The address of the PoolAddressesProvider from the AAVE website
     */
    function setUpEngineAndPoolProvider(address _engine, address _poolAddressesProvider) external onlyOwner {
        s_insuranceVaultEngine = InsuranceVaultEngine(_engine);
        s_liquidityInteractions = new LiquidityInteractions(_poolAddressesProvider);
        s_asset.approve(address(s_insuranceVaultEngine), type(uint256).max);
        transferOwnership(address(s_insuranceVaultEngine));
    }

    /**
     *
     * @param _account The account whose shares are to be burnt
     * @param _value The number of shares to be burned
     */
    function burn(address _account, uint256 _value) external onlyOwner {
        super._burn(_account, _value);
    }

    /**
     *
     * @param _account The account of the liquidator
     * @param _shares The no.of shares to be minted to the liquidator
     */
    function mintToLiquidator(address _account, uint256 _shares) external onlyOwner {
        super._mint(_account, _shares);
    }

    /**
     * @notice Putting assets into the lending pool just after they are put into the vault
     * @param assets The amount of assets to lend
     */
    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override {
        // s_liquidityInteractions.supplyLiquidity(address(s_asset), assets);
    }

    /**
     * @notice  Withdraws assets(along with interest gained) from the lending pool
     * @param   assets  The amount of assets to withdraw
     */
    function beforeWithdraw(uint256 assets, uint256 /*shares*/) internal override {
        
    }
}
