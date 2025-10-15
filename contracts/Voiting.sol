//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoitingLogic {

    event StatusChanged(VoitingStatus newStatus, address whoChanged);
    event Voted(address voter, address candidate, uint newVoteCount);
    event CandidateRegistered(address candidateAddress, string name);
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
        uint voicesCount;
    }

    VoitingStatus public currentStatus;
    mapping (address => bool) private isVoited;
    mapping (address => User) private users;

    address[] public candidates;
    address public curretnLider;
    uint public maxVotes;

    modifier onlyAdmin() {
        require(users[msg.sender].userAdmin, "Not admin");
        _;
    }

    constructor() {
        users[msg.sender] = User("admin", msg.sender, false, true, 0);
        currentStatus = VoitingStatus.Closed;
        emit AdminRegistered(msg.sender);
    }


    function changeStatus(VoitingStatus _newStatus) external onlyAdmin {
        require(_newStatus != currentStatus, "This status already set");
        currentStatus = _newStatus;
        emit StatusChanged(currentStatus, msg.sender);
    }

    function registerCandidate(string memory _name) external {
        require(currentStatus == VoitingStatus.Closed, "Imposible to add candidate during voiting");
        require(!users[msg.sender].userCandidate, "You have been already registered");

        users[msg.sender] = User(_name, msg.sender, true, false, 0);
        candidates.push(msg.sender);

        emit CandidateRegistered(msg.sender, _name);
    }

    function vote(address _candidate) external {
        require(currentStatus == VoitingStatus.Open, "Voting closed");
        require(users[_candidate].userCandidate, "Not a candidate");
        require(!isVoited[msg.sender], "You have been voited already");

        users[_candidate].voicesCount++;
        isVoited[msg.sender] = true;

        if (users[_candidate].voicesCount > maxVotes) {
            maxVotes = users[_candidate].voicesCount;
            curretnLider = _candidate;
        }

        emit Voted(msg.sender, _candidate, users[_candidate].voicesCount);
    }


}