// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Market} from "../../src/Market.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";

contract MarketTest is Test {
    Market public market;

    function setUp() public {
        market = new Market(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function testDeploy() public view {
        assertEq(address(market.getPriceFeed()), 0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }
}
