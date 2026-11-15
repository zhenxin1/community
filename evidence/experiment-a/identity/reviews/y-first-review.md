# 实验 A · Y 组独立首评

结论：**CHANGES_REQUESTED**。被评 SHA `0a6dd61e011ec6257f5322e3dc55db7d4c954acf`；副本基线 `9380032975644450aced41676ec74c31ef963242`（共同源码 `df0e7408eef962eedb6b0828557d6e925ede2f35` 的 snapshot）。18 文件，+337/-25。首轮通过率 **0/1 = 0%**。只读评审，不修补、不置 done、不 push。

## 范围与流程

被评目录：C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/y-final。完整标准从 D:/Code/Java/PetAdoptionCommunity 读取：AGENTS.md、最终 prd.md、architecture.md、database-transactions.md、api-contract.md、OpenAPI 1.1.0、frontend-conventions.md、test-strategy.md、project-context.md、experiment-a-protocol.md、story 4.4。这些是事后评审输入，不是 Y 实施输入。

执行副本 bmad-code-review 技能：解析 customization/config，按 gather-context → review → triage → present 阅读；默认无 prepend/append/persistent facts，无团队覆盖。uv 首次缓存权限失败，使用本评审工作目录缓存后解析成功。项目负责人，中文输出；full 模式。既有授权覆盖目标、完整评审及只读报告，因此不重复等待 checkpoint，不执行技能的修补、故事状态和 sprint 写入步骤。四层为 Blind Hunter、Edge Case Hunter、Verification Gap、Acceptance Auditor；子代理沿用当前默认模型配置，不主动切模型。发现配额不作为制造缺陷依据。

## 必须修改项（按独立根因归并）

路径均相对被评目录。high/medium 为本评审影响等级，并不把契约差异自动称为安全漏洞。

| ID | 等级/必须修 | 位置 | 影响与证据 | 对应标准 |
|---|---|---|---|---|
| F1 | high / 是 | src/main/java/com/example/petadoptioncommunity/web/NotificationsController.java:13-15；vue1/src/components/MyNotifications.vue:33 | 列表只有 unread=true/false，忽略 page/size/filter，SQL 无 LIMIT，返回裸数组；页面无分页。契约调用 filter=UNREAD 会得到全部通知，默认不限制20条，非法分页也不拒绝，NotificationPage 的 items/page/size/total 不存在。分页、筛选和分页信封作为同一列表协议根因归并。 | AC4.4-1，FR010，ADR-006 |
| F2 | high / 是 | NotificationsController.java:19；MyNotifications.vue:54 | 只注册 POST 已读，约定 PUT 端点无对应 handler；合规客户端不能完成显式已读。现有 HTTP 测试也只请求 POST，不能证明 PUT 契约。 | AC4.4-2，OpenAPI /me/notifications/{notificationId}/read |
| F3 | medium / 是 | NotificationsController.java:19 | 方法不接收或检查 body，带非空 JSON 的 POST 仍进入写入并设置 readAt。全局 Security/Errors 没有空 body 守卫；与无 body 端点携非空 body 必须400且不修改相违。F2 改方法注解并不能修复这一输入校验缺失。 | AC4.4-2，api-contract 输入补充，ADR-006 字段白名单 |
| F4 | medium / 是 | NotificationsController.java:17 | owned 用 user_id+id 同时查询，别人已有通知和不存在均404；源码及 myNotificationsHttp 明确断言404。无泄露或越权变更证据；这是明确403/404错误语义不符，不能称为授权绕过。 | AC4.4-3，api-contract |
| F5 | high / 是 | NotificationsController.java:11-12；src/main/resources/db/migrations/V002_notifications.sql:3-5 | 返回 content 而非 body，缺 type、operationId；V002 也缺 recipient_id/body/type/operation_id/actor_id。与 OpenAPI Notification 必填字段及数据库通知模型不兼容，后续状态通知/人工通知无法直接按已批准共享契约接入。标题200/TEXT也是该自定义通知模型的一部分。不是因未实现未来发送功能扣分，而是当前公开读资源及新增表已偏离接口。 | AC4.4-1/2 的统一契约，ADR-006，database-transactions |
| F6 | medium / 是 | MyNotifications.vue:62 | uncertain 错误仅显示文字，不重新读确认 readAt。实测 timeout-probe：仅一次 POST，0 GET，detail.readAt 仍 null。响应丢失而服务器已提交时页面不能确认真实状态。重试幂等使风险有限，但未实现故事要求的超时读取确认。 | AC4.4-4 |
| F7 | medium / 是 | MyNotifications.vue:39-44,54-59 | 标记中重新打开同一条通知：GET先返回未读，POST后成功；detailGeneration 已变化，current() 为 false，列表更新已读而详情保留未读。本轮 race-probe 精确复现 listReadAt 有值、detailReadAt=null；只两请求。与切到另一条详情应保留另一条的场景不同。 | AC4.4-2/4，准确阅读状态 |
| F8 | medium / 是（验收证据） | src/test/java/com/example/petadoptioncommunity/IdentityMysqlTest.java:243-280 | 通知测试只有串行重复已读，无并发首次时间不变测试；跨用户读取和标记对 foreign 各一次，未达各≥3次；没有通知路径 FROZEN/旧 Actor 重验测试。既有身份锁测试不等于通知路径已验收。需补足本故事 MySQL 应用路径证据；不声称当前锁实现有缺陷。真实冻结交错按故事留4.5，不要求提前实现4.5。 | AC4.4-2/3，story 必需测试，NFR-E4-001 |

