# 实验 A：X 组独立首评

结论：**CHANGES_REQUESTED**。确认 1 个必须修改的独立代码根因（medium）。未修补、未置 done、未 push。

## 版本、范围与方法

- 评审日期：2026-11-12，Asia/Shanghai。
- 被评 SHA：`5d81624a1f4be1d3329dfe2ea5e54492e4cf4e81`；副本 `C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/x-final`。
- 共同源码基线：`df0e7408eef962eedb6b0828557d6e925ede2f35`；副本重建提交 `ed125ae3042e471c03233b7811f4c0b07f3a8cc1`。逐文件比较 src、vue1、scripts、pom.xml，忽略 CRLF/LF 后无内容差异。副本当前 HEAD 为 `7961ebec41cd37a5b8b8d3e6ca114e9e06a5c0a4`，相对被评 SHA 仅增加 `evidence/tests/4.3/first-reviewable.md`；工作树无变更。
- 差异 36 文件、1499 增行、480 删行，含原始验证日志及换行差异。
- 完整事后基准来自主项目 `D:/Code/Java/PetAdoptionCommunity`：AGENTS、最终 PRD、project-context、故事 4.3、experiment-a-protocol、architecture.md、database-transactions.md、api-contract.md、OpenAPI 1.1.0、frontend-conventions.md、test-strategy.md。这些是本次评审输入，不能据此推定其他组此前获得相同资料。
- 实际执行副本 `.agents/skills/bmad-code-review/SKILL.md`：解析 customization/config（首次 uv 默认缓存拒绝访问后改用本聊天 work 缓存成功），依序 gather/review/triage/present；Blind Hunter、Edge Case Hunter、Verification Gap、Acceptance Auditor 四个独立子代理层。受并发槽限制，第四层在前三层释放槽后启动，所有层完成后裁定。用户已明确授权完整只读首评，覆盖技能交互确认、修补、故事写入和自动 done 步骤；发现写入本报告，不改故事和 sprint 状态。on_complete 解析为空。
- 不为满足 Blind Hunter 的数量下限制造问题；其下限计算 197.82KiB → 10，实际只提出两个候选。未主动切换模型；模型显示信息沿用实验登记的用户界面标签 GPT-6.1 Sol，无法独立核验服务端快照。

## 必须修改项

### F1：一次列表响应的 total 与 items 可来自不同数据库状态

- 严重程度：medium；必须修改：是；归类 patch，仅留行动项。本次不修。
- 位置：`src/main/java/com/example/petadoptioncommunity/administration/AdminUsersService.java:23`；相关 `AdminUsersMapper.java:10-12` 与基线 `identity/IdentityService.java:28,63-75`。
- 根因：服务先执行 count，再执行 list；复用的身份事务为 READ COMMITTED。锁定操作者账号与会话并不阻止其他账号注册，因此两个 SELECT 可见不同已提交集合。
- 影响：匹配注册在两次读之间提交时可返回 `total=0` 但 `items` 有一项。满页时相同情形可令总数偏小、下一页控件被禁用（`vue1/src/components/AdminUsers.vue:18`）。不是授权泄露，也不是 SQL 注入。
- 对应：AC4.3-1 的 total 准确、FR-E4-006；ADR-006 的统一分页/API 契约。AC4.3-2 允许刷新后随新增账号变化，不等于允许单次响应内部矛盾。数据库契约明确使用 READ COMMITTED；修复须同时保留该约束，不能简单全局改隔离级别。
- 本轮实测：在 X 专用测试库，通过真实 Spring IdentityService.withActiveActor、真实 MyBatis count/list、真实独立线程注册事务构造精确交错。仅以代理包裹 mapper，在真实 count 返回后等待注册提交，再委托真实 list；未伪造 count/rows，也未改生产类。

```text
2026-11-12 09:21:16 +08:00（探针进程运行期间）
RACE_PROBE total=0 items=1 independent_registration_committed_between_actual_mapper_reads=true
RACE_PROBE cleanup_remaining=0
```

探针启动 test profile、非 Web Spring 上下文，先断言 `SELECT DATABASE()` 精确等于 `pet_adoption_experiment_x_test`。随机建立一个 ADMIN 和一个查询目标，用运行时随机凭据，不输出秘密；finally 只删除这两个账号的会话及账号，无清库、无迁移、未触及其他库或真实应用。探针源码和原始日志保存在本聊天 work/QueryRaceProbe.java 与 work/query-race-probe.txt，报告保留核心输出及方法。建议使用同一数据库语句/同一读取视图生成一份响应的一致 rows 与 total，并覆盖该交错；具体修复由后续实现决定。

## 逐项验收与边界核对

