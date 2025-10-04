// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// sepolia 测试网合约地址： 0x917855197f9EB48Bf39A3fB2EC1fbaE1db732Fa2
contract MyERC20 is IERC20, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping (address account => mapping (address spender => uint256)) private _allowances;
    uint256 private _totalSupply;
    address private _owner;

    constructor() {
        _owner = msg.sender;
        mint(_owner, 10000);    // 给合约拥有者发 10000 代币
    }

    // 代币总供应量
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // 账户代币余额
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    // 代币转移（调用者 -> to）
    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    // 查询授权额度
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    // 授权 spender 一定额度内使用 调用者 代币
    function approve(address spender, uint256 value) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value, true);
        return true;
    }

    // 被授权用户代表授权者转移其代币
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    // 增发代币
    function mint(address account, uint256 value) public {
        require(_owner == msg.sender, "Just contract owner can mint");

        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    // 销毁代币
    function burn(address account, uint256 value) public {
        require(_owner == msg.sender, "Just contract owner can burn");

        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    // 代币转移
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    // 记录更新
    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            // 增发代币
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            // 销毁代币
            _totalSupply -= value;
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    // 授权
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    // 花费授权额度
    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}