# 寻爪 Pet Haven

寻爪是宠物领养与用品购买 Web 系统，覆盖账号治理、宠物发布与领养交接、自营商城选购及订单履约。普通用户可以发布宠物、提交领养申请和购买用品；管理员负责账号处置、通知、商品库存维护和订单发货。

## 功能与业务边界

| 领域 | 主要功能 | 关键规则 |
|---|---|---|
| 账号与治理 | 注册登录、资料修改、改密、通知、冻结解冻 | 固定 USER/ADMIN；会话可撤销；敏感操作在服务端鉴权 |
| 宠物领养 | 发布、组合筛选、联系、申请、选定、交接确认 | 每轮只选定一份申请；双方确认才成功；失败保留历史并恢复待领养 |
| 商城选购 | 分类搜索、购物车勾选、地址、优惠、建单 | 服务端以整数分报价；订单保存商品、金额和地址快照 |
| 商城履约 | 模拟付款、库存扣减、取消、后台发货和收货 | 付款时全单校验并原子扣库存；重复请求不重复扣减 |

联系方式按宠物状态和当事关系返回；个人订单、地址和通知均检查归属。系统采用模拟支付和人工物流信息，不发生真实资金交易，不接入真实物流服务。具体范围见[产品简报](_bmad-output/planning-artifacts/product-brief.md)和[PRD](_bmad-output/planning-artifacts/PRD.md)。

## 技术栈与目录

| 组件 | 版本或约定 |
|---|---|
| Java / Spring Boot / MyBatis | 17 / 4.1.2 / 4.0.0 |
| 数据库 | MySQL 8，InnoDB，utf8mb4，UTC |
| Vue / Vue Router / Pinia | 3.5.45 / 4.6.4 / 3.0.4 |
| Vite / plugin-vue | 8.3.8 / 6.0.10 |
| 构建与辅助工具 | Node.js 24、Python 3、PowerShell、Maven Wrapper |

后端使用 Spring MVC，职责依次为 Controller → Service → Mapper。Controller 处理请求和响应，Service 负责业务规则、授权和事务，Mapper 负责数据访问。

```text
PetAdoptionCommunity/
  src/main/java/         后端业务与接口
  src/main/resources/    配置、迁移及生产资源
  src/test/java/         单元测试
  vue1/                  Vue 前端
_bmad-output/            产品、需求、架构、故事及Sprint状态
docs/                    接口、数据库、追溯与交付说明
tests/                   HTTP/MySQL业务和质量检查
evidence/                测试结果、浏览器记录和实验A附件
scripts/                 配置、构建、初始化及启动脚本
pet_final.sql            单文件数据库结构及教学数据
decision-log.md          人机决策日志
retrospective.md         质量复盘与实验报告
```

## 环境与启动

运行环境需要 JDK17、Node.js24、MySQL8、Python3 和 PowerShell。`java`、`node`、`npm`、`mysql`、`python`需可从终端调用，`JAVA_HOME`指向 JDK17安装目录。以下命令均从仓库根目录执行。

### 脚本初始化方式

```powershell
python scripts/manage.py configure
./scripts/build.ps1
python scripts/manage.py init
python scripts/manage.py serve
```

`configure`交互输入数据库连接凭据，生成被 Git 忽略的本地配置。`init`创建专用数据库`pet_final`，按 V001—V004执行迁移，并离线初始化管理员；已有账号不会重置密码，普通账号不会被提升为管理员。`build.ps1`安装锁定的前端依赖、构建页面、运行后端单元测试并生成完整应用包。

服务运行后，在另一终端执行：

```powershell
python scripts/manage.py seed
./scripts/show-demo-accounts.ps1
```

演示资料包含6只宠物、14类28件商品和4个账号。脚本初始化的密码随机生成，仅保存在本地配置中；重复执行已有初始化不会重置密码或重复载入演示商品。

访问地址：**http://127.0.0.1:8080/**。应用包同时提供 Vue 页面与 API。已有本地配置及构建包时，可使用`./scripts/start.ps1`启动；启动脚本与其他应用实例共用8080端口，同一时刻仅运行一个实例。

### SQL初始化方式

根目录[pet_final.sql](pet_final.sql)包含建库、13张表、4条迁移校验记录及教学数据。此方式与脚本的`init`、`seed`二选一。

在仓库根目录打开客户端：

```powershell
mysql --default-character-set=utf8mb4 -u root -p
```

在 MySQL 提示符执行：

```sql
SOURCE pet_final.sql;
```

