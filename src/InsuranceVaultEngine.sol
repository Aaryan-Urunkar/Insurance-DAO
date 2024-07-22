// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {InsuranceVault} from "./InsuranceVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

/**
 * @author  Aaryan Urunkar
 * @title   InsuranceVaultEngine
 * @dev     Contract written with additional insurance based operations on InsuranceVault
 * @notice  An insurance system which promises
 */
contract InsuranceVaultEngine {
    event DepositSuccess(address sender, uint256 amount, uint256 incrementedMonth);

    error InsuranceVaultEngine__PaidLessThanPremiumAndFees();
    error InsuranceVaultEngine__IllegalTransfer();
    error InsuranceVaultEngine__TransferToVaultFailed();
    error InsuranceVaultEngine__MinimumPeriodNotLapsed();
    error InsuranceVaultEngine__PaidLessThanMinimumLiquidationFeeToLiquidate();
    error InsuranceVaultEngine__UserCannotBeLiquidatedYet();

    uint256 public constant MONTHLY_PREMIUM = 0.05 ether;
    uint256 public constant MONTHLY_FEE = 0.01 ether;
    uint256 public constant LIQUIDATION_FEE = 0.04 ether;
    uint256 public constant ONE_MONTH = 1 * 60 * 60 * 24 * 31;
    uint256 public constant MINIMUM_MEMBERSHIP_PERIOD_TO_AVAIL_CLAIM = ONE_MONTH * 6; //Approximately 6 months
    uint256 public constant MAX_PERCENTAGE_OF_TREASURY_ALLOTED = 49;
    uint256 public constant PERCENTAGE_PRECISION = 100;
    uint256 public constant LIQUIDATION_ELIGIBILITY_TIME_PERIOD = ONE_MONTH * 3;

    InsuranceVault s_vault;
    IERC20 public immutable s_asset;
    uint256 public s_totalFees; //Variable whicbh represents the exact amount of assets held by this contract
    mapping(address => uint256) public s_userToMonths;
    mapping(address => uint256) private s_userToTimestampOfLastPayment;

    /**
     * @dev This constructor sets the vault address and the asset token (ex: wETH, wBTC)
     * @param _vault The address of the deployed InsuranceVault contract
     * @param _asset The address of the deployed asset
     */
    constructor(address _vault, address _asset) {
        s_vault = InsuranceVault(_vault);
        s_totalFees = 0;
        s_asset = IERC20(_asset);
    }

    /**
     * @notice  A function to let new users enter the policy and existing users deposit their monthly premium
     *
     * @dev This function stores MONTHLY_PREMIUM in vault and the remainder( fees) to this contract
     */
    function depositToPolicy(uint256 _amount) public {
        if (
            s_userToMonths[msg.sender] != 0
                && (s_userToTimestampOfLastPayment[msg.sender] + ONE_MONTH > block.timestamp)
        ) {
            revert InsuranceVaultEngine__MinimumPeriodNotLapsed();
        }
        if (_amount < MONTHLY_PREMIUM + MONTHLY_FEE) {
            revert InsuranceVaultEngine__PaidLessThanPremiumAndFees();
        }
        s_totalFees += _amount - MONTHLY_PREMIUM;
        s_userToMonths[msg.sender] += 1;
        s_userToTimestampOfLastPayment[msg.sender] = block.timestamp;

        bool success = s_asset.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert InsuranceVaultEngine__TransferToVaultFailed();
        }

        s_asset.approve(address(s_vault), MONTHLY_PREMIUM);
        s_vault.deposit(MONTHLY_PREMIUM, msg.sender);

        emit DepositSuccess(msg.sender, _amount, s_userToMonths[msg.sender]);
    }

    /**
     * @notice Whenever a claim is triggered, the function will return all assets to the policy holder
     *         Minimum period for a claim is 6 months, i.e. policy holder must pay at least 6 premiums
     *
     *  2 scenarios: If premium * 2 > 49% of storage and premium * 2 < 49% of storage
     *  For 1st scenario the holder directly avails 49% of the treasury no questions asked
     *  For 2nd scenario the holder directly avails premium * 2
     */
    function withdrawClaim() external returns (uint256) {
        if (monthsToDuration(s_userToMonths[msg.sender]) < MINIMUM_MEMBERSHIP_PERIOD_TO_AVAIL_CLAIM) {
            revert InsuranceVaultEngine__MinimumPeriodNotLapsed();
        }
        uint256 additionalAmountToReturn = 0;
        uint256 userPremiumBalance = s_vault.balanceOf(msg.sender);
        uint256 fullTreasury = _calculateTreasury();
        uint256 fortyNinePercentOfTreasury = (fullTreasury * MAX_PERCENTAGE_OF_TREASURY_ALLOTED) / PERCENTAGE_PRECISION;

        if ((userPremiumBalance * 2) > fortyNinePercentOfTreasury) {
            //In this case directly the 49% of treasury will be given
            additionalAmountToReturn = _withdrawClaimMoreThanFortyNinePercentOfTreasury(
                fortyNinePercentOfTreasury, userPremiumBalance, msg.sender
            );
        } else {
            _withdrawClaimLessThanFortyNinePercentOfTreasury(userPremiumBalance, msg.sender);
            additionalAmountToReturn = userPremiumBalance;
        }
        return userPremiumBalance + additionalAmountToReturn;
    }

    /**
     * @notice Once a policy holder does not pay his monthly premiums and is very incosistent for a period longer
     *         than a predefined period, he can be liquidated by other users. Liquidators themselves have to pay
     *         a fee but in turn all the assets of the liquidated users are now registered as the assets of the
     *         liquidator.
     * @param _userToLiquidate The address of the user who is being liquidated
     * @param _liquidationFee The minimum fee to liquidate the user
     *
     * Steps for liquidation:
     * 1] Burn the shares of the liquidated
     * 2] Mint new shares to the liquidator
     * 3] Modify all details of both liquidator and liquidated
     */
    function liquidate(address _userToLiquidate, uint256 _liquidationFee)
        external
        returns (uint256 liquidatedUserShares)
    {
        if (_liquidationFee < LIQUIDATION_FEE) {
            revert InsuranceVaultEngine__PaidLessThanMinimumLiquidationFeeToLiquidate();
        }
        if (s_userToTimestampOfLastPayment[_userToLiquidate] > (block.timestamp - LIQUIDATION_ELIGIBILITY_TIME_PERIOD))
        {
            revert InsuranceVaultEngine__UserCannotBeLiquidatedYet();
        }

        s_totalFees += _liquidationFee;
        bool success = s_asset.transferFrom(msg.sender, address(this), _liquidationFee);
        if (!success) {
            revert InsuranceVaultEngine__TransferToVaultFailed();
        }

        liquidatedUserShares = s_vault.balanceOf(_userToLiquidate);
        s_vault.burn(_userToLiquidate, liquidatedUserShares);

        s_vault.mintToLiquidator(msg.sender, liquidatedUserShares);

        s_userToMonths[_userToLiquidate] = 0;
        s_userToTimestampOfLastPayment[_userToLiquidate] = 0;
    }

    fallback() external {
        revert InsuranceVaultEngine__IllegalTransfer();
    }

    /////////////////////////////////////
    ///Public and view/pure functions///
    ///////////////////////////////////

    /**
     * A function to convert months to timestamp(seconds)
     * @param months The number of months of user's subscription
     */
    function monthsToDuration(uint256 months) public pure returns (uint256) {
        return months * ONE_MONTH;
    }

    function getLastPaymentTimestampOfUser(address _user) external view returns (uint256) {
        return s_userToTimestampOfLastPayment[_user];
    }

    //////////////////////////
    ///Internal functions////
    ////////////////////////

    /**
     * @dev Returns the entire amount of assets present in the protocol
     */
    function _calculateTreasury() private view returns (uint256) {
        return s_totalFees + s_vault.totalAssets();
    }

    /**
     * Withdraws needed amount from the vault
     * @param _amount The amount needed to be withdrawn from the vault
     */
    function _flashWithdrawFromVault(uint256 _amount) private {
        s_asset.approve(address(this), _amount);
        s_asset.transferFrom(address(s_vault), address(this), _amount);
        s_totalFees += _amount;
    }

    /**
     * @notice Transfers intended insurance from the treasury to the user
     * @param _amount The amount to be withdrawn by the user
     * @param _to The address of the user( policy holder)
     */
    function _withdrawClaimLessThanFortyNinePercentOfTreasury(uint256 _amount, address _to) private {
        s_vault.withdraw(_amount, _to, _to);
        if (s_totalFees < _amount) {
            _flashWithdrawFromVault(_amount - s_totalFees); //Withdrawing exactly the amount we need, absolutely nothing extra
        }
        s_asset.transfer(_to, _amount);
        s_totalFees -= _amount;
    }

    /**
     * @notice This function withdraws claims from the vault
     * @param _claimToBeGiven The exact claim to be given
     * @param _userBalance The aggregate premium balance of the user in the vault
     * @param _to To whom must the claim be given to
     */
    function _withdrawClaimMoreThanFortyNinePercentOfTreasury(
        uint256 _claimToBeGiven,
        uint256 _userBalance,
        address _to
    ) private returns (uint256) {
        s_vault.withdraw(_userBalance, _to, _to);
        uint256 amountLeft = _claimToBeGiven - _userBalance;
        if (s_totalFees < amountLeft) {
            _flashWithdrawFromVault(amountLeft - s_totalFees); //Withdrawing exactly the amount we need, absolutely nothing extra
        }
        s_asset.transfer(_to, amountLeft);
        s_totalFees -= amountLeft;
        return (amountLeft);
    }
}
