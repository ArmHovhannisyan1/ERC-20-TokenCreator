// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "./mock/ERC20Mock.sol";
import {Types} from "../src/Types.sol";
import {OurToken, MintingDisabled, PausingDisabled, InvalidAddress} from "../src/OurToken.sol";
import {TokenConfig} from "../src/TokenConfig.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OurTokenCreate2Test is Test {
    IERC20 public usdt;
    address public user;
    address public feeRecipient;

    uint256 constant BASE_FEE = 39e6;
    uint256 public constant USDT_MINT = 200e6;
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    function setUp() external {
        user = makeAddr("user");
        feeRecipient = TokenConfig.FEE_RECIPIENT;

        ERC20Mock mock = new ERC20Mock();
        vm.etch(TokenConfig.USDT_ADDRESS, address(mock).code);
        usdt = IERC20(TokenConfig.USDT_ADDRESS);
        ERC20Mock(TokenConfig.USDT_ADDRESS).mint(user, USDT_MINT);
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
                    socialUrls: new string[](0),
                    tags: new string[](0),
                    hasCreatorInfo: false,
                    creatorName: "",
                    creatorWebsite: ""
                })
            });
    }

    function testUserCanDeployWithCreate2AndPayFee() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            // this retrieves the creation bytecode of OurToken,
            // with constructor and actual runtime code
            type(OurToken).creationCode,
            // takes parameteres for constructor(...) and it ABI-encode them so
            // the deployment process knows how to pass them to the new contract.
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.prank(user);
        usdt.approve(predicted, type(uint256).max);
        uint256 oldUserBalance = usdt.balanceOf(user);
        uint256 oldFeeRecipientBalance = usdt.balanceOf(feeRecipient);
        vm.prank(user);
        OurToken token = new OurToken{salt: salt}(params, user);
        uint256 feeAmount = token.calculateFee(
            params.revokeMinting,
            params.revokePausing,
            params.taxEnabled,
            params.metadata.hasCreatorInfo
        );
        assertEq(address(token), predicted);
        assertEq(oldUserBalance - feeAmount, usdt.balanceOf(user));
        assertEq(
            oldFeeRecipientBalance + feeAmount,
            usdt.balanceOf(feeRecipient)
        );
        assertEq(token.balanceOf(user), params.initialSupply);
    }

    function testDeployRevertsWithoutApproval() public {
        // Types.TokenParams memory params = createBaseTokenParams();
        vm.prank(user);
        vm.expectRevert();
        new OurToken(createBaseTokenParams(), user);
    }

    function testDeployRevertsWithInsufficientAllowance() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );

        vm.startPrank(user);
        usdt.approve(predicted, 0);
        vm.expectRevert();
        new OurToken{salt: salt}(params, user);
        vm.stopPrank();
    }

    function testDeployRevertsWithInsufficientBalance() public {
        Types.TokenParams memory params = createBaseTokenParams();
        address otherUser = makeAddr("otherUser");
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, otherUser)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            otherUser
        );
        ERC20Mock(TokenConfig.USDT_ADDRESS).mint(otherUser, BASE_FEE - 1);
        vm.startPrank(otherUser);
        usdt.approve(predicted, type(uint256).max);
        vm.expectRevert();
        new OurToken{salt: salt}(params, otherUser);
        vm.stopPrank();
    }

    function testTaxEnabledStoresTaxConfig() public {
        Types.TokenParams memory params = createBaseTokenParams();
        params.taxEnabled = true;
        params.taxRate = 100; // 1%
        params.taxRecipient = feeRecipient;
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predicted, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        vm.stopPrank();
        assert(token.taxEnabled());
        assertEq(token.taxRecipient(), params.taxRecipient);
        assertEq(token.taxRate(), params.taxRate);
    }

    function testTaxEnabledWithZeroRecipientReverts() public {
        Types.TokenParams memory params = createBaseTokenParams();
        params.taxEnabled = true;
        params.taxRate = 100; // 1%
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predicted, type(uint256).max);
        vm.expectRevert(InvalidAddress.selector);
        new OurToken{salt: salt}(params, user);
        vm.stopPrank();
    }

    function testMintRevertsWhenMintingRevoked() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predicted, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        vm.expectRevert(MintingDisabled.selector);
        token.mint(makeAddr("user2"), USDT_MINT);
        vm.stopPrank();
    }

    function testPauseRevertsWhenPausingRevoked() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predicted, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        vm.expectRevert(PausingDisabled.selector);
        token.pause();
        vm.stopPrank();
    }

    function testDeploymentFeeDeductionWorksCorrectly() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predictable = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        uint256 oldBalance = usdt.balanceOf(user);
        vm.startPrank(user);
        usdt.approve(predictable, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        vm.stopPrank();
        uint256 feeAmount = token.calculateFee(
            params.revokeMinting,
            params.revokePausing,
            params.taxEnabled,
            params.metadata.hasCreatorInfo
        );
        assertEq(usdt.balanceOf(user), oldBalance - feeAmount);
    }

    function testPauseAndUnpauseWorkWhenNotRevoked() public {
        Types.TokenParams memory params = createBaseTokenParams();
        params.revokePausing = false;
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predictable = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predictable, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        token.pause();
        token.unpause();
        vm.stopPrank();
    }

    function testMintWorksWhenNotRevoked() public {
        Types.TokenParams memory params = createBaseTokenParams();
        uint8 mintToken = 100;
        params.revokeMinting = false;
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predictable = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predictable, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        token.mint(user, mintToken);
        assertEq(token.balanceOf(user), mintToken + INITIAL_SUPPLY);
        vm.stopPrank();
    }

    function testOwnerIsUser() public {
        Types.TokenParams memory params = createBaseTokenParams();
        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predictable = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );
        vm.startPrank(user);
        usdt.approve(predictable, type(uint256).max);
        OurToken token = new OurToken{salt: salt}(params, user);
        vm.stopPrank();
        assertEq(token.owner(),user);
    }

    function testTransferTaxDeductsCorrectly() public {
        Types.TokenParams memory params = createBaseTokenParams();
        params.revokeMinting = false;
        params.taxEnabled = true;
        params.taxRate = 1000; // 10%
        params.taxRecipient = user; // ← user is the tax recipient (gets the tax)

        address otherUser = makeAddr("otherUser");
        address otherUser2 = makeAddr("otherUser2");

        bytes32 salt = keccak256("salt1");
        bytes memory bytecode = abi.encodePacked(
            type(OurToken).creationCode,
            abi.encode(params, user)
        );
        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(bytecode),
            user
        );

        vm.startPrank(user);
        usdt.approve(predicted, type(uint256).max);
        OurToken ourToken = new OurToken{salt: salt}(params, user);
        // Mint tokens to otherUser so they can transfer
        ourToken.mint(otherUser, 1000);
        vm.stopPrank();

        uint256 userTaxBalanceBefore = ourToken.balanceOf(user);

        // otherUser transfers to otherUser2 — tax goes to user
        vm.prank(otherUser);
        ourToken.transfer(otherUser2, 1000);

        uint256 taxAmount = (1000 * 1000) / 10000; // 10% of 1000 = 100

        assertEq(ourToken.balanceOf(otherUser2), 900); // received after tax
        assertEq(ourToken.balanceOf(user), userTaxBalanceBefore + taxAmount); // user got tax
        assertEq(ourToken.balanceOf(otherUser), 0); // fully transferred
    }
}
