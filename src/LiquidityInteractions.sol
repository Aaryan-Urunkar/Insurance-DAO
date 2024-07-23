// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';

/**
 * @title LiquidityInteractions
 * @author Aaryan Urunkar
 * @notice A contract to interact with the AAVE lending pool for the vault
 */
contract LiquidityInteractions {

    IPoolAddressesProvider immutable i_addressesProvider;
    IPool immutable i_pool;

    /**
     * To initialize the pool 
     * @param _addressesProvider The deployed address of the addressesProvider fetched from the AAVE website
     */
    constructor(address _addressesProvider ) {
        i_addressesProvider = IPoolAddressesProvider(_addressesProvider);
        i_pool = IPool(i_addressesProvider.getPool());
    }


    /**
     * @notice  To supply collateral to the AAVE lending pool to recieve interest
     * @param   _tokenAddress  The token being transferred(lent)
     * @param   _amount  The amount of the token being transferred
     */
    function supplyLiquidity(address _tokenAddress, uint256 _amount) external {
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        i_pool.supply(asset, amount, onBehalfOf, referralCode);
    }

    /**
     * @notice  To supply collateral to the AAVE lending pool to recieve interest
     * @param   _tokenAddress  The token being transferred(withdrawn) from the pool
     * @param   _amount  The amount of the token being withdrawn
     * @return  uint256  The value with interest being withdrawn
     */
    function withdrawlLiquidity(address _tokenAddress, uint256 _amount)
        external
        returns (uint256)
    {
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address to = address(this);

        return i_pool.withdraw(asset, amount, to);
    }

    /**
     * @notice  Returns the data of any user who has lent/borrowed
     * @param _userAddress The address of the protocol user
     */
    function getUserAccountData(address _userAddress)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return i_pool.getUserAccountData(_userAddress);
    }
}