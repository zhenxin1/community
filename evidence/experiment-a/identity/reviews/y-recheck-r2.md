# Y 组 R2 修补独立增量复核

结论：**technicalPASS**。R2已关闭，本轮未发现剩余必须修改项；前轮F1–F8、O1及R1的关闭结论保持。技术复核通过不等于浏览器真人验收或置done，不改写实验初版首评结果。

被评SHA：`0ddd11b2765e731186a6fde3a94423a6fe10169d`；增量基线：`fceced80130435d69abe9e3039f2e4b85ef65e1f`。被评目录：C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/y-final。2026-11-12，Asia/Shanghai。实际diff只有通知Vue组件、通知测试及新增R2修补规格，3文件+96/-30；后端、API和迁移未改。git status为空。

## R2 原始交错复验

本轮独立读取实际组件script，在隔离VM请求队列精确控制：标记A → 打开B并标记B → A成功且未读列表刷新完成 → B的PUT不确定 → GET B核对。重新构建探针只适配修后不再额外整页load的请求顺序，没有改业务代码。

| 核对分支 | 实测断言 | 结果 |
|---|---|---|
| GET B仍未读 | selectedId仍b、detail.id仍b、readAt=null；提示含“仍未读”；marking=false；直接再markRead发PUT，无需重开详情，成功后详情已读、提示清空 | 通过 |
| GET B失败 | 保留b详情和未读状态，提示含“读取核对失败”；marking=false；直接重试PUT成功，补页后仍保留b已读详情且提示清空 | 通过 |
| GET B已读 | b详情显示confirmed、markError为空、marking=false；未读列表刷新完成 | 通过 |

探针实际输出三行pass=true：unread与failed最终detailReadAt=retry-success，read最终detailReadAt=confirmed；三者selectedId=b、markError为空且marking=false。输出表示完成直接重试后的最终状态；重试前提示与未读详情由探针assert分别验证。

可复核原件均在本聊天工作目录：`work/y-r2-independent-probe.cjs`、`work/y-r2-independent-probe.log`。这是实际组件方法级测试，不冒称HTTP、数据库或浏览器真人验收。

## 原因与回归核验

`load()`只在显式刷新/切页/筛选/会话切换时增加viewGeneration并清理详情；自动列表工作统一由refreshList完成，不再调用会清理另一通知详情的load。markRead按token、每ID readAttempts、viewGeneration及selectedId确定详情归属，确认仍未读时保留当前详情并显示重试指导。因此A补页的列表generation变化不再使B丢失状态，AC4.4-4的结果说明恢复。

本轮实际重新运行 `node .../vue1/tests/notifications-flow.js`，通过，原始输出在本聊天 `work/y-r2-notifications.log`。检查其真实测试及实现，确认以下覆盖仍在且本轮执行：

- B普通成功、uncertain核对已读/未读/失败，未读或核对失败后直接重试。
- A补页后旧B确认晚到，不能覆盖新attempt已读结果或错误反馈。
- 显式筛选改变清理旧详情，旧确认不再回填；会话切换后旧请求不填入新会话、不发旧会话后续请求。
- 同条通知重开、切换其他详情、B在途详情、B普通标记失败的反馈及按钮状态。
- R1第一页补齐10条、末页回退、uncertain确认已读后补页、列表失败显式错误与重试、新筛选/会话的旧补页响应、持续缩页最多两次请求。

四层增量复核沿用当前默认模型配置：Blind确认R2关闭并实际运行通知脚本通过，无必须项；Edge未发现已证实剩余问题；Verification未发现验证缺口；Acceptance明确PASS，确认R2关闭且R1补页、有界回退、错误显示未回归，无必须项。四层均返回。父评审独立探针及专项测试证据如上。没有按发现配额制造问题。

## 历史证据、限制与冻结记录

读取而非重跑的实施日志：y-final/work/r2-final-tests.log五个前端脚本通过；r2-final-lint.log无错误；r2-final-build.log生产build成功，2026-11-12 10:07:03+08，hash `4e1c16385bfc9354`。本轮独立评审只运行上述通知专项与三个独立分支探针，未重跑build/lint/后端全集，不将历史日志冒充本轮执行。

后端未改，沿用前轮已核验的18项Java/MySQL历史证据；未重跑清库全集、未连接实际应用或其他数据库、未读取或输出秘密。没有源码修改、没有D盘写入、未合入主工程、未done、未push。

首评报告与指标完全冻结：8项、通过0/1、project-context违反0、ADR冲突4；本技术PASS不能覆盖首评或把事后完整标准回灌追认为初版输入。此前y-recheck.md与y-recheck-final.md保留，不覆盖。浏览器人工操作和视觉验收仍未执行；尚未done，done后返工仍未可测。两组不同故事、每组单样本、无随机化，不作一般因果推断。
