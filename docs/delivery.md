# 项目交付与验收说明

仓库根目录为D:\Code\temp\final。正式提交应包含根README、决策日志和复盘、_bmad-output、源码、tests及evidence；本地配置、上传和凭据按忽略规则处理，不进入公开仓库。

## 运行入口
已配置机器在根目录执行`.\scripts\start.ps1`，保持窗口运行后访问http://127.0.0.1:8080/。新环境先按README完成配置、构建、显式迁移和演示初始化。IDEA选择JDK17，主类PetAdoptionCommunityApplication，工作目录为后端目录。开发前端命令为npm run dev。新环境也可使用根目录pet_final.sql一次导入表结构与教学数据；与脚本init/seed方式二选一，具体命令和公开教学账密见README。

## 交付核对
| 项目 | 核对方式 |
|---|---|
| 功能 | 按docs/acceptance-checklist.md逐项执行 |
| 文档 | 按docs/submission-index.md检查十类产物 |
| 追溯 | 从PRD任取FR，经ADR和故事定位代码及测试 |
| 运行 | 核对数据库配置、迁移、生产jar、资源和工作目录 |
| 实验 | 原始输入、首版、首评、时间与限制共同保留 |
| 提交 | 真实分工、负责人接受、实际视频和GitHub可访问性 |

技术验证包括5项JUnit、45项HTTP/MySQL业务检查和17项补充业务检查，浏览器已验证商城履约与桌面手机布局。技术集合通过不等于最终人工验收。实际10分钟视频、真实四人分工与远程提交状态由负责人完成并确认，不以提纲替代视频。
