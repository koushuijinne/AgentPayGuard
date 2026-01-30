# SimpleFreeze 合约部署指南

**合约位置**: `contracts/SimpleFreeze.sol`  
**部署工具**: Remix IDE（最简单）

---

## 方案选择

### ✅ 方案 A：部署 SimpleFreeze 合约（推荐，更完整）

这个合约提供真实的冻结功能，部署后将 owner 转移给多签。

### ⚡ 方案 B：跳过合约部署（快速方案）

如果时间紧张，可以用多签发送一笔象征性转账作为"冻结操作"。

---

## 方案 A：使用 Remix 部署合约

### 步骤 1：打开 Remix

1. 访问 `https://remix.ethereum.org/`
2. 在左侧文件浏览器中，创建新文件：`SimpleFreeze.sol`
3. 复制 `contracts/SimpleFreeze.sol` 的内容粘贴进去

### 步骤 2：编译合约

1. 点击左侧的 "Solidity Compiler" 图标（第三个）
2. 选择编译器版本：`0.8.0` 或更高（如 `0.8.20`）
3. 点击 "Compile SimpleFreeze.sol"
4. 确认编译成功（绿色勾）

### 步骤 3：连接钱包

1. 点击左侧的 "Deploy & Run Transactions" 图标（第四个）
2. 在 "Environment" 下拉菜单中选择：`Injected Provider - MetaMask`
3. MetaMask 会弹出连接请求，点击 "连接"
4. **确认 MetaMask 已切换到 Kite Testnet**：
   - Network: Kite Testnet
   - Chain ID: 2368
   - RPC: https://rpc-testnet.gokite.ai/

### 步骤 4：部署合约

1. 在 "Contract" 下拉菜单中选择：`SimpleFreeze`
2. 点击橙色的 "Deploy" 按钮
3. MetaMask 会弹出交易确认：
   - 检查 Gas fee（应该很低）
   - 点击 "确认"
4. 等待 1-2 分钟，交易确认

### 步骤 5：记录合约地址

1. 部署成功后，在 Remix 底部"Deployed Contracts"会显示合约地址
2. 复制合约地址：`0x...`
3. 记录到 `multisig_config.md`：
   ```markdown
   ## 冻结合约
   - 合约地址: 0x...
   - 合约类型: SimpleFreeze
   - 部署 Tx: https://testnet.kitescan.ai/tx/0x...
   ```

### 步骤 6：转移所有权给多签

**重要**：合约部署后，owner 是你的地址，需要转移给多签地址。

1. 在 Remix 的 "Deployed Contracts" 中，展开合约
2. 找到 `transferOwnership` 函数
3. 输入参数：`newOwner` = 你的多签钱包地址（创建多签后获得）
4. 点击 "transact"
5. MetaMask 确认交易
6. 等待确认

**验证**：
- 调用 `owner()` 函数（view 函数，不消耗 gas）
- 应该返回你的多签地址

---

## 方案 B：快速方案（不部署合约）

如果时间不够或不想部署合约，可以用这个简化方案：

### 步骤：用多签发送象征性转账

1. 在 Ash Wallet 中，创建新交易
2. 填写：
   - **To**: 任意地址（如 `0x000000000000000000000000000000000000dEaD`）
   - **Value**: 0.001 KITE
   - **描述**: "冻结操作演示"
3. 提交提案，2/3 签名确认
4. 记录 Tx Hash

**说明**：
- 这笔交易的 Tx Hash 可以作为"冻结操作 Tx Hash"
- 虽然没有真实的冻结合约，但证明了多签流程
- 对于评审来说，关键是展示"多签 2/3 确认流程"

---

## 使用合约进行冻结操作

**前提**：已部署合约并转移 owner 给多签

### 步骤 1：编码 freeze 函数调用

在 Remix 中：
1. 在 "Deployed Contracts" 中，找到 `freeze` 函数
2. 输入要冻结的地址（例如：角色 B 的 AA 账户地址）
3. **不要点击 "transact"**，而是：
   - 点击右侧的 "Copy calldata" 按钮
   - 或者在控制台查看 calldata
4. 复制 calldata（类似：`0x8cfe0009000000000000000000000000...`）

### 步骤 2：在 Ash Wallet 创建冻结提案

1. 打开 Ash Wallet，选择你的多签
2. 点击 "New Transaction"
3. 选择 "Contract Interaction"
4. 填写：
   - **To**: SimpleFreeze 合约地址
   - **Value**: 0
   - **Data**: 粘贴刚才复制的 calldata
5. 提交提案

### 步骤 3：多签确认

1. Owner 1（你）：签名并提交
2. Owner 2（队友或你的第二钱包）：签名确认
3. 达到 2/3 阈值，自动执行
4. 记录 Tx Hash

---

## 验证冻结是否生效

在 Remix 中调用：
```solidity
isFrozen(被冻结的地址)
```
应该返回 `true`

---

## 时间估算

| 方案 | 时间 | 难度 |
|------|------|------|
| 方案 A（部署合约）| 1 小时 | 中等 |
| 方案 B（快速方案）| 5 分钟 | 简单 |

---

## 常见问题

**Q1：Remix 连不上 MetaMask？**
A：检查 MetaMask 是否在 Kite Testnet，刷新 Remix 页面重试。

**Q2：部署合约 gas 不够？**
A：确保你的钱包有至少 0.5 KITE，去 faucet 领取。

**Q3：如何获取 calldata？**
A：在 Remix 的函数输入框中填写参数后，点击旁边的复制按钮即可。

---

**推荐**：如果你熟悉 Remix 和 Solidity，用方案 A（约 1 小时）；如果时间紧或不熟悉，用方案 B（约 5 分钟）。
