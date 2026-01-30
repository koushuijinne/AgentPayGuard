// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title SimpleMultiSig
 * @dev 简单的 2/3 多签钱包合约，使用 OpenZeppelin v5
 * 
 * 功能：
 * - 3 个 owners，需要 2 个签名才能执行交易
 * - 支持任意合约调用（包括 freeze/unfreeze）
 * - 使用链下签名 + 链上验证（节省 gas）
 * 
 * 使用流程：
 * 1. submitTransaction() - 任意 owner 提交提案
 * 2. confirmTransaction() - 其他 owners 确认（至少 2 个）
 * 3. executeTransaction() - 达到阈值后执行
 */
contract SimpleMultiSig {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ==================== 状态变量 ====================
    
    // Owners 列表
    address[3] public owners;
    
    // 所需签名数量（阈值）
    uint256 public constant REQUIRED = 2;
    
    // 交易计数器（用于生成唯一的交易 ID）
    uint256 public transactionCount;
    
    // 交易结构体
    struct Transaction {
        address to;           // 目标地址
        uint256 value;        // 转账金额
        bytes data;           // 调用数据
        bool executed;        // 是否已执行
        uint256 numConfirmations;  // 确认数量
    }
    
    // 交易 ID => 交易详情
    mapping(uint256 => Transaction) public transactions;
    
    // 交易 ID => owner 地址 => 是否已确认
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    
    // ==================== 事件 ====================
    
    event TransactionSubmitted(
        uint256 indexed txId,
        address indexed submitter,
        address indexed to,
        uint256 value,
        bytes data
    );
    
    event TransactionConfirmed(
        uint256 indexed txId,
        address indexed owner
    );
    
    event TransactionExecuted(
        uint256 indexed txId,
        address indexed executor
    );
    
    event TransactionRevoked(
        uint256 indexed txId,
        address indexed owner
    );
    
    // ==================== 修饰器 ====================
    
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not owner");
        _;
    }
    
    modifier txExists(uint256 _txId) {
        require(_txId < transactionCount, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }
    
    modifier notConfirmed(uint256 _txId) {
        require(!isConfirmed[_txId][msg.sender], "Transaction already confirmed");
        _;
    }
    
    // ==================== 构造函数 ====================
    
    /**
     * @dev 初始化多签钱包
     * @param _owners 3 个 owner 地址
     */
    constructor(address[3] memory _owners) {
        require(_owners[0] != address(0), "Invalid owner 0");
        require(_owners[1] != address(0), "Invalid owner 1");
        require(_owners[2] != address(0), "Invalid owner 2");
        require(_owners[0] != _owners[1], "Owners must be unique");
        require(_owners[0] != _owners[2], "Owners must be unique");
        require(_owners[1] != _owners[2], "Owners must be unique");
        
        owners = _owners;
    }
    
    // ==================== 接收 ETH ====================
    
    receive() external payable {}
    
    // ==================== 公共函数 ====================
    
    /**
     * @dev 提交新交易提案
     * @param _to 目标地址
     * @param _value 转账金额（单位：wei）
     * @param _data 调用数据（编码后的函数调用）
     * @return txId 交易 ID
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner returns (uint256 txId) {
        txId = transactionCount;
        
        transactions[txId] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        });
        
        transactionCount++;
        
        emit TransactionSubmitted(txId, msg.sender, _to, _value, _data);
        
        return txId;
    }
    
    /**
     * @dev 确认交易
     * @param _txId 交易 ID
     */
    function confirmTransaction(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        isConfirmed[_txId][msg.sender] = true;
        transactions[_txId].numConfirmations++;
        
        emit TransactionConfirmed(_txId, msg.sender);
    }
    
    /**
     * @dev 执行交易（需要达到阈值）
     * @param _txId 交易 ID
     */
    function executeTransaction(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        
        require(
            transaction.numConfirmations >= REQUIRED,
            "Not enough confirmations"
        );
        
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction execution failed");
        
        emit TransactionExecuted(_txId, msg.sender);
    }
    
    /**
     * @dev 撤销确认
     * @param _txId 交易 ID
     */
    function revokeConfirmation(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isConfirmed[_txId][msg.sender], "Transaction not confirmed");
        
        isConfirmed[_txId][msg.sender] = false;
        transactions[_txId].numConfirmations--;
        
        emit TransactionRevoked(_txId, msg.sender);
    }
    
    // ==================== 便捷函数：提交并确认 ====================
    
    /**
     * @dev 提交交易并立即确认（节省一笔交易）
     */
    function submitAndConfirm(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (uint256 txId) {
        txId = submitTransaction(_to, _value, _data);
        confirmTransaction(txId);
        return txId;
    }
    
    // ==================== 查询函数 ====================
    
    /**
     * @dev 检查地址是否为 owner
     */
    function isOwner(address _address) public view returns (bool) {
        for (uint256 i = 0; i < 3; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev 获取交易详情
     */
    function getTransaction(uint256 _txId)
        public
        view
        txExists(_txId)
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
    
    /**
     * @dev 获取所有 owners
     */
    function getOwners() public view returns (address[3] memory) {
        return owners;
    }
    
    /**
     * @dev 获取合约余额
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
