// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract OurToken is ERC20, Ownable, ERC20Pausable {
    bool public mintable;
    bool public pausable;
    bool public taxEnabled;

    // Metadata
    string public description;
    string public website;
    string public social1;
    string public social2;
    string public social3;
    string public creatorName;
    string public creatorWebsite;
    string public bannerUrl; // IPFS/URL to banner image
    string[] public tags;

    uint8 private tokenDecimals;
    uint256 public taxRate;
    address public taxRecipient;

    event TaxCollected(
        address indexed from,
        address indexed to,
        uint256 taxAmount
    );
    event MintingRevoked();
    event PausingRevoked();

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 _tokenDecimals,
        address owner,
        bool _taxEnabled,
        uint256 _taxRate,
        address _taxRecipientAddress,
        bool _mintable,
        bool _pausable,
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
    ) ERC20(name, symbol) Ownable(owner) ERC20Pausable() {
        if (initialSupply > 0) {
            _mint(owner, initialSupply);
        }

        mintable = _mintable;
        pausable = _pausable;
        taxEnabled = _taxEnabled;

        if (taxEnabled) {
            require(_taxRate <= 10000, "Tax rate cannot exceed 100%");
            require(
                _taxRecipientAddress != address(0),
                "Tax recipient cannot be zero address"
            );
            taxRate = _taxRate;
            taxRecipient = _taxRecipientAddress;
        }
        if (revokeAllAuthorities) {
            renounceOwnership();
            /* owner = address(0); 
            this means that the contract will have no owner, 
            and therefore no one will be able to call functions that are restricted to
            the owner, such as minting new tokens or pausing the contract.
            And the onlyOwner modifier will always fail, because it checks if the caller is the owner,
            */
        }
        tokenDecimals = _tokenDecimals;
        description = _description;
        website = _website;
        social1 = _social1;
        social2 = _social2;
        social3 = _social3;
        tags = _tags;
        creatorName = _creatorName;
        creatorWebsite = _creatorWebsite;
        bannerUrl = _bannerUrl;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(mintable, "Minting is disabled");
        _mint(to, amount);
    }

    function revokeMinting() public onlyOwner {
        mintable = false;
        emit MintingRevoked();
    }

    function revokePausing() public onlyOwner {
        pausable = false;
        if (paused()) {
            _unpause();
        }
        emit PausingRevoked();
    }

    function pause() public onlyOwner {
        require(pausable, "Pausing is disabled");
        _pause();
    }

    function unpause() public onlyOwner {
        require(pausable, "Pausing is disabled");
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
                emit TaxCollected(from, taxRecipient, taxAmount);
                value -= taxAmount;
            }
        }
        super._update(from, to, value);
    }

    function getTags() external view returns (string[] memory) {
        return tags;
    }
}
