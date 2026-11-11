# 爪爪社区 · 宠物领养社区项目

当前已实现：**注册、登录、退出登录、登录状态恢复、个人资料和头像维护**。其余模块保留设计文档，尚未开发。

## 启动与使用

在当前 Windows 电脑双击 **启动项目.cmd**，看到 Ready 后访问：

**http://127.0.0.1:18080/login**

首次使用点击“加入爪爪”注册自己的账号。没有默认账号或管理员密码。注册后会自动进入个人资料页，可维护昵称、头像、联系方式和所在地。登录、注册和资料表单均支持回车提交。

- **启动项目.cmd**：启动项目独立 MySQL 开发库和应用；附带已构建的 JAR 时无需重新下载前端依赖。
- **停止项目.cmd**：只停止本项目创建的应用及数据库进程，保留已注册账号、资料和上传文件。
- **重新构建.cmd**：先停止本项目，再安装锁定依赖、构建前端并运行后端单元测试；完成后再次启动。

启动脚本使用 JAVA_HOME 指向的 Java 17+；当前电脑验证使用 Java 20.0.1、MySQL 8.0.35。MySQL 程序从 MYSQL_HOME 或 PATH 查找。启动器创建 .runtime/mysql/data 独立数据目录，不连接原有 MySQL 服务；数据库端口默认 33079。

如果端口被占用，可以在 PowerShell 里执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start.ps1 -AppPort 18081 -DatabasePort 33080
```

脚本会记住所选端口，并拒绝占用其他程序的端口。运行数据、本机随机数据库凭据和日志放在 .runtime，上传文件在 storage/uploads；这些目录已加入 .gitignore。

## 工程目录

```text
backend/
  pom.xml                 唯一的 Maven 配置
  src/
    main/
      java/com/petcommunity/
        PetCommunityApplication.java
        controller/       接口
        service/          业务逻辑（含 impl）
        mapper/           数据访问接口
        entity/           数据库实体
        dto/              请求参数
        vo/               返回数据
        utils/            文件工具
        validation/       输入校验
        common/           统一返回、业务异常
        config/           配置
        security/         会话、CSRF 与登录校验
        handler/          全局异常处理
        task/             定时任务
      resources/
        application.yml
        mapper/           MyBatis XML
    test/java/            后端测试
frontend/                 Vue 3 页面与请求、路由、状态
database/mysql/            完整数据库设计和本期基础表脚本
docs/                     接口、数据库、开发和验证说明
scripts/                  构建、启动和停止
tests/                    真实接口与浏览器检查
```

## 开发和重新构建

前端：Vue 3.5.45 + Vue Router 4.6.4 + Pinia 3.0.4 + Vite 8.3.8。需要 Node.js 20.19+ 或 22.12+，当前使用 24.12.0。

后端：Spring Boot 3.5.16 + Spring MVC + MyBatis Starter 3.0.5 + MySQL。源码目标 Java 17，Maven 3.6.3+。三层职责为 Controller → Service → Mapper。

独立调试前端时，先启动后端，再执行：

```powershell
cd frontend
npm ci
npm run dev
```

前端开发地址默认 http://127.0.0.1:5173，/api 代理到 18080。后端更换端口时，可在启动前设置 VITE_API_TARGET。打包时，前端 dist 通过 Maven resources 放入后端 JAR，正常使用仅需访问应用端口。

如以后连接自行管理的 MySQL，在新空库执行 database/mysql/ 下的完整 schema 和 seed；已有两表库按 migrations/002 补齐。然后设置 DB_URL、DB_USERNAME、DB_PASSWORD 和 APP_STORAGE_ROOT，直接使用 Java 运行 JAR。scripts/start.ps1 始终用于本项目独立本地开发库。

## 文档

- [本期功能与实现说明](docs/development/01-注册登录与个人资料.md)
- [完整接口文档](docs/api/README.md)
- [完整数据库设计](docs/database/README.md)
- [测试结果](docs/testing/README.md)

构建产物 backend/target/pet-community-0.1.0.jar 不作为源码提交；新电脑通过重新构建脚本生成。

## 数据库精简版

完整设计 25 张，当前数据库已全部建立。用户身份通过 role=USER/ADMIN 区分。启动器在新空库建立全部表；旧两表库先备份，再补齐其余 23 表。旧六表库先完成角色简化再补齐。现有账号资料保留，业务代码仍仅实现注册登录和个人资料。详情见 [数据库说明](docs/database/README.md)。
