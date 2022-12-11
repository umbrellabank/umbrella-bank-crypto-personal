// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "https://github.com/umbrellabank/umbrella-bank-crypto-personal/blob/52464a0f08adc8f88ce7260efe2a10f06fa20259/solidity/core/UmbrellaBankAccountFactory.sol";

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "../interfaces/IUBAFParentFactory.sol";

contract UBAFParentFactory is IUBAFParentFactory, IOpenVersion { 

    string constant name = "RESERVED_UMBRELLA_BANK_ACCOUNT_FACTORY_PARENT_FACTORY";
    uint256 constant version = 1; 

    address admin; 
    address faucet; 
    address self; 

    mapping(address=>bool) registeredBankByAddress; 
    mapping(address=>bool) factoryIssuedByAddress; 

    address [] afs; 

    constructor (address _admin) {
        admin = _admin;
        self = address(self);
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getFaucet() view external returns (address _faucet) {
        return faucet; 
    }

    function getIssuedAccountFactories() view external returns (address [] memory _afs) {
        adminOnly(); 
        return afs; 
    }

    function setFaucet(address _faucet) external returns (bool _set) {
        adminOnly();
        faucet = _faucet; 
        return true; 
    }

    function registerBank(address _bank) external returns (bool _registered) {
        require(msg.sender == faucet, " faucet only " );
        require(!registeredBankByAddress[_bank], " unregistered banks only ");
        registeredBankByAddress[_bank] = true; 
        return true; 
    }

    function createUBAF(address _owner) external returns (address _ubaf) {
        require(msg.sender == faucet, " faucet only " );
        UmbrellaBankAcountFactory ubaf_ = new UmbrellaBankAcountFactory(_owner);  
        factoryIssuedByAddress[msg.sender] = true;       
        _ubaf = address(ubaf_);
        afs.push(_ubaf);
        return _ubaf;
    }

    // ========================  INTERNAL ===================


    function adminOnly() view internal returns (bool) {
        require(msg.sender == admin, " admin only ");
        return true; 
    }


}