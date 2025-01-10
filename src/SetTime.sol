// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimedInheritance {
    struct Inheritance {
        address beneficiary;
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    mapping(address => Inheritance) public inheritances;

    event InheritanceCreated(
        address indexed creator,
        address beneficiary,
        uint256 amount,
        uint256 unlockTime
    );
    event BeneficiaryUpdated(address indexed creator, address newBeneficiary);
    event Claimed(address indexed beneficiary, uint256 amount);

    function createInheritance(
        address _beneficiary,
        uint256 _unlockTimeInYears
    ) external payable {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(msg.value > 0, "Must send some ETH");
        require(_unlockTimeInYears > 0, "Unlock time must be greater than 0");
        require(
            inheritances[msg.sender].amount == 0,
            "Inheritance already exists"
        );

        uint256 unlockTimestamp = block.timestamp +
            (_unlockTimeInYears * 1 days);

        inheritances[msg.sender] = Inheritance({
            beneficiary: _beneficiary,
            amount: msg.value,
            unlockTime: unlockTimestamp,
            claimed: false
        });

        emit InheritanceCreated(
            msg.sender,
            _beneficiary,
            msg.value,
            unlockTimestamp
        );
    }

    function updateBeneficiary(address _newBeneficiary) external {
        require(_newBeneficiary != address(0), "Invalid beneficiary address");
        require(inheritances[msg.sender].amount > 0, "No inheritance created");
        require(
            !inheritances[msg.sender].claimed,
            "Inheritance already claimed"
        );
        require(
            block.timestamp < inheritances[msg.sender].unlockTime,
            "Unlock time has passed"
        );

        inheritances[msg.sender].beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(msg.sender, _newBeneficiary);
    }

    function claim() external {
        address creator = findCreator(msg.sender);
        require(creator != address(0), "No inheritance found for beneficiary");

        Inheritance storage inheritance = inheritances[creator];
        require(!inheritance.claimed, "Already claimed");
        require(inheritance.beneficiary == msg.sender, "Not the beneficiary");
        require(
            block.timestamp >= inheritance.unlockTime,
            "Cannot claim before unlock time"
        );

        uint256 amount = inheritance.amount;
        inheritance.claimed = true;
        inheritance.amount = 0;

        payable(msg.sender).transfer(amount);
        emit Claimed(msg.sender, amount);
    }

    function findCreator(address _beneficiary) internal view returns (address) {
        for (uint160 i = 1; i < type(uint160).max; i++) {
            address creator = address(i);
            if (
                inheritances[creator].beneficiary == _beneficiary &&
                !inheritances[creator].claimed &&
                inheritances[creator].amount > 0
            ) {
                return creator;
            }
        }
        return address(0);
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
            bool claimed
        )
    {
        Inheritance memory inheritance = inheritances[_creator];
        return (
            inheritance.beneficiary,
            inheritance.amount,
            inheritance.unlockTime,
            inheritance.claimed
        );
    }

    function timeUntilUnlock(address _creator) external view returns (uint256) {
        Inheritance memory inheritance = inheritances[_creator];
        if (block.timestamp >= inheritance.unlockTime) return 0;
        return inheritance.unlockTime - block.timestamp;
    }
}
