// SPDX-License-Identifier: Unlicensed
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity ^0.8.14;

interface IERC20 is IERC20Upgradeable {
    function isAdmin(address who) external returns (bool);
    function isOperator(address who) external returns (bool);
    function mint(address to, uint256 amount) external;
}