// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Marketplace} from "@contracts/Marketplace.sol";

contract MarketplaceScript is Script {
    function run() public {
        vm.startBroadcast();

        Marketplace marketplace = new Marketplace{salt: 0x0}();
        marketplace.initialize();
    }
}