F3 的实际 HTTP 响应本轮未连接测试库重放，结论依据 Spring MVC 无 body 参数/约束的处理路径和无全局守卫的代码核验；不能把它描述为本轮数据库实测。F1/F2/F4/F5同样为代码及契约对照，已有历史测试仅证明它们当前自定义协议能工作。

## 可选改进与层间裁定

O1（low，非必须）：NotificationsController.java:12 使用 Instant.toString()，整秒会输出 `...00Z` 而非统一毫秒 `...00.000Z`。时间仍合法 RFC3339，无时间含义错误；ADR-006 固定毫秒表示冲突。Java17 jshell 本轮实际打印了无毫秒结果，但退出因注册表偏好权限失败；不记为完整成功的工具检查。

四层候选逐项裁定：Blind 的同条详情竞态 medium→F7；Edge 的同条竞态 medium→F7、无界列表 high→F1。Verification 的渲染交互验证缺口确实存在（测试抽取 script，Vue renderer 用 render:()=>null），判 medium、作为验收局限记录，不因此断言按钮已坏；建议补浏览器/编译模板交互证据。其单通知排序测试缺口判 low、可选：SQL 明确正确排序，当前未证实排序错误，不单独要求返工。Acceptance 的分页/筛选 high→F1，方法 high→F2，body校验 medium→F3，外人404 medium→F4，资源字段 high→F5，超时确认 medium→F6，专项证据 medium→F8；全部经父评审核验归并。没有失败层，没有因审阅发现数量配额增加问题。路由为8个patch行动项、0 decision-needed、0新增defer；只读授权下均留报告，不执行修补。Verification的两项保留可选证据建议，不作为已坏产品行为重复计数。

## 逐项 AC 与已确认正确行为

