# DSH Ops Skill 中文指南



[English README](../README.md)



`dsh-ops-skill` 是面向 **DeepSeek Harness（DSH）运维与排障** 的跨 Agent Skill。它可被 Claude Code、Codex、OpenCode、DSH 或任何能加载文件夹 Skill 的 Agent 使用。



它解决的不是某一个模型问题，而是 DSH 部署中最容易被忽略的运行时状态问题：容器升级后页面仍能打开，但历史会话、模型配置或工作区看起来像“全没了”。常见根因是 `HOME`、`DSH_HOME`、状态卷、入口点、工作目录或运行用户在新容器中发生漂移。



## 适用场景



| 现象 | 优先排查方向 |

|---|---|

| 左侧会话为空、设置页模型消失 | DSH 状态根目录变化；检查 `HOME`、`DSH_HOME` 和持久化挂载。 |

| Bash 报 `ENOENT` | 当前运行镜像没有 Bash，或 Shell 路径不正确。 |

| Sandbox/Bubblewrap 不可用 | 检查 `bwrap`、内核用户命名空间、seccomp 与权限边界。 |

| 模型 401、超时、回复被截断 | 检查 Profile 加载、模型路由、非敏感限额项和超时策略。 |

| 升级后 Web 页面异常 | 检查 entrypoint、command、workdir、状态路径和可信 Host 参数。 |



## 快速使用



```sh

git clone https://github.com/<YOUR_GITHUB_HANDLE>/dsh-ops-skill.git

cd dsh-ops-skill

sh scripts/dsh-doctor.sh verify

```



如果需要验证 Bubblewrap 是否能执行一个**无写入**的隔离命令：



```sh

DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify

```



如果需要在升级前后比较状态契约：



```sh

sh scripts/dsh-doctor.sh contract

```



诊断脚本只输出状态元数据：不会读取会话正文、模型配置值、凭据内容或 Docker inspect 完整输出。



## 交给外部 Agent 的提示词



将整个仓库目录作为 Skill 交给 Agent，或确保 Agent 能读取 `SKILL.md`、`scripts/` 和 `references/`。然后使用类似提示：



> 使用 DSH Ops Skill 排查这个 DeepSeek Harness 部署。先执行只读诊断；不要修改容器、状态卷、凭据、网络和权限。先给出脱敏诊断结论、最小修复方案与回滚计划，得到确认后再执行修复。
> 


## 核心原则



1. **先证明，再修改。** HTTP 200 不代表历史与模型已恢复；还要验证状态根目录、会话元数据和模型路由。
2. 
2. **状态根目录是契约。** 升级时必须保持 `HOME`/`DSH_HOME` 语义、状态挂载目标、Profile、入口点、工作目录和运行用户。
3. 
3. **默认只读。** 不应默认删除 volume、运行 `docker compose down --volumes`、挂 Docker Socket、开启 `--privileged` 或 `SYS_ADMIN`。
4. 
4. **先保留回滚点。** 新容器验证通过前，旧容器应保留为可启动的回滚目标。
5. 
5. **公开内容必须脱敏。** 不得提交内部模型地址、密钥、工作区、私网地址、会话日志或 Docker inspect 原文。
6. 


## Compose 覆盖示例



仓库里的 [`examples/compose.state-safe.yaml`](../examples/compose.state-safe.yaml) 是一个只负责“状态根目录和工作区明确化”的 Compose 覆盖文件。它不提供镜像、端口、启动命令、高权限能力或 Docker Socket。将其与自己的基础部署合并前，先用 `docker compose config` 查看最终配置。



## 贡献与反馈



欢迎提交已经完全脱敏、可复现的 DSH 部署问题和改进建议。不要在 Issue、截图、日志或 PR 中贴出任何密钥、私网地址、模型 URL、会话正文或公司基础设施信息。







