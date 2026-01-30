# 方案 B 部署指南：自己编写多签合约

**使用 OpenZeppelin v5 + Remix + Kite Testnet**

---

## 📋 总览

### 部署顺序
1. **部署 SimpleMultiSig 合约**（多签钱包）
2. **部署 SimpleFreeze 合约**（冻结合约）
3. **转移 SimpleFreeze 的 owner 给多签**
4. **通过多签调用 freeze() 函数**

### 预计时间
- 部署多签：30 分钟
- 部署 SimpleFreeze：15 分钟
- 执行冻结操作：30 分钟
- **总计**：约 1.5 小时

---

## 第一步：在 Remix 中准备环境

### 1.1 打开 Remix

访问：`https://remix.ethereum.org/`

### 1.2 创建工作区

1. 在左侧文件浏览器，点击 "+" 创建新文件夹：`AgentPayGuard`
2. 在 `AgentPayGuard` 文件夹下创建 2 个文件：
   - `SimpleMultiSig.sol`
   - `SimpleFreeze.sol`

### 1.3 安装 OpenZeppelin 依赖

**重要**：Remix 需要明确指定 npm 依赖版本

在 Remix 中：
1. 点击左下角 "Plugin Manager"
2. 搜索并激活 "Solidity Compiler" 和 "Deploy & Run Transactions"
3. 回到文件浏览器
4. 右键点击工作区根目录 → "Create" → "File"
5. 创建 `remixd.json`（可选，用于记录依赖）

**或者直接在合约中使用导入**：

Remix 会自动从 GitHub 拉取 OpenZeppelin 合约：

```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
```

当你编译时，Remix 会自动下载依赖（确保网络畅通）。

---

## 第二步：复制合约代码

### 2.1 复制 SimpleMultiSig.sol

1. 打开 `contracts/SimpleMultiSig.sol`（本地项目文件）
2. 复制全部代码
3. 粘贴到 Remix 的 `SimpleMultiSig.sol`

### 2.2 复制 SimpleFreeze.sol

1. 打开 `contracts/SimpleFreeze.sol`
2. 复制全部代码
3. 粘贴到 Remix 的 `SimpleFreeze.sol`

---

## 第三步：编译合约

### 3.1 编译 SimpleMultiSig

1. 点击左侧 "Solidity Compiler" 图标（第三个）
2. 选择编译器版本：`0.8.20` 或更高（推荐 `0.8.20`）
3. 点击 "Advanced Configurations"，确认：
   - EVM Version: `default`
   - Enable optimization: 可选勾选（200 runs）
4. 点击 "Compile SimpleMultiSig.sol"
5. 等待编译完成（绿色勾 ✅）

**如果出现依赖下载问题**：
- 检查网络连接
- 等待 1-2 分钟让 Remix 自动下载 OpenZeppelin 依赖
- 或者刷新页面重试

### 3.2 编译 SimpleFreeze

重复以上步骤，编译 `SimpleFreeze.sol`

---

## 第四步：连接 MetaMask 到 Kite Testnet

### 4.1 配置 Kite Testnet

在 MetaMask 中：
1. 点击网络下拉菜单
2. 点击 "添加网络"
3. 手动添加网络：
   - **网络名称**：Kite Testnet
   - **RPC URL**：`https://rpc-testnet.gokite.ai/`
   - **Chain ID**：`2368`
   - **货币符号**：KITE
   - **区块浏览器**：`https://testnet.kitescan.ai/`
4. 点击 "保存"

### 4.2 切换到 Kite Testnet

确认 MetaMask 显示：
- Network: **Kite Testnet**
- Chain ID: **2368**

### 4.3 确认账户余额

你的 3 个 Owner 地址应该都有余额：
- Owner 1: `0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77` → ≥ 0.5 KITE
- Owner 2: `0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9` → ≥ 0.5 KITE
- Owner 3: `0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8` → ≥ 0.5 KITE

