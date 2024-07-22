// SPDX-License-Identifier:MIT
pragma solidity  ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {InsuranceVault} from "../../src/InsuranceVault.sol";
import {InsuranceVaultEngine} from "../../src/InsuranceVaultEngine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Name is Test {

    event DepositSuccess(address sender , uint256 amount , uint256 incrementedMonth);

    InsuranceVault vault;
    InsuranceVaultEngine engine;
    IERC20 token;

    address USER = makeAddr("user");
    address newUser1;
    address newUser2;

    uint256 constant STARTING_BALANCE = 100e18;
    uint256 public constant ONE_MONTH = 1 * 60 * 60 * 24 * 31;
    uint256 public constant MONTHLY_PREMIUM = 0.05 ether;
    uint256 public constant MINIMUM_MEMBERSHIP_PERIOD_TO_AVAIL_CLAIM = ONE_MONTH * 6;

    function setUp() external {
        ERC20Mock newToken = new ERC20Mock();
        token = IERC20(address(newToken));
        vault = new InsuranceVault(address(token));
        engine = new InsuranceVaultEngine( address(vault), address(token));
        vm.deal( USER, STARTING_BALANCE);
        newToken.mint( USER, STARTING_BALANCE);

        vault.setUpEngine(address(engine));
    }


    ///////////////////// 
    // depositToPolicy//
    /////////////////// 

    function testIfPayingLesserReverts() external {
        vm.expectRevert(InsuranceVaultEngine.InsuranceVaultEngine__PaidLessThanPremiumAndFees.selector);
        vm.prank(USER);
        uint256 amt = 0.04 ether;
        engine.depositToPolicy(amt);
    }

    modifier depositedToPolicy() {
        vm.startPrank(USER);
        uint256 amt = 0.07 ether;
        token.approve(address(engine), amt); 
        engine.depositToPolicy(amt);
        vm.stopPrank();
        _;
    }

    function testIfVaultIsModifiedOnNewDeposit() external depositedToPolicy{
        assertEq( engine.s_totalFees() , 0.02 ether);
    }

    function testIfSuccessfulDepositEmitsEvent() external {
        vm.startPrank(USER);
        uint256 amt = 0.07 ether;
        token.approve(address(engine), amt); 
        vm.expectEmit(true, true , true, false, address(engine));
        emit DepositSuccess( USER, amt, 1);
        engine.depositToPolicy(amt);
        vm.stopPrank();
    }

    function testIfSharesAreMintedOnSuccessfulDeposit() external depositedToPolicy{
        uint256 monthlyPremium = 0.05 ether;
        assertEq(monthlyPremium , vault.balanceOf(USER) );
    }

    /////////////////////
    ///withdrawClaim////
    ///////////////////

    function testIfWithdrawWorksBeforeMinimumPeriod() external depositedToPolicy {
        vm.prank(USER);
        vm.expectRevert(InsuranceVaultEngine.InsuranceVaultEngine__MinimumPeriodNotLapsed.selector);
        engine.withdrawClaim();
    }

    modifier multipleDepositsValidForClaims()  {
        vm.startPrank(USER);
        uint256 amt = 0.07 ether;
        token.approve(address(engine), amt); 
        engine.depositToPolicy(amt);
        vm.stopPrank();
        newUser1 = makeAddr("newuser");
        newUser2 = makeAddr("alsonewuser");
        ERC20Mock tokenToMint = ERC20Mock(address(token));
        tokenToMint.mint( newUser1, 100 ether);
        tokenToMint.mint(newUser2, 100 ether);

        vm.prank(USER);
        token.approve(address(engine), type(uint256).max - 1);

        uint256 minimumNoOfMonthsToBeEligibleForClaim = 6;
        for(uint256 i = 1 ; i <= minimumNoOfMonthsToBeEligibleForClaim  + 1; i++){
            vm.warp(block.timestamp + ONE_MONTH + i);
        
            vm.startPrank(USER);
            engine.depositToPolicy(0.07 ether);
            vm.stopPrank();
            
            vm.startPrank(newUser1);
            token.approve(address(engine), type(uint256).max);
            engine.depositToPolicy(0.06 ether);
            vm.stopPrank();
            
            vm.startPrank(newUser2);
            token.approve(address(engine), type(uint256).max);
            engine.depositToPolicy(0.06 ether);
            vm.stopPrank();
        }
        _;
    }

    function testIfWithdrawCase1Works() external multipleDepositsValidForClaims {

        uint256 expectedAmount = ((vault.totalSupply() + engine.s_totalFees())*49) / 100;
        vm.startPrank(USER);
        
        vault.approve(address(engine) , type(uint256).max);
        
        uint256 totalClaim = engine.withdrawClaim();
        vm.stopPrank();
        console.log(totalClaim);
        
        assertEq(totalClaim , expectedAmount);
    }

    function testIfWithdrawCase2Works() external multipleDepositsValidForClaims {
        address tempUser = makeAddr("temp");
        ERC20Mock tokenToMint = ERC20Mock(address(token));
        tokenToMint.mint(tempUser, 100 ether);

        vm.startPrank(tempUser);
        uint256 amt = 0.07 ether;
        token.approve(address(engine), type(uint256).max); 
        engine.depositToPolicy(amt);
        vm.stopPrank();

        uint256 expectedClaim = MONTHLY_PREMIUM * engine.s_userToMonths(newUser1) * 2;

        vm.startPrank(newUser1);
        vault.approve(address(engine) , type(uint256).max);
        uint256 totalClaim = engine.withdrawClaim();
        vm.stopPrank();

        // console.log(vault.totalAssets());
        // console.log(engine.s_totalFees());

        assertEq(totalClaim, expectedClaim);
    }


    ///////////////////////
    /////liquidate////////
    /////////////////////

    function testBurnShares() external depositedToPolicy{
        vm.prank(address(engine));
        vault.burn(USER , MONTHLY_PREMIUM);
        
        assertEq(0 , vault.balanceOf(USER));
        assertEq(MONTHLY_PREMIUM , vault.totalAssets());
    }

    function testLiquidateRevertsIfLiquidationIsWrong() external multipleDepositsValidForClaims{
        vm.startPrank(USER);
        vm.expectRevert(InsuranceVaultEngine.InsuranceVaultEngine__UserCannotBeLiquidatedYet.selector);
        engine.liquidate(newUser1 , 0.04 ether);
        
    }

    function testLiquidateRevertsIfLiquidationFeeIsLow() external multipleDepositsValidForClaims{
        vm.startPrank(USER);
        vm.expectRevert(InsuranceVaultEngine.InsuranceVaultEngine__PaidLessThanMinimumLiquidationFeeToLiquidate.selector);
        engine.liquidate(newUser1 , 0.03 ether);
    }

    function testLiquidate() external multipleDepositsValidForClaims{
        vm.warp(block.timestamp + (ONE_MONTH * 6) );
        vm.startPrank(USER);
        uint256 initialShareBalanceOfLiquidator = vault.balanceOf(USER);
        uint256 initialShareBalanceOfLiquidated = vault.balanceOf(newUser1);
        uint256 newShares = engine.liquidate(newUser1 , 0.04 ether);

        uint256 finalShareBalanceOfLiquidator = vault.balanceOf(USER);
        uint256 finalShareBalanceOfLiquidated = vault.balanceOf(newUser1);

        assertEq(initialShareBalanceOfLiquidator + newShares , finalShareBalanceOfLiquidator);
        assertEq(newShares , initialShareBalanceOfLiquidated);
        assertEq(finalShareBalanceOfLiquidated , 0);
    }
}
