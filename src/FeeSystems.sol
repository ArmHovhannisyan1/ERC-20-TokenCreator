// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeSystems is Ownable {
    uint256 public baseFee;
    uint256 public revokeMintingFee;
    uint256 public revokePausingFee;
    uint256 public taxableFee;
    uint256 public creatorInfoFee;

    event FeesUpdated(
        uint256 baseFee,
        uint256 revokeMintingFee,
        uint256 revokePausingFee,
        uint256 taxableFee,
        uint256 creatorInfoFee
    );

    constructor(
        uint256 _baseFee,
        uint256 _revokeMintingFee,
        uint256 _revokePausingFee,
        uint256 _taxableFee,
        uint256 _creatorInfoFee,
        address owner
    ) Ownable(owner) {
        require(owner != address(0), "Owner cannot be zero address");
        baseFee = _baseFee;
        revokeMintingFee = _revokeMintingFee;
        revokePausingFee = _revokePausingFee;
        taxableFee = _taxableFee;
        creatorInfoFee = _creatorInfoFee;
    }

    function calculateFee(
        bool revokeMinting,
        bool revokePausing,
        bool taxEnabled,
        bool hasCreatorInfo
    ) public view returns (uint256 total) {
        total = baseFee;
        if (revokeMinting) total += revokeMintingFee;
        if (revokePausing) total += revokePausingFee;
        if (taxEnabled) total += taxableFee;
        if(hasCreatorInfo) total += creatorInfoFee;
    }

    function setFees(
        uint256 _baseFee,
        uint256 _revokeMintingFee,
        uint256 _revokePausingFee,
        uint256 _taxableFee,
        uint256 _creatorInfoFee
    ) external onlyOwner {
        require(_baseFee > 0, "Base fee cannot be zero");
        baseFee = _baseFee;
        revokeMintingFee = _revokeMintingFee;
        revokePausingFee = _revokePausingFee;
        taxableFee = _taxableFee;
        creatorInfoFee = _creatorInfoFee;
        emit FeesUpdated(
            _baseFee,
            _revokeMintingFee,
            _revokePausingFee,
            _taxableFee,
            _creatorInfoFee
        );
    }
}