**如果余额不足**：访问 `https://faucet.gokite.ai/` 领取测试币

---

## 第五步：部署 SimpleMultiSig（多签钱包）⭐

### 5.1 在 Remix 准备部署

1. 点击左侧 "Deploy & Run Transactions" 图标（第四个）
2. 在 "Environment" 下拉菜单中选择：`Injected Provider - MetaMask`
3. MetaMask 会弹出连接请求，点击 "连接"
4. 确认显示：
   - 网络：Kite Testnet (2368)
   - 账户：Owner 1 的地址

### 5.2 准备构造函数参数

SimpleMultiSig 的构造函数需要一个参数：`address[3] memory _owners`

**格式**（注意是数组格式）：
```json
["0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77","0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9","0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8"]
```

### 5.3 部署

1. 在 "Contract" 下拉菜单中选择：`SimpleMultiSig`
2. 在 "Deploy" 旁边的输入框中，粘贴构造函数参数：
   ```
   ["0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77","0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9","0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8"]
   ```
3. 点击橙色的 "transact" 按钮
4. MetaMask 会弹出交易确认：
   - 检查 Gas fee
   - 点击 "确认"
5. 等待 1-2 分钟，交易确认

### 5.4 记录多签合约地址 ⭐ 重要

部署成功后：
1. 在 Remix 底部 "Deployed Contracts" 会显示合约
2. 复制合约地址（点击地址旁边的复制按钮）
3. **记录到安全的地方**：
   ```
   SimpleMultiSig 地址: 0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA
   ```

### 5.5 验证部署

1. 访问 `https://testnet.kitescan.ai/address/0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`
2. 应该能看到：
   - Contract: 已创建
   - Balance: 0 KITE（可以后续转入）
3. 在 Remix "Deployed Contracts" 中，展开合约，点击 `getOwners`
4. 应该返回你的 3 个 Owner 地址

### 5.6 填充配置文档

打开 `docs/multisig/multisig_config.md`，填充：
```markdown
## 基本信息

- **多签地址**: `0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`
- **阈值**: 2/3
- **网络**: Kite Testnet (Chain ID: 2368)
- **部署 Tx Hash**: `0x9204503cf6c39bdb7d80f98f74345a5e9583015a616007ebe7e0e2eef356f3b7`
- **部署时间**: [填写当前时间]

## Owner 列表

| # | 地址 | 备注 | Faucet 状态 |
|---|------|------|------------|
| 1 | `0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77` | Owner 1 (huahua 主钱包) | ✅ 已领取 |
| 2 | `0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9` | Owner 2 | ✅ 已领取 |
| 3 | `0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8` | Owner 3 | ✅ 已领取 |
```

### 5.7 截图保存

- [ ] Remix 部署成功页面 → `multisig_deploy_remix.png`
- [ ] 浏览器合约地址页面 → `multisig_contract_explorer.png`

---

## 第六步：部署 SimpleFreeze（冻结合约）

### 6.1 在 Remix 准备部署

1. 确认仍然连接到 Kite Testnet
2. 确认使用 Owner 1 账户

### 6.2 部署 SimpleFreeze

1. 在 "Contract" 下拉菜单中选择：`SimpleFreeze`
2. **不需要构造函数参数**（owner 默认是部署者）
3. 点击橙色的 "transact" 按钮
4. MetaMask 确认交易
5. 等待部署完成

### 6.3 记录冻结合约地址

复制合约地址：
```
SimpleFreeze 地址: 0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719
```

### 6.4 转移 owner 给多签 ⭐ 关键

**重要**：现在 SimpleFreeze 的 owner 是你（Owner 1），需要转移给多签合约。

1. 在 Remix "Deployed Contracts" 中，展开 `SimpleFreeze` 合约
2. 找到 `transferOwnership` 函数
3. 输入参数：`newOwner` = **你的 SimpleMultiSig 地址**
   ```
   0x[你的多签地址]
   ```
