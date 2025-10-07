// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Market} from "../src/Market.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundMarket is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundMarket(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Market(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded Market with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Market", block.chainid);
        fundMarket(mostRecentlyDeployed);
    }
}

contract WithdrawMarket is Script {
    function withdrawMarket(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Market(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw Market balance!");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Market", block.chainid);
        withdrawMarket(mostRecentlyDeployed);
    }
}
