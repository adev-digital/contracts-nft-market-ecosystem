// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ITreasury.sol";

contract ERC20Token is ERC20 {
    ITreasury treasury;
    uint8 _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply,
        uint8 decimals_,
        ITreasury _treasury
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        treasury = _treasury;
        _mint(address(treasury), supply * 10**decimals_);
    }

    function transferMultiple(
        address[] memory receivers,
        uint256[] memory amount
    ) public {
        require(
            receivers.length == amount.length,
            "Different receiver and amount array length"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            _transfer(msg.sender, receivers[i], amount[i]);
        }
    }

    function mint(address to, uint256 amount) public {
        require(treasury.isOperator(msg.sender), "Restricted function");
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
