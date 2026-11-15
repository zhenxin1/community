# 寻爪 Pet Haven
寻爪是面向宠物领养与用品购买的Web系统，包含用户与平台治理、宠物发布和双向交接、自营商城选购及履约。普通用户可以发布与申请不同宠物，管理员负责账号处置、商品维护和订单发货。

## 技术与目录
Java17 / Spring Boot4.1.2 / MyBatis4.0.0 / MySQL8；Vue3.5.45 / Router4.6.4 / Pinia3.0.4 / Vite8.3.8。Node本机验证24.15.0。
`PetAdoptionCommunity`是后端，`vue1`是Vue源码；`scripts`负责构建/初始化/启动，`tests`为真实接口测试；`_bmad-output`为需求规划与故事，`evidence`记录实际验证。
后端遵循Controller→Service→Mapper，账号治理、宠物领养和商城业务共享身份体系与MySQL数据库。PRD定义功能和验收规则，接口合同规定前后端交互，架构文档约束分层职责与事务边界。

## 环境准备
需要JDK17、Node24（或满足Vite8引擎的版本）、MySQL8服务与命令行客户端、Python3（仅标准库管理脚本）、PowerShell。设置JAVA_HOME到JDK17并将java/node/npm/mysql/python加入PATH。本机JDK路径为`D:\Program Files\Java 17 for MC\jdk-17`，其他机器按实际安装修改。
在本仓库根目录`D:\Code\temp\final`执行：
```powershell
$env:JAVA_HOME='你的JDK17目录'
python scripts/manage.py configure
./scripts/build.ps1
python scripts/manage.py init
python scripts/manage.py serve
```
configure私密输入MySQL账号密码，仅写入已忽略`.local/runtime.json`。init只允许专用`pet_final`数据库，显式迁移并离线创建随机管理员；已存在ADMIN不覆盖密码，已有USER不提权。若已有本机配置和数据库，不必重复configure/init。
本机已配置后也可在根目录直接运行`./scripts/start.ps1`（自动识别本机JDK17）。serve或start保持运行，打开 http://127.0.0.1:8080/ 。生产包同时提供Vue与API，不需要额外启动前端。
另开终端初始化演示资料：
```powershell
python scripts/manage.py seed
./scripts/show-demo-accounts.ps1
```
演示包含6只宠物、14类28件商品；admin为后台，linlin为发布者，xiaoyu/anan为申请人和买家。上述脚本方式的密码随机生成，仅在本地查看，不提交、不录屏。seed有本地标记防止重复导入，不覆盖现有账号或商品。

## 使用根目录SQL初始化数据库

`pet_final.sql`是一份完整的MySQL 8初始化脚本，包含建库、13张表、4条迁移校验记录和教学演示数据。新环境可使用SQL方式替代前述`init`与`seed`，两种初始化方式二选一。

在仓库根目录打开MySQL客户端：

```powershell
mysql --default-character-set=utf8mb4 -u root -p
```

随后在MySQL提示符执行（其他目录按实际路径修改）：

```sql
SOURCE D:/Code/temp/final/pet_final.sql;
```

导入后，按环境准备步骤配置数据库连接并构建、启动即可，无须再执行`init`或`seed`。数据包括4个账号、6只待领养宠物、14类28件商品和2条虚构收货地址，不含会话、测试订单或本地数据库密码。

| SQL演示身份 | 账号 | 公开教学密码 |
|---|---|---|
| 管理员 | admin | Admin123456 |
| 宠物发布者 | linlin | User123456 |
| 买家与申请人 | xiaoyu | User123456 |
| 另一申请人 | anan | User123456 |

以上账号密码仅对应SQL在空库中创建的教学账号，不改变已有安装环境的账号密码。脚本不删除表、不清空业务记录；仅在迁移、账号、商品和宠物表均为空时插入演示数据。已有库重复导入不会重置账号或重复载入演示记录。

自动化测试读取`.local/demo-credentials.json`。若采用SQL方式在新环境运行`tests/integration.py`或`tests/quality.py`，将该本地文件配置为以下内容；使用原有脚本初始化的环境继续保留自身随机凭据：

```json
{
  "admin": {"account": "admin", "password": "Admin123456"},
  "publisher": {"account": "linlin", "password": "User123456"},
  "applicant": {"account": "xiaoyu", "password": "User123456"},
  "secondApplicant": {"account": "anan", "password": "User123456"}
}
```

SQL导入与实际应用的14项检查结果见`evidence/database-initialization-check.json`。

