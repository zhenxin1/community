# Git 与 AI 协作管理手册

适用项目：爪爪社区。适用人员：使用 AI 辅助开发、刚开始学习 Git 的四人课程小组。

本手册帮助每位成员完成：获取项目、创建功能分支、让 AI 开发、保存并上传代码、同步队友修改、提交合并申请，以及处理冲突。终端示例使用 Windows PowerShell，在 IDEA 底部“终端”中执行即可。

仓库地址：[zhenxin1/community](https://github.com/zhenxin1/community)。默认主分支为 `main`，不另设 `dev` 分支。当前项目已有注册、登录和个人资料功能，完整 25 张数据库表已建立；其余业务按功能逐步开发。

## 先读这一页：团队约定

1. `main` 保存已验证可用的公共版本。日常功能在自己的功能分支完成，通过 PR 合入。
2. 一个小功能建一个分支，例如 `feature/community-comment`。不要等整个社区或商城模块全部写完才合并。
3. 同一台电脑、同一个项目文件夹里，同时只让一个会修改代码的 AI 任务工作。两个聊天窗口共享文件夹时，也共享当前 Git 分支。
4. 开始新功能前更新 `main`；开发期间及时把最新 `main` 合进自己的功能分支。
5. 经常在功能分支提交和推送；完成、验证并审核后才合入 `main`。
6. 修改公共代码、接口合同或数据库前，先与对应负责人确认；不要顺手重构其他模块。
7. 本机数据库数据、密码、依赖和构建产物不提交；共享 SQL 和必要的示例配置。
8. AI 修改完成后，查看文件变化和验证结果，再决定提交哪些文件。

这些是本小组的协作约定。若仓库尚未设置分支规则，GitHub 不会仅因这份手册存在就阻止直接推送 `main`。

日常操作顺序：

```text
更新 main → 创建功能分支 → AI 开发 → 检查和验证 → 提交、推送功能分支
→ 同步最新 main 并验证 → 创建 PR → 负责人审核合并 → 更新 main → 下一个功能
```

遇到不熟悉的提示，先执行 `git status`，保留完整提示，再按第 12 节处理。每一步成功后再执行下一步，不要整页命令一次性粘贴。

## 目录

- [1．理解 Git 中的几个名字](#basics)
- [2．确定模块和公共文件负责人](#ownership)
- [3．新成员第一次获取项目](#onboarding)
- [4．开始一个新功能](#new-feature)
- [5．让 AI 在功能分支开发](#ai-development)
- [6．检查、提交并推送改动](#commit-push)
- [7．开发中同步队友代码](#sync-main)
- [8．创建 PR 和审核合并](#pull-request)
- [9．合并后开始下一个功能](#after-merge)
- [10．解决合并冲突](#conflicts)
- [11．管理数据库、依赖和配置](#database)
- [12．常见问题和恢复办法](#troubleshooting)
- [13．可直接交给 AI 的提示词](#ai-prompts)
- [14．负责人和成员的检查单](#checklists)
- [15．常用命令速查](#commands)
- [16．官方参考](#references)

<a id="basics"></a>
## 1．理解 Git 中的几个名字

| 名称 | 在本项目中的意思 |
| --- | --- |
| Git | 电脑上记录和合并代码版本的工具 |
| GitHub | 存放远程仓库、交流和审核 PR 的网站 |
| 仓库 | 项目文件及其 Git 历史 |
| 工作区 | 你当前项目文件夹中正在编辑的文件 |
| 暂存区 | 这一次准备放进提交的改动 |
| commit／提交 | 在本地记录一个版本；提交后还没有自动上传 |
| push／推送 | 把本地提交上传到远程分支 |
| 分支 | 一条独立的开发路线；每条分支都包含整个项目 |
| main | 本机的主分支 |
| origin | 本机给 GitHub 仓库起的远程名称 |
| origin/main | 本机保存的远程主分支信息，需要 fetch 才会更新 |
| fetch | 获取远程提交和分支信息，不会直接把改动合进当前分支 |
| merge | 把指定分支的修改合进当前分支 |
| pull | 获取远程更新并整合到当前分支；本手册在 main 上使用 `--ff-only` |
| PR | Pull Request，申请把功能分支合入 main，并让其他人审核 |

创建分支不会额外复制一个项目文件夹。切换分支时，同一个文件夹会显示该分支的版本。**尚未提交的改动不一定只属于当前分支**，它们可能随切换带过去，也可能阻止切换，所以先处理工作区改动再切分支。

推送到功能分支不会自动改变 `main`。合并 PR 后，其他成员还需要更新自己的本地代码。

## 2．确定模块和公共文件负责人
<a id="ownership"></a>

建议负责人维护以下分工表，实际人员在小组内确定；表中的 A、B、C 只是组员代称。

| 人员 | 主要负责 | 相关管理端工作 |
| --- | --- | --- |
| 项目负责人 | 账号模块、公共代码协调、数据库编号、文档总版本、PR 审核 | 管理员登录和公共权限逻辑 |
| 组员 A | 领养页面、Controller、Service、Mapper、DTO／VO | 宠物审核、领养记录和投诉 |
| 组员 B | 社区页面、帖子、日记、求助、评论和互动 | 社区审核和举报 |
| 组员 C | 商城页面、商品、购物车、地址、订单和退款 | 商品、订单和退款管理 |

按模块分工不需要再创建四套项目或重新拆 Maven 模块。现有 `user`／`admin` 分类下可以放不同业务类，每个人维护自己负责的文件。

以下内容由负责人协调修改：

| 公共内容 | 修改前要确认什么 |
| --- | --- |
| `backend/pom.xml` | 为什么增加或升级依赖，其他电脑如何安装 |
| `application.yml`、启动和构建脚本 | 是否影响他人启动，是否混入本机密码或绝对路径 |
| `common`、`security`、统一异常、用户实体等 | 是否影响登录、接口格式和其他模块 |
| 前端路由、导航、公共请求封装 | 新入口放哪里，是否改变原有调用方式 |
| 完整 SQL、数据字典、完整 OpenAPI 文件 | 是否与增量 SQL、请求字段和返回字段一致 |
| 锁文件 | 是否确实变更依赖，避免为了“解决冲突”直接删除后重建全部依赖版本 |

“由负责人协调”不代表其他人不能改。需要时在 PR 中写清原因，由负责人确认影响。业务模块文件优先由该模块成员修改，减少交叉改动。

<a id="onboarding"></a>
## 3．新成员第一次获取项目

### 3.1 准备环境和权限

每位成员需要 GitHub 账号，接受仓库协作邀请，并准备 Git、JDK 17+、Maven 3.6.3+、Node.js 和 MySQL。Node.js 可使用 22.12+ 的受支持版本；MySQL 使用兼容本项目脚本的 8.0 版本，最低 8.0.17，项目验证版本为 8.0.35。

`JAVA_HOME` 指向 JDK；Maven、Node.js 和 Git 的命令需要能在终端中使用。启动器从 `MYSQL_HOME` 或 `PATH` 找 MySQL 程序。项目自己的 MySQL 默认端口为 33079，网页默认端口为 18080。

### 3.2 克隆仓库，只做一次

在准备存放项目的父文件夹打开终端，执行：

```powershell
git clone https://github.com/zhenxin1/community.git
cd community
git status
```

预期：当前分支为 `main`，工作区干净。已有完整 Git 仓库的成员直接打开现有项目，不要再次运行 `git init`，也不要把新克隆的仓库放进旧项目里面。

负责人本机项目路径为 `D:\postgraduate\FIrstYear\community`；其他成员可以放在自己的路径。后续命令都在含 `backend`、`frontend`、`database`、`.gitignore` 的项目根目录执行。

### 3.3 配置提交身份

先查看配置：

```powershell
git config user.name
git config user.email
```

已有正确结果就不必重设。若没有配置，或本项目要使用另一身份，分别将下面两个示例值换成自己的名字和邮箱：

```powershell
git config user.name "张同学"
git config user.email "你的GitHub提交邮箱"
```

这里没有使用 `--global`，只设置当前仓库。名字用于记录作者，不必等于 GitHub 用户名；邮箱使用 GitHub 已验证邮箱或账号提供的 noreply 邮箱，便于关联提交。**这不是 GitHub 登录账号和密码。**

首次访问私有仓库或推送时，需要完成 GitHub 身份验证；具体方式取决于电脑配置的凭据管理器、HTTPS 令牌或 SSH。不要把登录凭据写进代码、聊天提示词或仓库地址。

### 3.4 构建和启动

在项目根目录依次执行：

```powershell
.\重新构建.cmd
.\启动项目.cmd
```

先确认构建成功，再启动；看到 `Ready` 后访问 `http://127.0.0.1:18080/login`。`重新构建.cmd` 会安装锁定的前端依赖、构建页面并打包后端，过程中也会停止本项目已经运行的服务。

启动脚本会为这台电脑创建独立 MySQL 数据目录，建立完整 25 张表，并初始化社区、商品分类各 4 条。首次使用自己注册应用账号。其他成员已有的账号和订单不会自动出现。

详细数据库操作见 [完整数据库初始化与升级](../database/06-初始化与校验.md)。

<a id="new-feature"></a>
## 4．开始一个新功能

以“社区评论”为例。动手前与负责人确认：本次要完成什么、接口和表字段是否已确定、谁同时在改公共文件。

### 4.1 检查项目和工作区

```powershell
git status
git branch --show-current
```

若有自己上个功能未提交的改动，先在原功能分支提交；若是队友或 AI 遗留、归属不明的改动，先确认，不要直接一起提交。工作区干净后继续。

### 4.2 更新主分支，再建新分支

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/community-comment
git branch --show-current
```

最后应显示 `feature/community-comment`。`-c` 表示创建并切换；同名分支已经存在时不要继续重复创建，先判断是继续旧任务还是另起新功能。

`--ff-only` 只允许本机 main 直接前进到远程版本；本机 main 若有独立提交，命令会拒绝，按第 12 节处理，不要改成强制覆盖。

### 4.3 分支命名和拆分

| 类型 | 示例 |
| --- | --- |
| 新功能 | `feature/pet-publish`、`feature/community-comment`、`feature/shop-cart` |
| 修复问题 | `fix/login-redirect` |
| 文档 | `docs/git-handbook` |

名称使用小写英文和短横线。同一功能有两人参与时，应事先约定同一分支协作还是拆成不同子功能，避免两个人各自创建同名但内容不同的分支。

一个功能分支通常覆盖一个能检查的目标。例如先做帖子列表和详情，再做发布和编辑，之后做评论。具体开发几天没有硬性限制；若一次 PR 难以说明和验证，就继续拆小。

<a id="ai-development"></a>
## 5．让 AI 在功能分支开发

开工时告诉 AI：当前分支、本次功能、接口依据、可以修改的文件范围，以及验证方式。可直接使用第 13 节模板。

AI 开始前应检查 `git status` 和当前分支。若发现自己在 `main`，先确认工作区状态并创建功能分支；不要一边生成大量代码，一边临时切换到别人的任务分支。

开发中遵守以下约定：

- 同一个项目文件夹只运行一个会写代码或切分支的 AI 任务。需要并行时使用各自独立克隆，并使用不同功能分支；多进程运行项目还需要不同端口和独立数据库配置。本小组初期优先每人一份克隆。
- 限制为本次功能需要的改动。不要让 AI 顺手改包结构、批量格式化、重命名全项目或升级依赖，这些变化会扩大 PR。
- AI 发现需要修改公共接口或数据库，应说明影响，与负责人确认设计后再修改。
- 每完成一个能说明的阶段，可以提交到功能分支保存进度；未完成的功能可以推送，但暂不合入 main。
- 结束时要求 AI 列出修改文件、验证结果、数据库升级要求和未完成内容。没有执行的验证不能写成“已通过”。

Git 能记录已提交的改动；未保存到文件的编辑和被忽略的数据库实际数据不由 Git 自动备份。AI 聊天记录也不能替代提交。

<a id="commit-push"></a>
## 6．检查、提交并推送改动

### 6.1 查看这次到底改了什么

在自己的功能分支执行：

```powershell
git status
git diff --stat
git diff
```

`git diff` 显示已跟踪文件尚未暂存的变化；新文件需要直接打开查看，或暂存后用 `git diff --staged` 查看。负责人重点看公共类、SQL、配置、依赖和接口字段。

执行适合本次变化的验证。功能代码至少完成受影响页面或接口的实际检查；前后端一并改动时，构建并验证完整流程。文档修改检查内容和链接即可，不要求每次文档提交都构建项目。

本项目完整构建可运行 `重新构建.cmd`。这会停止本项目服务，构建后要重新启动才能验收。`tests/api_smoke.py` 和浏览器检查脚本会创建随机测试账号，不能把它们当作对已有日常数据的纯只读检查；需要时使用独立测试实例。

### 6.2 选择文件并检查暂存区

**只有确认工作区所有变化都属于本次提交时**，才使用：

```powershell
git add .
git diff --staged --stat
git diff --staged
```

若混有其他改动，在 IDEA 的提交界面仅勾选本次相关文件，或使用 `git add -- "具体文件路径"`。仅部分代码行属于本任务时，需要进一步按块选择，不能只按文件整份提交。路径参数中的示例文字需要换成实际路径。

误暂存的文件可以取消暂存，代码仍会保留：

```powershell
git restore --staged -- "具体文件路径"
```

### 6.3 提交和上传

确认暂存区无密码、数据库实际数据和无关改动后：

```powershell
git commit -m "实现社区评论发布与列表"
git push -u origin feature/community-comment
git status
```

预期：提交成功，功能分支上传成功，工作区没有遗漏的改动。第一次推送使用 `-u` 建立本地与远程分支的对应关系，以后同一分支可以直接 `git push`。

一个 PR 可以有多个提交；后续在该分支继续提交和推送，已有 PR 会更新。提交说明写具体行为，例如“修复评论回复归属校验”，不要长期只写“修改”“更新”。

## 7．开发中同步队友代码
<a id="sync-main"></a>

场景：你正在评论分支开发，队友把宠物发布合入了 main。你不需要删掉自己的分支重来。

先提交自己手头的修改，确认当前确实是功能分支且工作区干净，然后执行：

```powershell
git branch --show-current
git fetch origin
git merge --no-edit origin/main
git status
```

这会把最新主分支合进**当前功能分支**。`--no-edit` 在需要产生普通合并提交时采用默认说明，避免新手被带进终端编辑器；若发生冲突，仍需按第 10 节处理。

成功后检查受影响功能，再将同步结果推送到自己的分支：

```powershell
git push
```

说明：

- 每天开工时检查 main 是否更新；公共接口或公共代码变更合入后及时同步。
- PR 准备合并前再检查一次。若 main 此后又更新，负责人根据影响要求重新同步验证。
- `git pull` 在功能分支上通常更新的是该功能分支自己的远程版本，不保证带来 main 的新变化。因此统一用上面的 fetch 和 merge 同步主分支。
- 在功能分支执行 `git merge origin/main` 是把主分支合过来；不要反过来切到 main 后执行 `git merge 功能分支` 来绕开 PR 审核。
- Git 没提示冲突也需要联调。后端改返回字段、前端仍使用旧字段，就可能自动合并成功但功能失败。

<a id="pull-request"></a>
## 8．创建 PR 和审核合并

### 8.1 成员创建合并申请

1. 推送自己的功能分支。
2. 在 GitHub 仓库打开 **Pull requests → New pull request**。
3. `base` 选 `main`，表示合入目标；`compare` 选自己的功能分支，表示本次来源。
4. 检查文件列表和修改范围，填写标题与说明，指定负责人审核。
5. 未完成但希望提前交流时，使用 Draft PR；验证完成后再标记可审核。

PR 说明可采用下面结构，按实际内容填写：

```text
完成内容：
社区详情页支持发布评论、显示评论列表，仅登录用户可提交。

相关接口／页面：
列出本次实际修改的接口和页面。

验证：
写清运行过哪些构建、接口或页面检查，以及结果。
未执行的检查明确写未执行。

数据库：
说明是否有升级 SQL；如有，写脚本名、执行顺序、备份及验证方式。

公共文件与影响：
列出公共代码、配置、依赖、接口字段的变化；没有则写无。

未完成内容：
明确哪些需求不属于本次 PR。
```

### 8.2 负责人审核

负责人查看 **Files changed**，确认范围、业务权限、接口字段、SQL 和验证结果。复杂功能拉到本机或独立检查目录实际运行，不能只根据 AI 的“已完成”判断。

在干净的工作区查看队友功能分支，示例：

```powershell
git fetch origin
git switch --track origin/feature/community-comment
```

此命令用于本机还没有同名分支时。本机已有该分支时使用 `git switch feature/community-comment`，再 `git pull --ff-only origin feature/community-comment`。若本机已有独立提交，先核对，不强行覆盖。

审核中需要修改时，通常由原作者修改并推送该功能分支。负责人若要亲自改队友分支，应先沟通，避免两人同时推送造成分叉。

### 8.3 合并方式和顺序

初期统一采用 **Create a merge commit**，保留各次提交和明确的合并记录；这是本手册建议的团队约定，并未自动更改仓库设置。如果仓库只允许其他方式，由负责人统一确定后更新手册。[GitHub 合并方式说明](https://docs.github.com/en/pull-requests/reference/pull-request-merges)

一次合并一个 PR。依赖其他未合并 PR 的功能，应说明依赖，先合并基础功能；不要把其他人的未完成代码随手复制到自己的分支。

合并前确认：功能可用、工作区变化可解释、所需 SQL 已提供、相关接口与文档一致。合并后在小组中说明“合了什么、有没有 SQL 或依赖变更”，便于其他人及时同步。

本流程依据 GitHub 的分支与 PR 协作方式编排；拆分大小、审核人和合并方法属于小组自己的约定。[GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow)

<a id="after-merge"></a>
## 9．合并后开始下一个功能

先确认 PR 在 GitHub 显示已合并，本机该功能分支没有尚未提交或尚未推送的新工作，再执行：

```powershell
git switch main
git pull --ff-only origin main
git branch -d feature/community-comment
git switch -c feature/community-like
```

预期：本机 main 包含刚才合并的功能，旧本地分支删除，当前进入新的点赞分支。旧远程分支可以在 PR 页面点击 **Delete branch**；它与本地分支是两个不同对象，删除远程分支不会自动删除本地分支。

删除已经合并的分支不会删除已合入 main 的代码和提交历史。若 `-d` 提示未完全合并，先检查有无未上传的新提交，以及 PR 是否采用了 Squash／Rebase 等不同方式；确认之前不要改成 `-D` 强制删除。

旧功能后续发现问题时，从最新 main 新建 `fix/...` 分支修复。不要在已合并且已经结束的旧分支上长期叠加新任务。

## 10．解决合并冲突
<a id="conflicts"></a>

### 10.1 什么时候会冲突

| 情况 | 常见结果 |
| --- | --- |
| 修改不同文件 | 通常自动合并 |
| 修改同一文件不同位置 | 通常也可自动合并 |
| 修改同一段代码 | 可能需要人工决定最终内容 |
| 一方删除文件，另一方修改该文件 | 可能出现删除／修改冲突 |
| 接口和页面逻辑不一致 | 可能无文本冲突，但运行失败 |

分支不会消除冲突；小功能、及时同步、公共文件协调可以减小每次处理的范围。[GitHub 冲突说明](https://docs.github.com/en/pull-requests/reference/merge-conflicts)

### 10.2 在功能分支解决

假设在干净的功能分支执行 `git merge --no-edit origin/main` 后提示冲突：

1. 执行 `git status`，列出冲突文件。
2. 在 IDEA 的合并工具中查看双方改动，或打开文本中的冲突标记。
3. 与另一位修改者确认预期行为，整理最终内容。两边都需要时应重新组合，不机械“全部选我的”或“全部选对方的”。
4. 确认所有冲突文件已处理，移除冲突标记，检查接口与数据库兼容性，构建并验证受影响功能。
5. 只暂存本次已处理、已确认的文件，完成合并提交后推送。

第 5 步示例；这里假设工作区只有本次合并相关变化：

```powershell
git add .
git diff --staged
git status
git commit -m "合并最新 main 并解决社区评论冲突"
git push
```

如果提交前仍有未合并文件，Git 会拒绝完成提交。先解决剩余冲突，不要反复执行提交命令。处理后的代码仍在自己的功能分支，PR 会随推送更新。[官方冲突处理步骤](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/resolving-a-merge-conflict-using-the-command-line)

### 10.3 解决不了，退出本次合并

仅在当前确实处于尚未完成的 merge 时使用：

```powershell
git merge --abort
git status
```

这会尝试恢复到本次合并前。正因为合并前要求先提交自己的改动，恢复才更可控；如果合并前已有未提交变化，Git 不保证能够完整恢复那些变化。退出后保留提示，交给负责人协助。[Git merge 官方说明](https://git-scm.com/docs/git-merge)

## 11．管理数据库、依赖和配置
<a id="database"></a>

### 11.1 每个人的数据库相互独立

每人本地一套 MySQL 数据，不需要共同连接负责人的电脑。共享的是代码、SQL、数据字典和不含私人信息的测试样例。

当前新电脑启动器自动建立 25 张表，已有两表库可自动补齐。**Git 切换分支不会切换 MySQL 数据，也不会自动撤销 SQL。** Git 提交不是数据库备份。

### 11.2 修改表结构

1. 模块成员先提出表和字段变更，由负责人协调字段名、默认值、兼容性与脚本编号。
2. 新增升级 SQL，例如下一份 `003-add-...sql`；脚本名按实际变化确定，编号先确认再使用。
3. SQL 尽量兼容已有数据；执行前备份，涉及填充数据或非空字段时说明处理顺序。
4. 更新必要的完整建表 SQL、数据字典和接口文档。完整脚本用于新空库，增量脚本用于已有库，结果应一致。
5. 代码、SQL 和说明放在同一个 PR；在自己的测试库验证后，由负责人合并。
6. 其他成员更新代码，按 PR 写明的顺序执行尚未执行的迁移，再验证功能。

已经被组员执行过的迁移脚本保留原内容；后续修正使用新编号。不要通过反复修改旧迁移，让不同电脑执行到不同结果。编号是本小组约定，当前没有 Flyway／Liquibase 自动迁移机制；每人需要自行记录哪些迁移已执行，不能把“SQL 文件已拉下来”等同于“数据库已经升级”。

当前启动器只处理手册中已说明的初始化与历史升级，不会自动扫描并执行未来所有 `003`、`004` 脚本。不要对已有库反复执行完整 `01-schema.sql`，也不要通过删库解决普通代码冲突。细节见 [数据库初始化说明](../database/06-初始化与校验.md)。

### 11.3 依赖和构建

前端依赖改变时一起提交 `package.json` 和对应 `package-lock.json`，其他成员运行 `npm ci` 或完整构建。不要提交 `node_modules`。后端依赖变更记录在 `backend/pom.xml`，经确认后重新构建。

拉到新代码后，仅重新打开网页可能还在访问旧 JAR。按变化重新构建并重启；完整 `重新构建.cmd` 会处理前后端并停止旧项目进程。独立使用 Vite 调试前端时，确认其 `/api` 代理与后端实际端口一致。

### 11.4 哪些文件不能一起上传

本项目 `.gitignore` 已排除：

| 内容 | 原因 |
| --- | --- |
| `.runtime/` | MySQL 实际数据、本机凭据、日志和备份 |
| `.cache/` | 本机依赖下载缓存 |
| `**/target/`、`frontend/dist/` | 构建产物，可从源码重新生成 |
| `frontend/node_modules/` | 安装得到的依赖 |
| `storage/uploads/` | 本机上传的头像等文件 |
| `.env`、`.env.*`（保留 `.env.example`） | 本机环境值；示例文件只放非秘密示例 |
| `.idea/`、`.vscode/`、`*.log` | IDE 本机配置和日志 |

`.gitignore` 不会自动取消已经被 Git 跟踪的文件，也不会删除已有提交中的秘密。发现密码被提交时立即告知负责人，更换相关凭据并检查历史；仅新增忽略规则不能让旧提交中的密码消失。[GitHub 忽略文件说明](https://docs.github.com/en/get-started/git-basics/ignoring-files)

<a id="troubleshooting"></a>
## 12．常见问题和恢复办法

### 12.1 提示本地改动会被覆盖，不能切分支或合并

先 `git status`，判断改动属于谁、属于哪个功能。通常先在当前功能分支提交；如果功能未完成，临时 WIP 提交也可以，暂不合入 main。

确实需要暂存未完成工作时，可在**没有正在进行的 merge／rebase**时使用：

```powershell
git stash push -u -m "临时保存社区开发进度"
git stash list
```

`-u` 包括未跟踪文件，不包括被忽略的数据库数据等。记录 stash 对应的分支。回到原功能分支、确认工作区干净后：

```powershell
git stash apply 'stash@{0}'
git status
```

仅在这条确实是要恢复的记录时使用 `stash@{0}`；多条记录先通过 `git stash list` 确认。这里使用 apply，恢复后仍保留 stash，待确认文件正确再处理。恢复也可能冲突，应按实际内容整理；`git merge --abort` 不用于撤销 stash apply。[Git stash 官方说明](https://git-scm.com/docs/git-stash)

### 12.2 误把代码写在 main，还没有提交

先 `git status` 确认改动属于本次任务，然后直接在当前版本创建一个未使用的新分支：

```powershell
git switch -c feature/community-comment
git status
```

改动会留在新功能分支工作区。之后检查、提交，再 fetch 和 merge 最新 main，不必先把代码提交到 main。

### 12.3 已经提交到本地 main，但还没推送

不要直接推送 main。先保留这些提交：从当前 main 创建一个新的功能分支，再从该分支走 PR；可让 AI 先检查 `git log --oneline --decorate -10` 并说明处理方案。

若按普通 merge commit 合并，原提交会保留在远程 main 的历史里，通常可以在 PR 合并后切回本机 main 并快进更新。若仍无法快进，或 PR 使用了其他合并方式，让负责人协助整理本地分支；不要复制网上的 `reset --hard` 覆盖现场。

### 12.4 push 提示 rejected／non-fast-forward

可能同一个远程功能分支又有别人推送的新提交。确认当前分支、远程分支和工作区，沟通后获取并合并该**功能分支**的远程变化。以评论分支为例：

```powershell
git fetch origin
git merge --no-edit origin/feature/community-comment
```

处理冲突、验证并提交后再 push。此操作与同步 `origin/main` 是不同事情。若拒绝来自 main 的保护规则，应提交 PR；认证失败则处理权限或登录。不要把所有 push 失败都当作代码冲突。

### 12.5 main 更新提示不能 fast-forward

本机 main 与远程可能各有独立提交。保留 `git status`、`git log --oneline --decorate -10` 和错误提示，按 12.3 的情况核对。不要关闭检查、强推或直接覆盖远程 main。

### 12.6 本地没有队友的分支

先 `git fetch origin`，再 `git branch -r` 查看远程分支。若有 `origin/feature/...`，按第 8 节建立本地跟踪分支。若没有，确认队友是否真正 push 到同一个仓库；本地 commit 本身不会让别人看到。

### 12.7 想撤销本次改动或已经合并的错误

| 当前状态 | 处理办法 |
| --- | --- |
| 只是误暂存 | `git restore --staged -- "具体文件路径"`；保留文件改动 |
| 尚未提交，确实不需要某份修改 | 先备份／确认，再对明确文件使用 `git restore -- "具体文件路径"`；会丢弃该文件未暂存的已跟踪改动，新文件不在此操作范围 |
| 已提交到功能分支 | 优先增加一个修正提交，保留可追溯的历史 |
| 已合入 main 且其他人已同步 | 由负责人创建修复或回退 PR；一般使用修正提交或 revert，避免重写共享历史 |

`revert` 会增加撤销提交，不会抹掉旧记录；撤销合并提交还涉及主线选择，不应把普通提交的撤销命令直接套上。回退代码也不会自动回退已经执行的数据库变化，需要单独设计数据处理。[Git revert 官方说明](https://git-scm.com/docs/git-revert)；[Git restore 官方说明](https://git-scm.com/docs/git-restore)

本小组初期不把强制 push、`reset --hard`、`clean -fd`、强制删除分支当作日常解决办法。若 AI 建议使用，先要求它说明当前会丢失什么，并保留可恢复的版本再决定。

### 12.8 拉完代码，网页还是旧的／数据库报缺字段

查看 PR 的构建与数据库要求。旧 JAR 需重新构建和重启；新增迁移需在自己数据库执行。Git 不会自动安装所有依赖、更新已经运行的应用或执行所有 SQL。

### 12.9 git status 出现大量与功能无关的文件

可能是 AI 批量格式化、换行变化、IDE 配置或生成文件。先检查 diff 和忽略规则，把格式化与功能修改拆开；不要为了提交成功把所有变化都打包上传。

<a id="ai-prompts"></a>
## 13．可直接交给 AI 的提示词

复制前填写“本次功能”和验证要求。下面是给后续 AI 任务的操作约定，不会自动改变当前 Git 或 GitHub 设置。

### 13.1 开始一个功能

```text
请按 docs/collaboration/01-Git与AI协作管理手册.md 开始本次开发。
本次功能：社区评论（请替换为实际任务）。

先检查项目路径、git status、当前分支、远程仓库和已有改动。
保留用户及其他任务的改动；归属不清时先说明，不要一起提交或丢弃。
如果工作区干净，从最新 main 创建本次功能分支，再开发。
如果本次功能分支已经存在，先判断是否继续原任务，不重复创建。
允许创建本次功能分支并修改本次需要的代码，未经我授权不提交或推送。
修改范围以本功能为限；公共接口、表结构和依赖变更先说明影响并与负责人确认。
完成后给出修改文件、运行过的验证、数据库操作和未完成事项。
```

### 13.2 保存并上传已确认的功能

```text
请检查当前功能分支和差异，将本次已确认的改动提交并推送到对应功能分支。
只包含本次任务的文件和代码块；不要混入用户或其他任务的修改。
提交前检查暂存内容、配置和验证结果。不得提交本机凭据、数据库数据和构建产物。
允许提交和推送这个功能分支，不要推送或合并 main。
最后给出分支名、提交号、验证结果和可复制的 PR 标题与说明。
```

### 13.3 同步 main 或处理冲突

```text
请检查当前功能分支，将最新 origin/main 合并进来。
先确认手头工作已妥善提交且工作区干净；如有已有改动，先说明归属和保存方式。
发生冲突时列出涉及文件，说明双方修改的目的；无法判断业务含义时向我确认。
不要直接全部选择某一方，不要用强推、硬重置或删库解决。
完成后验证受影响功能，说明修改与结果；提交和推送按我这次明确授权的范围执行。
```

### 13.4 只读检查，自己不知道发生了什么

```text
我不确定当前 Git 状态，请先只读检查：项目路径、当前分支、工作区改动、
最近提交、远程地址、是否正在合并，以及本地分支与远程的关系。
先解释问题并给出保留现有工作的处理方案，不切分支、不修改文件、不提交和不推送。
不要输出凭据或私人配置中的密码。
```

<a id="checklists"></a>
## 14．负责人和成员的检查单

### 成员每天开工

- [ ] 知道今天的功能、所属分支和相关负责人。
- [ ] 先检查工作区，再切分支或同步。
- [ ] 新功能从最新 main 创建分支；进行中的功能合入最新 main。
- [ ] 同一文件夹只开一个会修改项目的 AI 任务。

### 成员提交 PR

- [ ] 文件与代码块都属于本次功能，没有批量混入其他改动。
- [ ] 公共代码、接口和表结构变化已经说明。
- [ ] 必要构建与实际功能验证通过，未验证项明确标出。
- [ ] 有 SQL 时给出脚本、执行顺序和验证方式。
- [ ] 无凭据、数据库实际数据和无关生成文件。
- [ ] base 为 main，compare 为自己的功能分支。

### 负责人合并

- [ ] 功能可说明、改动可审核，不把整个模块拖到最后一次合并。
- [ ] 关联功能兼容；Git 无冲突不等于业务无问题。
- [ ] 依赖的其他 PR 已合入，SQL 和文档一致。
- [ ] 一次合并一个 PR，有新增变更时通知成员。
- [ ] 合并后提醒成员更新 main，旧分支确认无后续工作再删除。

## 15．常用命令速查
<a id="commands"></a>

下表是查阅用法，不是一组从上到下连续执行的命令。功能分支名和文件路径要按实际情况替换；合并、切换和恢复前先检查工作区。

| 目的 | 命令 |
| --- | --- |
| 查看当前状态 | `git status` |
| 查看当前分支 | `git branch --show-current` |
| 查看本地分支 | `git branch` |
| 查看远程分支信息 | `git fetch origin`，然后 `git branch -r` |
| 在本机 main 上更新主分支 | `git pull --ff-only origin main` |
| 从当前版本创建并切到新分支 | `git switch -c feature/community-comment` |
| 切到已有分支 | `git switch feature/community-comment` |
| 查看未暂存变化 | `git diff` |
| 查看已暂存变化 | `git diff --staged` |
| 暂存已确认的全部变化 | `git add .` |
| 本地保存版本 | `git commit -m "具体说明"` |
| 第一次推送当前示例功能分支 | `git push -u origin feature/community-comment` |
| 已设 upstream 后推送当前分支 | `git push` |
| 在功能分支同步最新主分支 | `git fetch origin`，然后 `git merge --no-edit origin/main` |
| 放弃正在进行的普通合并 | `git merge --abort` |
| 切回 main 并确认已合并后，删除旧本地分支 | `git branch -d feature/community-comment` |
| 查看最近提交 | `git log --oneline --decorate -10` |

<a id="references"></a>
## 16．官方参考

以下说明用于核对 Git 和 GitHub 行为；本项目的分工、频率、分支命名和 AI 使用规则是本小组约定。

- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow)
- [GitHub PR 合并方式](https://docs.github.com/en/pull-requests/reference/pull-request-merges)
- [GitHub 合并冲突](https://docs.github.com/en/pull-requests/reference/merge-conflicts)
- [命令行处理冲突](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/resolving-a-merge-conflict-using-the-command-line)
- [GitHub 忽略文件](https://docs.github.com/en/get-started/git-basics/ignoring-files)
- [Git merge](https://git-scm.com/docs/git-merge)
- [Git stash](https://git-scm.com/docs/git-stash)
- [Git restore](https://git-scm.com/docs/git-restore)
- [Git revert](https://git-scm.com/docs/git-revert)
