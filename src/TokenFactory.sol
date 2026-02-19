// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FeeSystems} from "./FeeSystems.sol";
import {OurToken} from "./OurToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFactory is Ownable {
    IERC20 public immutable USDT;
    using SafeERC20 for IERC20;
    FeeSystems public feeSystems;
    address public treasury;

    address[] public allTokens;
    mapping(address => address[]) public tokenByCreator;

    event TokenCreated(address indexed token, address indexed sender);

    constructor(
        IERC20 _usdt,
        FeeSystems _feeSystems,
        address _treasury,
        address owner
    ) Ownable(owner) {
        require(address(_usdt) != address(0), "Invalid USDT address");
        require(address(_feeSystems) != address(0));
        require(_treasury != address(0));
        treasury = _treasury;
        USDT = _usdt;
        feeSystems = _feeSystems;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals,
        bool taxEnabled,
        uint256 taxRate,
        address taxRecipient,
        bool mintable,
        bool pausable,
        bool revokeAllAuthorities,
        string memory _description,
        string memory _website,
        string memory _social1,
        string memory _social2,
        string memory _social3,
        string[] memory _tags,
        string memory _creatorName,
        string memory _creatorWebsite,
        string memory _bannerUrl
    ) external returns (address) {
        uint256 fee = feeSystems.calculateFee(
            mintable,
            pausable,
            taxEnabled,
            revokeAllAuthorities
        );
        USDT.safeTransferFrom(msg.sender, treasury, fee);

        OurToken newToken = new OurToken(
            name,
            symbol,
            initialSupply,
            decimals,
            msg.sender,
            taxEnabled,
            taxRate,
            taxRecipient,
            mintable,
            pausable,
            revokeAllAuthorities,
            _description,
            _website,
            _social1,
            _social2,
            _social3,
            _tags,
            _creatorName,
            _creatorWebsite,
            _bannerUrl
        );

        emit TokenCreated(address(newToken), msg.sender);
        allTokens.push(address(newToken));
        tokenByCreator[msg.sender].push(address(newToken));
        return address(newToken);
    }

    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function getTokensByCreator(
        address creator
    ) external view returns (address[] memory) {
        return tokenByCreator[creator];
    }

    function getTotalTokensCreated() external view returns (uint256) {
        return allTokens.length;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;
    }

    function setFeeSystems(FeeSystems _feeSystems) external onlyOwner {
        feeSystems = _feeSystems;
    }
}
