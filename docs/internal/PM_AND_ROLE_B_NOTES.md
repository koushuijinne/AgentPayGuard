# 项目管理 & 角色 B 注意事项（子模块与新增文件检测）

> 基于对当前仓库的再次扫描（含子模块 `frontend`），整理项目管理者和角色 B 需要关注的点。

---

## 一、新增/变化内容速览

### 1. 子模块 `frontend`

| 项目 | 内容 |
|------|------|
| **来源** | `.gitmodules` → `path=frontend`, `url=https://github.com/yoona333/hacker-hackathon-hub.git` |
| **技术栈** | Vite + React 18 + TypeScript + Tailwind + shadcn-ui + Framer Motion + Reown AppKit + wagmi + viem |
| **页面** | Index, Dashboard, Freeze, Proposals, History；钱包连接、多签/冻结展示 |
| **合约配置** | `frontend/src/lib/web3/config.ts` 已写死多签 `0xA247e042cAE22F0CDab2a197d4c194AfC26CeECA`、冻结合约 `0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719`（与角色 A 交付一致） |
| **构建/运行** | 子模块内用 **npm**（`npm i` / `npm run dev`），与根目录 **pnpm** 独立；README 指向 Lovable 编辑/发布 |

### 2. 前端配置与主仓不一致（需修正）

| 配置项 | 前端当前值 | 主仓 / Kite 官方 |
|--------|------------|------------------|
| **RPC URL** | `https://rpc.kite.testnet` | `https://rpc-testnet.gokite.ai/` |
| **区块浏览器** | `https://explorer.kite.testnet` | `https://testnet.kitescan.ai/` |

**影响**：前端连错 RPC/浏览器会导致 Kite 测试网钱包、交易链接不可用。  
**建议**：在 `frontend/src/lib/web3/config.ts` 中把 RPC 与 blockExplorers 改为上述官方地址。

### 3. 根仓与文档结构（无子模块部分）

- 根仓：`src/`（demo-pay、demo-reject、demo-ai-agent、test-freeze）、`contracts/`、`docs/`、`python/`；依赖 pnpm。
- 文档：`docs/reference/allocation.md`、`docs/internal/FINAL_DELIVERY_CHECKLIST.md`、`docs/multisig/交付给角色B.md`、各角色指南与 TESTING_GUIDE 等。
- 约束：`.clinerules` 内含安全、工作流、代码质量、自检清单等，**禁止读 `.env*`**，要求每次 Phase 更新 `docs/internal/AGENT_WORKLOG.md`。

---

## 二、项目管理者需要注意的

### 1. 子模块克隆与更新

- **首次克隆主仓**：若未 `git submodule update --init --recursive`，`frontend/` 目录会是空的。
- **日常更新**：子模块更新需在主仓根目录执行：
  - `git submodule update --remote frontend`（拉取子模块远程最新）
  - 然后进 `frontend/` 提交并推送到子模块仓库，再回主仓提交新的 submodule 指针。
- **协作**：确保所有成员都执行过 `git submodule update --init --recursive`，避免前端目录为空或版本不一致。

### 2. 前端 RPC / 浏览器地址

- 安排角色 C（或负责人）修正 `frontend/src/lib/web3/config.ts` 中的 RPC 与 blockExplorers 为 Kite 测试网官方地址（见上表），并与主仓 `.env.example` / 文档中的 RPC、浏览器链接保持一致。

### 3. 前后端接口约定

- 当前前端通过 **wagmi/viem + 钱包** 直接与链交互，**没有**调用主仓后端的 HTTP API。
- 若后续需要「前端表单 → 后端发起支付」：需明确 **B 提供的最小 API**（如 `POST /pay`、`POST /policy/validate`）及请求/响应格式，并在 `docs/reference/allocation.md` 或单独接口文档中写清，避免 C 与 B 理解不一致。

### 4. 子模块仓库归属与权限

- 子模块指向 `yoona333/hacker-hackathon-hub`，主仓提交只记录 **submodule 的 commit 指针**。
- 确认：谁有权限改子模块仓库、谁负责合并/发布；主仓与子模块的发布节奏（例如评审前锁定子模块指针，避免现场演示时前端版本漂移）。

### 5. 交付与检查清单

- 继续以 `docs/internal/FINAL_DELIVERY_CHECKLIST.md` 为总表，督促 A/B 的 Tx Hash 与 C 的 for_judge 填充、D 的 PPT/视频；子模块相关可加一条：「前端 RPC/浏览器已改为 Kite 测试网官方，且已验证连接/交易链接」。

