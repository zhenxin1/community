# 课程提交材料索引

提交单位为仓库根目录的完整项目，包含规划、故事、源码、测试及证据。目录沿用BMAD规划与实施结构，根目录提供决策日志、复盘及运行说明。

| 序号 | 产物与具体位置 | 内容与数量 | 状态 |
|---|---|---|---|
| 1 | _bmad-output/planning-artifacts/product-brief.md | 问题、用户、旅程、范围、成功度量 | 已整理 |
| 2 | _bmad-output/planning-artifacts/PRD.md | 21条FR、5条可测NFR、状态、权限和验收 | 已整理 |
| 3 | 同目录architecture.md | 9条ADR，问题、采用、备选、否决理由、代价及验证 | 已整理 |
| 4 | 同目录epics.md及implementation-artifacts/stories/ | 4史诗20故事，各4项可断言验收条件和任务 | review，待人工接受 |
| 5 | _bmad-output/project-context.md | 固定版本及14条具体规则 | 已整理 |
| 6 | _bmad-output/implementation-artifacts/sprint-status.yaml | 实际状态及Git版本证据 | 保持实际状态 |
| 7 | PetAdoptionCommunity、tests、evidence | 源码、5项JUnit、45项业务及17项补充业务检查、浏览器记录 | 已执行的集合通过 |
| 8 | decision-log.md | 30项人机决策，其中8项人工实质修改；包含阶段方案、判断依据、影响、验证及方案变化 | 决策、阶段状态与验证分别记录 |
| 9 | retrospective.md | 度量、实验A数据与限制、质量复盘；实验B免做说明 | 已整理 |
| 10 | README.md及实际10分钟录屏 | 环境、启动、分工和AI声明；提纲docs/demo-script.md | README已整理，实际录屏待完成 |

## 配套说明
docs/traceability.md提供FR到ADR、故事、代码及测试映射；api-contract.md与database.md提供接口和表结构；根目录pet_final.sql提供单文件建库、建表及教学数据初始化，导入验证见evidence/database-initialization-check.json。实验A附件与文件校验清单位于evidence/experiment-a/。evidence的原始失败与修补结果分别保存。
最终交付前完成负责人验收、真实四人分工、录屏和可访问GitHub链接。原实验A的跨日、任务差异及隔离限制应随结果说明，不以其他测试数字替代。当前没有证据的事项不标成已完成。
