// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/DigitalGoldToken.sol";

uint256 constant INITIAL_SUPPLY = 10**12;

contract Handler is Test {
    DigitalGoldToken public token;

    uint256 public sumTransfers = 0; // total amount that's been sent using transfer()
    uint256 public sumTransferFrom = 0; // total amount that's been sent using transferFrom()
    uint256 public allowanceIncreased = 0; // total amount of allowance increased done
    uint256 public allowanceDecreased = 0; // total amount of allowance decreased
    uint256 public sumMinted = 0; // total amount of tokens minted

    // All addresses that the invariant test uses during a test run
    address[] usedAddresses;

    constructor() {
        token = new DigitalGoldToken(INITIAL_SUPPLY);

        usedAddresses.push(address(this));
        usedAddresses.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        usedAddresses.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        usedAddresses.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        usedAddresses.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

        mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1500000);
        mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 1500000);
        mint(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 1500000);
        mint(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 1500000);
    }

    address internal currentActor;
    modifier useActor(uint256 addressIndexSeed) {
        currentActor = usedAddresses[bound(addressIndexSeed, 0, usedAddresses.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    function mint(address to, uint256 amount) internal {
        vm.startPrank(address(this)); // handler contract which is owner
        token.mint(to, amount);
        sumMinted += amount;
        vm.stopPrank();
    }

    function getRandomUser(uint256 seedVal) internal view returns(address) {
        address addr = usedAddresses[bound(seedVal, 0, usedAddresses.length - 1)];
        if (addr == currentActor) {
            addr = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        }
        return addr;
    }

    function transfer(uint256 toAddrSeed, uint256 amount, uint256 seedValue) useActor(seedValue) public returns (bool) {
        address to = getRandomUser(toAddrSeed);

        amount = bound(amount, 0, token.balanceOf(currentActor));

        bool result = token.transfer(to, amount);
        if (result) {
            sumTransfers += amount;
        }
        return result;
    }

    function increaseAllowance(uint256 spenderSeed, uint256 addedValue, uint256 seedValue) useActor(seedValue) public returns (bool) {
        address spender = getRandomUser(spenderSeed);

        addedValue = bound(addedValue, 0, 10**5);

        // Current caller lets address 'spender' spend his tokens
        bool result = token.increaseAllowance(spender, addedValue);
        if (result) {
            allowanceIncreased += addedValue;
        }
        return result;
    }

    function decreaseAllowance(uint256 spenderSeed, uint256 subtractedValue, uint256 seedValue) useActor(seedValue) public returns (bool) {
        address spender = getRandomUser(spenderSeed);

        subtractedValue = bound(subtractedValue, 0, token.allowance(currentActor, spender));

        bool result = token.decreaseAllowance(spender, subtractedValue);
        if (result) {
            allowanceDecreased += subtractedValue;
        }
        return result;
    }

    function transferFrom(uint256 randomFromAddrSeed, uint256 randomToAddrSeed, uint256 amount, uint256 seedValue) useActor(seedValue) public returns (bool) {
        address from = getRandomUser(randomFromAddrSeed);
        address to = usedAddresses[bound(randomToAddrSeed, 0, usedAddresses.length - 1)];

        // Current allowance for current caller, on from
        uint256 allowedAmount = token.allowance(from, currentActor);
        amount = bound(amount, 0, allowedAmount);
        if (amount == 0 || token.balanceOf(from) < amount) {
            return false;
        }
        
        bool result = token.transferFrom(from, to, amount); 
        if (result) {
            sumTransferFrom += amount;
        }
        return result;
    }

    function totalBalance() public view returns(uint256) {
        uint256 sum = 0;
        for (uint i=0; i<usedAddresses.length; i++) {
            sum += token.balanceOf(usedAddresses[i]);
        }
        return sum;
    }
}

contract DigitalGoldTokenTest is Test {
    Handler handler;

    function setUp() public {
        handler = new Handler();

        targetContract(address(handler));
    }

    function invariant_testTotalSupplyAfterMint() public {
        assertEq(handler.token().totalSupply(), INITIAL_SUPPLY + handler.sumMinted());
    }

    function invariant_testTotalBalanceOfUsersAfterTransfer() public {
        assertEq(handler.totalBalance(), handler.token().totalSupply());
    }

    function invariant_testTransferFromNotExceedAllowance() public {
        assertLe(handler.sumTransferFrom(), (handler.allowanceIncreased() - handler.allowanceDecreased()));
    }

    function invariant_testDebugValues() public view {
        console.log("################################");
        console.log("sumTransfers", handler.sumTransfers()); 
        console.log("sumTransferFrom", handler.sumTransferFrom()); 
        console.log("allowanceIncreased", handler.allowanceIncreased()); 
        console.log("allowanceDecreased", handler.allowanceDecreased()); 
        console.log("sumMinted", handler.sumMinted()); 
        console.log("################################");
    }
}
