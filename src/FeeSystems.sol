// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeSystems is Ownable {
    uint256 public baseFee;
    uint256 public mintableFee;
    uint256 public pausableFee;
    uint256 public taxFee;
    uint256 public revokeAuthorityFee;

    event FeesUpdated(
        uint256 baseFee,
        uint256 mintableFee,
        uint256 pausableFee,
        uint256 taxFee,
        uint256 revokeAuthorityFee
    );

    constructor(
        uint256 _baseFee,
        uint256 _mintableFee,
        uint256 _pausableFee,
        uint256 _taxFee,
        uint256 _revokeAuthorityFee,
        address owner
    ) Ownable(owner) {
        require(owner != address(0), "Owner cannot be zero address");
        baseFee = _baseFee;
        mintableFee = _mintableFee;
        pausableFee = _pausableFee;
        taxFee = _taxFee;
        revokeAuthorityFee = _revokeAuthorityFee;
    }

    function calculateFee(
        bool mintable,
        bool pausable,
        bool taxEnabled,
        bool revokeAuthority
    ) public view returns (uint256 total) {
        total = baseFee;

        if (mintable) total += mintableFee;
        if (pausable) total += pausableFee;
        if (taxEnabled) total += taxFee;
        if (revokeAuthority) total += revokeAuthorityFee;
    }

    function setFees(
        uint256 _baseFee,
        uint256 _mintableFee,
        uint256 _pausableFee,
        uint256 _taxFee,
        uint256 _revokeAuthorityFee
    ) external onlyOwner {
        baseFee = _baseFee;
        mintableFee = _mintableFee;
        pausableFee = _pausableFee;
        taxFee = _taxFee;
        revokeAuthorityFee = _revokeAuthorityFee;
        emit FeesUpdated(
            _baseFee,
            _mintableFee,
            _pausableFee,
            _taxFee,
            _revokeAuthorityFee
        );
    }
}