4. 点击 "transact"
5. MetaMask 确认交易
6. 等待确认
7. tx hash：`0x96561793c490f28558bd2063a70d202f828117e3db18d3f95d4ff5697ed6f73e`

### 6.5 验证 owner 转移

1. 在 Remix 中，调用 `owner()` 函数（view 函数，不消耗 gas）
2. 应该返回你的多签地址（而不是 Owner 1 的地址）

### 6.6 填充配置文档

在 `multisig_config.md` 中添加：
```markdown
## 冻结合约

- **合约地址**: `0x[SimpleFreeze 地址]`
- **合约类型**: SimpleFreeze
- **部署 Tx**: `https://testnet.kitescan.ai/tx/0x[部署TxHash]`
- **Owner**: `0x[多签地址]`（已转移）
- **转移 Owner Tx**: `https://testnet.kitescan.ai/tx/0x[转移TxHash]`
```

---

## 第七步：通过多签调用 freeze() ⭐ 关键交付物

现在我们要演示：通过 2/3 多签确认，调用 SimpleFreeze 的 `freeze()` 函数。

### 7.1 编码 freeze() 调用数据

我们需要生成 `freeze(address account)` 的 calldata。

#### 方法：使用 Remix

1. 在 Remix "Deployed Contracts" 中，找到 `SimpleFreeze` 合约
2. 找到 `freeze` 函数
3. 输入要冻结的地址（例如：Owner 2 的地址）：
   ```
   0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9
   ```
4. **不要点击 "transact"**！
5. 在浏览器开发者工具（F12）中：
   - 打开 "Console" 标签
   - 输入以下命令来获取 calldata：
     ```javascript
     // 先获取 SimpleFreeze 的 ABI
     // 然后编码 freeze 函数
     const iface = new ethers.utils.Interface([
       "function freeze(address account)"
     ]);
     const calldata = iface.encodeFunctionData("freeze", ["0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9"]);
     console.log(calldata);
     ```

**或者使用在线工具**：
- 访问 `https://abi.hashex.org/`
- 输入函数签名：`freeze(address)`
- 输入参数：`0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9`
- 获取 calldata（`8d1fdf2f000000000000000000000000b89ffb647bc1d12edcf7b0c13753300e17f2d6e9`）

### 7.2 提交交易提案（Owner 1）

1. 切换到 `SimpleMultiSig` 合约（在 Remix "Deployed Contracts" 中）
2. 找到 `submitAndConfirm` 函数（提交并立即确认）
3. 输入参数：
   - `_to`: SimpleFreeze 合约地址
   - `_value`: `0`（不转账）
   - `_data`: 刚才获取的 calldata（`8d1fdf2f000000000000000000000000b89ffb647bc1d12edcf7b0c13753300e17f2d6e9`）
4. 点击 "transact"
5. MetaMask 确认交易
6. 等待确认

### 7.3 查看交易 ID

1. 在 Remix 控制台查看交易返回值，应该返回 `txId: 0`（第一笔交易）
2. 或者调用 `transactionCount()`，应该返回 `1`（说明有 1 笔交易）

### 7.4 Owner 2 确认交易

现在需要第二个 Owner 签名：

1. **在 MetaMask 中切换到 Owner 2 的账户**
2. 在 Remix 中，"Account" 应该自动更新为 Owner 2 的地址
3. 在 `SimpleMultiSig` 合约中，找到 `confirmTransaction` 函数
4. 输入参数：`_txId` = `0`
5. 点击 "transact"
6. MetaMask 确认交易
7. 等待确认

### 7.5 执行交易

达到 2/3 阈值后，任意 Owner 可以执行：

1. 在 `SimpleMultiSig` 合约中，找到 `executeTransaction` 函数
2. 输入参数：`_txId` = `0`
3. 点击 "transact"
4. MetaMask 确认交易
5. 等待确认

**执行成功后**，`freeze()` 函数被调用，Owner 2 的地址被冻结！

### 7.6 验证冻结生效

