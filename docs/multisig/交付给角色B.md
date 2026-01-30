# 角色 A → 角色 B 交付文档

**交付时间**: 2026-01-30  
**发件人**: huahua (角色 A - 链上)  
**收件人**: Sulla (角色 B - 后端/AA)

---

## 📦 交付内容概述

角色 A 已完成多签钱包和冻结合约的部署，现将相关信息交付给角色 B，用于后端集成和支付流程增强。

---

## 🔑 核心交付物

### 1. 多签钱包（SimpleMultiSig）

- **合约地址**: `0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`
- **合约类型**: SimpleMultiSig（自研，基于 OpenZeppelin v5）
- **阈值**: 2/3
- **网络**: Kite Testnet (Chain ID: 2368)
- **浏览器链接**: `https://testnet.kitescan.ai/address/0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`

**功能**:
- 提交交易提案：`submitTransaction(address _to, uint256 _value, bytes _data)`
- 确认交易：`confirmTransaction(uint256 _txId)`
- 执行交易：`executeTransaction(uint256 _txId)`
- 提交并确认（快捷）：`submitAndConfirm(address _to, uint256 _value, bytes _data)`

---

### 2. 冻结合约（SimpleFreeze）

- **合约地址**: `0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719`
- **合约类型**: SimpleFreeze
- **Owner**: `0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`（多签地址）
- **浏览器链接**: `https://testnet.kitescan.ai/address/0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719`

**功能**:
- 冻结账户：`freeze(address account)` - 只有多签可调用
- 解冻账户：`unfreeze(address account)` - 只有多签可调用
- 查询状态：`isFrozen(address account) returns (bool)` - 任何人可查询

---

### 3. Owner 地址列表

用于多签操作的 3 个 Owner 地址：

| # | 地址 | 备注 |
|---|------|------|
| 1 | `0x04A3FA73f6C4c8BF870575037EC06C76F387Aa77` | Owner 1 (huahua 主钱包) |
| 2 | `0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9` | Owner 2 |
| 3 | `0x930AB98c99E6AaAc76A6AeCFAd9da77A7b7C2Fa8` | Owner 3 |

---

## 🔧 可能的集成方式

### 方案 1：在支付前检查冻结状态（推荐）

在 `src/lib/policy.ts` 的 `evaluatePolicy` 函数中，增加冻结状态检查：

```typescript
// 伪代码示例
import { ethers } from 'ethers';

const FREEZE_CONTRACT_ADDRESS = '0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719';
const FREEZE_ABI = [
  'function isFrozen(address account) view returns (bool)'
];

export async function evaluatePolicy(params: {
  recipient: string;
  amount: bigint;
  policy: PolicyConfig;
  provider?: ethers.Provider; // 新增参数
}): Promise<PolicyResult> {
  // 原有的白名单、限额检查...
  
  // 新增：检查收款地址是否被冻结
  if (params.provider) {
    const freezeContract = new ethers.Contract(
      FREEZE_CONTRACT_ADDRESS,
      FREEZE_ABI,
      params.provider
    );
    
    const isFrozen = await freezeContract.isFrozen(params.recipient);
    
    if (isFrozen) {
      return {
        allowed: false,
        reason: `收款地址 ${params.recipient} 已被多签冻结，禁止支付`
      };
    }
  }
  
  // 继续原有逻辑...
}
```

**好处**：
- 在支付执行前就拦截
- 节省 gas（不会发起失败的交易）
- 日志清晰（"被策略拒绝"而非"链上失败"）

---

### 方案 2：仅用于文档说明（最简单）

如果时间紧张，可以只在文档中说明：

> "当高风险事件发生时（如连续失败、可疑行为），多签成员可通过 SimpleMultiSig（地址：0xA247...）调用 SimpleFreeze.freeze() 冻结可疑地址，阻止后续支付。"

然后在 `for_judge.md` 或演示 PPT 中展示冻结功能的 Tx Hash 和浏览器截图。

---

### 方案 3：在 AA 账户层面集成（高级）

如果你们的 AA 账户支持自定义逻辑，可以在 UserOperation 验证阶段检查冻结状态。

**示例**：在 `src/lib/kite-aa.ts` 的 `sendErc20ViaAA` 中：

```typescript
// 在发送 UserOperation 之前检查
const freezeContract = new ethers.Contract(
  '0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719',
  ['function isFrozen(address) view returns (bool)'],
  new ethers.JsonRpcProvider('https://rpc-testnet.gokite.ai/')
);

const accountFrozen = await freezeContract.isFrozen(accountAddress);
if (accountFrozen) {
  throw new Error('[AA] AA 账户已被冻结，无法发起支付');
}

// 继续原有的 sendUserOperation 逻辑...
```

