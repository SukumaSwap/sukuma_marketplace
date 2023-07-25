// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Marketplace} from "@contracts/Marketplace.sol";

contract MarketplaceScript is Script {
    function run() public {
        vm.startBroadcast();

        new Marketplace{salt: 0x0}();
    }
}
