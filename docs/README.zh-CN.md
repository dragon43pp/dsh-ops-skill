# DSH Ops Skill 中文指南

[English README](../README.md) · [架构](architecture.md) · [脱敏演示](demo.md) · [兼容性](compatibility.md) · [路线图](../ROADMAP.md) · [安全策略](../SECURITY.md)

> **DeepSeek Harness 的升级安全与运行时可靠性工具包。**
>
> 先证明状态契约，再进行最小、可逆的修复，避免一次 DSH 升级把实例启动成全新空白状态。

DSH Ops Skill 面向 DeepSeek Harness（DSH）运维与故障恢复，可被 Claude Code、Codex、OpenCode、DSH 或任何能加载文件夹 Skill 的 Agent 使用。项目以英文为主，并维护本中文入口；它是 DSH 生态的社区运维伴侣，不是 DeepSeek 官方插件，也不默认获得 Docker Socket、SYS_ADMIN 或其他高权限能力。

它处理的是容易被误判为数据丢失的一类运行时问题：容器升级后页面仍能打开，但历史会话、模型路由或工作区看起来全没了。根因通常是新运行时的 HOME、DSH_HOME、状态卷目标、入口点、工作目录或运行用户发生漂移。

## 证据先于修改

~~~mermaid
flowchart LR
    A[捕获脱敏基线] --> B[只读验证候选状态契约]
    B --> C[制定最小可逆修复]
    C --> D[操作员确认]
    D --> E[验证浏览器可见恢复]
~~~

HTTP 200 不能证明历史状态已恢复。正确的首步不是复制文件或删除卷，而是检查候选运行时选择的状态根目录，并证明它包含预期状态结构。

| 该项目帮助确认 | 它明确不会做 |
|---|---|
| 状态根目录和预期状态工件是否存在。 | 不读取会话正文、提示词、凭据或模型配置值。 |
| 实际镜像中是否具备 Bash 和 Bubblewrap。 | 不默认开启 privileged、Docker Socket 或 SYS_ADMIN。 |
| 候选容器启动契约是否偏离升级前基线。 | 不将会话文件复制到猜测出来的新路径。 |
| 是否应继续修复、停止排查或回滚。 | 不把一次事故的临时绕过方案包装成通用实践。 |

## 快速开始

~~~sh
git clone https://github.com/dragon43pp/dsh-ops-skill.git
cd dsh-ops-skill
sh scripts/dsh-doctor.sh verify
~~~

升级前后可通过以下命令输出精简、无密钥的状态契约；完整环境细节请仅私下保存：

~~~sh
sh scripts/dsh-doctor.sh contract
~~~

如确实需要验证 Bubblewrap 是否能够运行无写入隔离命令，必须显式开启：

~~~sh
DSH_DOCTOR_RUN_SANDBOX=1 sh scripts/dsh-doctor.sh verify
~~~

诊断脚本仅输出文件存在性和命令可用性；不会读取会话正文、模型配置值、凭据内容、模型 URL、Docker inspect 原文或存储数据库。

## 适用场景

| 现象 | 首先收集的证据 | 安全的下一步 |
|---|---|---|
| 会话为空、设置页模型消失 | 状态根目录和 settings、profiles、sessions、storages 的存在性。 | 在写入任何内容前比较升级前后 HOME、DSH_HOME 与挂载语义。 |
| Bash 报 spawn bash ENOENT | 实际运行镜像中 Bash 是否存在。 | 构建派生候选镜像，在隔离环境验证后再替换服务。 |
| Sandbox 或 Bubblewrap 不可用 | bwrap 是否存在；必要时运行无写入烟雾测试。 | 分析后端兼容性，任何能力变更都需单独完成威胁建模。 |
| 模型 401、超时或回复被截断 | 状态/Profile 加载路径和非敏感限额元数据。 | 在改模型设置之前先确认状态根目录。 |

完整、完全脱敏的案例请见[演示文档](demo.md)。请参阅[架构](architecture.md)、[兼容性](compatibility.md)、[修复手册](../references/remediation-playbooks.md)、[状态契约](../references/state-contract.md)和[路线图](../ROADMAP.md)。

## 交给外部 Agent 的提示词

> 使用 DSH Ops Skill 排查这个 DeepSeek Harness 部署。先执行只读诊断；不要修改容器、状态卷、凭据、网络、能力或模型配置。先给出脱敏诊断结论、最小修复方案与回滚计划，得到确认后再执行修复。

## 安全与贡献

本项目面向单租户、受信任的运维环境。不要将未认证的 DSH Web UI 暴露在公网。任何 Issue、截图、日志、PR 或公开示例中都不得包含 API Key、Token、密码、凭据文件、私网地址、内部 DNS、私有路径、容器 ID、会话日志、提示词、对话截图或 Docker inspect 原文。

欢迎提交完全脱敏、可复现的问题和改进建议。请遵循[安全策略](../SECURITY.md)与[贡献指南](../CONTRIBUTING.md)，并使用仓库的问题模板。
