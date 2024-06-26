//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  Ref: https://github.com/Uniswap/merkle-distributor
 */
contract MerkleAirdrop is Ownable {
    bytes32 public immutable merkleRoot;
    IERC20 public token;
    uint256 public startTime;
    uint256 public endTime;

    event Claimed(address account, uint256 amount);

    mapping(address => bool) public claimed;

    constructor(bytes32 _merkleRoot, address _tokenAddress, uint _startTime, uint _endTime) {
        merkleRoot = _merkleRoot;
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endTime = _endTime;
    }

    function setAirdropPeriod(uint _startTime, uint _endTime) public onlyOwner {
        require(_endTime > _startTime, "Invalid airdrop period");
        startTime = _startTime;
        endTime = _endTime;
    }

    function claim(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Airdrop not active");
        require(!claimed[msg.sender], "User has already claimed tokens");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Transfer ERC20 tokens to the user
        token.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function extractTokens() public onlyOwner {
        require(block.timestamp > endTime, "Cannot extract tokens before airdrop ends");
        uint remainingTokens = token.balanceOf(address(this));
        require(token.transfer(msg.sender, remainingTokens), "Token transfer failed");
    }
}
