// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FeeSystems} from "../src/FeeSystems.sol";
import {Treasury} from "../src/Treasury.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProtocol is Script {
    function run() external returns (TokenFactory) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getActiveConfig();
        vm.startBroadcast();
        IERC20 usdt = IERC20(config.usdt);
        Treasury treasury = new Treasury(msg.sender);
        FeeSystems feeSystems = new FeeSystems(
            config._baseFee,
            config._revokeMintingFee,
            config._revokePausingFee,
            config._taxableFee,
            config._creatorInfoFee,
            msg.sender
        );
        TokenFactory tokenFactory = new TokenFactory(
            usdt,
            feeSystems,
            address(treasury),
            msg.sender
        );
        vm.stopBroadcast();

        return tokenFactory;
    }
}
