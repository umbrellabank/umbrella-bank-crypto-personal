// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import"https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "../interfaces/IUmbrellaBankAccountFactory.sol";

import "./UmbrellaBankPersonalAccount.sol";


contract UmbrellaBankAcountFactory is IUmbrellaBankAccountFactory, IOpenVersion { 

    string constant name = "RESERVED_UMBRELLA_BANK_CRYPTO_ACCOUNT_FACTORY";
    uint256 constant version = 1; 

    address owner; 
    address bank;     
    address [] accounts; 

    constructor(address _owner) {
        owner = _owner; 
    }

    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getBank() view external returns (address _bank) {
        return bank;
    }

    function getAccounts() view external returns(address [] memory _accounts) {      
        ownerOrBankOnly() ;
        return accounts; 
    }

    function getAccount(address _erc20) external returns (address _account) {
        require(msg.sender == bank, " bank only ");
        UmbrellaBankPersonalAccount account_ = new UmbrellaBankPersonalAccount(bank, _erc20);
        _account = address(account_);
        accounts.push(_account);
        return _account; 
    }

    function setBank() external returns (bool _set) {
        require(owner == IUmbrellaBankPersonal(msg.sender).getOwner(), " owner mismatch "); 
        bank = msg.sender; 
        return true; 
    }

    function changeOwner(address newOwner) external returns (bool _changed){
        require(msg.sender == owner, "unknown user");
        owner = newOwner; 
        return true; 
    }

    // ======================================= INTERNAL =============================================

    function ownerOrBankOnly() view internal returns (bool) {
        require(msg.sender == owner || msg.sender == bank, " unknown user ");
        return true; 
    }

}