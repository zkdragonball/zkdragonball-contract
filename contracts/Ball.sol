// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Ball is ERC20, Ownable{

  using SafeMath for uint256;

  mapping(address => bool) private _burnlist;

  uint256 private _totalSupply;
  uint256 private _burnRate = 3; // 3% burn rate

  constructor() ERC20("ZkDragonball","Ball")  {
    _mint(msg.sender, 1_000_000_000e18);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
      uint256 burnAmount = 0;
      if (_burnlist[from] || _burnlist[to]) {
          burnAmount = amount.mul(_burnRate).div(1000);
      }
      uint256 transferAmount = amount.sub(burnAmount);
      super._transfer(from, to, transferAmount);
      if (burnAmount > 0) {
          _burn(from, burnAmount);
      }
  }

  function burn(uint256 amount) public {
    _burn(msg.sender, amount);
  }

  function addToBurnlist(address account) external onlyOwner {
      _burnlist[account] = true;
  }

  function removeFromBurnlist(address account) external onlyOwner {
      _burnlist[account] = false;
  }

  function isBurnlisted(address account) external view returns (bool) {
      return _burnlist[account];
  }

  function setBurnRate(uint256 newBurnRate) external onlyOwner {
      require(newBurnRate <= 1000, "Burn rate must be less than or equal to 1000 (i.e., 100%)");
      _burnRate = newBurnRate;
  }

  function getBurnRate() external view returns (uint256) {
      return _burnRate;
  }

}