// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {FeeSystems} from "../src/FeeSystems.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "./mock/ERC20Mock.sol";

contract TokenFactoryTest is Test {
    DeployProtocol public deployer;
    TokenFactory public tokenFactory;
    FeeSystems public feeSystems;
    IERC20 public usdt;
    address public owner;

    address public user = makeAddr("user");

    uint256 public constant INITIAL_SUPPLY = 100 ether;

    function setUp() external {
        deployer = new DeployProtocol();
        tokenFactory = deployer.run();
        feeSystems = tokenFactory.feeSystems();

        owner = feeSystems.owner();
        usdt = tokenFactory.USDT();
        ERC20Mock(address(usdt)).mint(user, 100e6);
    }

    function testFactoryIsDeployed() public view {
        assert(address(tokenFactory) != address(0));
    }

    function testCreateToken() public {
        vm.startPrank(user);

        // console.log("Factory Address:", address(tokenFactory));
        // console.log("USDT Address in Factory:", address(tokenFactory.usdt()));

        address feeSysAddr = address(tokenFactory.feeSystems());
        // console.log("FeeSystems Address:", feeSysAddr);

        uint256 fee = FeeSystems(feeSysAddr).calculateFee(
            true,
            true,
            false,
            false
        );
        console.log("Fee calculated:", fee);

        usdt.approve(address(tokenFactory), fee);
        console.log("Approval successful");

        address tokenAddress = tokenFactory.createToken(
            "MyToken",
            "MTK",
            INITIAL_SUPPLY,
            18,
            false,
            0,
            address(0),
            true,
            true,
            false,
            "A test token",
            "https://mytoken.com",
            "https://twitter.com/mytoken",
            "https://instagam.com/mytoken",
            "https://facebook.com/mytoken",
            new string[](0),
            "MyToken Creator",
            "https://mytoken-creator.com",
            "https://mytoken.com/banner.png"
        );

        vm.stopPrank();
        assert(tokenAddress != address(0));
    }

    function testInitialSupplyMintedToUser() public {
        uint256 fee = tokenFactory.feeSystems().calculateFee(
            true,
            true,
            false,
            false
        );

        vm.startPrank(user);
        console.log("Code size of Factory:", address(tokenFactory).code.length); // 3. Now the call will succeed
        usdt.approve(address(tokenFactory), fee);
        address tokenAddress = tokenFactory.createToken(
            "MyToken",
            "MTK",
            INITIAL_SUPPLY,
            18,
            false,
            0,
            user,
            true,
            true,
            false,
            "A test token",
            "https://mytoken.com",
            "https://twitter.com/mytoken",
            "https://instagam.com/mytoken",
            "https://facebook.com/mytoken",
            new string[](0),
            "MyToken Creator",
            "https://mytoken-creator.com",
            "https://mytoken.com/banner.png"
        );

        vm.stopPrank();

        OurToken token = OurToken(tokenAddress);
        assertEq(token.balanceOf(user), INITIAL_SUPPLY);
    }

    function testMultipleTokenCreation() public {
        uint256 fee = tokenFactory.feeSystems().calculateFee(
            true,
            true,
            false,
            false
        );
        vm.startPrank(user);
        usdt.approve(address(tokenFactory), fee * 2);

        address token1 = tokenFactory.createToken(
            "Token1",
            "TK1",
            INITIAL_SUPPLY,
            18,
            false,
            0,
            address(0),
            true,
            true,
            false,
            "A test token",
            "https://mytoken.com",
            "https://twitter.com/mytoken",
            "https://instagam.com/mytoken",
            "https://facebook.com/mytoken",
            new string[](0),
            "MyToken Creator",
            "https://mytoken-creator.com",
            "https://mytoken.com/banner.png"
        );

        address token2 = tokenFactory.createToken(
            "MyToken",
            "MTK",
            INITIAL_SUPPLY,
            18,
            false,
            0,
            address(0),
            true,
            true,
            false,
            "A test token",
            "https://mytoken.com",
            "https://twitter.com/mytoken",
            "https://instagam.com/mytoken",
            "https://facebook.com/mytoken",
            new string[](0),
            "MyToken Creator",
            "https://mytoken-creator.com",
            "https://mytoken.com/banner.png"
        );

        vm.stopPrank();

        assert(token1 != token2);
    }

    function testOnlyOwnerCanChangeFee() public {
        vm.prank(user); // user is not owner
        vm.expectRevert();
        feeSystems.setFees(10e6, 5e6, 3e6, 7e6, 2e6);
    }

    function testOwnerCanChangeFee() public {
        vm.prank(owner); // actual owner
        feeSystems.setFees(10e6, 5e6, 3e6, 7e6, 2e6);
        uint256 fee = feeSystems.calculateFee(true, true, false, false);
        assertEq(fee, 18e6);
    }

    function testTreasuryReceivesFees() public {
        uint256 fee = tokenFactory.feeSystems().calculateFee(
            true,
            true,
            false,
            false
        );
        uint256 initialTreasuryBalance = usdt.balanceOf(
            tokenFactory.treasury()
        );

        vm.startPrank(user);
        usdt.approve(address(tokenFactory), fee);
        tokenFactory.createToken(
            "Test",
            "TST",
            100,
            18,
            false,
            0,
            user,
            true,
            true,
            false,
            "A test token",
            "https://mytoken.com",
            "https://twitter.com/mytoken",
            "https://instagam.com/mytoken",
            "https://facebook.com/mytoken",
            new string[](0),
            "MyToken Creator",
            "https://mytoken-creator.com",
            "https://mytoken.com/banner.png"
        );
        vm.stopPrank();

        uint256 finalTreasuryBalance = usdt.balanceOf(tokenFactory.treasury());
        assertEq(finalTreasuryBalance, initialTreasuryBalance + fee);
    }
}
