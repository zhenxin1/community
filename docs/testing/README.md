# 注册登录与个人资料验证

本期在独立 MySQL 8.0.35 开发库完成检查。测试数据均为随机测试账号，不复制到正式交付目录的开发库。

| 检查 | 结果 |
| --- | --- |
| Vue 生产构建 | 通过 |
| Maven 单模块打包 | 通过 |
| JUnit 单元测试 | 6 项通过 |
| 真实 HTTP 与数据库联调 | 38 项通过 |
| 无头 Edge 浏览器操作 | 12 项通过 |
| 桌面、390px 与 320px 布局 | 检查通过 |

接口检查包含 CSRF、会话轮换、注册重名、禁止越权字段、资料并发更新、Unicode 密码、头像归属/删除/Range、账号冻结、认证版本撤销和登录失败限流。浏览器检查包含注册、登录、回车提交、保存、头像上传、刷新恢复与退出。

- [接口检查明细](api-results.json)
- [浏览器检查明细](browser-results.json)
- [桌面登录页](login-desktop.png)
- [桌面注册页](register-desktop.png)
- [桌面个人资料](profile-desktop.png)
- [手机登录页](login-mobile.png)
- [手机个人资料](profile-mobile.png)

后端单元测试源码在 backend/src/test/java/com/petcommunity/AccountBoundaryTest.java。完整构建脚本默认执行这些测试。

需要重复运行接口或浏览器脚本时，使用独立测试开发实例；脚本会创建随机测试账号，接口脚本末尾会测试同一 IP 的登录限流。先重启测试应用以清空内存限流，再运行浏览器流程。示例：

```powershell
python tests/api_smoke.py --base-url http://127.0.0.1:18080
node tests/browser_smoke.mjs http://127.0.0.1:18080
```

接口脚本仅需 Python 3 标准库；浏览器脚本需要 Node.js 和 Microsoft Edge，可通过 EDGE_PATH 指定 Edge 程序路径。浏览器使用独立无头配置目录，不使用日常浏览器的账号或 Cookie。

## 数据库精简验证

完整建表、JSON 字段约束、模拟付款退款字段和旧六表迁移共 34 项检查通过，详情见 [数据库结果](../database/validation-result.json)。旧账号迁移测试验证了角色映射、密码哈希和个人资料保留，迁移可重复执行。
