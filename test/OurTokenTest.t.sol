// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.33;

// import {Test} from "forge-std/Test.sol";
// import {OurToken} from "../src/OurToken.sol";
// import {console} from "forge-std/console.sol";
// import {console2} from "forge-std/console2.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC20Mock} from "./mock/ERC20Mock.sol";
// import {Types} from "../src/Types.sol";

// contract TokenFactoryTest is Test {
//     OurToken public ourToken;
//     IERC20 public usdt;
//     // IERC20 public token;
//     address public owner;

//     address public user = makeAddr("user");
//     address public feeRecipient = makeAddr("feeRecipient");

    // uint256 public constant INITIAL_SUPPLY = 100 ether;
    // uint256 public constant USDT_MINT = 2000e6; // 200 USDT with 6 decimals

    // function createBaseTokenParams()
    //     internal
    //     pure
    //     returns (Types.TokenParams memory)
    // {
    //     return
    //         Types.TokenParams({
    //             name: "MyToken",
    //             symbol: "MTK",
    //             initialSupply: INITIAL_SUPPLY,
    //             tokenDecimals: 18,
    //             taxEnabled: false,
    //             taxRate: 0,
    //             taxRecipient: address(0),
    //             revokeMinting: true,
    //             revokePausing: true,
    //             metadata: Types.MetadataParams({
    //                 tokenDescription: "",
    //                 tokenWebsite: "",
    //                 socialUrls: new string[](0),
    //                 tags: new string[](0),
    //                 hasCreatorInfo: false,
    //                 creatorName: "",
    //                 creatorWebsite: ""
    //             })
    //         });
    // }

//     // function setUp() external {
//         usdt = new ERC20Mock();
//         Types.TokenParams memory params = createBaseTokenParams();
//         ERC20Mock(address(usdt)).mint(address(this), USDT_MINT);
//         // vm.prank(user);
//         usdt.approve(address(this), type(uint256).max);
//         ourToken = new OurToken(params, usdt, feeRecipient);
//     }

//     // function testUserCanDeployWithCreate2AndPayFee() public {
//         Types.TokenParams memory params = createBaseTokenParams();
//         bytes32 salt = keccak256("salt1");
//         bytes memory bytecode = abi.encodePacked(
//             // this retrieves the creation bytecode of OurToken,
//             // with constructor and actual runtime code
//             type(OurToken).creationCode,
//             // takes parameteres for contructor(...) and it ABI-encode them so
//             // the deployment process knows how to pass them to the new contract.
//             abi.encode(params, usdt, feeRecipient)
//         );
//         address predicted = vm.computeCreate2Address(salt, keccak256(bytecode));
//         vm.prank(user);
//         usdt.approve(predicted, type(uint256).max);
//         uint256 oldUserBalance = usdt.balanceOf(user);
//         uint256 oldFeeRecipientBalance = usdt.balanceOf(feeRecipient);
//         vm.prank(user);
//         OurToken ourTokenAddress = new OurToken{salt: salt}(
//             params,
//             usdt,
//             feeRecipient
//         );
//         uint256 feeAmount = ourTokenAddress.calculateFee(
//             true,
//             true,
//             false,
//             false
//         );
//         assert(address(ourTokenAddress) == predicted);
//         assertEq(oldUserBalance - feeAmount, usdt.balanceOf(user));
//         assertEq(
//             oldFeeRecipientBalance + feeAmount,
//             usdt.balanceOf(feeRecipient)
//         );
//         assertEq(INITIAL_SUPPLY, params.initialSupply);
//     }

//     //     function testCreateToken() public {
//     //         Types.TokenParams memory tokenParams = createBaseTokenParams();
//     //         string[] memory socialUrlsUpdate = new string[](1);
//     //         socialUrlsUpdate[0] = "https://twitter.com/mytoken";
//     //         tokenParams.metadata.socialUrls = socialUrlsUpdate;
//     //         vm.prank(user);
//     //         address tokenAddress = tokenFactory.createToken(tokenParams);

//     //         assert(tokenAddress != address(0));
//     //     }

//     //     function testInitialSupplyMintedToUser() public {
//     //         Types.TokenParams memory tokenParams = createBaseTokenParams();
//     //         string[] memory socialUrlsUpdate = new string[](1);
//     //         socialUrlsUpdate[0] = "https://twitter.com/mytoken";
//     //         tokenParams.metadata.socialUrls = socialUrlsUpdate;
//     //         vm.prank(user);
//     //         address tokenAddress = tokenFactory.createToken(tokenParams);
//     //         OurToken token = OurToken(tokenAddress);
//     //         assertEq(token.balanceOf(user), INITIAL_SUPPLY);
//     //     }

