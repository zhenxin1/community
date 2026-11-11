# 接口文档 V1.1（精简版）

完整设计 159 个接口；目前仅注册登录、个人资料及头像相关 10 个接口已实现，其余是待开发合同。前端 Vue 3，后端 Spring Boot + Spring MVC + MyBatis，MySQL 8.0。

- [通用约定](00-通用约定.md)
- [用户接口](01-用户接口.md)
- [领养接口](02-领养接口.md)
- [社区接口](03-社区接口.md)
- [商城接口](04-商城接口.md)
- [管理接口](05-管理接口.md)
- [数据模型](06-数据模型.md)
- [状态与业务规则](07-状态流转与业务规则.md)
- [需求覆盖](08-需求覆盖表.md)
- [OpenAPI 可导入文件](openapi.json)

身份改为 User.role=USER/ADMIN；不再返回 roleIds/permissions。管理员角色分配接口变为 PUT /api/v1/admin/users/{userId}/role。商城直接模拟购买成功，不对接支付平台。