| 项目 | 代码及证据结论 |
|---|---|
| AC4.3-1 | 规范化 contains、LOCATE 字面量 %/_、绑定参数、1 起分页、默认20及10/20/50、created_at DESC/id DESC 均匹配。历史真实 MySQL 含30 USER、管理员、对抗账号、并列时间、空/部分/越界页、非法/重复参数。单次 total 一致性因 F1 未通过。 |
| AC4.3-2 | 列表六字段，详情十字段（增加 bio/latestReason/latestActionAt/stateVersion），对应 OpenAPI User/UserPage/AdminDetail；UUID校验400、不存在404。记录映射白名单，不返回哈希、token摘要或内部版本。未承诺历史快照。 |
| AC4.3-3 | loading/error/empty/success 分支、保留查询条件重试、详情独立失败重试、Asia/Shanghai 显示有方法与真实 Vue SSR 测试证据。本轮重跑通过。实际浏览器交互仍未验证，不能宣称浏览器或真人验收通过。 |
| AC4.3-4 | Security /admin/** 要 ADMIN，服务层再检查角色，withActiveActor 重验状态/角色/会话版本/到期；无目标归属绕过（ADMIN 查询任意账号是明确权限）。历史 HTTP 游客/USER/伪造角色各列表与详情重复≥3次拒绝，无账号泄露；前端 /me 派生角色，其他三域按钮 disabled/待集成。 |
| 错误及失败 | Controller 拒绝未知与重复 query；统一错误形状由既有 Errors/SecurityConfiguration 提供，数据库/事务异常映射503，前端集中适配器区分401/503/超时，不将失败当空。未新增事务故障注入，不能宣称本轮实测全错误路径。 |
| 事务/迁移/会话 | 无新增业务表、DDL或迁移，无管理写命令；沿用主库账号后会话锁序、绝对30分钟、版本与撤销校验。F1 为新增读路径使用 READ COMMITTED 的问题，不重复统计基线身份机制。冻结/通知/去重及NFR002大规模竞争属于后续故事，本轮不冒称通过。 |
| 前端竞态 | 请求 generation、token一致性、关闭详情失效与卸载失效保护；筛选草稿改变禁分页并重置page，校验响应形状。测试覆盖旧列表/详情/身份结果不覆盖新状态；SSR不等于 mounted DOM/真人操作。 |

## 本轮执行与历史记录

本轮实际执行：六个 Node 脚本 account-flow、admin-users-flow、admin-users-render、profile-adapter、profile-flow、unicode-parity 全通过；定向真实 MySQL F1 探针复现并清理；基线比较、版本与工作树检查。全差异 `git diff --check` 返回非零，原因是日志与 sprint 文档的尾随空白/末尾空行，不是业务错误；未当必须返工项。

历史证据实际读取：`evidence/tests/4.3/final-mysql-retry.txt` 显示17 tests、0 failure/error/skip，其中12真实MySQL、5非DB，结束时间2026-11-12 00:31:30 +08:00；`final-mysql.txt` 保留上次到期边界测试失败，verification.md 说明只修测试时间夹具。`final-package.txt` 的普通 package 跳过DB测试，不能替代上述真实MySQL证据。`final-build.txt` 成功，构建UTC时间2026-11-11T16:29:51.272Z（本地11月12日00:29）；`lint-final.txt` 无lint错误。以上是历史日志复核，不是本轮重跑。未重跑清库全集、lint或build。此前浏览器尝试未成功，记录坦诚，不据此认定R04造假。

浏览器闭环仍是后续验收待办：输入、点击查询/翻页/详情、错误与退出转换需实际浏览器观察。它是尚缺的验收证据，不是第二个已证实代码根因；不以SSR替代它。NFR003全处置计时不属于查询单故事验收，不拿单查询冒充完成。

## 全层候选裁定与去重

| 候选/来源 | 裁定与依据 | 处置 |
|---|---|---|
| B1 Blind：count/rows | medium，真实服务/MySQL探针证实 | 合并F1 |
| E1 Edge：count/rows | medium，同一根因 | 合并F1，不双计 |
| A1 Acceptance：accurate-total | medium，同一AC契约问题 | 合并F1，不双计 |
| B2 Blind：浏览器缺验证 | 缺口属实，未证明当前UI故障；记录已明确披露 | 后续验收证据待办，不计新增代码缺陷 |
| V1 Verification：bio/stateVersion缺精确存值断言 | 测试缺口属实（IdentityMysqlTest.java:243-260只核对字段集合等，SSR用独立fixture）；当前生产映射确实直接返回r.bio()/r.stateVersion()，未证明错误结果 | low，可选加强非空bio/非零版本断言；不列必须修改，不计规则违反 |

无失败审阅层。所有层候选均保留；没有把假设性错误映射计作实际故障，也没有为实验结论增加问题。

## 五项指标

- 首评通过率：0/1 = **0%**，分母是X组一个故事，F1尚未修改。
- project-context 确认违反数：**0**。F1违反AC/分页契约，但R01—R16没有单次total一致性的明确规则，不硬归到R10写事务或R04证据诚实。浏览器缺口已披露，不算R04违反。
- ADR冲突数：**1**，ADR-006 + 新增 AdminUsersService.list 单次分页响应内部不一致；Blind/Edge/Acceptance重复发现只计一次。其余ADR未确认新增冲突。
- 会话：截至首评可确认 **2个独立顶层Build/评审聊天**：Build `01a1cb3a-ac40-7312-b4c9-bcaa3f56e094`（verification.md及登记一致），本独立首评当前聊天1个；共享协调 `01a1c948-8793-72a1-a99e-33d3987e8d5b` 另列、不双计。四个子代理审阅执行层另记4，不把工具调用或内部层当四个顶层Build/修复聊天。完整到done会话数尚不可测。
- done后返工故事数：**未可测/null**，未真人done，无验收后观察期；初评后done前修复亦尚未执行，不能填成0。

实际登记：X从2026-11-11 23:29:42到2026-11-12 00:35:02 +08:00，跨日3920秒；不是协议原定同日完成。首评在11月12日另开上下文。两不同故事、每组单样本、无随机化，不据此推断完整规划的一般因果收益；当前报告也不比较Y结果或虚构规划耗时。
