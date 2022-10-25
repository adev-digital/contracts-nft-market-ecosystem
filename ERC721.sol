// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/ITreasury.sol";

contract ERC20Token is ERC721 {
    using Strings for uint256;

    ITreasury treasury;

    bool public paused = true;
    bool public isRevealed = false;
    string baseUri;
    string hiddenUri;

    uint256 totalSupply = 3000;
    uint256 supply;

    uint256 mintPrice = 0.1 ether;

    constructor(
        string memory name_,
        string memory symbol_,
        ITreasury _treasury,
        string memory _hiddenUri
    ) ERC721(name_, symbol_) {
        treasury = _treasury;
        hiddenUri = _hiddenUri;
    }

    //public functions
    function mint(uint256 amount) public payable {
        require(!paused, "Contract is paused");
        require(supply + amount <= totalSupply, "Amount exceeds total supply");
        require(
            msg.value >= (mintPrice * amount),
            "Insufficient message value"
        );
        for (uint256 i = 0; i < amount; i++) {
            supply++;
            _mint(msg.sender, supply);
        }
        (bool success, ) = address(treasury).call{value: amount, gas: 21000}(
            ""
        );
        require(success, "Failed to send ETH");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (isRevealed) {
            return
                string(abi.encodePacked(baseUri, tokenId.toString(), ".json"));
        } else {
            return hiddenUri;
        }
    }

    //admin functions
    function changePause() public {
        require(treasury.isAdmin(msg.sender), "Restricted function");
        paused = !paused;
    }

    function reveal(string memory _baseUri) public {
        require(treasury.isAdmin(msg.sender), "Restricted function");
        require(!isRevealed, "Already revealed");
        baseUri = _baseUri;
        isRevealed = true;
    }

    function changeMintPrice(uint256 newPrice) public {
        require(treasury.isAdmin(msg.sender), "Restricted function");
        mintPrice = newPrice;
    }

    receive() external payable {}
}
