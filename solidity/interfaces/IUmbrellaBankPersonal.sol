// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.17;


interface IUmbrellaBankPersonal { 

    // ============================= USERS =======================================

    function isUser(address _user) view external returns (bool _isUser);

    function getUsers() view external returns (address [] memory _users, address [] memory _suspendedUsers);

    function addUser(address _user) external returns (bool _added);

    function removeUser(address _user) external returns (bool _removed);

    function suspendUser(address _user) external returns (bool _suspended);

    function unsuspendUser(address _user) external returns (bool _unsuspended);

    // ============================= OWNER =======================================

    function getOwner() view external returns (address _owner); 

    function changeOwner(address _newOwner) external returns (address _owner);

}