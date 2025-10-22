//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingLogic {

    // 1️⃣ EVENTS
    event StatusChanged(VotingStatus newStatus, address whoChanged);
    event Voted(address voter, address candidate, uint256 newVoteCount);
    event CandidateRegistered(address candidateAddress, string name);
    event AdminRegistered(address adminAddress);

    // 2️⃣ ENUMS
    enum VotingStatus {
        Closed,
        Open,
        Finished
    }

    // 3️⃣ STRUCTS
    struct User {
        string userName;
        address userAddress;
        bool userCandidate;
        bool userAdmin;
        uint256 votesCount;
    }

    // 4️⃣ STATE VARIABLES
    VotingStatus public currentStatus;
    mapping(address => bool) private hasVoted;
    mapping(address => User) private users;
    address[] public candidates;
    address public currentLeader;
    uint256 public maxVotes;

    // 5️⃣ MODIFIERS
    modifier onlyAdmin() {
        require(users[msg.sender].userAdmin, "Not admin");
        _;
    }

    // 6️⃣ CONSTRUCTOR
    constructor() {
        users[msg.sender] = User("admin", msg.sender, false, true, 0);
        currentStatus = VotingStatus.Closed;
        emit AdminRegistered(msg.sender);
    }

    // 7️⃣ PUBLIC/EXTERNAL FUNCTIONS
    function changeStatus(VotingStatus _newStatus) external onlyAdmin {
        require(_newStatus != currentStatus, "This status already set");
        currentStatus = _newStatus;
        emit StatusChanged(currentStatus, msg.sender);
    }

    function registerCandidate(string memory _name) external {
        require(currentStatus == VotingStatus.Closed, "Cannot add candidate during voting");
        require(!users[msg.sender].userCandidate, "Already registered as candidate");

        users[msg.sender] = User(_name, msg.sender, true, false, 0);
        candidates.push(msg.sender);

        emit CandidateRegistered(msg.sender, _name);
    }

    function vote(address _candidate) external {
        require(currentStatus == VotingStatus.Open, "Voting is not open");
        require(users[_candidate].userCandidate, "Not a candidate");
        require(!hasVoted[msg.sender], "Already voted");

        users[_candidate].votesCount++;
        hasVoted[msg.sender] = true;

        if (users[_candidate].votesCount > maxVotes) {
            maxVotes = users[_candidate].votesCount;
            currentLeader = _candidate;
        }

        emit Voted(msg.sender, _candidate, users[_candidate].votesCount);
    }

    function getWinner() external view returns (User memory) {
        require(currentLeader != address(0), "No votes yet");
        return users[currentLeader];
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

    function hasUserVoted(address _user) external view returns (bool) {
        return hasVoted[_user];
    }
}