//     //     function testTokenCreationWithDifferentSybols() public {
//     //         Types.TokenParams memory tokenParams1 = createBaseTokenParams();
//     //         string[] memory socialUrlsUpdate1 = new string[](1);
//     //         socialUrlsUpdate1[0] = "https://twitter.com/mytoken";
//     //         tokenParams1.metadata.socialUrls = socialUrlsUpdate1;
//     //         vm.prank(user);
//     //         address tokenAddress1 = tokenFactory.createToken(tokenParams1);
//     //         Types.TokenParams memory tokenParams2 = createBaseTokenParams();
//     //         tokenParams2.symbol = "MTK2";
//     //         string[] memory socialUrlsUpdate2 = new string[](1);
//     //         socialUrlsUpdate2[0] = "https://twitter.com/mytoken";
//     //         tokenParams2.metadata.socialUrls = socialUrlsUpdate2;
//     //         vm.prank(user);
//     //         address tokenAddress2 = tokenFactory.createToken(tokenParams2);

//     //         assert(tokenAddress1 != tokenAddress2);
//     //     }

//     //     function testDuplicateTokenCreationReverts() public {
//     //         Types.TokenParams memory tokenParams1 = createBaseTokenParams();
//     //         string[] memory socialUrlsUpdate1 = new string[](1);
//     //         socialUrlsUpdate1[0] = "https://twitter.com/mytoken";
//     //         tokenParams1.metadata.socialUrls = socialUrlsUpdate1;
//     //         vm.prank(user);
//     //         tokenFactory.createToken(tokenParams1);
//     //         Types.TokenParams memory tokenParams2 = createBaseTokenParams();
//     //         string[] memory socialUrlsUpdate2 = new string[](1);
//     //         socialUrlsUpdate2[0] = "https://twitter.com/mytoken";
//     //         tokenParams2.metadata.socialUrls = socialUrlsUpdate2;
//     //         vm.prank(user);
//     //         vm.expectRevert();
//     //         tokenFactory.createToken(tokenParams2);
//     //     }

//     //     function testOnlyOwnerCanChangeFee() public {
//     //         vm.prank(user); // user is not owner
//     //         vm.expectRevert();
//     //         feeSystems.setFees(10e6, 5e6, 3e6, 7e6, 2e6);
//     //     }

//     //     function testOwnerCanChangeFee() public {
//     //         vm.prank(owner); // actual owner
//     //         feeSystems.setFees(10e6, 5e6, 3e6, 7e6, 2e6);
//     //         uint256 fee = feeSystems.calculateFee(true, true, false, false);
//     //         assertEq(fee, 18e6);
//     //     }

//     //     function testGasDeploymentWITHOUTMetadata() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         // Clear everything to see the 'base' cost
//     //         params.metadata.tokenWebsite = "";
//     //         params.metadata.creatorName = "";
//     //         params.metadata.hasCreatorInfo = false;

//     //         uint256 gasStart = gasleft();
//     //         vm.prank(user);
//     //         tokenFactory.createToken(params);
//     //         uint256 gasUsed = gasStart - gasleft();

//     //         console2.log("BASE GAS (No Metadata):", gasUsed);
//     //     }

//     //     function testGasDeploymentWITHIPFS() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         // Simulate a full IPFS CID and creator info
//     //         params
//     //             .metadata
//     //             .tokenWebsite = "https://ipfs.io/ipfs/QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco";
//     //         params.metadata.creatorName = "Arman";
//     //         params.metadata.creatorWebsite = "https://arman.dev";
//     //         params.metadata.hasCreatorInfo = true;

//     //         uint256 gasStart = gasleft();
//     //         vm.prank(user);
//     //         tokenFactory.createToken(params);
//     //         uint256 gasUsed = gasStart - gasleft();

//     //         console2.log("IPFS GAS (Full Metadata):", gasUsed);
//     //     }

//     //     ////// METADATA TESTS

//     //     function testMetadataStoredCorrectly() public {
//     //         string[] memory socialUrls = new string[](2);
//     //         socialUrls[0] = "https://twitter.com/mytoken";
//     //         socialUrls[1] = "https://t.me/mytoken";

//     //         string[] memory tags = new string[](2);
//     //         tags[0] = "MEME";
//     //         tags[1] = "UTILITY";

