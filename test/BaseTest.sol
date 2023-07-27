// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Marketplace} from "@contracts/Marketplace.sol";

abstract contract BaseTest is Test {
    Marketplace marketplace;

    /// Participants
    address public defaultAdmin = makeAddr("defaultAdmin");
    address public trader1 = makeAddr("trader1");

    address public constant WLD = 0x163f8C2467924be0ae7B5347228CABF260318753;

    uint256 mainnetFork;

    function setUp() public virtual {
        mainnetFork = vm.createFork("https://eth-mainnet.public.blastapi.io");

        vm.label(defaultAdmin, "defaultAdmin");
        deal(defaultAdmin, 10 ether);

        vm.selectFork(mainnetFork);
        vm.startPrank(defaultAdmin);
        marketplace = new Marketplace();
        marketplace.initialize();

        vm.stopPrank();
    }
}
