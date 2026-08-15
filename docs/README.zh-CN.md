# DSH Ops Skill 中文指南

[English README](../README.md) · [架构](architecture.md) · [脱敏演示](demo.md) · [兼容性](compatibility.md) · [路线图](../ROADMAP.md) · [安全策略](../SECURITY.md)

> **DeepSeek Harness 的升级安全与运行时可靠性工具包。**
>
> 先证明状态契约，再进行最小、可逆的修复，避免一次 DSH 升级把实例启动成“全新空白”的状态。

`dsh-ops-skill` 是面向 [DeepSeek Harness（DSH）](https://github.com/deepseek-ai/deepseek-harness) 运维与故障恢复的跨 Agent Skill。它可被 Claude Code、Codex、OpenCode、DSH 或任何能加载文件夹 Skill 的 Agent 使用。项目以英文为主，并维护本中文入口；它是 DSH 生态的社区运维伴侣，不是 DeepSeek 官方插件，也不默认获得 Docker Socket、`SYS_ADMIN` 或其他高权限能力。

它解决的不是单个模型问题，而是一类容易被误判为“数据丢失”的运行时状态故障：容器升级后 Web 页面仍能打开，但历史会话、模型配置或工作区看起来像“全没了”。常见根因是新运行时的 `HOME`、`DSH_HOME`、状态卷目标、入口点、工作目录或运行用户发生漂移。

## 运维原则：证据先于修改

```mermaid
flowchart LR
    A[捕获脱敏基线] --> B[只读验证候选状态契约]
    B --> C[制定最小可逆修复]
    C --> D[操作员确认]
    D --> E[验证浏览器可见恢复]
```

HTTP 200 并不能证明历史状态已经恢复。正确的首步不是复制文件或删除卷，而是检查候选运行时真正选择的状态根目录，并证明它包含预期的状态结构。

| 该项目帮助确认 | 它明确不会做 |
|---|---|
| 状态根目录是否存在，以及预期状态工件是否存在。 | 不读取会话正文、提示词、凭据、模型配置值或存储数据库。 |
| 实际运行镜像中是否有 Bash 和 Bubblewrap。 | 不默认开启 `--privileged`、Docker Socket 或 `SYS_ADMIN`。 |
| 候选容器的启动契约是否偏离升级前基线。 | 不会把会话文件复制到猜测出来的新路径。 |
| 是否应继续修复、停止排查或回滚。 | 不会把某次事故中的临时绕过方案包装成通用安全实践。 |

## 快速开始

```sh
git clone https://github.com/dragon43pp/dsh-ops-skill.git
cd dsh-ops-skill
sh scripts/dsh-doctor.sh verify
```

升级前后可通过下面命令输出精简、无密钥的状态契约，完整环境细节请仅私下保存：

```sh
sh scripts/dsh-doctor.sh contract
sh scripts/dsh-doctor.sh contract --format json
```

契约只记录状态工件存在性、有限文件计数、命令可用性、状态根选择来源和不可逆指纹，**不会输出实际状态根路径**。对升级前运行时和隔离候选运行时分别保存私有快照，再比较已跟踪的不变量：

```sh
sh scripts/dsh-doctor.sh snapshot /secure/path/before.contract
# 启动并检查隔离候选实例；此时不要修改生产环境。
sh scripts/dsh-doctor.sh snapshot /secure/path/candidate.contract
sh scripts/dsh-doctor.sh diff /secure/path/before.contract /secure/path/candidate.contract
```

`UNCHANGED` 的退出码为 `0`；出现 `REVIEW` 时退出码为 `2`，必须由操作员审查后才能继续。快照命令不会覆盖已有文件。

如确实需要验证 Bubblewrap 是否能够运行一个**无写入**隔离命令，必须显式开启：

```sh
DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify
```

诊断脚本仅输出文件存在性和命令可用性；它不会读取会话正文、模型配置值、凭据内容、模型 URL、Docker inspect 原文或存储数据库。

## 工程化保证

| 保证 | 实现方式 | 避免的问题 |
|---|---|---|
| 稳定契约 | 版本化键值契约与 JSON 契约，字段有明确含义。 | 依赖脆弱的人工终端输出解析。 |
| 安全比较 | 私有快照、禁止覆盖、仅报告变化字段及独立审查退出码。 | 误复制状态或因 HTTP 健康检查而产生虚假信心。 |
| 可重复测试 | `sh tests/test-dsh-doctor.sh` 构造合成状态树和命令桩。 | 回归问题只在真实事故中暴露。 |
| 默认零高权限 | 无 Docker API、无变更命令、无网络调用、无自动恢复。 | 诊断工具演变为宿主机高权限攻击面。 |

可在本地运行离线回归测试：

```sh
sh tests/test-dsh-doctor.sh
```

公开质量工作流会在 PR 与 `main` 推送时运行同一套隔离测试。

## 适用场景

| 现象 | 首先收集的证据 | 安全的下一步 |
|---|---|---|
| 左侧会话为空、设置页模型消失 | 状态根目录和 `settings.yaml`、`profiles/`、`sessions/`、`storages/` 的存在性。 | 在写入任何内容前，比较升级前后 `HOME`/`DSH_HOME` 与挂载语义。 |
| Bash 报 `spawn bash ENOENT` | 实际运行镜像中 Bash 是否存在。 | 构建派生候选镜像，在隔离环境验证后再替换服务。 |
| Sandbox / Bubblewrap 不可用 | `bwrap` 是否存在；必要时运行无写入烟雾测试。 | 分析后端兼容性，任何能力变更都需单独完成威胁建模。 |
| 模型 401、超时、回复被截断 | 状态/Profile 加载路径和非敏感限额元数据。 | 在改模型设置之前先确认状态根目录。 |
| 升级后 Web 页面异常 | entrypoint、command、workdir、用户、挂载、环境语义与回滚目标。 | 旧实例保持可启动，直到候选实例验证通过。 |

完整、完全脱敏的案例请见 [演示文档](demo.md)。

## 交给外部 Agent 的提示词

将整个仓库目录作为 Skill 交给 Agent，或确保 Agent 能读取 `SKILL.md`、`scripts/` 和 `references/`。然后使用类似提示：

> 使用 DSH Ops Skill 排查这个 DeepSeek Harness 部署。先执行只读诊断；不要修改容器、状态卷、凭据、网络、能力或模型配置。先给出脱敏诊断结论、最小修复方案与回滚计划，得到确认后再执行修复。

## 专业文档体系

| 文档 | 用途 |
|---|---|
| [架构](architecture.md) | 说明状态契约、证据闭环和默认安全边界。 |
| [脱敏演示](demo.md) | 通过虚构案例演示从空白实例症状到验证恢复的流程。 |
| [兼容性](compatibility.md) | 区分已验证、预期和未验证的适用范围，避免虚假兼容承诺。 |
| [修复手册](../references/remediation-playbooks.md) | 将常见症状映射为最小、可逆的恢复路径。 |
| [状态契约](../references/state-contract.md) | 记录升级不变量及公开脱敏规则。 |
| [路线图](../ROADMAP.md) | 说明项目的后续验证方向与明确的非目标。 |
| [`tests/test-dsh-doctor.sh`](../tests/test-dsh-doctor.sh) | 运行合成、无网络的契约、快照、差异、脱敏和错误语义回归测试。 |

## 最小权限 Compose 覆盖

[`examples/compose.state-safe.yaml`](../examples/compose.state-safe.yaml) 将状态根目录与工作区明确分开，并设置 `no-new-privileges` 与 `cap_drop: ALL`。它不定义镜像、端口、启动命令、高权限能力或 Docker Socket；与既有 Compose 服务合并前，先审阅渲染结果：

```sh
DSH_STATE_DIR=$PWD/.dsh-state DSH_WORKSPACE=$PWD \
  docker compose -f compose.yaml -f examples/compose.state-safe.yaml config
```

## 安全与贡献

本项目面向单租户、受信任的运维环境。不要将未认证的 DSH Web UI 暴露在公网。任何 Issue、截图、日志、PR 或公开示例中都不得包含 API Key、Token、密码、凭据文件、私网地址、内部 DNS、私有路径、容器 ID、会话日志、提示词、对话截图或 Docker inspect 原文。

欢迎提交完全脱敏、可复现的问题和改进建议。请遵循 [安全策略](../SECURITY.md) 与 [贡献指南](../CONTRIBUTING.md)，并使用仓库提供的问题模板。
