// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Ball is ERC20, Ownable{

  using SafeMath for uint256;

  address public constant teamAddress = 0x79E98c0b69883B44A14CBD3C974ff0C0b9B5CA78; // 团队地址

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _whitelist;

  uint256 private _totalSupply;
  uint256 private _burnRate = 3; // 3% burn rate
  uint256 private _teamRate = 2; // 2% team allocation rate
  address public pancakePair = address(0);

  constructor() ERC20("ZkDragonball","Ball")  {
    _mint(msg.sender, 100_000_000e18);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
      uint256 burnAmount = 0;
      uint256 teamAmount = 0;
      if ((!_whitelist[from] && to == pancakePair) || (from == pancakePair && !_whitelist[to])) {
          burnAmount = amount * _burnRate / 100;
          teamAmount = amount * _teamRate / 100;
      }
      uint256 transferAmount = amount - burnAmount - teamAmount;
      super._transfer(from, to, transferAmount);
      if (teamAmount > 0) {
        super._transfer(from, teamAddress, teamAmount);      
      }
      if (burnAmount > 0) {
          _burn(from, burnAmount);
      }
  }

  function setPancakePair(address pair) external onlyOwner {
      pancakePair = pair;
  }

   function addToWhitelist(address account) external onlyOwner {
      _whitelist[account] = true;
  }

  function removeFromWhitelist(address account) external onlyOwner {
      _whitelist[account] = false;
  }

  function isWhitelisted(address account) external view returns (bool) {
      return _whitelist[account];
  }

}