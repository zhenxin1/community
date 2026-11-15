# Y 未读分页修补最终增量复核

结论：**CHANGES_REQUESTED，尚不满足 technicalPASS**。R1 的分页补齐/末页回退已关闭；新增联动仍有一项必须修改的中等问题 R2。报告名 final 表示本次要求的交付文件，不代表技术通过。

被评 SHA：`fceced80130435d69abe9e3039f2e4b85ef65e1f`，增量基线 `6f44151f420b417b61f0ec1dbfc92250374f16eb`。被评目录 C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/y-final。日期2026-11-12，Asia/Shanghai。只读，不改源码、不done、不push，不尝试D盘写入；首评报告、metrics及上轮recheck均未改。

## R2：A 的未读补页使 B 的未确认结果与重试提示消失

等级：medium；必须修改：是。位置：`vue1/src/components/MyNotifications.vue:88`，与第104–105行及load第34行的清理行为联动。

可达顺序：未读列表中标记A → 打开B并标记B → A成功并完成refreshUnreadPage，列表generation递增 → B的PUT超时/网络不确定 → B自动GET确认，服务器返回B仍未读 → reconcile发现B开始标记时的listGeneration已旧，执行load()。load会清空selectedId、detail及markError；随后第105行因selectedId不再为B，不能显示“结果未确认，当前仍未读，可重试标记”。

本轮对实际组件脚本的独立探针输出：`{"selectedId":null,"detail":null,"markError":""}`。请求顺序为 PUT A、GET B、PUT B、GET未读列表、GET B、GET未读列表。没有用真实数据库或假称HTTP实测。探针文件：本聊天 `work/y-recheck-final-uncertain.cjs`，原始结果 `work/y-recheck-final-uncertain.log`。

影响：用户当前操作B的不确定/未成功结果与可重试详情被另一个通知的列表刷新清掉，页面只剩列表，没有解释B未标记完成。B仍在未读列表中，未发现数据错误或假成功，故不升为high；但违反AC4.4-4要求的失败/超时状态说明及本轮修补承诺的独立详情/标记联动。该问题是本次R1补页引起generation变化后触发的联动，不倒灌为初版发现。

建议：将独立列表补页与显式整页刷新/筛选变化区分；B确认仍未读时保留B详情与未确认提示，不因A的补页调用会清空详情的load。补一条“A补页完成 + B uncertain + 确认仍未读”的精确回归，并保留现有旧token、旧页面、旧attempt保护。无需引入新业务。

## R1 与其他联动核验

- `refreshUnreadPage`从服务器重取当前未读页，不再仅本地删项减数；11→10第一页能够显示完整10条。
- 末页失效根据服务器total回退到合法末页；最多两次GET，继续缩页则显式错误和重试，未发现无限循环。
- 列表失败用error分支而非空列表；已确认的详情已读结果保留。显式重试load恢复。
- 新筛选/页码或新会话的请求递增generation，旧补页不覆盖新结果。
- open不再被单独列表补页的generation变化取消，B在途详情能完成；B普通标记失败仍显示错误并释放按钮。上述普通失败分支已修，但不能覆盖R2的uncertain后确认未读分支。
- 前轮F1–F8/O1仍按上轮复核结论关闭，本提交未修改后端/迁移；不重跑无关MySQL全集。

## 实际证据与多层审阅

本轮实际运行通知前端专项 `node .../vue1/tests/notifications-flow.js`，通过；输出在本聊天 `work/y-recheck-final-notifications.log`。其新增用例覆盖第一页补齐、末页回退、确认已读后补页、补页失败及重试、旧筛选/旧会话响应、连续缩页两次上限、B详情及B普通标记失败。本轮另实际运行R2组件探针，独立复现。

历史日志核验（不是本轮重跑）：y-final/work/r1-final-tests.log五个脚本通过；r1-final-lint.log无lint错误；r1-release-build.log最终生产构建成功，2026-11-12 09:54:55+08，hash `9ff69ae559f1a8cb`。工作区git status为空。增量只有Vue组件、前端测试及本轮修补规格三个文件。

多层增量审阅沿用当前默认模型配置：Blind提出R2，父评审用实际组件探针核验；Verification报告其检查的R1专项覆盖无缺口；Edge独立确认同一R2根因、无其他已证实缺陷；Acceptance确认R1关闭、R2为AC4.4-4中等必须修项。四层均返回。测试通过不作为否定已复现剩余行为的理由，不按问题配额制造发现。

首评8项、首次通过0/1、context0/ADR4保持冻结；上轮R1单独记录仍保留。浏览器人工操作与视觉验收仍未执行，Vue宿主与方法探针不是浏览器真人验收。尚未done，done后返工仍未可测。不同故事单样本无随机化，不作一般因果推断。
