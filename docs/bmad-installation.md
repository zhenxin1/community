# BMAD工具环境

文档状态：`Done`。

## 版本与目录

项目工具版本为`bmad-method@6.12.4`，包含Core、BMM与29个Codex技能入口。安装元数据见`_bmad/_config/manifest.yaml`。

| 路径 | 用途 |
|---|---|
| `_bmad/` | 框架脚本、模块与配置 |
| `.agents/skills/` | 项目技能入口 |
| `_bmad/custom/config.toml` | 团队中文配置 |
| `_bmad-output/` | 规划与实施产物 |
| `.local/bmad-tools/` | 本地uv工具，不进入版本库 |

## 环境准备

技能运行需要Node.js20.12+、Python3.11+和uv。以下命令在仓库根目录执行：

```powershell
python -m pip install --only-binary=:all: --target ./.local/bmad-tools uv
. ./scripts/bmad-env.ps1
uv run ./_bmad/scripts/resolve_config.py --project-root .
```

`bmad-env.ps1`仅设置当前终端的本地工具路径。配置解析用于检查项目目录及语言设置。工具环境核验与业务测试、故事验收分别进行。

参考：[BMAD官方仓库](https://github.com/bmad-code-org/BMAD-METHOD)、[uv安装说明](https://docs.astral.sh/uv/getting-started/installation/)。
