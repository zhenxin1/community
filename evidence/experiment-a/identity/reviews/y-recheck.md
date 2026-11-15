# Y 组事后修补增量复核

结论：**CHANGES_REQUESTED（尚不满足 technicalPASS）**。原首评 F1–F8 及 O1 的针对性修补已核实；新增分页维护回归 R1 尚需处理。此为事后修复复核，不是实验初版或新首评。

被评提交：`6f44151f420b417b61f0ec1dbfc92250374f16eb`；增量基线：`0a6dd61e011ec6257f5322e3dc55db7d4c954acf`。目录：C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/y-final。2026-11-12，Asia/Shanghai。只读，未改业务代码、未置done、未push，未尝试写D盘。

## 剩余项

**R1 · medium · 必须修改：已读后仅本地删项及减总数，未补齐或调整未读分页。**

位置：`vue1/src/components/MyNotifications.vue:61-62`，与模板第7行下一页禁用判断联动。

复现：11条未读，每页10条，第1页显示10条。显式标记其中一条成功后，reconcile只从当前items删掉该条，并将total从11改成10；当前页只剩9条，但 `page * size >= total` 为true，“下一页”被禁用。原第二页尚有一条真实未读，当前分页导航已不能显示它，用户须额外手动刷新才会出现。组件探针实际输出：`{"page":1,"total":10,"visibleItems":9,"nextDisabled":true,"remainingOffPageUnread":1}`。

同根边界：11条未读、size10，在第2页标记最后一条后，page仍2、total10、items0，页面显示暂无通知，另10条仍在上一页。它不是第二个独立问题。探针输出：`{"page":2,"size":10,"total":10,"items":0,"previousPageAvailable":true}`。

影响：未读筛选分页在本次成功写入后不再代表更新后的页边界；用户继续处理剩余通知时会漏见一条或停留在空页。存在刷新/上一页恢复路径，故不是数据丢失或越权，也不定为high。对应AC4.4-1的分页结果与AC4.4-2的标记后未读筛选联动。建议确认已读后重取当前未读页，必要时将页码收敛到有效末页；保留原有token/generation/attempt守卫，避免重引竞态。补11→10跨页和末页清空回归即可。

## 原问题关闭核验

| 首评项 | 本次核验 | 结果 |
|---|---|---|
| F1 | Controller白名单page/size/filter；Service验证page≥1、size10/20/50、ALL/UNREAD；MyBatis稳定排序LIMIT/OFFSET，Page信封；UI页码、size、筛选接入。HTTP测试覆盖默认20、各size与越界空页、非法值、同时间ID降序。 | 原协议缺失关闭；新R1单列 |
| F2 | @PutMapping；前端显式PUT；HTTP无body PUT成功并重复返回相同资源。 | 关闭 |
| F3 | 读取请求输入流，任何非空body均400；HTTP覆盖{}、未知字段、[]、null及空白，每次断言read_at未改。无body无需Content-Type。 | 关闭 |
| F4 | 查本人资源失败再查存在性，存在外人403、不存在404；三轮GET/PUT错误及无内容泄露断言，外人read_at不变。 | 关闭 |
| F5 | Service DTO恰为id/title/body/type/operationId/createdAt/readAt；MyBatis显式列；V002为recipient_id/body/type/operation_id/actor_id、相应长度/索引/外键；HTTP七字段断言。 | 关闭 |
| F6 | uncertain后GET确认，不自动重放PUT；已读、仍未读、确认失败均有测试与提示。 | 关闭 |
| F7 | 对当前相同selectedId回填确认状态并递增detailGeneration，屏蔽旧GET；readAttempts按ID屏蔽旧尝试结果。同条重开、旧确认晚到均覆盖。 | 关闭 |
| F8 | 专项真实MySQL应用服务测试覆盖旧Actor在冻结与再激活后list/detail/read均401、无read_at变化；双线程屏障并发首次已读结果相同且与持久化后读取一致；跨用户读/标各≥3次。 | 关闭 |
| O1 | appendInstant(3)；固定整秒夹具断言.000Z；V001校验和不变。 | 关闭 |

MyBatis通知服务继续调用IdentityPort.withActiveActor，同一主库事务内锁账号后锁会话，重验身份、状态/认证版本、角色、有效期；COALESCE保持首次readAt。未发现新增事务或授权破坏。真实冻结命令交错仍按故事约定留4.5，不将测试内FROZEN夹具冒称真实冻结集成验收。

V002校正已在修补规格明确记录为未发布、仅指定y测试库使用，并由授权测试入口重建；初版SHA与旧校验和可从Git保留。本轮实算V001 SHA256仍d3d6c24919827c6eaf71ff06ade6264c189a23ccadaad5cd12951b2ffa2b5f13，V002为124b52b3e833940ec4e936636df4ecaa79d4ae81b3cb0add51ef0ad4800fdf01，与checksums.properties相符。不能将该未发布实验校正流程推广为可改写已部署迁移的规则。

## 执行证据与多层裁定

本轮实际执行：读取提交增量、实现/测试/修补规格与原始日志；重新运行 `node .../vue1/tests/notifications-flow.js`，通过，输出保存于本聊天work/y-recheck-notifications.log；运行两个无数据库组件探针，分别保存work/y-recheck-page-refill.cjs/.log、work/y-recheck-last-page.cjs/.log；核验迁移文件哈希。未重跑清库全集、未读取私密连接配置、未连接真实应用或其他数据库。

本轮四层增量审阅沿用默认模型配置：Blind识别第一页未补齐，Edge识别末页空页，父评审分别实测后归并R1；Verification核验F8与日志，并指出模板已读按钮仍未实际调用、排序夹具时间相同这两处窄证据缺口；Acceptance核对原AC/契约。没有以发现配额制造问题。

Verification两项建议保留非阻断：当前模板确有@click=markRead且方法测试通过，没有证据证明按钮坏；新增模板宿主测试已覆盖实际分页/详情事件与纯文本，仍可补一次可见已读按钮调用。排序SQL明确created_at DESC,id DESC，新夹具验证了ID tie-break及分页，但可补不同createdAt夹具以防主排序回归。延续首评裁定，不把未证实产品缺陷重复算必须返工。

历史修补日志（非本轮重跑）：post-review-mysql.log记录2026-11-12 09:34:14+08，18项0失败/错误/跳过，其中IdentityMysqlTest14项；post-review-package.log打包成功，不能以其跳过测试代替前述MySQL日志。post-review-final-tests.log五脚本通过，post-review-final-lint.log无错误，post-review-final-build.log最终构建成功，09:40:16+08，hash a847381cfb4a0788。原sandbox spawn EPERM和模板宿主首次失败日志保留，未把失败写成通过。

## 冻结指标及限制

首评仍为8项、0/1通过、project-context违反0、ADR冲突4；**完全不改首评报告或metrics**。R1为此次修补引入/暴露的未读分页维护回归，不能倒灌为初版第9项。完整标准首次回灌的时点及本轮修补性质在post-review规格中明确记录，不追认Y初版已知上游。

浏览器人工操作与视觉验收仍未执行；模板自定义Vue宿主测试和组件探针不能冒称真人浏览器验收。尚未done，done后返工指标仍未可测。不同故事、单样本、无随机化，不作一般因果推断。
