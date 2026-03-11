// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script, console2} from "forge-std/Script.sol";
import {OurToken} from "../src/OurToken.sol";
import {Types} from "../src/Types.sol";
import {TokenConfig} from "../src/TokenConfig.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

interface IERC20Approve {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract DeployOurToken is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;

    error MissingUsdtCode(address usdt);

    uint256 constant BASE_FEE = 39e6;
    uint256 constant REVOKE_MINTING_FEE = 19e6;
    uint256 constant REVOKE_PAUSING_FEE = 19e6;
    uint256 constant TAXABLE_FEE = 15e6;
    uint256 constant CREATOR_INFO_FEE = 19e6;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        IERC20 usdt = IERC20(TokenConfig.USDT_ADDRESS);
        address feeRecipient = TokenConfig.FEE_RECIPIENT;

        if (TokenConfig.USDT_ADDRESS.code.length == 0) {
            revert MissingUsdtCode(TokenConfig.USDT_ADDRESS);
        }

        // Local/dev: deploy a mock and etch it into the hardcoded address.
        if (block.chainid != SEPOLIA_CHAIN_ID) {
            ERC20Mock mockUsdt = new ERC20Mock();
            vm.etch(TokenConfig.USDT_ADDRESS, address(mockUsdt).code);
            ERC20Mock(TokenConfig.USDT_ADDRESS).mint(deployer, 100e6);
        }

        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256(abi.encodePacked("salt1"));

        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, deployer)
        );

        address predicted = vm.computeCreate2Address(salt, keccak256(bytecode));

        uint256 fee = calculateFee(
            params.revokeMinting,
            params.revokePausing,
            params.taxEnabled,
            params.metadata.hasCreatorInfo
        );

        console2.log("Deployer:", deployer);
        console2.log("Predicted:", predicted);
        console2.log("Fee:", fee);
        console2.log("USDT:", address(usdt));
        console2.log("FeeRecipient:", feeRecipient);

        vm.startBroadcast(privateKey);

        IERC20Approve(address(usdt)).approve(predicted, fee);

        OurToken token = new OurToken{salt: salt}(
            params,
            deployer
        );

        vm.stopBroadcast();

        console2.log("Deployed:", address(token));
    }

    function calculateFee(
        bool _revokeMinting,
        bool _revokePausing,
        bool _taxEnabled,
        bool _hasCreatorInfo
    ) internal pure returns (uint256 total) {
        total = BASE_FEE;
        if (_revokeMinting) total += REVOKE_MINTING_FEE;
        if (_revokePausing) total += REVOKE_PAUSING_FEE;
        if (_taxEnabled) total += TAXABLE_FEE;
        if (_hasCreatorInfo) total += CREATOR_INFO_FEE;
    }

    function createBaseTokenParams()
        internal
        pure
        returns (Types.TokenParams memory)
    {
        return
            Types.TokenParams({
                name: "MyToken",
                symbol: "MTK",
                initialSupply: INITIAL_SUPPLY,
                tokenDecimals: 18,
                taxEnabled: false,
                taxRate: 0,
                taxRecipient: address(0),
                revokeMinting: true,
                revokePausing: true,
                metadata: Types.MetadataParams({
                    tokenDescription: "",
                    tokenWebsite: "",
                    socialUrls: new string[](3),
                    tags: new string[](3),
                    hasCreatorInfo: false,
                    creatorName: "",
                    creatorWebsite: ""
                })
            });
    }
}
