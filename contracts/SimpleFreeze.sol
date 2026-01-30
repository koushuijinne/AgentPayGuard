// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleFreeze
 * @dev 最简单的冻结合约，用于演示多签权限控制
 * 
 * 使用方式:
 * 1. 部署合约（owner 为部署者）
 * 2. 调用 transferOwnership(多签地址) 转移权限
 * 3. 通过多签调用 freeze(account) 冻结账户
 * 4. 通过多签调用 unfreeze(account) 解冻账户
 */
contract SimpleFreeze {
    // 合约所有者（应该是多签地址）
    address public owner;
    
    // 冻结列表：地址 => 是否被冻结
    mapping(address => bool) public frozen;
    
    // 事件：账户被冻结
    event Frozen(address indexed account, uint256 timestamp);
    
    // 事件：账户被解冻
    event Unfrozen(address indexed account, uint256 timestamp);
    
    // 事件：所有权转移
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev 构造函数，部署者成为初始 owner
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @dev 修饰器：只有 owner 可以调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "SimpleFreeze: caller is not the owner");
        _;
    }
    
    /**
     * @dev 转移所有权（部署后应立即调用，转移给多签地址）
     * @param newOwner 新的 owner 地址（多签地址）
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SimpleFreeze: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @dev 冻结账户（只有 owner 即多签可调用）
     * @param account 要冻结的账户地址
     */
    function freeze(address account) external onlyOwner {
        require(account != address(0), "SimpleFreeze: cannot freeze zero address");
        require(!frozen[account], "SimpleFreeze: account already frozen");
        
        frozen[account] = true;
        emit Frozen(account, block.timestamp);
    }
    
    /**
     * @dev 解冻账户（只有 owner 即多签可调用）
     * @param account 要解冻的账户地址
     */
    function unfreeze(address account) external onlyOwner {
        require(account != address(0), "SimpleFreeze: cannot unfreeze zero address");
        require(frozen[account], "SimpleFreeze: account not frozen");
        
        frozen[account] = false;
        emit Unfrozen(account, block.timestamp);
    }
    
    /**
     * @dev 检查账户是否被冻结
     * @param account 要查询的账户地址
     * @return 是否被冻结
     */
    function isFrozen(address account) external view returns (bool) {
        return frozen[account];
    }
}