---

## 三、角色 B 需要注意的

### 1. 必须完成（阻塞 C）

- **EOA 真实支付**：`PAYMENT_MODE=eoa`、`EXECUTE_ONCHAIN=1`，跑通 `pnpm demo:pay`，拿到 **EOA Tx Hash** 和 Kite 浏览器链接，交给 C 填 `for_judge.md`。
- **AA 真实支付**：`PAYMENT_MODE=aa`、`EXECUTE_ONCHAIN=1`，配置正确 `BUNDLER_URL`（如 `https://bundler-service.staging.gokite.ai/rpc/`），跑通 `pnpm demo:pay`，拿到 **AA Tx Hash**（或 UserOp 对应的 settlement tx）和浏览器链接，交给 C。
- 根仓环境变量：与 `docs/guides/TESTING_GUIDE.md` 一致（如 `KITE_RPC_URL`、`KITE_SETTLEMENT_TOKEN`、`OWNER_PRIVATE_KEY` 等）；若主仓 `.env.example` 仍用 `RPC_URL`/`SETTLEMENT_TOKEN_ADDRESS`，建议在文档中注明与 TESTING_GUIDE 的对应关系，避免混淆。

### 2. 与前端子模块的关系

- 前端当前**不依赖**后端 API，而是用 Reown AppKit + wagmi 直连链。B **不必须**为前端提供 HTTP 接口，除非 PM 明确要求「从网页发起支付由后端执行」。
- 若后续要做「前端调后端支付」：B 需提供最小 API（如 `POST /pay`）及错误码/策略拒绝原因格式，便于前端展示；接口约定建议写在 `docs/reference/allocation.md` 或 `docs/guides/` 下。

### 3. 冻结检查与 A 的交付

- 主仓已支持：`evaluatePolicy` 可传 `provider` + `freezeContractAddress`（`0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719`），拒绝码 `RECIPIENT_FROZEN`；`pnpm demo:freeze` 可验证链上冻结拦截。
- B 可选：在 `demo-pay` 中默认传入冻结合约地址（或通过 `.env` 的 `FREEZE_CONTRACT_ADDRESS` / `CHECK_FREEZE_STATUS`），使「支付前查冻结」成为演示一部分；实现方式见 `docs/multisig/交付给角色B.md` 方案 1。

### 4. 自检与日志

- 每次完成 EOA/AA 链上执行后：
  - 跑一遍 `pnpm typecheck`、`pnpm demo:pay`、`pnpm demo:reject`（必要时 `pnpm demo:freeze`），确保无退化。
  - 在 `docs/internal/AGENT_WORKLOG.md` 末尾追加一条：Phase 13（或当前 Phase）— Role B 完成 EOA/AA 链上执行，并注明已交付给 C 的 Tx Hash/链接或占位更新情况。

### 5. 安全与约束

- 遵守 `.clinerules`：不提交未通过 `pnpm typecheck` / demo 脚本的代码；不读、不提交 `.env*`；新环境变量需在 `.env.example` 中占位并同步文档（如 TESTING_GUIDE）。

---

## 四、快速检查清单

**项目管理者**

- [ ] 新成员克隆后执行 `git submodule update --init --recursive`，确认 `frontend/` 有内容。
- [ ] 前端 RPC / 浏览器地址已改为 Kite 测试网官方，并在文档或 CHECKLIST 中记录。
- [ ] 前后端若有 API 需求，接口约定已写在 allocation 或单独文档。
- [ ] 子模块仓库权限与发布节奏已明确。

**角色 B**

- [ ] EOA Tx Hash 已产出并交付 C。
- [ ] AA Tx Hash 已产出并交付 C。
- [ ] 环境变量与 TESTING_GUIDE / .env.example 一致，无遗漏。
- [ ] 若启用冻结检查，`FREEZE_CONTRACT_ADDRESS` 与 A 交付一致，且 demo:freeze 或 demo:pay 验证通过。
- [ ] AGENT_WORKLOG 已更新 Phase 13（或当前 Phase）。

---

**文档版本**：1.0  
**生成依据**：对主仓及子模块 `frontend` 的再次检测（目录、.gitmodules、frontend 配置与合约地址、allocation、FINAL_DELIVERY_CHECKLIST、交付给角色B、.clinerules）。
