// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Treasury is Ownable {
    using SafeERC20 for IERC20;
    event ERC20Withdrawn(address indexed token, uint256 amount);
    event ERC20WithdrawnAll(address indexed token, uint256 amount);

    constructor(address owner) Ownable(owner) {}

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        IERC20(token).safeTransfer(owner(), amount);
        emit ERC20Withdrawn(token, amount);
    }

    function withdrawAllERC20(address token) external onlyOwner {
        require(token != address(0), "Invalid token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        IERC20(token).safeTransfer(owner(), balance);
        emit ERC20WithdrawnAll(token, balance);
    }

    // event ETHWithdrawn(uint256 amount);

    // function withdrawETH() external onlyOwner {
    //     uint256 balance = address(this).balance;
    //     require(balance > 0, "No ETH balance");
    //     (bool success, ) = owner().call{value: balance}("");
    //     require(success, "ETH transfer failed");
    //     emit ETHWithdrawn(balance);
    // }

    // receive() external payable {}
}
