# 课程提交材料索引

文档状态：`Done`。

本索引对应课程讲义第33页的十类产物，交付状态为`Done`。路径均相对仓库根目录，演示视频作为GitHub Release附件提供。

| 序号 | 产物 | 具体位置 | 内容与课程要求 |
|---|---|---|---|
| 1 | 产品简报 | [_bmad-output/planning-artifacts/product-brief.md](../_bmad-output/planning-artifacts/product-brief.md) | 问题、目标用户、使用旅程、成功度量与范围外 |
| 2 | PRD | [PRD.md](../_bmad-output/planning-artifacts/PRD.md) | 21条编号FR、5条可测NFR、状态、权限与验收场景 |
| 3 | 架构 | [architecture.md](../_bmad-output/planning-artifacts/architecture.md) | 9条ADR，包含采用方案、被否决备选、理由、代价与验证 |
| 4 | 史诗与故事 | [epics.md](../_bmad-output/planning-artifacts/epics.md)、[stories/](../_bmad-output/implementation-artifacts/stories/) | 4史诗20故事，80项可验证验收条件 |
| 5 | 项目上下文 | [project-context.md](../_bmad-output/project-context.md) | 固定技术版本与14条具体实现规则 |
| 6 | Sprint状态 | [sprint-status.yaml](../_bmad-output/implementation-artifacts/sprint-status.yaml) | 记录故事状态；纳入Git，版本记录通过git log核对 |
| 7 | 源码与测试 | [后端与前端](../PetAdoptionCommunity/)、[tests/](../tests/)、[evidence/](../evidence/) | 5项JUnit、45项HTTP/MySQL业务、17项补充业务及NFR对应证据 |
| 8 | 决策日志 | [decision-log.md](../decision-log.md) | 30项决策，其中8项人工实质修改，记录判断、理由、影响及验证 |
| 9 | 复盘 | [retrospective.md](../retrospective.md) | 项目度量、实验A结果与局限；实验B免做说明 |
| 10 | 运行与演示 | [README.md](../README.md)、[演示提纲](demo-script.md)、[演示视频 Release](https://github.com/zhenxin1/community/releases/tag/demo-video-20261116) | 启动、职责登记、AI声明与10分钟演示要求 |

## 实现与验证索引

[追溯矩阵](traceability.md)连接FR、ADR、故事、源码和测试。[接口合同](api-contract.md)定义请求与响应，[数据库说明](database.md)定义结构、迁移及事务边界。根目录[pet_final.sql](../pet_final.sql)提供单文件初始化，结果见[SQL验证记录](../evidence/database-initialization-check.json)。

## 材料登记与证据边界

| 项目 | 仓库登记情况 |
|---|---|
| 功能与质量材料 | 规划、实现、技术验证和实验附件已收录 |
| 故事完成确认 | 20个故事均为done，完成依据为项目负责人确认；状态与故事卡保持一致 |
| Sprint版本演进 | Git保留初始状态与完成状态更新，具体演进通过该文件的git log核对 |
| 成员分工 | 涂远豪：管理员后台；韩子玉：商城；胡勇：宠物领养；蔡鹏飞：数据库、系统验证与交付。具体职责见README |
| AI模型版本 | Agent为Codex，模型为GPT6.1 Sol；使用范围见README |
| 实际演示视频 | Done；[演示视频 Release](https://github.com/zhenxin1/community/releases/tag/demo-video-20261116)，附件为`pawpaw-community-demo.mp4`，[下载 MP4](https://github.com/zhenxin1/community/releases/download/demo-video-20261116/pawpaw-community-demo.mp4) |
| 远程仓库 | [zhenxin1/community](https://github.com/zhenxin1/community) |

技术检查结果与人工验收分开记录。实验A按原始首版、首次评审和实际时间报告，跨日、任务差异及隔离限制随结果说明；实验B依据教师补充说明免做。
