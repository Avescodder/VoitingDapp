//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoitingLogic {

    event StatusChanged(VoitingStatus newStatus, address whoChanged);
    event Voted(address voter, address candidate, uint256 newVoteCount);
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
        uint256 voicesCount;
    }

    VoitingStatus public currentStatus;
    mapping (address => bool) private isVoited;
    mapping (address => User) private users;

    address[] public candidates;
    address public curretnLider;
    uint256 public maxVotes;

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

    function getWinner() external view returns (User memory) {
        require(curretnLider != address(0), "No votes yet");
        return users[curretnLider];
    }

    function getCandidate(address _candidate) external view returns (User memory) {
        require(users[_candidate].userCandidate, "User not a candidate");
        return users[_candidate];
    }

    function getAllResults() external view onlyAdmin returns (User[] memory) {
        User[] memory results = new User[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            results[i] = users[candidates[i]];
        }
        return results;
    }

    function getCandidateLength() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidateAddress(uint256 _index) external view returns (address) {
        require(_index < candidates.length, "Index out of range");
        return candidates[_index];
    }

    function hasVoited(address _user) external view returns (bool) {
        return isVoited[_user];
    }
    
}