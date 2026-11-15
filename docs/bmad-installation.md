# BMAD 工具安装与使用

## 安装范围

项目工具版本为官方 `bmad-method@6.12.4`，包含 Core、BMM 和 Codex 的 29 个技能入口。版本与安装元数据见 `_bmad/_config/manifest.yaml`。

- `_bmad/`：框架脚本、模块、配置和技能目录清单。
- `.agents/skills/`：Codex 可发现的技能入口。
- `_bmad/custom/config.toml`：团队配置，使用中文交流与输出。
- `_bmad-output/`：需求、架构和实施文档。
- `.local/bmad-tools/`：本机 uv 运行工具，已由现有 `.gitignore` 排除。

官方安装命令：

```powershell
npx --yes bmad-method@6.12.4 install --directory D:\Code\temp\final --modules bmm --tools codex --user-name "PetHaven Team" --communication-language Chinese --document-output-language Chinese --output-folder _bmad-output --no-shims --yes
```

## 本机使用

在 PowerShell 中执行：

```powershell
cd D:\Code\temp\final
. .\scripts\bmad-env.ps1
uv run --python "D:\Python\python.exe" .\_bmad\scripts\resolve_config.py --project-root .
```

第一条脚本仅为当前终端添加本地 uv 路径。随后从该终端启动 Codex，并将工作目录设为本项目根目录；若技能列表尚未刷新，可重新打开该项目的会话。`bmad-help` 可用于询问工具用法，`bmad-code-review` 可用于后续真实代码审查。按需求分析、方案设计、实施或审查任务选用相应技能。

更换电脑后，先准备 Node.js 20.12+ 和 Python 3.11+，再安装本地 uv：

```powershell
python -m pip install --only-binary=:all: --target .\.local\bmad-tools uv
. .\scripts\bmad-env.ps1
```

## 核验范围

可执行`uv --version`检查运行工具，并使用上述配置解析命令核对中文和项目目录设置。工具环境检查与业务测试、故事验收分别进行。

参考：[BMAD 官方仓库](https://github.com/bmad-code-org/BMAD-METHOD)、[uv 官方安装说明](https://docs.astral.sh/uv/getting-started/installation/)。