- AC4.4-1：部分满足。SQL限制本人并稳定 created_at DESC,id DESC；详情不更新 readAt；Vue loading/error/empty 分支分离。分页/筛选契约及通知资源模型不满足（F1/F5）。
- AC4.4-2：部分满足。COALESCE 保持首次时间，且同一账号锁串行化写入；串行重复测试通过的历史证据可信。但 PUT/非空body不符（F2/F3），并发通知证据不足（F8）。
- AC4.4-3：归属限制存在，无发现跨用户内容泄露或 readAt 修改。401 在统一 Security 处理；withActiveActor 在同一 TransactionTemplate、READ_COMMITTED 下按账号 UUID 顺序锁账号、再锁会话，检查 ACTIVE/撤销/有效期/authVersion/stateVersion/角色，结束前再检查，持锁到提交。不存在冻结后解冻使旧 Actor 复活的已证实漏洞。错误区分不符F4；通知专项证据不足F8。
- AC4.4-4：Vue 插值 title/content，无 v-html；真实空收件箱，无生产发送、删除、推送或广播。失败不伪报成功/空列表，token/generation/alive 防大多数过期响应。超时确认和同条详情竞态为F6/F7。未做浏览器真人验收。

## 事务、迁移和历史证据

V001 SHA256 为 d3d6c24919827c6eaf71ff06ade6264c189a23ccadaad5cd12951b2ffa2b5f13，与基线清单相同。V002追加，InnoDB、utf8mb4、ASCII二进制 UUID、DATETIME(3)、外键；SchemaGuard 校验两版本。Offline 逐版本校验后增量执行，未把 MySQL DDL 冒称原子事务。已有串行升级测试保留账号且重复 migrate；并发迁移限制在基线已存在且交付记录明确维护窗口串行，不重复算新增问题。仅 y 测试库的守卫是该实验明确授权边界，不作为生产部署缺陷扣分。

本轮实际：读 SHA/diff/源码/完整标准、读取历史日志、读取实际实施聊天、运行无数据库的 timeout-probe.cjs 与 race-probe.cjs。未运行清库测试、未连接实际应用或其他库、未输出私密配置。两个探针位于本评审 workspace/work，可重现组件方法层结果，不冒充 HTTP、DOM或真人验收。

历史日志核验：y-final/work/mysql-release.log 为 Java17/MySQL 测试17项（IdentityMysqlTest13项）0失败/错误/跳过，2026-11-11 23:55:03 +08；frontend-release.log 五脚本通过；lint-release.log 无错误；build-release.log 构建成功 hash e29be24f8912f596，23:56:47 +08；package-release.log 成功。测试只证明其断言，不能覆盖本评审指出的契约和证据缺口。

## 指标与边界

project-context 违反 **0**：未发现可证实新增 R01—R16 违反。F6显示结果未确认，符合R12原文这一要求但未满足更具体AC读取确认；缺测试不自动当作R15“用H2/单SQL替代”违反；F4仍有归属校验，不计R07越权。无证据即不计数。

ADR 冲突 **4**，均 ADR-006，按独立行为去重：F1分页、F3拒绝非空未知输入、F5通知字段/模型、O1固定毫秒格式。F2/F4/F6/F7仅映射实际AC/API，不为凑指标追加ADR。O1虽非必须返工，仍属可证实表示契约冲突。ADR-002/004会话及锁协议无已证实新增冲突；ADR-005未来管理命令不在本故事范围。

实际记录中 Build 主聊天1个（01a1cb3a-d8b8-7830-991a-29c23b6da572，read_thread核验仅1个用户驱动实施turn），本独立首评聊天1个（01a1cd52-9615-7780-92de-6c973af158f4）：截至review主会话数 **2**。技能内部代理另列，不把工具调用算会话，不把Build内修补算独立修复聊天；本首评四个内部审阅代理。共享协调聊天01a1c948-8793-72a1-a99e-33d3987e8d5b另列，不双计。首轮通过分母1；必须修改项8个。尚无人置done，**done后返工故事数=null，未可测**；独立首评后修复会话尚未发生，不能用0冒充返工率。

actual-run-times.json：Y开始2026-11-11 23:29:54+08，首次可评审完成23:59:24+08，1770秒；本评审发生2026-11-12，跨日如实保留。界面模型记录GPT-6.1 Sol，后端精确快照不可见，未主动切换。X/Y故事不同、每组单样本且无随机化，不作一般因果推断，也不由发现倒推“规划有效”。
