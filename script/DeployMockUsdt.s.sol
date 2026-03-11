// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract DeployMockUsdt is Script {
    // 1,000 USDT with 6 decimals (adjust if you like)
    uint256 public constant MINT_AMOUNT = 1_000e6;
    bytes32 public constant SALT = keccak256("mock-usdt-v1");

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console2.log("Deployer:", deployer);

        bytes memory bytecode = type(ERC20Mock).creationCode;
        address predicted = vm.computeCreate2Address(SALT, keccak256(bytecode));
        console2.log("Predicted Mock USDT:", predicted);

        vm.startBroadcast(privateKey);

        ERC20Mock mockUsdt = new ERC20Mock{salt: SALT}();
        require(address(mockUsdt) == predicted, "unexpected mock address");
        mockUsdt.mint(deployer, MINT_AMOUNT);

        vm.stopBroadcast();

        console2.log("Mock USDT deployed at:", address(mockUsdt));
        console2.log("Minted to deployer:", MINT_AMOUNT);
    }
}
