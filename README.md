# Damn Vulnerable DeFi - Updated Foundry Version - (June/2022) 

Damn Vulnerable DeFi is the wargame to learn offensive security of DeFi smart contracts.

Throughout numerous challenges you will build the skills to become a bug hunter or security auditor in the space. 🕵️‍♂️

1 - Based on the original work of: https://github.com/tinchoabbate/damn-vulnerable-defi
Visit [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz)

2 - Sequentially based on the modified (foundry edition) work of: https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry

3 - This version is made only with the newest foundry/forge and forge-std dependencies (with embedded ds-test). 

It contains the solutions (shown as program comments) to the challenges.

The directory structure was modified to conform to the foundry standard

4 - Commented solutions can be found on this excellent article series at : 

https://stermi.medium.com/damn-vulnerable-defi-challenge-1-unstoppable-92bacdefafcc

https://stermi.medium.com/damn-vulnerable-defi-challenge-2-solution-naive-receiver-341376fdc967

5 - To expand your knowledge about security issues, take a look at this list of contract´s possible vulnerabilities:

SWC Registry - Smart Contract Weakness Classification and Test Cases.
https://swcregistry.io/


## How To Play 🕹️

1.  **Install Foundry**

First run the command below to get foundryup, the Foundry toolchain installer:

``` bash
curl -L https://foundry.paradigm.xyz | bash
```

Then, in a new terminal session or after reloading your PATH, run it to get the latest forge and cast binaries:

``` console
foundryup
```
Advanced ways to use `foundryup`, and other documentation, can be found in the [foundryup package](./foundryup/README.md)

2. **Clone This Repo and install dependencies**
``` 
git clone https://github.com/0xSchellen/damn-vulnerable-defi-foundry-updated.git
cd damn-vulnerable-defi-foundry-updated
git submodule update --init --recursive

```
3. **Code your solutions in the provided `[NAME_OF_THE_CHALLENGE].t.sol` files (inside each challenge's folder in the test folder)**

4. **Run your exploit for a challenge**

forge test --match-test [NAME_OF_THE_TEST_WITH_YOUR_SOLUTION] --match-contract [CONTRACT_LEVEL_NAME]

Test 1 - Unstoppable
forge test --match-contract Unstoppable -vvvv

Test 2 - Naive Receiver
forge test --match-contract NaiveReceiver -vvvv

If the challenge is executed successfully, you've passed!🙌🙌

### Tips and tricks ✨
- In all challenges you must use the account called attacker. In Forge, you can use the [cheat code](https://github.com/gakonst/foundry/tree/master/forge#cheat-codes) `prank` or `startPrank`.
- To code the solutions, you may need to refer to [Forge docs](https://onbjerg.github.io/foundry-book/forge/index.html).
- In some cases, you may need to code and deploy custom smart contracts.

### Preinstalled dependencies
`forge-std` for testing and better cheatcode UX, and `openzeppelin-contracts` and for contract implementations. 