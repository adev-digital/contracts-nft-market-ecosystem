// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/IERC20.sol";

contract Stake is Initializable {
    bool paused = true;

    ITreasury public treasury;
    IERC20 paymentToken;
    IERC721Upgradeable stakingNFT;

    mapping(uint256 => address) originalNftOwner;
    mapping(address => uint256[]) stakedNFTsOfAddress;
    mapping(uint256 => StakedNFT) tokenIdToStakeInfo;

    uint256 stakePeriod = 1 days;
    uint256 amountPerPeriod = .01 ether;

    uint256 public totalClaimed;

    struct StakedNFT {
        uint256 stakeStart;
        uint256 claimedTill;
    }

    event RewardsClaimed(address indexed claimer, uint256 amount);

    event NFTStaked(address staker, uint256 tokenId);
    event NFTUnstaked(address staker, uint256 tokenId);

    function initialize(
        ITreasury _treasury,
        IERC20 token,
        IERC721Upgradeable _nft
    ) public initializer {
        treasury = _treasury;
        paymentToken = token;
        stakingNFT = _nft;
    }

    //internals
    modifier onlyAdmin() {
        require(treasury.isAdmin(msg.sender), "Restricted function");
        _;
    }

    modifier isUnpaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function _sendTokens(uint256 amount) internal {
        if (paymentToken.balanceOf(address(treasury)) < amount) {
            paymentToken.mint(
                address(treasury),
                amount - paymentToken.balanceOf(address(treasury))
            );
        }
        paymentToken.transferFrom(address(treasury), msg.sender, amount);
    }

    function _getRewardsForNFT(StakedNFT memory vault)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 a = block.timestamp - vault.claimedTill;
        uint256 stakingPeriod = a - (a % stakePeriod);
        return (amountPerPeriod * (stakingPeriod / stakePeriod), stakingPeriod);
    }

    function _getRewards(address who) internal view returns (uint256 rewards) {
        for (uint256 i = 0; i <= stakedNFTsOfAddress[who].length; i++) {
            (uint256 rewardToAdd, ) = _getRewardsForNFT(tokenIdToStakeInfo[i]);
            rewards += rewardToAdd;
        }
    }

    function changeRewardBonuses(uint256 _stakeReward) public onlyAdmin {
        amountPerPeriod = _stakeReward;
    }

    //user funcs
    function stakeNFT(uint256 tokenId) public isUnpaused {
        require(stakingNFT.ownerOf(tokenId) == msg.sender, "Not an owner");
        stakingNFT.transferFrom(msg.sender, address(this), tokenId);
        originalNftOwner[tokenId] = msg.sender;
        stakedNFTsOfAddress[msg.sender].push(tokenId);
        tokenIdToStakeInfo[tokenId].stakeStart = block.timestamp;
        tokenIdToStakeInfo[tokenId].claimedTill = block.timestamp;
        emit NFTStaked(msg.sender, tokenId);
    }

    function unstakeNFT(uint256 tokenId) public isUnpaused {
        require(
            originalNftOwner[tokenId] == msg.sender,
            "Not the original owner"
        );
        (uint256 amount, ) = _getRewardsForNFT(tokenIdToStakeInfo[tokenId]);
        _sendTokens(amount);
        totalClaimed += amount;
        uint256 ind;
        uint256[] memory newArr = new uint256[](
            stakedNFTsOfAddress[msg.sender].length - 1
        );
        for (uint256 i = 0; i < stakedNFTsOfAddress[msg.sender].length; i++) {
            if (stakedNFTsOfAddress[msg.sender][i] != tokenId) {
                newArr[ind] = stakedNFTsOfAddress[msg.sender][i];
                ind++;
            }
        }
        stakedNFTsOfAddress[msg.sender] = newArr;
        delete originalNftOwner[tokenId];
        delete tokenIdToStakeInfo[tokenId];
        emit NFTUnstaked(msg.sender, tokenId);
    }

    function claimRewards() public payable {
        uint256 rewards;
        for (uint256 i = 0; i <= stakedNFTsOfAddress[msg.sender].length; i++) {
            uint256 tokenId = stakedNFTsOfAddress[msg.sender][i];
            (uint256 rewardToAdd, uint256 claimedTill) = _getRewardsForNFT(
                tokenIdToStakeInfo[tokenId]
            );
            if (rewardToAdd > 0) {
                rewards += rewardToAdd;
                tokenIdToStakeInfo[tokenId].claimedTill += claimedTill;
            }
        }
        require(rewards > 0, "Can't withdraw 0");
        _sendTokens(rewards);
        totalClaimed += rewards;
        emit RewardsClaimed(msg.sender, rewards);
    }

    //view functions
    function tokensStaked(address who) public view returns (uint256[] memory) {
        return stakedNFTsOfAddress[who];
    }

    function viewOwnRewards() public view returns (uint256) {
        return _getRewards(msg.sender);
    }
}
