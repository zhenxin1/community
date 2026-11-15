# X组 F1 修补增量复核

结论：**technicalPASS**。F1已解决；本次限定增量复核未发现剩余必须修改项。浏览器交互及真人验收仍待完成，不置done。

- 日期：2026-11-12，Asia/Shanghai。
- 被评提交：`843f29000eeb2e843a9a2fadca3835992bce2aaf`。
- 副本：`C:/Users/29201/Documents/Codex/2026-11-11/yue-du/work/experiment-a/x-final`；本轮检查时HEAD精确匹配，工作树干净。
- 范围：对比首版 `5d81624a1f4be1d3329dfe2ea5e54492e4cf4e81`，仅复核F1及回归增量；不扩大为新一轮全故事首评，不修改业务代码。
- 原首评维持CHANGES_REQUESTED、1个必须修改独立根因、0/1=0%。修后technicalPASS不覆盖首次结果，也不改变已确认的首次规则/ADR计数。done后返工仍未可测。

## 修补核对

`src/main/java/com/example/petadoptioncommunity/administration/AdminUsersMapper.java:7-17` 将独立count与分页SELECT改为一条普通SELECT：COUNT聚合派生表 LEFT JOIN 分页派生表，两侧使用同一过滤表达式；最终再次按created_at DESC、id DESC排序。InnoDB在READ COMMITTED下一条一致性读语句使用同一语句读取视图，注册不能再提交到两个独立语句之间而令该响应total/items矛盾。

COUNT无GROUP BY，空集合仍产生一行total；LEFT JOIN在无匹配或越界页时产生null-ID占位行，保留准确总数。`AdminUsersService.java:22` 从该投影读取total，并在映射时间等公开字段前剔除null-ID行。因SQL保证至少一行，projection.get(0)的使用有依据。真实用户id为非空主键，不会被错误剔除。列表对外六字段与Page形状不变，没有将内部total重复字段泄露到User。

原有身份重验、ADMIN授权、参数绑定、过滤规范化、稳定排序、size/page边界及账号后会话锁序均保留；无DDL、无全局锁、无隔离级别更改、无前端业务变化。此修补满足AC4.3-1/FR-E4-006的一次响应总数准确要求，也保留AC4.3-2允许后续刷新观察到新增账号的语义；不承诺历史分页快照。

## 新增回归核对

`src/test/java/com/example/petadoptioncommunity/IdentityMysqlTest.java:273-304` 的RegistrationReadBarrier只拦截指定读线程的真实AdminUsersMapper Executor.query，实际查询执行后才暂停返回。主测试线程通过真实IdentityService.register提交注册，再释放查询线程。断言包含：

- 实际事务绑定连接为READ_COMMITTED，并且只有一条管理查询；未伪造数据库结果。
- 暂停前读取的响应total=0/items空，后续请求total=1且目标账号出现。
- 越界页total=1/items空，无匹配筛选total=0/items空。
- latch等待有超时，finally使拦截器不再激活并释放屏障、关闭执行器。

该交错能检出旧实现：旧count返回后暂停，注册提交后旧list会读到新账号，导致查询数或0/空断言失败。新实现只返回已执行完毕的一条查询结果。原adminQueryStory43仍覆盖30账号、10/20/50页大小、并列时间排序、字面量匹配、空/部分/越界页及HTTP授权/字段白名单。没有用换隔离级别或假mapper规避原问题。

## 证据与本轮执行边界

本轮实际执行了版本/工作树检查、逐行增量代码及测试审阅、源码增量git diff --check（通过），并实际读取下列原始日志。它们是修补阶段历史运行证据，**不是本次复核重跑**：

| 原始记录（副本evidence/tests/4.3/post-review/下） | 实际内容 |
|---|---|
| targeted-mysql-initial-fixture-failure.txt | 2026-11-12 09:31:44 +08:00，2项中1项失败，隔离级别期望2实际4；失败未删除。 |
| targeted-mysql.txt | 09:33:11 +08:00，2项定向MySQL测试，0失败/错误/跳过。 |
| full-mysql.txt | 09:34:48 +08:00，18项，0失败/错误/跳过；其中13项IdentityMysqlTest、5项非DB；含READ_VIEW43真实交错输出。 |
| package.txt | 09:34:54 +08:00打包成功，但18项中13项DB测试跳过；不作为全量DB通过依据。 |
| frontend.txt | 六份Node脚本及lint通过，明确SSR不等于真实浏览器。 |
| build.txt | Vue生产构建成功，UTC 2026-11-12T01:35:11.855Z，即本地09:35:11。 |

夹具修正已核对：现有断言在拦截器执行期间通过DataSourceUtils检查实际事务绑定连接，消除了此前读取池外默认REPEATABLE_READ连接的误判；生产IdentityService仍设置READ_COMMITTED。不能把早期夹具失败写成业务隔离级别曾被改动。

本轮没有未决疑问需要新增数据库探针，依照授权未重跑会清库的数据库全集，也未重复前端构建。未启动真实应用、未读取秘密到输出、未改故事或状态。

## 仍待验收

浏览器中的输入、查询/翻页/详情点击、错误重试及退出转换仍未实测，沿用原报告的明确缺口；方法测试和SSR不冒称DOM或真人验收。这不构成此次已证实的新增UI故障，也不阻止针对F1修补给出technicalPASS。仍不done、不push。两不同故事单样本且无随机化，不据修补结果推断规划的一般因果收益。
