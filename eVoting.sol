// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract eVoting {
    


    // admin address
    address public owner;
   // bool public votingActive;

    enum State { NotStarted, CommitActive, RevealActive, Finished }
    State public currentState;


    event StateChanged(State newState);
    event CandidateAdded(uint id, string name);
    event VoterRegistered(address voter);
    event VoteCommitted(address voter);
    event VoteRevealed(address voter, uint candidateId);


    struct Candidate {
        uint id;            
        string name;        
        uint voteCount;     
    }

    struct Voter {
        bool isRegistered; 
        bool hasCommitted;
        bool hasRevealed; 
        bytes32 commitment;      
    }

    // numbre of candidates
    uint public candidatesCount;

    mapping(uint => Candidate) public candidates;


    mapping(address => Voter) public voters;


    constructor() {
        owner = msg.sender; 
        currentState = State.NotStarted;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Only the owner can call this function.");
        _;
    }

    function startCommitPhase() public onlyOwner {
        require(currentState == State.NotStarted, "Voting process already started.");
        currentState = State.CommitActive;
        emit StateChanged(currentState);
    }

    function startRevealPhase() public onlyOwner {
        require(currentState == State.CommitActive, "Commit phase is not active.");
        currentState = State.RevealActive;
        emit StateChanged(currentState);
    }

    function endVoting() public onlyOwner {
        require(currentState == State.RevealActive, "Reveal phase is not active.");
        currentState = State.Finished;
        emit StateChanged(currentState);
    }
    


    // add candidate only by owner
    function addCandidate(string memory _name) public onlyOwner {
        require(currentState == State.NotStarted, "Error: Voting process has started.");
        candidatesCount++;
        candidates[candidatesCount] = Candidate ({
            id : candidatesCount,
            name : _name,
            voteCount : 0

        });

        emit CandidateAdded(candidatesCount, _name);
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidatesCount);
        for (uint i = 0; i < candidatesCount; i++) {
            allCandidates[i] = candidates[i + 1];
        }
        return allCandidates;
    }


     //registerVoter only by admin
    function registerVoter(address[] memory _voterAddresses) public onlyOwner {
        require(currentState == State.NotStarted, "Error: Voting process has started.");
        for (uint i = 0; i < _voterAddresses.length; i++) {
            address _voterAddress = _voterAddresses[i];
        if (voters[_voterAddress].isRegistered == false) {
            voters[_voterAddress].isRegistered = true;
            emit VoterRegistered(_voterAddress);
        }
        
        }
    }

     //vote by only user we give primissions
    function commitVote(bytes32 _commitment) public {
        require(currentState == State.CommitActive, "Error: Commit phase is not active.");
        require(voters[msg.sender].isRegistered, "Error: You are not registered to vote.");
        require(voters[msg.sender].hasCommitted == false, "Error: You have already committed.");
        voters[msg.sender].commitment = _commitment;
        voters[msg.sender].hasCommitted = true;
        emit VoteCommitted(msg.sender);

    }

    function revealVote(uint _candidateId, bytes32 _secret) public {
        require(currentState == State.RevealActive, "Error: Reveal phase is not active.");
        require(voters[msg.sender].hasCommitted, "Error: You did not commit a vote.");
        require(voters[msg.sender].hasRevealed == false, "Error: You have already revealed your vote.");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Error: Invalid candidate ID.");

        // commpare the newGeneratted Hash and the Stored Hash
        bytes32 calculatedHash = keccak256(abi.encodePacked(_candidateId, _secret));
        require(calculatedHash == voters[msg.sender].commitment, "Error: Vote/Secret mismatch.");

        voters[msg.sender].hasRevealed = true;
        candidates[_candidateId].voteCount++;

        emit VoteRevealed(msg.sender,  _candidateId);
    }


    function getWinner() public view returns (string[] memory winnerNames) {
        require(currentState == State.Finished, "Error: Voting is not finished.");
        
        uint highestVotes = 0;
        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
            }
        }

        uint winnerCount = 0;
        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount == highestVotes) {
                winnerCount++;
            }
        }
        winnerNames = new string[](winnerCount);
        uint winnerIndex = 0;
        for (uint i = 1; i <= candidatesCount; i++) {
            if(candidates[i].voteCount == highestVotes){
                winnerNames[winnerIndex] = candidates[i].name;
                winnerIndex++;
            }


        }
        return winnerNames;
    }


// generate HAsh to tst the code
    function getHash(uint _candidateId, bytes32 _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_candidateId, _secret));
    }


}