## 日常开发
终端一运行`python scripts/manage.py serve`。终端二进入`PetAdoptionCommunity/vue1`后执行`npm.cmd ci`、`npm.cmd run dev`，打开http://127.0.0.1:5173/。Vite将/api和/media代理至8080。
**构建前先停止本项目Vite及后端进程**，避免Windows锁住Rolldown原生依赖或jar；不要终止未知进程。运行窗口Ctrl+C正常停止。数据库和上传重启保留，登录Bearer仅内存，刷新需重登。

## 测试
后端业务启动并初始化后，在根目录执行：
```powershell
python tests/integration.py
python tests/quality.py
```
测试只创建带qa标签的教学记录，不清空数据库；结束后下架测试商品，保留相关记录便于核对。先核对测试目标为本项目专用库，不能指向其他真实系统。构建脚本运行全部纯规则JUnit测试；HTTP集合在真实MySQL应用服务路径执行。结果见evidence/verification.md，不把构建成功等同业务正确。

## 使用与边界
用户可发布/筛选/联系/申请宠物，发布者选定后双方确认；失败恢复待领养。联系方式按状态及当事关系开放。商城购物车及未付款不占库存，成功付款才原子扣减；优惠最高档满减后八折，全部模拟，不发生真实支付。ADMIN只在订单付款后查看收货详情并发货。
上传JPEG/PNG<=8MB，重编码保存`.local/uploads`；数据库迁移checksums防止改写已执行脚本。所有凭证、上传和本地日志不进入Git，缺失时按配置说明补齐。

## 课程交付与真实状态
第33页清单见docs/submission-index.md；追溯见docs/traceability.md；接口/数据库说明见docs/api-contract.md、docs/database.md。4史诗20故事，9条ADR，14条项目规则；实验附件见evidence/experiment-a/。
故事review表示已实现待负责人验收，不等于真人接受。尚需负责人补真实姓名分工、实际录制10分钟演示、确认实验A局限及GitHub远程/提交。docs/demo-script.md仅录屏提纲，不是视频。
实验B按老师补充免做；实验A沿用原有真实证据并披露跨日、任务差异和隔离不足，不能宣称严格对照或编造收益。

## AI使用声明与贡献说明
开发中使用Codex辅助需求整理、方案比较、文档、代码、界面及测试。功能边界和架构选择需要团队评估，实际完成程度由源码、版本记录及测试证据核对。团队分工覆盖账号与平台治理、宠物发布与领养、商城选购与履约、系统验证与交付；四名成员姓名、负责事项及工作量由负责人核对后填写。
Git署名、技术验证和人工接受分别记录，不将自动生成文档视为真实访谈或独立评审；实验结果、限制和未完成事项保留在复盘与提交清单中。

## 在IDEA运行主类
导入`PetAdoptionCommunity/pom.xml`，选择JDK17，运行`com.example.petadoptioncommunity.PetAdoptionCommunityApplication`。Working directory设为`D:\Code\temp\final\PetAdoptionCommunity`（其他机器用实际后端目录），以保持上传与资源路径一致。
`python scripts/manage.py configure`会同时写入已忽略的`.local/runtime.json`和`.local/application-local.properties`；脚本与IDEA读取相同配置来源，环境变量仍可覆盖。无需将数据库密码写入Java或提交到Git。当前机器已同步，重新运行主类即可。主类与start.ps1不要同时占用8080。
如出现`using password: NO`，表示没有读到本地连接密码，先核对上述私密文件和运行目录。迁移缺失与端口占用是不同故障，不通过关闭校验解决。

## 主要页面和演示路线
| 页面 | 路径 | 主要功能 |
|---|---|---|
| 首页 | / | 领养与商城入口、伙伴推荐和流程说明 |
| 寻找伙伴 | /pets | 名称、类别、地区、品种组合筛选 |
| 宠物详情与发布 | /pets/:id、/pets/new | 照片说明、联系信息授权、发布与申请 |
| 我的领养 | /adoptions | 本人申请、收到的申请、选定及交接确认 |
| 账号 | /account | 资料、通知与改密 |
| 商城 | /shop、/shop/:id | 分类搜索、详情、价格库存和加购 |
| 购物车与结算 | /cart、/checkout | 勾选、地址、优惠报价与建单 |
| 订单 | /orders | 模拟付款、取消、物流及收货 |
| 管理中心 | /admin | 用户、商品与订单管理 |
路径由Vue hash路由承载。普通用户在一个账号下既可发布也可申请他人宠物；管理员入口只有ADMIN可见且接口仍检查权限。

## 验收建议
先用发布者准备一只宠物，切换两名申请者申请，再由发布者选定与双方确认。另准备失败场景核对恢复及旧请求。商城选择两类商品、只勾选部分结算，核对地址与优惠，依次模拟付款失败、成功、发货、收货。最后检查账号冻结、通知和权限拒绝。完整10分钟讲解提纲见docs/demo-script.md。
