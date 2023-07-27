// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Marketplace} from "@contracts/Marketplace.sol";

abstract contract BaseTest is Test {
    Marketplace marketplace;

    /// Participants
    address public defaultAdmin = makeAddr("defaultAdmin");
    address public trader1 = makeAddr("trader1");

    function setUp() public virtual {
        // https://eth.llamarpc.com

        vm.label(defaultAdmin, "defaultAdmin");
        deal(defaultAdmin, 10 ether);

        vm.startPrank(defaultAdmin);
        marketplace = new Marketplace();

        vm.stopPrank();
    }
}
