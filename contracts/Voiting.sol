//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoitingLogic {

    event StatusChanged(VoitingStatus newStatus, address whoChanged);
    event AdminRegistered(address adminAddress);

    enum VoitingStatus{
        Closed,
        Open,
        Finished
    }

    struct User {
        string userName;
        address userAddress;
        bool userCandidate;
        bool userAdmin;
    }

    VoitingStatus public currentStatus;
    mapping (address => bool) private isVoited;
    mapping (uint => User) public voicesAmount;
    mapping (address => User) private users;

    modifier onlyAdmin() {
        require(users[msg.sender].userAdmin, "Not admin");
        _;
    }

    constructor() {
        users[msg.sender] = (User("admin", msg.sender, false, true));
        currentStatus = VoitingStatus.Closed;
        emit AdminRegistered(msg.sender);
    }


    function changeStatus(VoitingStatus _newStatus) external onlyAdmin {
        require(_newStatus != currentStatus, "This status already set");
        currentStatus = _newStatus;
        emit StatusChanged(currentStatus, msg.sender);
    }

}