// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

library Types {
    struct MetadataParams {
        string tokenDescription;
        string tokenWebsite;
        string[] socialUrls;
        string[] tags;
        bool hasCreatorInfo;
        string creatorName;
        string creatorWebsite;
    }

    struct TokenParams {
        string name;
        string symbol;
        uint256 initialSupply;
        uint8 tokenDecimals;
        bool taxEnabled;
        uint256 taxRate;
        address taxRecipient;
        bool revokeMinting;
        bool revokePausing;
        MetadataParams metadata;
    }
}