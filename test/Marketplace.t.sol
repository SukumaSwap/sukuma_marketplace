// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BaseTest} from "./BaseTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMarketplace} from "@contracts/IMarketplace.sol";

contract MarketplaceTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    //functions to be tested:
    //   1.createAccount.     [x]
    //   2.getAccount.        [x]
    //   3.createOffer.       [x]
    //   4.closeOffer.        [x]
    //   5.createBuyTrade.
    //   6.closeBuyTrade
    //   7.createSellTrade.
    //   8.closeSellTrade
    //   9.releaseCrypto.
    //   10.getMarketplaceFee. [x]
    //   11.setMarketplaceFee  [x]
    //   12.deposit.           [x]
    //   13.withdraw.          [x]
    //   14.checkBalance.      [x]
    //   15.transfer.          [x]
    //   16.like.              [x]
    //   17.dislike.           [x]
    //   18.blockAccount.      [*]

    //test for createAccount
    function testFuzz_CreateAccount(address caller) public {
        vm.startPrank(caller);

        uint256 id = marketplace.createAccount();

        assertEq(id, 1);
        vm.stopPrank();
    }

    function testFuzz_GetAccount(
        address caller,
        address another_caller
    ) public {
        vm.startPrank(caller);

        uint256 id = marketplace.createAccount();
        assertEq(id, 1);

        (uint256 accountId, uint256 likes, uint256 dislikes, ) = marketplace
            .getAccount(caller);

        assertEq(accountId, 1);
        assertEq(likes, 0);
        assertEq(dislikes, 0);
        vm.stopPrank();

        // when address does not exist
        (accountId, likes, dislikes, ) = marketplace.getAccount(another_caller);

        assertEq(accountId, 0);
        assertEq(likes, 0);
        assertEq(dislikes, 0);
    }

    // Test for transfer
    function testFork_Transfer() external {
        uint256 quantity = 45;
        address token = WLD;

        deal(token, defaultAdmin, quantity);
        vm.startPrank(defaultAdmin);
        //approve marketplace to trasfer token from acc to markertplace
        IERC20(token).approve(address(marketplace), quantity);

        // Assume that the account has been created and has enough balance
        marketplace.deposit(token, quantity); // Deposit initial quantity
        //get balance after deposit
        uint256 balance = marketplace.checkBalance(defaultAdmin, token);
        assertEq(balance, quantity);

        marketplace.transfer(token, quantity, trader1); // Transfer a portion of the funds

        // Check that the account's balance has been reduced by the correct amount
        balance = marketplace.checkBalance(defaultAdmin, token);
        assertEq(balance, 0);

        balance = marketplace.checkBalance(trader1, token);

        assertEq(balance, quantity);

        vm.stopPrank();
    }

    // Test for setMarketplaceFee
    function testFuzz_SetMarketplaceFee(uint256 fee) external {
        vm.startPrank(defaultAdmin);

        marketplace.setMarketplaceFee(fee);

        assertEq(marketplace.getMarketplaceFee(), fee);

        vm.stopPrank();
    }

    // Test for withdraw
    function testFork_Withdraw() external {
        uint256 quantity = 45;

        vm.startPrank(defaultAdmin);
        // deposit
        {
            deal(WLD, defaultAdmin, quantity);
            IERC20(WLD).approve(address(marketplace), quantity);
            marketplace.deposit(WLD, quantity);
            uint256 balance = marketplace.checkBalance(defaultAdmin, WLD);
            assertEq(balance, quantity);
        }

        // withdraw
        {
            marketplace.withdraw(WLD, 20);
            uint256 balance = marketplace.checkBalance(defaultAdmin, WLD);
            assertEq(balance, 25);
        }
        vm.stopPrank();
    }

    // Test for like
    function test_Like() external {
        uint256 account_id = 0;
        address alice = makeAddr("alice");

        // create account
        {
            vm.startPrank(alice);
            account_id = marketplace.createAccount();

            assertEq(account_id, 1);
            vm.stopPrank();
        }

        // like
        {
            address bob = makeAddr("bob");
            vm.startPrank(bob);
            marketplace.like(account_id);
            (, uint256 likes, , ) = marketplace.getAccount(alice);
            assertEq(likes, 1);
            vm.stopPrank();
        }
    }

    // Test for dislike
    function test_Dislike() external {
        uint256 account_id = 0;
        address alice = makeAddr("alice");

        // create account
        {
            vm.startPrank(alice);
            account_id = marketplace.createAccount();

            assertEq(account_id, 1);
            vm.stopPrank();
        }

        // dislike
        {
            address bob = makeAddr("bob");
            vm.startPrank(bob);
            marketplace.dislike(account_id);
            (, , uint256 dislikes, ) = marketplace.getAccount(alice);
            assertEq(dislikes, 1);
            vm.stopPrank();
        }
    }

    // Test for createOffer
    function testFork_CreateOffer() external {
        uint256 quantity = 100;
        address alice = makeAddr("alice");
        vm.startPrank(alice);
        // deposit
        {
            deal(WLD, alice, quantity);
            IERC20(WLD).approve(address(marketplace), quantity);
            marketplace.deposit(WLD, quantity);
            uint256 balance = marketplace.checkBalance(alice, WLD);
            assertEq(balance, quantity);
        }
        // create offer
        uint256 offerId;
        {
            uint256 _offerRate = 1;
            string[] memory currencies = new string[](1);
            currencies[0] = "USD";
            string[] memory methods = new string[](1);
            methods[0] = "Mastercard";

            offerId = marketplace.createOffer(
                WLD,
                quantity,
                IMarketplace.OfferType.Buy,
                1, // min
                100, // max
                "instructions",
                _offerRate,
                currencies,
                methods
            );
            assertEq(offerId, 1);
        }
        vm.stopPrank();

        // close offer
        {
            vm.startPrank(alice);
            marketplace.closeOffer(offerId);
            vm.stopPrank();
        }
    }
}
