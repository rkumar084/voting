// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract Voting {

    enum ElectionStatus { NOTSTARTED, ONGOING, COMPLETE}

    ElectionStatus electionStatus;
    address constant public admin = 0x8789b0f86349370BC36E4a7ab63e33c69B193E43;
    uint256 public voterCount;

    struct Voter {
        address voterAddress;
        string name;
        uint256 candidateId; //The candidate who has been voted for
        bool isDelegated; //If the vote is delegated or not
        bool hasVoted; //If the voter has casted the vote
        address delegateAddress; // Specifies the address who can vote on behalf the voter
    }

    struct Candidate {
        uint256 id;
        string name;
        string agenda;
        uint256 voteCount;
    }

    mapping(address => Voter)  voterMapping; 
    mapping(uint256 => Candidate)  candidateMapping; 
    uint256[] candidateKeys;

    constructor () {
        electionStatus = ElectionStatus.NOTSTARTED;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Error! Only admin can perform operation");
    _;}


    function addCandidate(string memory _name, string memory _proposal, address owner) public onlyAdmin  {        
        uint256 candidateId = candidateKeys.length + 1;
        Candidate memory _candidate;
        _candidate.id = candidateId;
        _candidate.name = _name;
        _candidate.agenda = _proposal;
        _candidate.voteCount = 0;
        candidateMapping[candidateId] = _candidate;
        // update  candidateKeys
        candidateKeys.push(candidateId);
    }

    function addVoter(address _voterAddress, address owner, string memory name) public onlyAdmin  {
        Voter memory _voter;
        _voter.voterAddress = _voterAddress;
        _voter.name = name;
        voterMapping[_voterAddress] = _voter;
        // update votercount
        voterCount++;
    }

    function startElection(address owner) public onlyAdmin {
        electionStatus = ElectionStatus.ONGOING;
    }

    function endElection(address owner) public onlyAdmin {
         electionStatus = ElectionStatus.COMPLETE;
    }

    function delegateVote(address delegateAddress, address voterAddress) public  {
        require(voterAddress  == msg.sender, "Unauthorized! Voter cannot delegate for other voters");
        Voter memory _voter = voterMapping[voterAddress];
        require(_voter.voterAddress  > 0x0000000000000000000000000000000000000000, "Error! Voter does not exist.");
        Voter memory _delegateVoter = voterMapping[delegateAddress];
        require(_delegateVoter.voterAddress  > 0x0000000000000000000000000000000000000000, "Error! Delegate voter does not exist.");        
        require(_voter.hasVoted == false, "Error! Voter has voted already.");

        //This function can be called only when the election is going on and by a voter who has not yet voted
        require(electionStatus == ElectionStatus.ONGOING, "Error! Election should be in progress for delegation.");
        _voter.delegateAddress = delegateAddress; // delegate address can vote on behalf of _voter
        voterMapping[voterAddress] = _voter;        
    }

    function vote(uint256 _id, address voterAddress) public {
        Voter memory _voter;
        _voter = voterMapping[voterAddress];
        require(_voter.voterAddress  > 0x0000000000000000000000000000000000000000, "Error! Voter does not exist.");        
        require(electionStatus == ElectionStatus.ONGOING, "Error! Election should be in progress for voting.");
        require(_voter.hasVoted == false, "Error! Voter has voted already.");
        
        if (voterAddress != msg.sender) { // the possibility is sender is a delegatee
            address delegateAddress = _voter.delegateAddress;
            require(_voter.delegateAddress == msg.sender, "Error! sender is not delegated to cast vote.");            
        } 

        _voter.candidateId = _id;
        _voter.hasVoted = true;
        voterMapping[voterAddress] = _voter;
        Candidate memory _candiate = candidateMapping[_id];
        _candiate.voteCount++;
        candidateMapping[_id] = _candiate;
    }

    function displayCandidateDetails(uint256 _id) public view returns (uint256 _candidateId, string memory name,  string memory proposal, uint256 voteCount) {
        Candidate memory _candidate = candidateMapping[_id]; 
        require(_candidate.id > 0, "Error! Candidate does not exist.");
        return(_candidate.id, _candidate.name, _candidate.agenda, _candidate.voteCount);
    }

    //function getVoter()
    function voterProfile(address voter) public view returns (string memory name, uint256 candidateId, bool isDelegated, bool hasVoted, address delegateAddress) {
        Voter memory _voter = voterMapping[voter]; 
        require(_voter.voterAddress  > 0x0000000000000000000000000000000000000000, "Error! Voter does not exist.");        
        return(_voter.name, _voter.candidateId, _voter.isDelegated,_voter.hasVoted, _voter.delegateAddress);
    }

    function getVoterCount() public view returns (uint256 count) {
        return voterCount;
    }


    function showResults(uint256 _id) public view returns (string memory name, uint256 id, uint256 votes) {
        Candidate memory _candidate = candidateMapping[_id]; 
        require(_candidate.id > 0, "Error! Candidate does not exist.");
        return(_candidate.name, _candidate.id, _candidate.voteCount);
    }

    function showWinner() public view returns (string memory name, uint256 id, uint256 votes) {
        require(electionStatus == ElectionStatus.COMPLETE, "Error! Election is not complete for a winner to be shown.");
        uint256 maxVotes = 0;
        uint256 winnerId = 0;

        for (uint i=0; i<candidateKeys.length; i++) {
            if (candidateMapping[candidateKeys[uint(i)]].voteCount >= maxVotes) {
                winnerId = candidateKeys[uint(i)];
            }
        }
        return(candidateMapping[winnerId].name, candidateMapping[winnerId].id, candidateMapping[winnerId].voteCount);
    }

    function getCandateCount() public view returns (uint256 count) {
        return candidateKeys.length;
    }

    function checkState() public view returns (string memory status) {
        if (ElectionStatus.NOTSTARTED == electionStatus) return "NOTSTARTED";
        if (ElectionStatus.ONGOING == electionStatus) return "ONGOING";
        if (ElectionStatus.COMPLETE == electionStatus ) return "COMPLETE";
        return "";
    }

    function checkSender() public view returns (address sender) {
         return msg.sender;
    }
}