// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {InsuranceVault} from "./InsuranceVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

/**
 * @author  Aaryan Urunkar
 * @title   InsuranceVaultEngine.sol
 * @dev     Contract written with additional insurance based operations on InsuranceVault
 * @notice  An insurance system which promises 200% ROI or 49% of treasury to policy holders
 */
contract InsuranceVaultEngine {
    event DepositSuccess(address sender, uint256 amount, uint256 incrementedMonth);
    event ClaimWithdrawn(address reciever, uint256 claimAmount);

    error InsuranceVaultEngine__PaidLessThanPremiumAndFees();
    error InsuranceVaultEngine__IllegalTransfer();
    error InsuranceVaultEngine__TransferToVaultFailed();
    error InsuranceVaultEngine__MinimumPeriodNotLapsed();
    error InsuranceVaultEngine__PaidLessThanMinimumLiquidationFeeToLiquidate();
    error InsuranceVaultEngine__UserCannotBeLiquidatedYet();

    uint256 public constant MONTHLY_PREMIUM = 150 ether; //Assuming we are working with DAI
    uint256 public constant MONTHLY_FEE = 30 ether;
    uint256 public constant LIQUIDATION_FEE = 120 ether;
    uint256 public constant ONE_MONTH = 1 * 60 * 60 * 24 * 31;
    uint256 public constant MINIMUM_MEMBERSHIP_PERIOD_TO_AVAIL_CLAIM = ONE_MONTH * 6; //Approximately 6 months
    uint256 public constant MAX_PERCENTAGE_OF_TREASURY_ALLOTED = 49;
    uint256 public constant PERCENTAGE_PRECISION = 100;
    uint256 public constant LIQUIDATION_ELIGIBILITY_TIME_PERIOD = ONE_MONTH * 3;

    InsuranceVault private s_vault;
    IERC20 public immutable s_asset;
    uint256 public s_totalFees; //Variable whicbh represents the exact amount of assets held by this contract
    mapping(address => uint256) private s_userToMonths;
    mapping(address => uint256) private s_userToTimestampOfLastPayment;
    address[] private users;
    mapping(address => uint256) private s_userToLatitude;
    mapping(address => uint256) private s_userToLongitude;
    mapping(address => bool) private s_userToPureMembership;

    /**
     * @dev This constructor sets the vault address and the asset token (ex: wETH, wBTC, DAI)
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
     * @dev This function stores MONTHLY_PREMIUM in vault and the remainder( fees) within this contract
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
        uint256 userMonths = s_userToMonths[msg.sender] += 1;
        s_userToTimestampOfLastPayment[msg.sender] = block.timestamp;
        if (userMonths >= 6) {
            users.push(msg.sender);
            s_userToPureMembership[msg.sender] = true;
        }

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
     *
     * @param _to The address of the receiver of the claim
     */
    function _withdrawClaim(address _to) internal returns (uint256) {
        if (monthsToDuration(s_userToMonths[_to]) < MINIMUM_MEMBERSHIP_PERIOD_TO_AVAIL_CLAIM) {
            revert InsuranceVaultEngine__MinimumPeriodNotLapsed();
        }

        uint256 userPremiumBalance = s_vault.balanceOf(_to);
        uint256 fullTreasury = _calculateTreasury();
        uint256 fortyNinePercentOfTreasury = (fullTreasury * MAX_PERCENTAGE_OF_TREASURY_ALLOTED) / PERCENTAGE_PRECISION;
        s_userToMonths[_to] = 0;
        s_userToTimestampOfLastPayment[_to] = 0;
        s_userToPureMembership[_to] = false;

        return __withdrawClaim(fortyNinePercentOfTreasury, userPremiumBalance, _to);
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
        s_userToPureMembership[_userToLiquidate] = false;
    }

    fallback() external {
        revert InsuranceVaultEngine__IllegalTransfer();
    }

    receive() external payable {
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

    /**
     * A function to feth the last payment timestamp of the policy holder
     * @param _user Address of policy holder
     */
    function getLastPaymentTimestampOfUser(address _user) external view returns (uint256) {
        return s_userToTimestampOfLastPayment[_user];
    }

    /**
     * @notice  A function to fetch the no.of months(or premiums paid) a user has existed in the protocol for
     * @param   _user  The address of the user
     */
    function getMembershipMonthsOfUser(address _user) external view returns (uint256) {
        return s_userToMonths[_user];
    }

    /**
     * A function to get all users of the protocol
     */
    function getUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @notice Returns location details of user such as latitude
     * @param _user The address of the user
     */
    function getUserLatitude(address _user) internal view returns (uint256) {
        return s_userToLatitude[_user];
    }

    /**
     * @notice Returns the details of th euser such as longitude
     * @param _user The address of the user
     */
    function getUserLongitude(address _user) internal view returns (uint256) {
        return s_userToLongitude[_user];
    }

    /**
     * @notice Returns if the user has a pure membership(aka Has spent enough time in the protocol to be eligible for a claim)
     * @param _user The address of the user
     */
    function getIfUserHasPureMemberShip(address _user) public view returns (bool) {
        return s_userToPureMembership[_user];
    }

    //////////////////////////
    ///Internal functions////
    ////////////////////////

    /**
     * @dev Returns the entire amount of assets present in the protocol
     */
    function _calculateTreasury() private view returns (uint256) {
        return s_totalFees + s_vault.getTrueAmountOfAssets();
    }

    /**
     * Withdraws needed amount from the vault
     * @param _amount The amount needed to be withdrawn from the vault
     */
    function _flashWithdrawFromVault(uint256 _amount) private {
        s_vault.emergencyWithdrawal(_amount);
        s_totalFees += _amount;
    }

    /**
     * Can transfer claims for eligible members by withdrawing from vault
     *
     * @param _fortyNinePercentOfTreasury Forty nine percent of the treasury
     * @param _amount The aggregate premiums of the user in the protocol
     * @param _to The address of the reciever of the claim
     */
    function __withdrawClaim(uint256 _fortyNinePercentOfTreasury, uint256 _amount, address _to)
        internal
        returns (uint256)
    {
        s_vault.withdraw(_amount, _to, _to);
        if (_fortyNinePercentOfTreasury >= (_amount * 2)) {
            _withdrawClaimRemainder(_to, _amount);
            emit ClaimWithdrawn(_to, _amount * 2);
            return _amount * 2;
        } else {
            _withdrawClaimRemainder(_to, _fortyNinePercentOfTreasury - _amount);
            emit ClaimWithdrawn(_to, _fortyNinePercentOfTreasury - _amount);
            return _amount + (_fortyNinePercentOfTreasury - _amount);
        }
    }

    /**
     * @notice  A function to transfer remainder of the claim(the additional amount after the aggregate premiums)
     * @param   _to  The address of the reciever of the assets
     * @param   _remainder  The remainder amount of the assets after first transfer
     */
    function _withdrawClaimRemainder(address _to, uint256 _remainder) internal {
        if (s_totalFees < _remainder) {
            _flashWithdrawFromVault(_remainder - s_totalFees);
        }
        s_asset.transfer(_to, _remainder);
        s_totalFees -= _remainder;
    }
}
