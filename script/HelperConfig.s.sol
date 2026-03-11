// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract HelperConfig is Script {
    /* If we are on a local anvil chain,
    we deploy mocks, otherwise, we grab the
    existing address from the helperconfig */
    uint256 constant BASE_FEE = 39e6; // 39 USDT
    uint256 constant REVOKE_MINTING_FEE = 19e6;
    uint256 constant REVOKE_PAUSING_FEE = 19e6;
    uint256 constant TAXABLE_FEE = 15e6;
    uint256 constant CREATOR_INFO_FEE = 19e6;

    struct NetworkConfig {
        address usdt;
        uint256 _baseFee;
        uint256 _revokeMintingFee;
        uint256 _revokePausingFee;
        uint256 _taxableFee;
        uint256 _creatorInfoFee;
    }

    NetworkConfig public activeNetwork;

    function getActiveConfig() public returns (NetworkConfig memory) {
        if (block.chainid == 11155111) activeNetwork = getSepoliaEthConfig();
        else if (block.chainid == 1) activeNetwork = getMainnetEthConfig();
        else activeNetwork = getAnvilEthConfig();
        return activeNetwork;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            usdt: 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06,
            _baseFee: BASE_FEE,
            _revokeMintingFee: REVOKE_MINTING_FEE,
            _revokePausingFee: REVOKE_PAUSING_FEE,
            _taxableFee: TAXABLE_FEE,
            _creatorInfoFee: CREATOR_INFO_FEE
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            _baseFee: BASE_FEE,
            _revokeMintingFee: REVOKE_MINTING_FEE,
            _revokePausingFee: REVOKE_PAUSING_FEE,
            _taxableFee: TAXABLE_FEE,
            _creatorInfoFee: CREATOR_INFO_FEE
        });
        return mainnetConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetwork.usdt != address(0)) {
            return activeNetwork;
        }
        vm.startBroadcast();
        ERC20Mock mockUsdt = new ERC20Mock();
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            usdt: address(mockUsdt),
            _baseFee: BASE_FEE,
            _revokeMintingFee: REVOKE_MINTING_FEE,
            _revokePausingFee: REVOKE_PAUSING_FEE,
            _taxableFee: TAXABLE_FEE,
            _creatorInfoFee: CREATOR_INFO_FEE
        });
        return anvilConfig;
    }
}