//     //         Types.TokenParams memory tokenParams = createBaseTokenParams();
//     //         tokenParams.metadata = Types.MetadataParams({
//     //             tokenDescription: "Test description",
//     //             tokenWebsite: "https://mytoken.com",
//     //             socialUrls: socialUrls,
//     //             tags: tags,
//     //             hasCreatorInfo: true,
//     //             creatorName: "Test Creator",
//     //             creatorWebsite: "https://creator.com"
//     //         });

//     //         vm.prank(user);
//     //         address tokenAddress = tokenFactory.createToken(tokenParams);

//     //         // Calling token.metadata() Returns 5 Or More Separate Values, But Your
//     //         // Code Is Trying To Force All Of Them Into A Single Variable Called storedMetadata
//     //         // Types.MetadataParams memory storedMetadata = OurToken(tokenAddress)
//     //         //     .metadata();
//     //         // Add A Manual Function To Your OurToken Contract That Returns The Entire Struct.
//     //         Types.MetadataParams memory storedMetadata = OurToken(tokenAddress)
//     //             .getMetadata();

//     //         assertEq(storedMetadata.tokenDescription, "Test description");
//     //         assertEq(storedMetadata.tokenWebsite, "https://mytoken.com");
//     //         assertEq(storedMetadata.socialUrls.length, 2);
//     //         assertEq(storedMetadata.socialUrls[0], "https://twitter.com/mytoken");
//     //         assertEq(storedMetadata.socialUrls[1], "https://t.me/mytoken");
//     //         assertEq(storedMetadata.tags.length, 2);
//     //         assertEq(storedMetadata.tags[0], "MEME");
//     //         assertEq(storedMetadata.tags[1], "UTILITY");
//     //         assertTrue(storedMetadata.hasCreatorInfo);
//     //         assertEq(storedMetadata.creatorName, "Test Creator");
//     //         assertEq(storedMetadata.creatorWebsite, "https://creator.com");
//     //     }

//     //     function testDefaultCreatorWebsiteWhenNotPaid() public {
//     //         vm.prank(user);
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.metadata.hasCreatorInfo = false;
//     //         params.metadata.creatorName = "Test Creator";
//     //         params.metadata.creatorWebsite = "https://should-not-be-used.com";
//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         Types.MetadataParams memory storedCorrectly = OurToken(tokenAddress)
//     //             .getMetadata();
//     //         assertFalse(storedCorrectly.hasCreatorInfo);
//     //         assertEq(storedCorrectly.creatorName, "Test Creator");
//     //         assertEq(storedCorrectly.creatorWebsite, "ARMCP.net");
//     //     }

//     //     function testCreatorInfoFeeAdded() public view {
//     //         uint256 baseFee = feeSystems.baseFee();
//     //         uint256 creatorInfoFee = feeSystems.creatorInfoFee();

//     //         Types.TokenParams memory params1 = createBaseTokenParams();
//     //         params1.metadata.hasCreatorInfo = false;

//     //         uint256 fee1 = feeSystems.calculateFee(
//     //             params1.revokeMinting,
//     //             params1.revokePausing,
//     //             params1.taxEnabled,
//     //             params1.metadata.hasCreatorInfo
//     //         );
//     //         assertEq(fee1, baseFee + 19e6 + 19e6);

//     //         Types.TokenParams memory params2 = createBaseTokenParams();
//     //         params2.metadata.hasCreatorInfo = true;
//     //         uint256 fee2 = feeSystems.calculateFee(
//     //             params2.revokeMinting,
//     //             params2.revokePausing,
//     //             params2.taxEnabled,
//     //             params2.metadata.hasCreatorInfo
//     //         );
//     //         assertEq(fee2, baseFee + 19e6 + 19e6 + creatorInfoFee);
//     //     }

//     //     function testEmptyArraysWork() public {
//     //         vm.prank(user);

//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.metadata.socialUrls = new string[](0);
//     //         params.metadata.tags = new string[](0);

//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         Types.MetadataParams memory storedMetadata = OurToken(tokenAddress)
//     //             .getMetadata();
//     //         assertEq(storedMetadata.socialUrls.length, 0);
//     //         assertEq(storedMetadata.tags.length, 0);
//     //     }

//     //     /////// TAX SYSTEM TESTS

//     //     function testTaxIsDeductedOnTransfer() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.taxEnabled = true;
//     //         params.taxRate = 500;
//     //         address taxCollector = makeAddr("taxCollector");
//     //         address normalReceiver = makeAddr("normalReceiver");
//     //         params.taxRecipient = taxCollector;
//     //         params.revokeMinting = false;
//     //         vm.startPrank(user);
//     //         address token = tokenFactory.createToken(params);

