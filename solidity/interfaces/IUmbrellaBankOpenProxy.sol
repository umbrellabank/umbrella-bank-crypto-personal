// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
/**
 * @author Umbrella Bank Crypto 
 * @title IUmbrellaBankOpenProxy
 * @dev this interface is in place to deal with inheritance deliniation 
 */

interface IUmbrellaBankOpenProxy{ 

     function registerTxnRef(uint256 _txnRef) external returns (bool _registered);

     function getSafety() view external returns (address _safety);
}