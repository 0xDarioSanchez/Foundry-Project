// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {DeployMarket} from "../../script/DeployMarket.s.sol";
import {Market} from "../../src/Market.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract MarketTest is ZkSyncChainChecker, CodeConstants, StdCheats, Test {
    Market public market;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    uint160 public constant USER_NUMBER = 50;
    address public constant USER = address(USER_NUMBER);

    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployMarket deployer = new DeployMarket();
            (market, helperConfig) = deployer.deployMarket();
        } else {
            MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
            market = new Market(address(mockPriceFeed));
        }
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testPriceFeedSetCorrectly() public skipZkSync {
        address retreivedPriceFeed = address(market.getPriceFeed());
        // (address expectedPriceFeed) = helperConfig.activeNetworkConfig();
        address expectedPriceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;
        assertEq(retreivedPriceFeed, expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public skipZkSync {
        vm.expectRevert();
        market.fund();
    }

    function testFundUpdatesFundedDataStructure() public skipZkSync {
        vm.startPrank(USER);
        market.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = market.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public skipZkSync {
        vm.startPrank(USER);
        market.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = market.getFunder(0);
        assertEq(funder, USER);
    }

    // https://twitter.com/PaulRBerg/status/1624763320539525121

    modifier funded() {
        vm.prank(USER);
        market.fund{value: SEND_VALUE}();
        assert(address(market).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded skipZkSync {
        vm.expectRevert();
        vm.prank(address(3)); // Not the owner
        market.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded skipZkSync {
        // Arrange
        uint256 startingMarketBalance = address(market).balance;
        uint256 startingOwnerBalance = market.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(market.getOwner());
        market.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingMarketBalance = address(market).balance;
        uint256 endingOwnerBalance = market.getOwner().balance;
        assertEq(endingMarketBalance, 0);
        assertEq(
            startingMarketBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    // Can we do our withdraw function a cheaper way?
    function testWithdrawFromMultipleFunders() public funded skipZkSync {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2 + USER_NUMBER;

        uint256 originalMarketBalance = address(market).balance; // This is for people running forked tests!

        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_USER_BALANCE);
            market.fund{value: SEND_VALUE}();
        }

        uint256 startingFundedeBalance = address(market).balance;
        uint256 startingOwnerBalance = market.getOwner().balance;

        vm.startPrank(market.getOwner());
        market.withdraw();
        vm.stopPrank();

        assert(address(market).balance == 0);
        assert(startingFundedeBalance + startingOwnerBalance == market.getOwner().balance);

        uint256 expectedTotalValueWithdrawn = ((numberOfFunders) * SEND_VALUE) + originalMarketBalance;
        uint256 totalValueWithdrawn = market.getOwner().balance - startingOwnerBalance;

        assert(expectedTotalValueWithdrawn == totalValueWithdrawn);
    }
}
