// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Mind {
    string public ideaname;
    string public description;
    string public domain;
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    function setName(string memory idea, string memory desc, string memory dom) public {
        require(msg.sender == creator, "Only the creator can modify the idea details");
        ideaname = idea;
        description = desc;
        domain = dom;
    }
}

contract ApprovalProcess {
    string public approved;
    address public contractAddress;
    address public creator;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
        creator = msg.sender;
    }

    function approve(string memory result) public {
        require(msg.sender == creator, "Only the creator can approve the patent");
        approved = result;
    }

    function getIdeaDetails() public view returns (string memory, string memory, string memory) {
        Mind contractMind = Mind(contractAddress);
        return (contractMind.ideaname(), contractMind.description(), contractMind.domain());
    }
}

contract IdeaDisplay {
    struct InvestorInfo {
        string name;
        uint investment;
    }

    struct PartialInvestorInfo {
        string name;
        uint investment;
    }

    ApprovalProcess public approvalProcess;
    mapping(address => InvestorInfo) public investors;
    mapping(uint => address) public investorAddresses;
    mapping(address => PartialInvestorInfo) public partialInvestors;
    mapping(uint => address) public partialInvestorAddresses;
    uint public totalInvestment;
    uint public defaultInvestAmount = 2 ether;
    uint public investorIdCounter;
    uint public partialInvestorIdCounter;

    constructor(address _approvalProcess) {
        approvalProcess = ApprovalProcess(_approvalProcess);
        investorIdCounter = 1;
        partialInvestorIdCounter = 1;
    }

    function displayIdea() public view returns (string memory, string memory, string memory) {
        require(keccak256(bytes(approvalProcess.approved())) == keccak256(bytes("yes")), "Patent not approved yet");
        Mind contractMind = Mind(approvalProcess.contractAddress());
        return (contractMind.ideaname(), contractMind.description(), contractMind.domain());
    }

    function invest(string memory investorName) public payable {
        require(msg.value > 0, "Investment amount should be greater than zero");
        require(keccak256(bytes(approvalProcess.approved())) == keccak256(bytes("yes")), "Cannot invest until the patent is approved");

        if (bytes(investors[msg.sender].name).length == 0) {
            // Investor
            investors[msg.sender].name = investorName;
            investors[msg.sender].investment = msg.value;
            investorAddresses[investorIdCounter] = msg.sender;
            investorIdCounter++;
        } else {
            // Partial Investor
            partialInvestors[msg.sender].name = investorName;
            partialInvestors[msg.sender].investment += msg.value;
            partialInvestorAddresses[partialInvestorIdCounter] = msg.sender;
            partialInvestorIdCounter++;
        }

        totalInvestment += msg.value;
    }

    function getInvestorId(address investor) public view returns (uint) {
        for (uint i = 1; i < investorIdCounter; i++) {
            if (investorAddresses[i] == investor) {
                return i;
            }
        }
        return 0;
    }

    function getPartialInvestorId(address partialInvestor) public view returns (uint) {
        for (uint i = 1; i < partialInvestorIdCounter; i++) {
            if (partialInvestorAddresses[i] == partialInvestor) {
                return i;
            }
        }
        return 0;
    }

    function getInputNameFromPartialOwners() public view returns (string memory) {
        // Get the list of partial owners
        uint[] memory partialOwners = new uint[](partialInvestorIdCounter);

        for (uint i = 1; i < partialInvestorIdCounter; i++) {
            partialOwners[i] = i;
        }

        // If there are no partial owners, return an empty string
        if (partialOwners.length == 0) {
            return "";
        }

        // Get the name of the first partial owner
        string memory name = partialInvestors[partialInvestorAddresses[partialOwners[0]]].name;

        // Return the name
        return name;
    }
}
