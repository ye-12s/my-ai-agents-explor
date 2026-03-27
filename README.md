# AI Agent Skills Collection

个人定制的AI Agent技能集合，用于嵌入式开发、任务管理和工作流优化。

## 📦 包含内容

本仓库包含8个精心设计的AI Agent技能：

### 🔌 嵌入式开发 (4个)

| 技能 | 描述 | 使用场景 |
|------|------|----------|
| **embedded-serial-debugging** | UART/串口调试技术 | 调试嵌入式设备的串口通信 |
| **jlink-debugging** | J-Link调试器使用 | ARM Cortex-M芯片的调试和烧录 |
| **embedded-logging** | 轻量级日志系统 | 为MCU实现printf风格的日志 |
| **embedded-gdb-debugging** | GDB嵌入式调试 | 使用GDB分析hard fault和内存 |

### ⚡ 工作流优化 (4个)

| 技能 | 描述 | 使用场景 |
|------|------|----------|
| **task-archiving** | 任务归档系统 | 记录实现细节和设计决策，支持强制归档 |
| **task-completion-hooks** | 任务完成钩子 | 任务完成后自动触发归档等操作 |
| **parallel-task-decomposition** | 并行任务分解 | 将复杂任务拆分为可并行执行的子任务 |
| **discussion-context-hook** | 讨论上下文保持 | 在subAgent间保持用户意图和约束 |

## 🚀 快速开始

### 下载安装

```bash
# 下载最新Release
curl -L -o skills.tar.gz https://github.com/YOUR_USERNAME/ai-agent-skills/releases/latest/download/custom-skills-v1.0.0.tar.gz

# 解压安装
tar -xzf skills.tar.gz
python install.py
```

### 使用技能

```typescript
// 嵌入式调试
task({
  load_skills: ["embedded/jlink-debugging"],
  prompt: "使用JLink烧录固件到STM32"
});

// 任务归档
task({
  load_skills: ["superpowers/task-archiving"],
  prompt: "归档本次完成的任务"
});

// 并行任务分解
task({
  load_skills: ["superpowers/parallel-task-decomposition"],
  prompt: "将这个复杂功能拆分为并行子任务"
});
```

## 📋 安装方法

支持跨平台安装：**Linux** | **macOS** | **Windows**

### 方法1: Python脚本（推荐）

```bash
python install.py                    # 默认安装
python install.py --target ~/.custom  # 自定义路径
python install.py --force            # 强制覆盖
```

### 方法2: 平台特定

**Linux/macOS:**
```bash
./install.sh
```

**Windows PowerShell:**
```powershell
.\install.ps1
```

## 📖 详细文档

- [恢复指南 (RECOVERY.md)](./RECOVERY.md) - 详细的恢复和故障排除指南
- [迁移指南 (MIGRATION_GUIDE.md)](./MIGRATION_GUIDE.md) - 跨环境迁移说明

## 📁 仓库结构

```
.
├── install.py              # 跨平台安装脚本
├── install.ps1             # Windows PowerShell脚本
├── install.sh              # Linux/macOS Bash脚本
├── RECOVERY.md             # 恢复指南
├── MIGRATION_GUIDE.md      # 迁移指南
├── releases/               # 打包的Release版本
│   └── custom-skills-v1.0.0.tar.gz
├── src/                    # 源代码
│   ├── embedded/           # 嵌入式skills
│   └── superpowers/        # 工作流skills
└── README.md               # 本文件
```

## 🔧 技能详情

### Task Archiving
- 可选归档和强制归档模式
- 支持工作区级别的自动归档
- 结构化记录决策和经验教训

### Parallel Task Decomposition
- 依赖分析和任务拆分
- 多阶段并行执行
- 结果整合模式

### Discussion Context Hook
- 保持用户原始意图
- 传递约束和偏好到subAgent
- 确保并行任务一致性

## 🔄 更新

```bash
# 从GitHub更新
git pull origin main
python install.py --force
```

## 📝 许可证

MIT License - 详见 [LICENSE](./LICENSE) 文件

## 🤝 贡献

欢迎提交Issue和Pull Request！

## ⭐ 特别功能

- **跨平台支持**: 一套脚本，Linux/macOS/Windows通吃
- **Hooks机制**: 任务完成自动触发归档
- **上下文保持**: subAgent不丢失讨论上下文
- **强制归档**: 工作区级别强制执行任务归档

---

**版本**: v1.0.0  
**最后更新**: 2024-03-28
