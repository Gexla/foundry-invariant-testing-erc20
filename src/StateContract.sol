// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StateContract {
    uint256 public oddNum = 1;
    uint256 public evenNum = 2;

    function addValue(uint256 num) public {
        if (num % 2 != 0) {
            evenNum = num + 1;
        } else {
            evenNum = num;
        }

        oddNum = evenNum - 1;
        
        // If num is close to max value, break invariant intentionally
        /*if (num > type(uint256).max - 1000) {
            evenNum--;
        }*/
    }

    function mulValue(uint256 num) public {
        evenNum *= num;
        oddNum *= num;
        if (oddNum % 2 == 0) {
            oddNum++;
        }
    }
}