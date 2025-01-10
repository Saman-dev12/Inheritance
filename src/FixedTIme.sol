// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleInheritance {
    struct Inheritance {
        address beneficiary;
        uint256 amount;
        uint256 unlockTime;
        uint256 lastPingTime;
        bool claimed;
    }

    uint256 public constant REQUIRED_PING_INTERVAL = 30 seconds;

    mapping(address => Inheritance) public inheritances;

    event InheritanceCreated(
        address indexed creator,
        address beneficiary,
        uint256 amount
    );
    event Pinged(address indexed creator);
    event Claimed(address indexed beneficiary, uint256 amount);

    function createInheritance(address _beneficiary) external payable {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(msg.value > 0, "Must send some ETH");
        require(
            inheritances[msg.sender].amount == 0,
            "Inheritance already exists"
        );

        inheritances[msg.sender] = Inheritance({
            beneficiary: _beneficiary,
            amount: msg.value,
            unlockTime: block.timestamp + REQUIRED_PING_INTERVAL,
            lastPingTime: block.timestamp,
            claimed: false
        });

        emit InheritanceCreated(msg.sender, _beneficiary, msg.value);
    }

    function ping() external {
        Inheritance storage inheritance = inheritances[msg.sender];
        require(inheritance.amount > 0, "No inheritance created");
        require(!inheritance.claimed, "Inheritance already claimed");

        inheritance.lastPingTime = block.timestamp;
        inheritance.unlockTime = block.timestamp + REQUIRED_PING_INTERVAL;

        emit Pinged(msg.sender);
    }

    function claim(address creator) external {
        require(creator != address(0), "No inheritance found for beneficiary");

        Inheritance storage inheritance = inheritances[creator];
        require(!inheritance.claimed, "Already claimed");
        require(inheritance.beneficiary == msg.sender, "Not the beneficiary");
        require(block.timestamp > inheritance.unlockTime, "Cannot claim yet");

        uint256 amount = inheritance.amount;
        inheritance.claimed = true;
        inheritance.amount = 0;

        payable(msg.sender).transfer(amount);
        emit Claimed(msg.sender, amount);
    }

    function getInheritanceDetails(
        address _creator
    )
        external
        view
        returns (
            address beneficiary,
            uint256 amount,
            uint256 unlockTime,
            uint256 lastPingTime,
            bool claimed
        )
    {
        Inheritance memory inheritance = inheritances[_creator];
        return (
            inheritance.beneficiary,
            inheritance.amount,
            inheritance.unlockTime,
            inheritance.lastPingTime,
            inheritance.claimed
        );
    }
}