//     //         uint256 amount = 20e18;
//     //         OurToken(token).mint(user, 92e18);
//     //         /* In Solidity, approve is only required when a third party (a contract
//     //            or another person) wants to spend tokens on your behalf. Since you are the one
//     //            driving your own car, you don't need to sign a permission slip for yourself.
//     //            I.e. user mints to user.
//     //         */
//     //         // IERC20(token).approve(address(tokenFactory), type(uint256).max);
//     //         OurToken(token).transfer(normalReceiver, amount);
//     //         vm.stopPrank();

//     //         uint256 expectedTax = (amount * 500) / 10000; // 1e18
//     //         uint256 expectedToReceiver = amount - expectedTax; // 19e18

//     //         assert(OurToken(token).balanceOf(taxCollector) < amount);
//     //         // Correct amount goes to taxRecipient
//     //         assertEq(OurToken(token).balanceOf(taxCollector), expectedTax);
//     //         // Correct amount goes to actual receiver
//     //         assertEq(OurToken(token).balanceOf(normalReceiver), expectedToReceiver);
//     //     }

//     //     function testTaxRateReverts() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.taxEnabled = true;
//     //         params.taxRate = 0;
//     //         vm.expectRevert();
//     //         new OurToken(params);
//     //     }

//     //     function testTaxRateReverts2() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.taxEnabled = true;
//     //         params.taxRate = 10000;
//     //         vm.expectRevert();
//     //         new OurToken(params);
//     //     }

//     //     /////// REVOKE LOGIC TESTS

//     //     function testRevokeMintingFunctionReverts() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokeMinting = false;
//     //         vm.prank(user);
//     //         address token = tokenFactory.createToken(params);
//     //         vm.prank(user);
//     //         OurToken(token).revokeMintingFunction();
//     //         vm.expectRevert();
//     //         OurToken(token).mint(user, USDT_MINT);
//     //     }

//     //     function testOnlyOwnerCanRevokeMinting() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         vm.prank(user);
//     //         address token = tokenFactory.createToken(params);
//     //         vm.expectRevert();
//     //         OurToken(token).revokeMintingFunction();
//     //     }

//     //     function testRevokePausingFunctionReverts() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokePausing = false;
//     //         vm.prank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         OurToken token = OurToken(tokenAddress);

//     //         vm.prank(user);
//     //         token.revokePausingFunction();
//     //         vm.expectRevert();
//     //         token.pause();
//     //     }

//     //     function testVeifyTokenIsUnpausedAfterRevokePause() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokePausing = false;
//     //         vm.startPrank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         OurToken token = OurToken(tokenAddress);
//     //         token.pause();
//     //         token.revokePausingFunction();
//     //         vm.stopPrank();
//     //         assert(!(token.paused()));
//     //     }

//     //     /////// TOKEN FACTORY TESTS

//     //     function testSetTreasuryUpdatesCorrectly() public {
//     //         address factoryOwner = tokenFactory.owner();

//     //         // 2. Prepare the new address
//     //         address newTreasury = makeAddr("newTreasury");

//     //         // 3. Act as the owner
//     //         vm.prank(factoryOwner);
//     //         tokenFactory.setTreasury(newTreasury);
//     //         assertEq(newTreasury, tokenFactory.treasury());

//     //         vm.expectRevert();
//     //         tokenFactory.setTreasury(address(0));
//     //     }

//     //     function testSetFeeSystemAddressZero() public {
//     //         vm.expectRevert();
//     //         tokenFactory.setFeeSystems(FeeSystems(address(0)));
//     //     }

//     //     function testGetTokenByCreatorsIsCorrect() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         vm.prank(user);
//     //         address token = tokenFactory.createToken(params);
//     //         address[] memory tokenCreated = tokenFactory.getTokensByCreator(user);
//     //         assertEq(tokenCreated[0], token);
//     //     }

//     //     function testFactoryIsDeployed() public view {
//     //         assert(address(tokenFactory) != address(0));
//     //     }

//     //     /////// PAUSE BEHAVIOUR TESTS

//     //     function testTransferWorksAfterUnpause() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokePausing = false;
//     //         address x = makeAddr("x");
//     //         uint256 amount = 1e6;

//     //         vm.startPrank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         OurToken token = OurToken(tokenAddress);

//     //         token.pause();
//     //         // token.approve(user, amount); // use approve() when using tranferFrom(), transfer() skips approve() fn

