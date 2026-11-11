# 完整数据库初始化与升级

当前项目使用本地 MySQL，库名 pet_community，默认端口 33079，完整结构为 25 张表。注册登录和个人资料代码已实现，领养、社区、商城及管理端业务代码仍待开发。数据库建好不代表对应功能已经开发。

## 新电脑与新空库

推荐按照项目 README 构建，再运行启动项目.cmd。启动脚本创建独立数据目录 .runtime/mysql/data，并在空库创建完整 25 张表，初始化社区 4 个分类和商品 4 个分类。不提供默认用户或管理员密码，各成员使用自己本地的账号。

若自行管理 MySQL，按顺序执行：00-create-database.sql → 选择 pet_community → 01-schema.sql → 02-seed.sql → 03-check.sql。后端通过 DB_URL、DB_USERNAME、DB_PASSWORD 连接自己的数据库，应用账号需有业务表 CRUD 权限。

## 已有本项目两张账号表

停止后端，备份数据库。在已选中的 pet_community 库执行 migrations/002-add-business-tables.sql，然后执行 02-seed.sql 和 03-check.sql。002 只新增 23 张业务表及其外键，不重建用户表或文件表，不改变已有账号、密码哈希、资料和头像元信息。原有 media_file.owner_id 外键保留，名称可能与空库初始化不同，但关联列与规则相同。

当前启动脚本也能自动识别两表库，在 .runtime/backups 完成备份后执行 002 和分类初始化。若已运行旧后端，先停止再启动。若检测到部分业务表已经存在而未建齐，脚本停止并提示人工核对，避免静默覆盖。002 是一次性迁移，完整建库后不要重复执行；再次正常启动会跳过建表和分类初始化，不覆盖后续修改。

## 更早的六张账号表

先备份并执行 migrations/001-simplify-accounts.sql，将角色权限改成 sys_user.role=USER/ADMIN，再执行 002 和分类初始化。启动脚本兼容这一顺序。旧 37 表完整设计若已录入领养、商城等数据，不能直接套用本升级路径，需先检查数据转换方案。

## 团队协作

共享 database/mysql/ 下的建表和升级 SQL、docs/ 下的数据字典。每个人在自己电脑建立数据库；不上传 .runtime/ 中的本机凭据、实际数据或备份。此后修改表结构使用 003、004 等新的编号迁移，与相关代码一起提交。git pull 只更新文件，不会自动执行任意新 SQL。

## 备份与验证

本次建库先备份，再新增表，最后检查 25 张表、字段、外键、索引和 CHECK 与数据字典一致；确认原有用户与媒体记录未改变，分类各 4 个。验证结果见 [initialization-result.json](../../docs/database/initialization-result.json)。

MySQL DDL 会隐式提交，不能依靠 ROLLBACK 撤销整次建表。若迁移中断，应先确认已创建的表和备份，再处理；不要删除原有用户表。备份含密码哈希与个人资料，只放在被 Git 忽略的 .runtime/backups。
