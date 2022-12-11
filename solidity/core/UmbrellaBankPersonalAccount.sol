// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fcf35e5722847f5eadaaee052968a8a54d03622a/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "https://github.com/Block-Star-Logic/open-libraries/blob/703b21257790c56a61cd0f3d9de3187a9012e2b3/blockchain_ethereum/solidity/V1/libraries/LOpenUtilities.sol";

import "https://github.com/Block-Star-Logic/open-bank/blob/8e37a4379c3f23cc4d1cbf839a564f6d00f81c67/blockchain_ethereum/solidity/V2/contracts/core/OpenBankAccount.sol";

import "../interfaces/IUmbrellaBankOpenProxy.sol";
import "../interfaces/IUmbrellaBankPersonal.sol";


contract UmbrellaBankPersonalAccount is OpenBankAccount { 

    using LOpenUtilities for string; 

    IUmbrellaBankPersonal bank; 
    IUmbrellaBankOpenProxy openProxy; 
     
    mapping(address=>mapping(string=>bool)) hasLimitByFunctionByUser; 
    mapping(address=>mapping(string=>uint256)) limitByFunctionByUser;

    constructor(address _bank, address _erc20) OpenBankAccount(_erc20) {
        bank = IUmbrellaBankPersonal(_bank);
        openProxy = IUmbrellaBankOpenProxy(_bank);
        name = string("UMBRELLA_BANK_PERSONAL_ACCOUNT_").append(IERC20Metadata(_erc20).name());
        version = 2; 
    }

    function payIn(uint256 _amount, string memory _reference) payable external returns (uint256 _txnRef) {
        withinLimit("PAY_IN", _amount);      
        _txnRef = credit(_amount, msg.sender, self);  
        txnRefs.push(_txnRef);
        Txn memory txn_ = getTxn( msg.sender,
                             self, 
                             "PAY_IN",
                             _reference,
                             self, 
                             symbol,
                             _amount,              
                             block.timestamp,      
                             _txnRef,
                             registeredBalance, 
                             getUnregisteredBalanceInternal()
                            );       
        txnByTxnRef[_txnRef] = txn_;
        openProxy.registerTxnRef(_txnRef);
        return _txnRef;         
    } 

    function payOut(address payable _to, uint256 _amount, string memory _reference) external returns (uint256 _txnRef){
        withinLimit("PAY_OUT", _amount);
        _txnRef = debit(_amount, _to);
        txnRefs.push(_txnRef);
        Txn memory txn_ = getTxn(
                            self,
                             _to, 
                            "PAY_OUT",
                             _reference,
                           self, 
                             symbol,
                           _amount,              
                             block.timestamp,      
                             _txnRef,
                             registeredBalance, 
                             getUnregisteredBalanceInternal()
                            );       
        txnByTxnRef[_txnRef] = txn_;
        openProxy.registerTxnRef(_txnRef);
        return _txnRef; 
    }

    function deposit(uint256 _amount, string memory _reference) payable external returns (uint256 _txnRef){
        require(isOwner(), " owner only ");
        _txnRef = credit(_amount, msg.sender, self);
        txnRefs.push(_txnRef);

        Txn memory txn_ = getTxn(
                            msg.sender,
                            self, 
                            "DEPOSIT",
                            _reference,
                            self, 
                            symbol,
                            _amount,              
                            block.timestamp,      
                            _txnRef,
                            registeredBalance, 
                            getUnregisteredBalanceInternal()
                            );       
        txnByTxnRef[_txnRef] = txn_;
        openProxy.registerTxnRef(_txnRef);
        return _txnRef; 
    }

    function withdraw(uint256 _amount, string memory _reference) external returns (uint256 _txnRef){
        require(isOwner(), " owner only ");
        _txnRef = debit(_amount, payable(msg.sender));
        txnRefs.push(_txnRef);

        Txn memory txn_ = getTxn(
                                    self,
                                        msg.sender, 
                                        "WITHDRAW",
                                        _reference,
                                        self, 
                                        symbol,
                                        _amount,              
                                        block.timestamp,      
                                        _txnRef,
                                        registeredBalance, 
                                        getUnregisteredBalanceInternal()
                                        );       
        txnByTxnRef[_txnRef] = txn_;
        openProxy.registerTxnRef(_txnRef);
        return _txnRef;  
    }

    function mergeDiscrepancy(uint256 _amount, string memory _reference) external returns (uint256 _txRef) {
        withinLimit("MERGE", _amount);
        _txRef = mergeDiscrepancyInternal(_amount); 
        Txn memory txn_ = getTxn(
                                        self,
                                        self, 
                                        "MERGE",
                                        _reference,
                                        self, 
                                        symbol,
                                        _amount,              
                                        block.timestamp,      
                                        _txRef,
                                        registeredBalance, 
                                        getUnregisteredBalanceInternal()
                                        );       
        txnByTxnRef[_txRef] = txn_;
        openProxy.registerTxnRef(_txRef);
        return _txRef; 
    }

    function mergeDiscrepancy(string memory _reference) external returns (uint256 _txRef) {        
        uint256 discrepancy_ = getDiscrepancyInternal();
        withinLimit("MERGE_ALL", discrepancy_);
        _txRef = mergeDiscrepancyInternal(discrepancy_); 
        Txn memory txn_ = getTxn(
                                        self,
                                        self, 
                                        "MERGE_ALL",
                                        _reference,
                                        self, 
                                        symbol,
                                        discrepancy_,              
                                        block.timestamp,      
                                        _txRef,
                                        registeredBalance, 
                                        getUnregisteredBalanceInternal()
                                        );       
        txnByTxnRef[_txRef] = txn_;
        openProxy.registerTxnRef(_txRef);
        return _txRef; 
    }

    function setLimit(address _user, uint256 _amount, string memory _function) external returns (bool _set){
        require(isOwner(), " owner only ");
        require(bank.isUser(_user), " Unknown user " );
        hasLimitByFunctionByUser[_user][_function] = true; 
        limitByFunctionByUser[_user][_function] = _amount; 
        return true;  
    }

    function exitDiscrepancy() external returns (bool _exited){
        require(isOwner(), " owner only ");
        erc20.transferFrom(self, openProxy.getSafety(), getDiscrepancyInternal());
        return true;  
    }

    //===================================================== HAS LIMIT ============================================

    function isUser() view internal returns (bool) {
        require(bank.isUser(msg.sender), " unknown user "); 
        return true; 
    }

    function withinLimit(string memory _function, uint256 _requestedAmount) view internal returns (bool){
        if(!isOwner()) {
            uint256 limit_ = 0; 
            if(!hasLimitByFunctionByUser[msg.sender][_function]) {
                require(hasLimitByFunctionByUser[msg.sender]["ALL"], " no limit set by owner ");
                limit_ = limitByFunctionByUser[msg.sender]["ALL"];
            }
            else {
                limit_ = limitByFunctionByUser[msg.sender][_function];
            }

            require(limit_ > _requestedAmount, " limits exceeded. ");            
        }
        return true; 
    }

    function isOwner() view internal returns (bool) {
        return bank.getOwner() == msg.sender; 
    }
}