# 实验 A 输入清单

> **2026-11-08 变更：** 用户接受无法保证严格隔离，按作业简化。下文保留原白名单及禁止内容作为减少污染的目标；不同目录和不继承聊天的会话仅用于减少直接混入，并不阻断其他路径或自动注入，不能当作严格隔离证明。执行前记录候选文件哈希与拟发送任务；真实投递和偏差后续补记。

状态：候选包已制备，清单和验证记录位于 `preparation/`；简化输入已复制并记录哈希，实际投递待记录。当前环境未强制限制对其他目录的访问，不证明实施者无法读取其他内容。

## X 白名单

X 获得当前完整有效规划及 Story 1.5 任务；下列为明确的规划来源，不使用目录通配复制：

- `_bmad-output/specs/spec-pet-mall-bmad/SPEC.md`
- `_bmad-output/planning-artifacts/prds/prd-pet-mall-bmad-2026-11-05/prd.md`
- `_bmad-output/planning-artifacts/architecture/architecture-pet-mall-bmad-2026-11-06/ARCHITECTURE-SPINE.md`
- `_bmad-output/planning-artifacts/ux-designs/ux-pet-mall-bmad-2026-11-06/DESIGN.md`
- `_bmad-output/planning-artifacts/ux-designs/ux-pet-mall-bmad-2026-11-06/EXPERIENCE.md`
- `_bmad-output/planning-artifacts/ux-designs/ux-pet-mall-bmad-2026-11-06/mockups/key-home.html`
- `_bmad-output/planning-artifacts/ux-designs/ux-pet-mall-bmad-2026-11-06/mockups/key-cart.html`
- `_bmad-output/planning-artifacts/ux-designs/ux-pet-mall-bmad-2026-11-06/mockups/key-checkout.html`
- `_bmad-output/planning-artifacts/epics.md`（含完整 Story 1.5 与依赖）

候选包含任务提示草案、项目规则转录、启动说明和依赖锁定；逐文件清单及前置来源见候选清单。首轮提示已发送并保留原文，自动注入和实际访问范围未独立核验。历史简报不覆盖当前 PRD/SPEC。

X 禁止：`experiments/A/review-rubric.md`、本协议/隔离记录/冻结控制文件、规划目录 `reviews/` 及各类 `review-rubric.md`/评审报告、Y 实现/测试/会话、旧商城实现或开发历史。完整规划指需求、架构、UX、故事及项目规则，不包含评审者评分材料。

## Y 白名单

以下为Y包内逻辑路径；简化执行已发送任务提示并记录输入文件，实际可访问范围未受严格限制：

| 包内路径 | 允许内容 | 边界 |
| --- | --- | --- |
| `task.md` | Story 2.1 的用户业务需求和 AC-2.1-1—4 的全部可观察行为 | 独立转录；保留不透明 ID/版本、400、409 RUN_CHANGED、无重放、非空校验、隐私和 UX 行为，不含来源/ADR/架构路径或评分细则 |
| `README.md` | 安装、启动、检查命令及固定夹具使用方式 | 仅运行所必需，不链接源工程或规划 |
| 共同骨架逐文件列表 | 见候选清单共同文件 | 包内确切路径、字节数和 SHA-256 须在冻结清单列出 |
| 独立夹具逐文件列表 | 固定商品、购物车、报价响应与只读测试入口说明 | 来源独立于 X，不含购物车/优惠计算算法或 X 测试 |
| 实际首轮提示（单独留证） | 指定 `task.md` 与本包边界 | 提示及附加消息均需留存，不自动注入全局记忆/技能/历史 |

Y 的业务需求须逐条映射四项 AC，组织者保留映射表在包外；不得为了避开规划泄漏而删掉实际业务验收条件。固定夹具提供有可结算商品、无可结算商品、报价失败的预置场景；运行身份由共同最小运行设施提供，允许重启验证 RUN_CHANGED。夹具不实现动态购物车修改、满减计算、地址保存/编辑/选择或订单/付款。

Y 禁止：`_bmad-output/`、`_bmad/`、`.agents/`、`.codex/`、`.git/`、`experiments/`、`docs/`、本仓库 README/decision-log、任何规划/ADR/设计稿/评分表、X 源码及测试/记录、旧商城、当前聊天及继承上下文、自动加载的项目/全局记忆、可以检索上述内容的连接器与工具。允许包中的 README 是新生成的运行说明，不是本仓库 README。

## 共同最小骨架与前置边界

共同骨架限于可运行 Vue/TypeScript 前端、Express 服务空入口、依赖及锁文件、构建/类型检查/启动脚本、最小运行身份和传输边界、无业务的测试启动设施。必要共享接口只暴露调用夹具/运行所需的形状，不携带完整领域模型、设计理由或架构答案。两组共同文件须逐字节同哈希；任何组间差异单列原因。

共同骨架不得含购物车合并/修改/删除/勾选/金额计算、地址持久化/版本变更/校验逻辑、订单及付款，被测功能的测试/断言或参考实现。X 的 Story 1.4 商品浏览前置和 Y 的只读固定夹具不是相同代码，须分别审查并披露，不能用“共同骨架”掩盖差异。候选包在临时副本运行的证据见 `preparation/verification.md`，不能据此宣称实际受限环境可运行。

## 冻结与实际输入登记

1. 骨架准备者记录来源、命令与结果；检查无被测实现及答案。验证 Y 固定夹具能独立运行、断开 X 目录后仍可用。
2. 将允许文件逐一展开成实际包清单（相对路径、大小、SHA-256、用途、来源）；检查隐藏文件、软链接/junction、源码映射、缓存及日志，不仅检查可见文件名。
3. 记录 X/Y 包的绝对根目录、初始提示、自动注入提示和后续消息的原文及 SHA-256；记录工具清单和真实文件系统可见边界。输入包文件及运行证据不放到 Y 可见的源工程中。
4. 按 isolation-record 完成禁止目录访问探测、历史/连接器核验；控制记录与 rubric 单独保管并哈希，永不发送实施者。
5. freeze-manifest 记录以上实际路径与摘要。尚未制备的文件用缺项表达，不能以空列表或设计文档哈希冒充输入包已冻结。冻结后改动必须留旧哈希、变更时间、原因、受影响运行及重冻记录。
