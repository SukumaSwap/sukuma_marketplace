// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BaseTest} from "./BaseTest.sol";

contract MarketplaceTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

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
}
