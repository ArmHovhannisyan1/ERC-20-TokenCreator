// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Types} from "./Types.sol";

error TaxRateExceeded();
error MintingDisabled();
error PausingDisabled();
error InvalidAddress();

contract OurToken is ERC20, Ownable, ERC20Pausable {
    event TaxCollected(address indexed from, address indexed to, uint256 taxAmount);
    event MintingRevoked();
    event PausingRevoked();

    uint8 public tokenDecimals;
    uint256 public taxRate;
    address public taxRecipient;
    bool public revokeMinting;
    bool public revokePausing;
    bool public taxEnabled;

    Types.MetadataParams public metadata;

    constructor(Types.TokenParams memory params)
        ERC20(params.name, params.symbol)
        Ownable(params.owner)
        ERC20Pausable()
    {
        if (params.owner == address(0)) revert InvalidAddress();

        tokenDecimals = params.tokenDecimals;
        revokeMinting = params.revokeMinting;
        revokePausing = params.revokePausing;
        taxEnabled = params.taxEnabled;

        metadata = Types.MetadataParams({
            tokenDescription: params.metadata.tokenDescription,
            tokenWebsite: params.metadata.tokenWebsite,
            socialUrls: params.metadata.socialUrls,
            tags: params.metadata.tags,
            hasCreatorInfo: params.metadata.hasCreatorInfo,
            creatorName: params.metadata.creatorName,
            creatorWebsite: params.metadata.hasCreatorInfo
                ? params.metadata.creatorWebsite
                : "ARMCP.net"
        });

        if (taxEnabled) {
            if (params.taxRate >= 10000 || params.taxRate == 0) {
                revert TaxRateExceeded();
            }
            if (params.taxRecipient == address(0)) revert InvalidAddress();
            taxRate = params.taxRate;
            taxRecipient = params.taxRecipient;
        }

        if (params.initialSupply > 0) {
            _mint(params.owner, params.initialSupply);
        }
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function getMetadata() external view returns (Types.MetadataParams memory) {
        return metadata;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        if (revokeMinting) revert MintingDisabled();
        _mint(to, amount);
    }

    function revokeMintingFunction() public onlyOwner {
        revokeMinting = true;
        emit MintingRevoked();
    }

    function revokePausingFunction() public onlyOwner {
        revokePausing = true;
        if (paused()) {
            _unpause();
        }
        emit PausingRevoked();
    }

    function pause() public onlyOwner {
        if (revokePausing) revert PausingDisabled();
        _pause();
    }

    function unpause() public onlyOwner {
        if (revokePausing) revert PausingDisabled();
        _unpause();
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        if (
            taxEnabled &&
            from != address(0) &&
            to != address(0) &&
            to != taxRecipient &&
            from != taxRecipient
        ) {
            uint256 taxAmount = (value * taxRate) / 10000;
            if (taxAmount > 0) {
                super._update(from, taxRecipient, taxAmount);
                emit TaxCollected(from, taxRecipient, taxAmount);
                value -= taxAmount;
            }
        }

        super._update(from, to, value);
    }
}
