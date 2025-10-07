// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DeployMarket} from "../../script/DeployMarket.s.sol";
import {FundMarket, WithdrawMarket} from "../../script/Interactions.s.sol";
import {Market} from "../../src/Market.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract InteractionsTest is ZkSyncChainChecker, StdCheats, Test {
    Market public market;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external skipZkSync {
        if (!isZkSyncChain()) {
            DeployMarket deployer = new DeployMarket();
            (market, helperConfig) = deployer.deployMarket();
        } else {
            helperConfig = new HelperConfig();
            market = new Market(helperConfig.getConfigByChainId(block.chainid).priceFeed);
        }
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public skipZkSync {
        uint256 preUserBalance = address(USER).balance;
        uint256 preOwnerBalance = address(market.getOwner()).balance;
        uint256 originalMarketBalance = address(market).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(USER);
        market.fund{value: SEND_VALUE}();

        WithdrawMarket withdrawMarket = new WithdrawMarket();
        withdrawMarket.withdrawMarket(address(market));

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(market.getOwner()).balance;

        assert(address(market).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE + originalMarketBalance, afterOwnerBalance);
    }
}
