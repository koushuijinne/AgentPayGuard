# 方案 B 快速参考卡片

**使用 OpenZeppelin v5 自研多签钱包**

---

## 📦 已准备好的内容

### ✅ 3 个 Owner 地址（已有 Gas）
```
Owner 1: 0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77
Owner 2: 0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9
Owner 3: 0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8
```

### ✅ 2 个 Solidity 合约（已编写）
- `contracts/SimpleMultiSig.sol` - 2/3 多签钱包
- `contracts/SimpleFreeze.sol` - 冻结合约

### ✅ 完整部署指南
- `docs/multisig/部署指南_方案B.md`（600+ 行详细教程）

---

## 🚀 部署流程（3 步）

### 步骤 1：部署 SimpleMultiSig（30 分钟）

1. **打开 Remix**: `https://remix.ethereum.org/`
2. **创建并粘贴**: `SimpleMultiSig.sol` 代码
3. **编译**: Solidity 0.8.20
4. **连接 MetaMask**: Kite Testnet
5. **部署参数**:
   ```json
   ["0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77","0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9","0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8"]
   ```
6. **记录多签地址**: `0x_______________`

---

### 步骤 2：部署 SimpleFreeze 并转移 owner（15 分钟）

1. **部署 SimpleFreeze**（无构造参数）
2. **记录合约地址**: `0x_______________`
3. **调用 transferOwnership**:
   - 参数: 你的多签地址
4. **验证**: `owner()` 应返回多签地址

---

### 步骤 3：通过多签调用 freeze()（30 分钟）

1. **编码 calldata**（使用 Remix 或在线工具）:
   - 函数: `freeze(address)`
   - 参数: Owner 2 地址（或任意地址）
   
2. **Owner 1 提交并确认**:
   - 调用 `submitAndConfirm()`
   - 参数: `(SimpleFreeze地址, 0, calldata)`
   
3. **Owner 2 确认**:
   - 切换 MetaMask 到 Owner 2
   - 调用 `confirmTransaction(0)`
   
4. **任意 Owner 执行**:
   - 调用 `executeTransaction(0)`
   - 🎉 **记录这个 Tx Hash！**

5. **验证**: `isFrozen(地址)` 返回 `true`

---

## 📝 关键参数速查

### Kite Testnet
```
Chain ID: 2368
RPC: https://rpc-testnet.gokite.ai/
Explorer: https://testnet.kitescan.ai/
Faucet: https://faucet.gokite.ai/
```

### 构造函数参数（复制粘贴）
```json
["0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77","0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9","0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8"]
```

### 在线 ABI 编码器
```
https://abi.hashex.org/
```

---

## 🎯 核心交付物

最重要的 3 个信息：

1. **多签地址**: `0x_______________` ⭐
2. **冻结 Tx Hash**: `0x_______________` ⭐⭐⭐
3. **浏览器链接**: `https://testnet.kitescan.ai/tx/0x_______________`

填充到：
- `docs/multisig/multisig_config.md`
- `docs/multisig/tx_links.md`
- `for_judge.md`

---

## ⚠️ 常见问题速查

### Q: OpenZeppelin 依赖下载失败？
A: 等待 1-2 分钟，Remix 会自动重试。刷新页面重试。

### Q: 如何切换 MetaMask 账户？
A: 点击 MetaMask 头像 → 选择账户。Remix 会自动识别。

### Q: 如何获取 calldata？
A: 方法 1：Remix 控制台 + ethers.js  
   方法 2：在线工具 `https://abi.hashex.org/`

### Q: executeTransaction 失败？
A: 检查 `getTransaction(0)` 的 `numConfirmations`，必须 ≥ 2。

---

## 📊 时间估算

| 步骤 | 时间 |
|------|------|
| 部署 SimpleMultiSig | 30 分钟 |
| 部署 SimpleFreeze | 15 分钟 |
| 执行冻结操作 | 30 分钟 |
| 整理文档和截图 | 30 分钟 |
| **总计** | **约 1.5-2 小时** |

---

## 🔗 相关文档

- **详细指南**: `docs/multisig/部署指南_方案B.md`
- **操作清单**: `docs/multisig/操作清单.md`
- **合约代码**: `contracts/SimpleMultiSig.sol`, `contracts/SimpleFreeze.sol`

---

**开始时间**: ___________  
**完成时间**: ___________  
**实际用时**: ___________

祝你顺利！💪
