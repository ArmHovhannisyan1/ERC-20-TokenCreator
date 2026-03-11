// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Types} from "./Types.sol";
import {TokenConfig} from "./TokenConfig.sol";

error TaxRateExceeded();
error MintingDisabled();
error PausingDisabled();
error InvalidAddress();

contract OurToken is ERC20, Ownable, ERC20Pausable {
    using SafeERC20 for IERC20;
    // Metadata
    event TaxCollected(
        address indexed from,
        address indexed to,
        uint256 taxAmount
    );
    event MintingRevoked();
    event PausingRevoked();
    event TokenCreated(
        address indexed owner,
        address token,
        string name,
        string symbol
    );

    // Fees
    uint256 constant BASE_FEE = 39e6; // 39 USDT
    uint256 constant REVOKE_MINTING_FEE = 19e6;
    uint256 constant REVOKE_PAUSING_FEE = 19e6;
    uint256 constant TAXABLE_FEE = 15e6;
    uint256 constant CREATOR_INFO_FEE = 19e6;

    uint8 public tokenDecimals;
    uint256 public taxRate;
    address public taxRecipient;
    bool public revokeMinting;
    bool public revokePausing;
    bool public taxEnabled;

    Types.MetadataParams public metadata;
    bool public hasCreatorInfo;

    address public constant FEE_RECIPIENT = TokenConfig.FEE_RECIPIENT;
    IERC20 public constant USDT = IERC20(TokenConfig.USDT_ADDRESS);

    constructor(
        Types.TokenParams memory _params,
        address deployer
    ) ERC20(_params.name, _params.symbol) Ownable(deployer) ERC20Pausable() {
        if (FEE_RECIPIENT == address(0) || address(USDT).code.length == 0) {
            revert InvalidAddress();
        }
        if (deployer == address(0)) revert InvalidAddress();
        uint256 fee = calculateFee(
            _params.revokeMinting,
            _params.revokePausing,
            _params.taxEnabled,
            _params.metadata.hasCreatorInfo
        );
        USDT.safeTransferFrom(deployer, FEE_RECIPIENT, fee);
        if (_params.initialSupply > 0) {
            _mint(deployer, _params.initialSupply);
        }

        tokenDecimals = _params.tokenDecimals;
        revokeMinting = _params.revokeMinting;
        revokePausing = _params.revokePausing;
        taxEnabled = _params.taxEnabled;
        metadata = Types.MetadataParams({
            tokenDescription: _params.metadata.tokenDescription,
            tokenWebsite: _params.metadata.tokenWebsite,
            socialUrls: _params.metadata.socialUrls,
            tags: _params.metadata.tags,
            hasCreatorInfo: _params.metadata.hasCreatorInfo,
            creatorName: _params.metadata.creatorName,
            creatorWebsite: _params.metadata.hasCreatorInfo
                ? _params.metadata.creatorWebsite
                : "ARMCP.net"
        });

        if (_params.taxEnabled) {
            if (_params.taxRate >= 10000 || _params.taxRate <= 0)
                revert TaxRateExceeded();
            if (_params.taxRecipient == address(0)) revert InvalidAddress();

            taxRate = _params.taxRate;
            taxRecipient = _params.taxRecipient;
        }
        emit TokenCreated(
            deployer,
            address(this),
            _params.name,
            _params.symbol
        );
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
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

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
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
                value -= taxAmount;
            }
        }
        super._update(from, to, value);
    }

    function calculateFee(
        bool _revokeMinting,
        bool _revokePausing,
        bool _taxEnabled,
        bool _hasCreatorInfo
    ) public pure returns (uint256 total) {
        total = BASE_FEE;
        if (_revokeMinting) total += REVOKE_MINTING_FEE;
        if (_revokePausing) total += REVOKE_PAUSING_FEE;
        if (_taxEnabled) total += TAXABLE_FEE;
        if (_hasCreatorInfo) total += CREATOR_INFO_FEE;
    }

    function getMetadata() external view returns (Types.MetadataParams memory) {
        return metadata;
    }
}