导入后执行`configure`、`build.ps1`和`serve`，无需重复初始化。SQL不删除表、不清空业务记录；仅在相关表为空时插入演示数据，不覆盖已有账号密码。

| SQL演示身份 | 账号 | 公开教学密码 |
|---|---|---|
| 管理员 | admin | Admin123456 |
| 发布者 | linlin | User123456 |
| 买家与申请人 | xiaoyu | User123456 |
| 另一申请人 | anan | User123456 |

以上仅为SQL在空库中创建的教学凭据。SQL方式运行自动化测试时，`.local/demo-credentials.json`应与这些账号对应；脚本方式使用其生成的随机凭据。配置格式如下：

```json
{
  "admin": {"account": "admin", "password": "Admin123456"},
  "publisher": {"account": "linlin", "password": "User123456"},
  "applicant": {"account": "xiaoyu", "password": "User123456"},
  "secondApplicant": {"account": "anan", "password": "User123456"}
}
```

## 开发与测试

后端运行后，可在`PetAdoptionCommunity/vue1`目录执行：

```powershell
npm.cmd ci
npm.cmd run dev
```

前端开发地址为 http://127.0.0.1:5173/，`/api`和`/media`代理至8080。生产构建前需停止对应开发进程和占用应用包的实例，释放文件锁。

在已初始化且运行的专用教学环境中，从仓库根目录执行：

```powershell
python tests/integration.py
python tests/quality.py
```

测试创建带`qa`标记的资料并保留验证记录，不清空数据库。质量结果包括5项JUnit、45项HTTP/MySQL业务检查、17项补充业务检查，以及独立SQL初始化检查。完整口径见[技术验证记录](evidence/verification.md)，需求与验证的对应关系见[追溯矩阵](docs/traceability.md)。

## 页面入口

页面使用Vue hash路由，例如`http://127.0.0.1:8080/#/pets`。

| 路径 | 功能 |
|---|---|
| `/` | 首页与业务入口 |
| `/login`、`/account` | 注册登录、资料、通知和改密 |
| `/pets`、`/pets/:id`、`/pets/new` | 宠物查找、详情、联系和发布 |
| `/adoptions` | 本人申请、收到的申请及交接处理 |
| `/shop`、`/shop/:id` | 商品分类搜索及详情 |
| `/cart`、`/checkout` | 勾选购物车、地址、报价和下单 |
| `/orders` | 付款、取消、物流和收货 |
| `/admin` | 用户、商品和订单管理 |

会话仅保存在页面内存中，刷新后重新登录。数据库凭据、演示凭据、上传、日志和构建输出均遵守Git忽略规则。上传支持JPEG/PNG，限制为8MB及2000万像素，解码后重新编码保存。

## 课程产物与交付记录

项目包含21条FR、5条NFR、9条ADR、4个史诗、20个故事、14条实现规则和30项人机决策。十类产物及材料登记见[提交材料索引](docs/submission-index.md)。

- 仓库：[zhenxin1/community](https://github.com/zhenxin1/community)。
- 故事状态：[sprint-status.yaml](_bmad-output/implementation-artifacts/sprint-status.yaml)，20个故事均为`done`，完成依据为项目负责人确认。
- 演示路线：[十分钟演示提纲](docs/demo-script.md)；实际视频链接尚未登记。
- 实验A：[复盘与实验报告](retrospective.md)，附件位于`evidence/experiment-a/`。
- 实验B：依据教师补充说明免做。

## 团队分工登记

| 责任领域 | 工作内容 | 成员登记 |
|---|---|---|
| 账号与平台治理 | 身份、资料、权限、通知及管理规则 | 未登记 |
| 宠物发布与领养 | 发布查找、申请、交接及失败恢复 | 未登记 |
| 商城选购与履约 | 商品、购物车、报价、订单、库存和收发货 | 未登记 |
| 系统验证与交付 | 测试、部署、产物追溯、复盘及演示 | 未登记 |

成员姓名及实际工作量尚未提供；上表列示责任领域，不作为个人工作量统计。

## AI使用声明

| 项目 | 登记内容 |
|---|---|
| Agent／开发工具 | Codex |
| AI模型 | GPT6.1 Sol |
| 方法与技能框架 | BMAD Method 6.12.4 |

Codex与GPT6.1 Sol用于辅助需求整理、方案比较、文档、代码、界面和测试。BMAD组织项目资料与技能入口。需求边界、方案取舍、测试结论和验收判断由项目团队负责。

人机决策见[decision-log.md](decision-log.md)，测试结果与实验限制分别保存在技术验证记录及复盘中。实验首版、首评和修补结果独立留存，不以最终测试成绩替代实验初版数据。
