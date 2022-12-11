// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.17;


interface IUmbrellaBankAccountFactory { 

    function getAccount(address _erc20) external returns (address _account);

    function setBank() external returns (bool _set);
}