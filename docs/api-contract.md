# 统一HTTP接口合同

文档状态：`Done`。
前缀 /api/v1，JSON采用camelCase，成功返回DTO或列表；失败返回{code,message,requestId}，冻结核验额外reason/actionAt。401未认证/会话失效，403权限拒绝，404不存在，409冲突，400非法输入，413上传超限，503数据库依赖不可用。未知JSON字段拒绝；整数不接受浮点截断。前端不能提交可信userId/role/price/payable。
Authorization: Bearer <token>，仅内存保存，绝对30分钟，不刷新。退出POST无body返回204。资料与改密端点拒绝附加查询字段。

| 方法和路径 | 请求或查询 | 权限/行为 |
| --- | --- | --- |
| POST /auth/register | account,password,confirmPassword | 游客，201 USER |
| POST /auth/login | account,password | 正确ACTIVE凭据返回user/accessToken/expiresAt |
| POST /auth/logout | 无body | 撤销当前会话，重复204 |
| GET /me | 无 | 本人profile |
| PUT /me | nickname,bio,expectedProfileVersion | 本人，旧版本409 |
| POST /me/password | oldPassword,newPassword,confirmPassword | 成功204，全部旧会话失效 |
| GET /me/notifications | page,size,filter=ALL/UNREAD | 本人分页 |
| GET /me/notifications/{id} | 无 | 本人，查看不自动读 |
| PUT /me/notifications/{id}/read | 无body | 本人，首次readAt不被重放覆盖 |
| GET /admin/users | accountContains,status,page,size | ADMIN，size=10/20/50 |
| GET /admin/users/{id} | 无 | ADMIN，含stateVersion |
| POST /admin/users/{id}/state | operationId,expectedStateVersion,targetStatus,reason | ADMIN，仅USER，状态通知命令同事务 |
| POST /admin/users/{id}/notifications | operationId,title,body | ADMIN单用户通知，逻辑命令幂等 |
| GET /admin/operations/{operationId} | 无 | 原操作者查结果，404不证明原请求必败 |
| GET /pets | keyword,category,region,breed,page | 游客，每页12，仅AVAILABLE，不含联系字段 |
| GET /pets/{id} | 无 | 按身份/宠物状态裁剪联系方式 |
| POST /pets | name,category,province,region,breed,description,image,phone,wechat,email | 登录，类别cat/dog，至少一种联系渠道 |
| POST /pets/{id}/applications | 无body | 非发布者，AVAILABLE，重复最多一份有效 |
| GET /adoptions | 无 | 本人发布宠物和相关申请 |
| POST /adoptions/{id}/select | 无body | 发布者，一份当前交接 |
| POST /adoptions/{id}/success | 无body | 当事双方分别确认 |
| POST /adoptions/{id}/failure | 无body | 任一当事方结束本轮，恢复待领养 |
| GET /products | keyword,category,page | 游客，仅上架；推荐优先，每页12 |
| GET /products/{id} | 无 | 游客，上架商品 |
| GET /admin/products | keyword,page | ADMIN，含下架商品 |
| POST /admin/products | name,category,description,image,price,stock,listed,recommended,version | ADMIN，price整数分，stock整数 |
| PUT /admin/products/{id} | 同上，version为已读版本 | ADMIN，旧版本409，付款扣减递增版本 |
| GET /cart | 无 | 本人购物车 |
| POST /cart/{productId} | quantity,selected | 数量累加，超过库存拒绝 |
| PUT /cart/{productId} | quantity,selected | 绝对数量替换，正整数 |
| DELETE /cart/{productId} | 无body | 删除本人该行 |
| GET /addresses | 无 | 本人地址 |
| POST /addresses | recipient,phone,address | 本人创建 |
| PUT /addresses/{id} | 上述字段加version | 本人编辑，旧版本409 |
| GET /orders/quote | addressId | 当前勾选行及地址的服务端报价和quoteToken |
| POST /orders | addressId,quoteToken,operationId | 同用户同operationId同内容返回原单，异内容409；成功移除所选行 |
| GET /orders、GET /orders/{id} | 无 | 本人列表/本人或ADMIN详情 |
| POST /orders/{id}/pay | success=true/false | 本人模拟结果，实际成功与库存一次提交 |
| POST /orders/{id}/cancel | 无body | 本人待付款 |
| POST /orders/{id}/receive | 无body | 本人已发货，重复保持COMPLETED |
| GET /admin/orders | 无 | ADMIN，未付/取消订单裁剪收货字段 |
| POST /admin/orders/{id}/ship | carrier,tracking | ADMIN，PAID才可发货 |
| POST /uploads | multipart file | 登录，<=8MB JPEG/PNG，<=2000万像素，重编码 |
| GET /health | 无 | 健康摘要 |

## 报价、重试和状态
quoteToken绑定当前所选商品ID/数量/单价/版本和地址版本；改变后必须重新确认，不自动按新金额下单。建单operationId为UUID，一次意图稳定，未知结果先查本人订单或以原请求重试。付款按订单锁和升序商品锁整单提交，不用操作日志去重。
order状态PENDING待付款、PAID待发货、SHIPPED已发货、COMPLETED完成、CANCELLED取消。宠物AVAILABLE/HANDOVER/ADOPTED，申请PENDING/SELECTED/SUCCESS/NOT_SELECTED/CANCELLED。金额整数分，时间UTC，上海时区展示。
