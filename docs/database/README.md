# 数据库设计 V1.1（课程精简版）

完整项目采用 **25 张表，现已全部建立**。当前代码仅实现注册、登录与个人资料，其余模块的数据结构已经准备好，功能仍需后续开发。新空库执行 01-schema.sql；已有账号两表的库执行 migrations/002-add-business-tables.sql 补齐，不重复创建用户表和文件表。

## 合并了什么

| 原设计 | 精简后 |
| --- | --- |
| 4 张角色／权限表 | sys_user.role=USER/ADMIN |
| 群发公告表 | user_notice 里区分群发主记录和实际收件消息 |
| 领养申请事件表 | adoption_application.progress JSON 数组 |
| 双人会话成员表 | 会话中的两个已读消息位置 |
| 标签表和内容标签关联表 | community_post.tags JSON 数组 |
| 付款记录、订单事件、库存流水 | 订单状态、付款及退款结果、里程碑时间；库存直接维护商品 |

保留用户资料、宠物发布、领养申请／私信／预约、帖子／日记／求助／评论、收藏、通知、举报、商品、购物车、地址、订单、退款和管理日志。取消自定义角色与逐项授权；模拟购买没有第三方支付流水。

## 约定

主键 BIGINT，自增；接口以字符串传 ID。UTC 存库，接口 RFC3339。金额 BIGINT，单位分。密码只保存哈希。MyBatis Mapper XML 编写 SQL，Service 负责事务、归属、状态和 JSON 内容校验。version 用于资料和业务并发修改，auth_version 用于撤销会话。外键只用于固定关联，多态资源与已读位置由 Service 校验。

JSON 只用于小且有上限的标签与进度，不把订单明细、评论、聊天消息等可增长集合塞进一个字段。标签最多 5 个；申请状态进度最多 100 项。标签检索示例：`JSON_CONTAINS(tags, JSON_QUOTE(#{tag}))`，本版不建标签统计系统。

## 文件

- [全部表用途](01-数据库设计说明.md)
- [数据字典](02-数据字典.md)
- [ER 图](03-ER关系图.md)
- [事务规则](04-索引与事务规则.md)
- [接口映射](05-接口与表映射.md)
- [初始化与迁移](06-初始化与校验.md)
- [完整建表 SQL](../../database/mysql/01-schema.sql)
- [当前两表 SQL](../../database/mysql/modules/01-account-schema.sql)

- [两表升级到完整 25 表](../../database/mysql/migrations/002-add-business-tables.sql)
- [本次完整建库验证结果](initialization-result.json)
