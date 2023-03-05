// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StateContract.sol";

contract StateContractTest is Test {
    StateContract public stateContract;

    function setUp() public {
        stateContract = new StateContract();
    }

    function invariant_testInvariantStateContract() public {
        assertTrue(stateContract.evenNum() % 2 == 0);
        assertTrue(stateContract.oddNum() % 2 != 0);
    }
}