---

## 📋 合约 ABI（供集成使用）

### SimpleFreeze ABI（最小版本）

```json
[
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "freeze",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "unfreeze",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "isFrozen",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
]
```

**完整 ABI**：见 `contracts/SimpleFreeze.sol`，编译后可获取。

---

### SimpleMultiSig ABI（关键函数）

```json
[
  {
    "inputs": [
      {"internalType": "address", "name": "_to", "type": "address"},
      {"internalType": "uint256", "name": "_value", "type": "uint256"},
      {"internalType": "bytes", "name": "_data", "type": "bytes"}
    ],
    "name": "submitAndConfirm",
    "outputs": [{"internalType": "uint256", "name": "txId", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "_txId", "type": "uint256"}],
    "name": "confirmTransaction",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "_txId", "type": "uint256"}],
    "name": "executeTransaction",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "_txId", "type": "uint256"}],
    "name": "getTransaction",
    "outputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"},
      {"internalType": "bool", "name": "executed", "type": "bool"},
      {"internalType": "uint256", "name": "numConfirmations", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
```

**完整 ABI**：见 `contracts/SimpleMultiSig.sol`，编译后可获取。

---

## 🔍 验证示例

### 使用 ethers.js 查询冻结状态

```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider('https://rpc-testnet.gokite.ai/');
const freezeContract = new ethers.Contract(
  '0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719',
  ['function isFrozen(address) view returns (bool)'],
  provider
);

// 查询某个地址是否被冻结
const address = '0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9';
const isFrozen = await freezeContract.isFrozen(address);
console.log(`地址 ${address} 冻结状态: ${isFrozen}`);
// 输出: 地址 0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9 冻结状态: true
```

---

## 📚 参考文档

### 角色 A 提供的文档

- **合约源码**: `contracts/SimpleMultiSig.sol`, `contracts/SimpleFreeze.sol`
- **配置详情**: `docs/multisig/multisig_config.md`
- **交易记录**: `docs/multisig/tx_links.md`
- **部署指南**: `docs/multisig/部署指南_方案B.md`
- **完成总结**: `docs/multisig/完成总结.md`

### Kite 官方文档

- **Kite 测试网浏览器**: `https://testnet.kitescan.ai/`
- **RPC URL**: `https://rpc-testnet.gokite.ai/`
- **Chain ID**: `2368`

---

## ⚙️ 环境变量建议（可选）

如果要在 `.env` 中添加冻结合约配置：

```bash
# 冻结合约配置（可选）
FREEZE_CONTRACT_ADDRESS=0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719
CHECK_FREEZE_STATUS=true  # 是否在支付前检查冻结状态
```

然后在 `src/lib/config.ts` 中添加验证：

```typescript
export const EnvSchema = z.object({
  // 原有字段...
  
  // 新增（可选）
  FREEZE_CONTRACT_ADDRESS: z.string().optional(),
  CHECK_FREEZE_STATUS: z.string().optional().transform(val => val === 'true')
});
```

---

## 🎯 建议的使用场景

### 场景 1：演示"冻结拦截支付"

1. 在 `demo:pay` 执行前，先调用 `freezeContract.isFrozen(recipient)`
2. 如果返回 `true`，打印日志并拒绝支付
3. 演示时展示：
   - 正常支付成功 ✅
   - 多签冻结地址（Tx Hash）
   - 再次尝试支付 → 被拦截 ❌
   - 多签解冻地址
   - 支付恢复正常 ✅

### 场景 2：集成到策略检查

在 `evaluatePolicy` 中作为最后一道检查：

```
白名单检查 → 限额检查 → 每日限额 → 冻结状态检查 → 允许/拒绝
```

### 场景 3：仅用于文档说明

如果时间不够，只需在：
- `for_judge.md` 中说明多签冻结功能 ✅（已完成）
- 演示 PPT 中展示冻结 Tx Hash
- 演示视频中展示浏览器验证

---

## 💬 联系方式

如有问题或需要更多信息，请联系：

- **角色 A (huahua)**: [你的联系方式]
- **文档位置**: `docs/multisig/`
- **合约代码**: `contracts/`

---

## ✅ 交付清单

- [x] 多签合约地址和 ABI
- [x] 冻结合约地址和 ABI
- [x] Owner 地址列表
- [x] 集成方案建议（3 种）
- [x] 验证示例代码
- [x] 参考文档链接
- [x] 环境变量建议
- [x] 使用场景说明

---

**祝集成顺利！如有疑问随时沟通。**

---

**最后更新**: 2026-01-30
