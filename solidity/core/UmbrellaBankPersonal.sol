// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fcf35e5722847f5eadaaee052968a8a54d03622a/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "https://github.com/Block-Star-Logic/open-bank/blob/8bd243e86259ba0c3ff560726c878b7eaf3a4afb/blockchain_ethereum/solidity/V2/contracts/interfaces/IOpenBankSafety.sol";
import "https://github.com/Block-Star-Logic/open-bank/blob/8bd243e86259ba0c3ff560726c878b7eaf3a4afb/blockchain_ethereum/solidity/V2/contracts/core/OpenBank.sol";

import "../interfaces/IUmbrellaBankAccountFactory.sol";
import "../interfaces/IUmbrellaBankPersonal.sol";


contract UmbrellaBankPersonal is OpenBank, IUmbrellaBankPersonal { 

    using LOpenUtilities for address; 

    address private owner;     
    address [] users; 
    address [] suspendedUsers; 
    IUmbrellaBankAccountFactory accountFactory; 
    
    address defaultErc20; 
    bool activated; 

    constructor(address _owner, 
                address _safeHarbour, 
                address _defaultAccountErc20, 
                address _accountFactoryAddress ) OpenBank(_safeHarbour) { 
        owner = _owner; 
        name = "OPEN BANK PERSONAL"; 
        version = 4; // override parent version
        accountFactory = IUmbrellaBankAccountFactory(_accountFactoryAddress);
        defaultErc20 = _defaultAccountErc20; 
    }

    function getActivated() view external returns (bool _activated) {
        return activated; 
    }

    function activateBank() external returns (bool _bankActivated){
        ownerOnly(); 
        require(!activated, "already activated");
        accountFactory.setBank(); 
        registerCurrencyAccountInternal(defaultErc20); 
        activated = true; 
        return activated;       
    }

    function registerCurrencyAcccount(address _erc20) external returns (address _account){
        ownerOnly();     
        return registerCurrencyAccountInternal( _erc20);              
    }

    function isUser(address _user) view external returns (bool _isUser) {
        isRegisteredAccount(); 
        return (_user.isContained(users));
    }

    function getUsers() view external returns (address [] memory _users, address [] memory _suspendedUsers){  
        return (users, suspendedUsers); 
    }

    function addUser(address _user) external returns (bool _added){
        ownerOnly();
        return addUserInternal(_user);
    }

    function removeUser(address _user) external returns (bool _removed){
        ownerOnly();
        return removeUserInternal(_user);
    }

    function suspendUser(address _user) external returns (bool _suspended){
        ownerOnly();
        removeUserInternal(_user);
        suspendedUsers.push(_user);
        return true; 
    }

    function unsuspendUser(address _user) external returns (bool _unsuspended){
        ownerOnly();
        suspendedUsers = _user.remove(suspendedUsers);
        addUserInternal(_user);
        return true; 
    }

    function updateSafety(address _newSafety) external returns (address _safety) {
        ownerOnly();      
        SAFE_HARBOUR = _newSafety; 
        return SAFE_HARBOUR; 
    }   

    function getSafety() view external returns (address _safeHarbour){
        return SAFE_HARBOUR; 
    }

    function transferToAccount(address _erc20) external returns (address _account) {
        require(hasAccountByErc20[_erc20], " create ERC20 account first ");
        _account = accountByErc20[_erc20]; 
        if(_erc20 == NATIVE) {
            address payable p = payable(_account);
            p.transfer(self.balance);
        }    
        else {           
            IERC20 erc20_ = IERC20(_erc20);
            uint256 balance_ = erc20_.balanceOf(self);
            erc20_.transferFrom(self, _account, balance_);
        }
        return _account;
    }

    function pumpDescrepanciesToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _nonDenominatedDecrepantAmount){
        ownerOnly();
        _erc20Address = new address[](_batchSize);
        _nonDenominatedDecrepantAmount = new uint256[](_batchSize);
        uint256 y = 0; 
        for(uint256 x = 0; x < allAccounts.length ; x++){
            IOpenBankAccount account_ = IOpenBankAccount(allAccounts[x]);
            (address denominationAddress_, string memory symbol_) = account_.getDenomination(); 
            _erc20Address[y] = denominationAddress_; 
                       
            _nonDenominatedDecrepantAmount[x] = account_.getBalanceDescrepancy(); 

            if(_nonDenominatedDecrepantAmount[x] > 0) {
                safeHarbourTransfer(denominationAddress_,  _nonDenominatedDecrepantAmount[x]);
                y++;
                if(y >= _batchSize){
                    break; 
                }
            }
        }  
        return (_erc20Address, _nonDenominatedDecrepantAmount);
    }

    function exitToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _exitedNonDenominatedBalances, address _safetyAddress){
        ownerOnly();
        
        _erc20Address = new address[](_batchSize);
        _exitedNonDenominatedBalances = new uint256[](_batchSize);
        uint256 y = 0; 
        for(uint256 x = 0; x < allAccounts.length ; x++){
            IOpenBankAccount account_ = IOpenBankAccount(allAccounts[x]);
            (address denominationAddress_, string memory symbol_) = account_.getDenomination(); 
            _erc20Address[y] = denominationAddress_; 
            
            IERC20 erc20_ = IERC20(denominationAddress_);
           
            _exitedNonDenominatedBalances[x] = erc20_.balanceOf(self);

            if(_exitedNonDenominatedBalances[x] > 0) {
                safeHarbourTransfer(denominationAddress_,  _exitedNonDenominatedBalances[x]);
                y++;
                if(y >= _batchSize){
                    break; 
                }
            }
        }  
        return (_erc20Address, _exitedNonDenominatedBalances, SAFE_HARBOUR );
    }
    

    function getOwner() view external returns (address _owner){
        return owner; 
    }

    function changeOwner(address _newOwner) external returns (address _owner){
        ownerOnly();
        owner =  _newOwner; 
        return _owner; 
    }

    // ============================== INTERNAL =====================================


    function registerCurrencyAccountInternal( address _erc20) internal returns (address _account){     
        require(!hasAccountByErc20[_erc20], "account already registered");  
        address account_ = accountFactory.getAccount(_erc20);             
        require(addAccountInternal(account_, _erc20), " failed to add account ");
        return account_; 
    }

    function safeHarbourTransfer(address _erc20, uint256 _amount) internal returns (uint256 _transferedBalance ) {
        IERC20 erc20_ = IERC20(_erc20);
        
        if(_amount > 0){
            erc20_.transferFrom(self, SAFE_HARBOUR, _amount);
            return _amount; 
        }
        return 0; 
    }


    function isRegisteredAccount() view internal returns (bool) {
        require(msg.sender.isContained(allAccounts), " bank accounts only");
        return true; 
    }

    function ownerOnly() view internal returns (bool) {
        require(msg.sender == owner, "owner only");
        return true; 
    }

    function addUserInternal(address _user) internal returns (bool) {
        users.push(_user);
        return true; 
    }

    function removeUserInternal(address _user) internal returns (bool) {
         users = _user.remove(users);
        return true; 
    }
}