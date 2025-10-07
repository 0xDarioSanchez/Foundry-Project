// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Market} from "../src/Market.sol";

contract DeployMarket is Script {
    function deployMarket() public returns (Market, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;

        vm.startBroadcast();
        Market market = new Market(priceFeed);
        vm.stopBroadcast();
        return (market, helperConfig);
    }

    function run() external returns (Market, HelperConfig) {
        return deployMarket();
    }
}
