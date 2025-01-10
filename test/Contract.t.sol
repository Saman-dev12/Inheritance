// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/FixedTime.sol";

contract TestContract is Test {
    SimpleInheritance c;

    function setUp() public {
        c = new SimpleInheritance();
    }

    function test_create() public {
        address recipient = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        uint256 amount = 10 ether;
        c.createInheritance{value: amount}(recipient);
        console.log(address(c).balance);

        assertEq(address(c).balance, amount, "Contract balance mismatch");
    }
}
