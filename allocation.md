项目分工（链上 / 后端 / 前端(可选) / 新人辅助）

> 说明：当前仓库的 MVP 以 **CLI Demo + 文档证据** 为主（不强依赖网页前端）。如果你们要做网页演示，可把“角色 C”升级为前端负责人即可；同时建议安排 1 位新人做 PPT/视频素材产出，提升呈现效果与评委理解速度。

---

角色 A：链上（合约/多签）

- 负责内容：
  - Kite 多签钱包（Ash Wallet）创建/配置（2/3 或 3/5）与操作流程
  - （可选）策略合约/Guard 合约：冻结/解冻/策略更新的权限边界
  - 链上部署、合约地址、浏览器证据收集
- **交付给 C 的内容**：
  - 多签钱包地址（供 `for_judge.md` 作证据）
  - 成员清单与阈值配置（截图/Tx链接）
  - 冻结操作 Tx Hash：`0xTODO_FREEZE_TX_HASH`（用于演示"高风险事件 → 多签介入"）
  - 解冻操作 Tx Hash：`0xTODO_UNFREEZE_TX_HASH`（用于演示"风险恢复"）
- **交付给 B 的内容**：
  - 多签地址（如B需要在 AA 流程中调用多签冻结接口）
  - 冻结/解冻/策略更新的合约ABI与函数签名

---

角色 B：后端（支付执行/AA 集成/链上交互）--Sulla

- 负责内容：
  - Kite AA SDK（`gokite-aa-sdk`）集成：`PAYMENT_MODE=aa` 跑通 userOp
  - 稳定币支付执行（测试网转账）跑通并产出 tx hash（`PAYMENT_MODE=eoa` 或 `aa` 均可）
  - （如需要网页/服务）提供最小 API：`POST /pay`、`POST /policy/validate`（可选）
- **已交付给 C 的内容**：
  - ✅ `src/lib/kite-aa.ts` (104 行) - 完整的 ERC-4337 UserOperation 支付流程
  - ✅ `src/lib/policy.ts` - 权限规则引擎（白名单/单笔上限/日限额）
  - ✅ `pnpm demo:pay` - 正常支付演示脚本（输出：通过策略校验）
  - ✅ `pnpm demo:reject` - 异常拒绝演示脚本（输出：NOT_IN_ALLOWLIST）
  - ✅ `src/demo-pay.ts` + `src/demo-reject.ts` 源码（供截图讲解）
  - ✅ `.env.example` - 环境变量占位符清单
  - ✅ `pnpm typecheck` 通过（0 errors）
- **需要 A 补充的内容**：
  - 多签地址与冻结/解冻 Tx Hash（用于完整演示风控链路）
- **C 需要用来填充 for_judge.md 的内容**：
  - B 的支付 Tx Hash（`EXECUTE_ONCHAIN=1 pnpm demo:pay` 后得到）
  - A 的冻结 Tx Hash

---

角色 C：前端 / 体验与可复现（默认：演示与工程整合）

- 负责内容（无网页时）：
  - 策略/风控逻辑（白名单/单笔上限/日限额）与拒绝路径：`pnpm demo:reject`
  - README 一键复现、录屏脚本、截图证据整理
  - `for_judge.md`：把 tx hash/证据路径填满，保证评委 1 分钟能判定达标
- 负责内容（有网页时，可选升级）：
  - 做一个最小 Web UI：配置策略 → 发起支付 → 展示 tx hash / 拒绝原因
- **已获得的交付物**：
  - ✅ 来自 B：`pnpm demo:pay` / `pnpm demo:reject` 脚本 + 源码
  - ✅ 来自 B：`src/lib/policy.ts` 权限规则
  - ✅ 待补充自 A：冻结 Tx Hash
  - ✅ 待补充自 B：支付 Tx Hash（EXECUTE_ONCHAIN=1 后）
- **需要完成的**：
  - 填充 `for_judge.md` 第一个表格（赛道要求对照）：
    - 链上支付 → Tx Hash：`0xTODO_PAYMENT_TX_HASH`（来自 B）
    - Agent 身份 → Kite AA SDK 集成说明
    - 权限控制 → 拒绝案例截图 + 冻结 Tx Hash（来自 A）
    - 可复现性 → `pnpm demo:pay/reject` 命令
  - 制作演示视频或截图（5 分钟流程：代码 → 正常 → 拒绝 → 证据表）
  - 列出所有 Tx Hash 和证据路径供 D（PPT/视频）使用

---

## 📦 交接总表（关键证据）

| 证据项 | 来源 | 接收方 | 用途 | 状态 |
|:---|:---|:---|:---|:---|
| 支付 Tx Hash | B（支付执行） | C | 填充 for_judge.md 第一行 | 待 EXECUTE_ONCHAIN=1 |
| 冻结 Tx Hash | A（多签操作） | C | 填充 for_judge.md 权限控制行 | 待交付 |
| 代码实现 | B | C/D | 截图讲解 + PPT | ✅ 已交付 |
| 权限规则 | B | C | 拒绝演示证据 | ✅ 已交付 |
| 多签地址 | A | B/C | 权限管理入口 + 证据 | 待交付 |

---

接口约定（避免互相阻塞）

- B → A：多签/合约的操作接口与权限说明（冻结/解冻/策略更新的具体入口）
- A → B/C：链 ID、合约/多签地址、ABI、成员地址与阈值（用于展示/集成）
- C → B：策略配置格式（JSON/TS/ENV）与错误码规范（用于前端/日志/演示一致）

---

角色 D：运营（PPT/视频剪辑/视觉与素材整理）

> 目标：把“技术成果”变成“评委一眼能看懂的呈现”

- 负责内容：
  - PPT 设计与排版（封面/目录/架构图/流程图/亮点页/对照表页）
  - Demo 视频剪辑（1-3 分钟版本 + 10-30 秒高能版本），加字幕/高亮
  - 证据材料整理：tx hash、截图、日志输出、链接汇总到 `docs/`（或统一文档）
  - 现场演示“讲稿”与时间轴（每一步该说什么、该切哪个画面）
- 交付物（可验收）：
  - `pitch_deck.pdf`（或 `pptx`）一份：10-12 页（问题/方案/MVP/对齐 Kite/ demo/证据/路线图）
  - `demo_video.mp4`：1-3 分钟（含字幕与关键画面标注）
  - “证据索引页”：一页表格列出所有 tx hash、合约/多签地址、文档链接与截图位置