1. 在 `SimpleFreeze` 合约中，调用 `isFrozen` 函数
2. 输入参数：`0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9`
3. 应该返回 `true` ✅

### 7.7 记录冻结 Tx Hash ⭐ 关键

从 MetaMask 或浏览器复制 `executeTransaction` 的 Tx Hash：

```
冻结操作 Tx Hash: 0xab40fc72ea1fa30a6455b48372a02d25e67952ab7c69358266f4d83413bfa46c
```

填充到 `docs/multisig/tx_links.md`：
```markdown
## 2. 冻结操作（多签交易）

⭐ **关键交付物**

- **Tx Hash**: `0x[executeTransaction 的 TxHash]`
- **浏览器链接**: `https://testnet.kitescan.ai/tx/0xab40fc72ea1fa30a6455b48372a02d25e67952ab7c69358266f4d83413bfa46c`
- **操作类型**: 多签提案 → 2/3 签名确认 → 执行
- **目标合约**: `0x[SimpleFreeze 地址]`
- **方法**: `freeze(address)`
- **被冻结地址**: `0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9`
- **描述**: 通过 2/3 多签执行冻结操作

### 签名记录
- Owner 1 提交并确认: Tx Hash
- Owner 2 确认: Tx Hash
- 达到阈值并执行: Tx Hash（⭐ 这个是关键）
```

### 7.8 截图保存

- [ ] 提交交易页面 → `freeze_submit.png`
- [ ] Owner 2 确认页面 → `freeze_confirm.png`
- [ ] 执行交易页面 → `freeze_execute.png`
- [ ] 浏览器交易详情 → `freeze_tx_explorer.png`
- [ ] `isFrozen` 返回 true → `freeze_verified.png`

---

## 第八步：填充 for_judge.md

打开 `for_judge.md`，更新：

```markdown
| 权限控制 | 自研 2/3 多签 + 策略校验 | 多签地址: 0x[你的多签地址] + 冻结 Tx: https://testnet.kitescan.ai/tx/0x[TxHash] |
```

并在技术架构部分添加：

```markdown
异常/高风险 → 自研 SimpleMultiSig（2/3 多签）介入：冻结/解冻

- **多签合约**: `0x[多签地址]`
- **冻结合约**: `0x[SimpleFreeze 地址]`
- **阈值**: 2/3
- **冻结 Tx**: https://testnet.kitescan.ai/tx/0x[TxHash]
- **技术栈**: OpenZeppelin v5 + Solidity 0.8.20
```

---

## 🎉 完成！

### 交付物清单

- [x] SimpleMultiSig 合约地址（自研 2/3 多签）
- [x] SimpleFreeze 合约地址（冻结功能）
- [x] SimpleFreeze 的 owner 已转移给多签
- [x] 通过多签执行 freeze() 的 Tx Hash ⭐
- [x] 所有配置文档已填充
- [x] 所有截图已保存
- [x] for_judge.md 已更新

### 技术亮点

✨ 使用 OpenZeppelin v5 标准库  
✨ 自研多签合约（展示 Solidity 能力）  
✨ 完整的多签流程（提交 → 确认 → 执行）  
✨ 真实的冻结功能（可验证）  

---

## 常见问题

### Q1: OpenZeppelin 依赖下载失败？
A: 检查网络，刷新 Remix 页面，或者等待 1-2 分钟自动重试。

### Q2: 如何快速切换 MetaMask 账户？
A: 点击 MetaMask 头像 → 选择账户 → Remix 会自动更新。

### Q3: executeTransaction 失败？
A: 检查是否达到 2/3 阈值，调用 `getTransaction(0)` 查看 `numConfirmations`。

### Q4: 如何获取 calldata？
A: 使用 Remix 控制台 + ethers.js，或者在线 ABI 编码器。

---

**预计总时间**: 1.5 小时  
**难度**: 中等（需要理解多签流程）  
**技术含量**: ⭐⭐⭐⭐⭐（高，展示自研能力）
