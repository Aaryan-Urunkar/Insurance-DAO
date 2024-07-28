// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {InsuranceVaultEngine} from "./InsuranceVaultEngine.sol";
import {ERC4626Strategy} from "../imports/ERC4626Strategy.sol";
import {LiquidityInteractions} from "../lending-pool-conf/LiquidityInteractions.sol";
import {Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @author  Aaryan Urunkar
 * @title   InsuranceVault
 * @dev     The asset this vault stores is DAI
 * @notice  A vault for policy claimers to deposit their premiums and to withdraw them
 */
contract InsuranceVault is ERC4626Strategy, Ownable {

    using Math for uint256;

    error InsuranceVault__TransferFromLendingPoolToVaultFailed();
    error InsuranceVault__TransferFromVaultToEngineFailed();
    error InsuranceVault__TransferFromVaultToLendingPoolFailed();

    uint256 private s_trueAmountOfAssets;
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
        s_insuranceVaultEngine = InsuranceVaultEngine(payable(_engine));
        s_liquidityInteractions = new LiquidityInteractions(_poolAddressesProvider , address(s_asset));
        s_asset.approve(address(s_insuranceVaultEngine), type(uint256).max);
        // s_asset.approve(address(s_liquidityInteractions) , type(uint256).max);
        transferOwnership(address(s_insuranceVaultEngine));
        s_trueAmountOfAssets = 0;
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
     * In case the s_totalFees of the engine are insufficient to cover off the remainder of the claim, 
     * the engine can withdraw assets as well for an emergency basis
     * 
     * @param assets The amount of additional assets to be withdrawn by the engine
     */
    function emergencyWithdrawal(uint256 assets) external onlyOwner {
        s_liquidityInteractions.withdrawlLiquidity( address(s_asset), assets);
        bool successFromPoolToVault = s_asset.transferFrom(address(s_liquidityInteractions) , address(this) , assets);
        if(!successFromPoolToVault){
            revert InsuranceVault__TransferFromLendingPoolToVaultFailed();
        }
        s_trueAmountOfAssets -= assets;
        bool successFromVaultToEngine = s_asset.transfer(address(s_insuranceVaultEngine) , assets);
        if(!successFromVaultToEngine){
            revert InsuranceVault__TransferFromVaultToEngineFailed();
        }
    }


    ///////////////////////////////////////////////////////////////
    //Override functions from ERC4626.sol & ERC4626Strategy.sol////
    ///////////////////////////////////////////////////////////////



    /**
     * @notice Putting assets into the lending pool just after they are put into the vault
     * @param assets The amount of assets to lend
     *
     * 1] Approve the amount of assets to the liquidity pool contract
     * 2] Transfer the amount of assets to the liquidity pool contract
     * 3] Use the supplyLiquidity() function
     */
    function _afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override {
        s_trueAmountOfAssets += assets;
        s_asset.approve(
            address(s_liquidityInteractions),
            s_asset.allowance(address(this), address(s_liquidityInteractions)) + assets
        );
        bool successFromVaultToPool = s_asset.transfer(address(s_liquidityInteractions), assets);
        if(!successFromVaultToPool) {
            revert InsuranceVault__TransferFromVaultToLendingPoolFailed();
        }
        s_liquidityInteractions.approvePool(assets);
        s_liquidityInteractions.supplyLiquidity(address(s_asset), assets);
    }

    /**
     * @notice  Withdraws just the needed amount assets from the lending pool
     * @param   assets  The amount of assets to withdraw
     *
     *  1] Withdraw from the pool
     *  2] Bring the withdrawn funds from LiquidityInteractions to this contract 
     */
    function _beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal override {
        s_liquidityInteractions.withdrawlLiquidity( address(s_asset), assets);
        bool successFromPoolToVault = s_asset.transferFrom(address(s_liquidityInteractions) , address(this) , assets);
        if(!successFromPoolToVault){
            revert InsuranceVault__TransferFromLendingPoolToVaultFailed();
        }
        s_trueAmountOfAssets -= assets;
    }

    /**
     * Overridden function fron ERC4626.sol
     * @param assets The amount of assets to be converted to shares
     * @param rounding The type of rounding ( example: floor, ceil etc. )
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns(uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), s_trueAmountOfAssets + 1, rounding);
    }

    /**
     * Overridden function fron ERC4626.sol
     * @param shares The amount of assets to be converted to shares
     * @param rounding The type of rounding ( example: floor, ceil etc. )
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
        return shares.mulDiv(s_trueAmountOfAssets + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    

    //////////////////
    ////Getters//////
    ////////////////

    /**
     * @notice  A getter function to get the address of the associated liquity pool contract
     */
    function getLiquidityPoolAddress() external view returns (address) {
        return address(s_liquidityInteractions);
    }

    /**
     * @notice A getter function to get the address of the associated InsuranceVaultEngine contract
     */
    function getVaultEngineAddress() external view returns (address) {
        return address(s_insuranceVaultEngine);
    }

    /**
     * @notice A getter function which returns the amount of assets transferred into the liquidity pool at the moment
     */
    function getTrueAmountOfAssets() external view returns(uint256) {
        return s_trueAmountOfAssets;
    }
}
