// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.17;

import "https://github.com/Block-Star-Logic/open-bank/blob/8bd243e86259ba0c3ff560726c878b7eaf3a4afb/blockchain_ethereum/solidity/V2/contracts/interfaces/IOpenBankAccount.sol";

interface IUmbrellaBankAccountPersonal is IOpenBankAccount {
    
    function mergeDiscrepancy(uint256 _amount, string memory _reference) external returns (uint256 _txRef);
    
    function mergeDiscrepancy(string memory _reference) external returns (uint256 _txRef);
}