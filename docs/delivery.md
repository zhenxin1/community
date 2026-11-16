# 项目交付说明

文档状态：`Done`。

## 交付组成

交付仓库为[zhenxin1/community](https://github.com/zhenxin1/community)，内容包括产品与需求文档、架构及故事、源码、测试、决策日志、复盘、初始化SQL和运行脚本。十类课程产物的位置见[提交材料索引](submission-index.md)。

本地凭据、上传、日志、依赖安装目录和构建输出不进入版本库。配置与构建从仓库源文件复现，数据库结构通过带校验值的编号迁移建立。

## 运行与数据

运行环境、脚本和SQL两种初始化方式均见[README](../README.md)。生产应用由一个Spring Boot进程提供页面和接口，默认地址为http://127.0.0.1:8080/；开发前端使用5173端口。数据库为MySQL8专用库`pet_final`，已有账号及数据不通过启动流程重置。

## 交付核验

| 对象 | 核验依据 |
|---|---|
| 功能 | [业务验收清单](acceptance-checklist.md)与故事验收条件 |
| 需求覆盖 | [追溯矩阵](traceability.md)中的FR、ADR、代码和测试映射 |
| 质量 | [技术验证记录](../evidence/verification.md)及原始结果 |
| 数据库 | [数据库说明](database.md)、迁移校验及SQL导入记录 |
| 实验 | 冻结输入、初版、首评、执行时间与局限说明 |
| 演示 | Done；[演示提纲](demo-script.md)、[演示视频 Release](https://github.com/zhenxin1/community/releases/tag/demo-video-20261116)及[下载 MP4](https://github.com/zhenxin1/community/releases/download/demo-video-20261116/pawpaw-community-demo.mp4) |

技术证据包括5项JUnit、45项HTTP/MySQL业务检查和17项补充业务检查；浏览器记录覆盖商城履约与桌面、手机布局。故事人工接受、成员信息和演示视频的登记状态集中列于提交材料索引。
