// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BaseTest} from "./BaseTest.sol";

contract MarketplaceTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }
    //functions to be tested:
    //   1.createAccount.
    //   2.getAccount.
    //   3.createOffer.
    //   4.createBuyTrade.
    //   5.createSellTrade.
    //   6.getMarketplaceFee.
    //   7.setMarketplaceFee
    //   8.deposit.
    //   9.withdraw.
    //   10.checkBalance.
    //   11.trasfer.
    //   12.releaseCrypto.
    //   13.closeOffer.
    //   14.like.
    //   15.dislike.
    //   16.blockAccount.

//test for createAccount
    function testFuzz_createAccount(address caller) public {
        vm.startPrank(caller);

        uint256 id = marketplace.createAccount();

        assertEq(id, 1);
        vm.stopPrank();
    }

    function testFuzz_getAccount(
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
function testFuzz_transfer(address _caller, address _token, uint256 _quantity, address _recipient) public {
    require(_caller != address(0), "Invalid caller address");
    require(_token != address(0), "Invalid token address");
    require(_recipient != address(0), "Invalid recipient address");
    require(_quantity > 0, "Quantity must be greater than zero");
    vm.startPrank(_caller);

    // Assume that the account has been created and has enough balance
    marketplace.deposit(_token, _quantity);  // Deposit initial quantity

    marketplace.transfer(_token, _quantity, _recipient); // Transfer a portion of the funds

    // Check that the account's balance has been reduced by the correct amount
    (, , , uint256 balance) = marketplace.getAccount(_caller);
    assertEq(balance, _quantity - _quantity);
    
    vm.stopPrank();
}
    //function to test withdrawal function
     function testFuzz_partialWithdraw(
        address caller,
        address token,
        uint256 quantity,
        uint256 withdrawAmount
    ) public {
        require(withdrawAmount <= quantity, "Withdraw amount is more than quantity");
        
        vm.startPrank(caller);

        // Assume that the account has been created and has enough balance
        marketplace.deposit(token, quantity);  // Deposit initial quantity

        marketplace.withdraw(token, withdrawAmount); // Withdraw a portion of the funds

        // Check that the account's balance has been reduced by the correct amount
        (, , , uint256 balance) = marketplace.getAccount(caller);
        assertEq(balance, quantity - withdrawAmount);
        
        vm.stopPrank();
    }  
 
}
