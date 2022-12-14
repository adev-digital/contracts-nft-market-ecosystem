// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./mixins/role-control.sol";

contract Treasury is RoleControl {
    event TokenWithdraw(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    function initialize(address admin) public initializer {
        OPERATOR_ROLE = bytes32("OPERATOR_ROLE");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function withdrawToken(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) public onlyAdmin {
        token.transfer(to, amount);
        emit TokenWithdraw(to, address(token), amount);
    }

    function withdrawETH(address to, uint256 amount) public onlyAdmin {
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool success, ) = to.call{value: amount, gas: 21000}("");
        require(success, "Failed to send ETH");
    }

    receive() external payable {}
}
