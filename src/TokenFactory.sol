// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FeeSystems} from "./FeeSystems.sol";
import {OurToken} from "./OurToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Types} from "./Types.sol";

error InvalidAddress();

contract TokenFactory is Ownable {
    IERC20 public immutable USDT;
    using SafeERC20 for IERC20;
    FeeSystems public feeSystems;
    address[] public allTokens;
    mapping(address => address[]) public tokenByCreator;
    mapping(bytes32 => bool) public symbolExists; // ensure tokens won't be duplicated

    address public treasury;

    event TokenCreated(address indexed token, address indexed sender);

    constructor(
        IERC20 _usdt,
        FeeSystems _feeSystems,
        address _treasury,
        address owner
    ) Ownable(owner) {
        if (
            address(_usdt) == address(0) ||
            address(_treasury) == address(0) ||
            address(_feeSystems) == address(0)
        ) {
            revert InvalidAddress();
        }
        treasury = _treasury;
        USDT = _usdt;
        feeSystems = _feeSystems;
    }

    function createToken(
        Types.TokenParams memory _params
    ) external returns (address) {
        // Token duplication check
        bytes32 key = keccak256(abi.encodePacked(_params.symbol));
        require(!symbolExists[key], "Symbol taken");
        symbolExists[key] = true;

        _params.owner = msg.sender;
        uint256 fee = feeSystems.calculateFee(
            _params.revokeMinting,
            _params.revokePausing,
            _params.taxEnabled,
            _params.metadata.hasCreatorInfo
            // _params.revokeAllAuthorities
        );
        USDT.safeTransferFrom(msg.sender, treasury, fee);

        OurToken newToken = new OurToken(_params);

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
        if (_treasury == address(0)) revert InvalidAddress();
        treasury = _treasury;
    }

    function setFeeSystems(FeeSystems _feeSystems) external onlyOwner {
        if (address(_feeSystems) == address(0)) revert InvalidAddress();
        feeSystems = _feeSystems;
    }
}