//     //         vm.expectRevert();
//     //         token.transfer(x, amount);
//     //         token.unpause();
//     //         token.transfer(x, amount);
//     //         vm.stopPrank();

//     //         assertEq(amount, token.balanceOf(x));
//     //     }

//     //     function testNonOwnerCantPause() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokePausing = false;
//     //         vm.prank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);
//     //         OurToken token = OurToken(tokenAddress);
//     //         vm.expectRevert();
//     //         token.pause();
//     //     }

//     //     /////// TREASURY TESTS

//     //     function testCorrectWithdrawedToTheOwner() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokeMinting = false;

//     //         vm.startPrank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);

//     //         OurToken token = OurToken(tokenAddress);
//     //         Treasury treasury = new Treasury(user);
//     //         uint256 amount = 10e6;

//     //         token.mint(address(treasury), amount);
//     //         uint256 oldBalance = OurToken(token).balanceOf(user);
//     //         treasury.withdrawERC20(tokenAddress, amount);
//     //         vm.stopPrank();
//     //         uint256 newBalance = OurToken(token).balanceOf(user);
//     //         assertEq(oldBalance + amount, newBalance);
//     //     }

//     //     function testWithdrawAllBalance() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokeMinting = false;

//     //         vm.startPrank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);

//     //         OurToken token = OurToken(tokenAddress);
//     //         Treasury treasury = new Treasury(user);
//     //         uint256 amount = 10e6;

//     //         token.mint(address(treasury), amount);
//     //         treasury.withdrawAllERC20(tokenAddress);
//     //         uint256 balance = OurToken(token).balanceOf(address(treasury));
//     //         vm.stopPrank();
//     //         assertEq(balance, 0);
//     //     }

//     //     function testOnlyOwnerCanWithdraw() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokeMinting = false;

//     //         vm.startPrank(user);
//     //         address tokenAddress = tokenFactory.createToken(params);

//     //         OurToken token = OurToken(tokenAddress);
//     //         Treasury treasury = new Treasury(user);
//     //         uint256 amount = 10e6;

//     //         token.mint(address(treasury), amount);
//     //         vm.stopPrank();
//     //         vm.expectRevert();
//     //         treasury.withdrawAllERC20(tokenAddress);
//     //     }

//     //     function testWithdrawETH() public {
//     //         Types.TokenParams memory params = createBaseTokenParams();
//     //         params.revokeMinting = false;
//     //         vm.deal(user, 20 ether);
//     //         vm.startPrank(user);
//     //         Treasury treasury = new Treasury(user);

//     //         // token.mint(address(treasury), INITIAL_SUPPLY);
//     //         (bool sent, ) = address(treasury).call{value: 10 ether}("");
//     //         require(sent, "Failed to send Ether");
//     //         treasury.withdrawEth();
//     //         vm.expectRevert();
//     //         treasury.withdrawEth();
//     //         vm.stopPrank();
//     //     }

//     //     function testTreasuryReceivesFees() public {
//     //         uint256 initialTreasuryBalance = usdt.balanceOf(
//     //             tokenFactory.treasury()
//     //         );
//     //         uint256 fee = tokenFactory.feeSystems().calculateFee(
//     //             true,
//     //             true,
//     //             false,
//     //             false
//     //         );

//     //         Types.TokenParams memory tokenParams = Types.TokenParams({
//     //             name: "MyToken",
//     //             symbol: "MTK",
//     //             initialSupply: INITIAL_SUPPLY,
//     //             tokenDecimals: 18,
//     //             owner: user,
//     //             taxEnabled: false,
//     //             taxRate: 0,
//     //             taxRecipient: address(0),
//     //             revokeMinting: true,
//     //             revokePausing: true,
//     //             metadata: Types.MetadataParams({
//     //                 tokenDescription: "A test token",
//     //                 tokenWebsite: "https://mytoken.com",
//     //                 socialUrls: new string[](1),
//     //                 tags: new string[](0),
//     //                 hasCreatorInfo: false,
//     //                 creatorName: "Arman",
//     //                 creatorWebsite: ""
//     //             })
//     //         });
//     //         tokenParams.metadata.socialUrls[0] = "https://twitter.com/mytoken";
//     //         vm.prank(user);
//     //         tokenFactory.createToken(tokenParams);

//     //         uint256 finalTreasuryBalance = usdt.balanceOf(tokenFactory.treasury());
//     //         assertEq(finalTreasuryBalance, initialTreasuryBalance + fee);
//     //     }
// }
