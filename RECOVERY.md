# Skills 恢复指南 (RECOVERY.md)

本指南详细说明如何从GitHub仓库恢复AI Agent Skills到新工作环境。

## 📦 仓库结构

```
ai-agent-skills/
├── README.md                    # 项目说明
├── RECOVERY.md                  # 本恢复指南
├── LICENSE                      # 许可证
├── releases/
│   └── custom-skills-v1.0.0.tar.gz    # 最新打包版本
├── install.py                   # 跨平台安装脚本
├── install.ps1                  # Windows安装脚本
├── install.sh                   # Linux/macOS安装脚本
└── src/                         # 源代码（可选）
    ├── embedded/
    └── superpowers/
```

---

## 🚀 快速恢复（推荐）

### 方法1: 使用Release包（最简单）

```bash
# 1. 下载最新Release
curl -L -o skills.tar.gz https://github.com/YOUR_USERNAME/ai-agent-skills/releases/download/v1.0.0/custom-skills-v1.0.0.tar.gz

# 2. 解压
tar -xzf skills.tar.gz

# 3. 安装
python install.py
```

### 方法2: 克隆仓库并安装

```bash
# 1. 克隆仓库
git clone https://github.com/YOUR_USERNAME/ai-agent-skills.git
cd ai-agent-skills

# 2. 直接从源代码安装
python install.py --source .

# 或使用Release包
python install.py --source releases/custom-skills-v1.0.0.tar.gz
```

---

## 🔧 详细恢复步骤

### 第一步：获取Skills包

#### 选项A: 从GitHub Release下载

1. 访问 `https://github.com/YOUR_USERNAME/ai-agent-skills/releases`
2. 下载最新的 `.tar.gz` 包
3. 解压到本地目录

#### 选项B: 使用git克隆

```bash
git clone https://github.com/YOUR_USERNAME/ai-agent-skills.git
cd ai-agent-skills
```

#### 选项C: 直接下载ZIP

```bash
# 下载main分支的ZIP
curl -L -o ai-agent-skills.zip https://github.com/YOUR_USERNAME/ai-agent-skills/archive/refs/heads/main.zip
unzip ai-agent-skills.zip
cd ai-agent-skills-main
```

---

### 第二步：安装Skills

#### 跨平台安装（推荐）

```bash
# 使用Python脚本（适用于 Linux/macOS/Windows）
python install.py

# 查看帮助
python install.py --help

# 常用选项
python install.py --target ~/.custom/skills    # 自定义安装路径
python install.py --force                      # 强制覆盖已有安装
python install.py --list                       # 列出将要安装的技能
```

#### Linux/macOS

```bash
# 使用Bash脚本
./install.sh

# 或带参数
./install.sh ~/.agents/skills       # 自定义路径
./install.sh ~/.agents/skills true  # 强制覆盖
```

#### Windows

**PowerShell:**
```powershell
# 设置执行策略（如遇到权限问题）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 执行安装
.\install.ps1

# 或带参数
.\install.ps1 -Target C:\Users\YourName\.agents\skills
.\install.ps1 -Force
```

**命令提示符(CMD):**
```cmd
python install.py
```

---

### 第三步：验证安装

#### Linux/macOS

```bash
# 检查安装目录
ls -la ~/.agents/skills/

# 检查embedded skills
ls ~/.agents/skills/embedded/
# 应该看到: embedded-gdb-debugging, embedded-logging, embedded-serial-debugging, jlink-debugging

# 检查superpowers skills
ls ~/.agents/skills/superpowers/
# 应该看到: discussion-context-hook, parallel-task-decomposition, task-archiving, task-completion-hooks

# 验证skill内容
cat ~/.agents/skills/embedded/jlink-debugging/SKILL.md
cat ~/.agents/skills/superpowers/task-archiving/SKILL.md
```

#### Windows

```powershell
# 检查安装目录
ls $env:USERPROFILE\.agents\skills

# 检查skills
ls $env:USERPROFILE\.agents\skills\embedded
ls $env:USERPROFILE\.agents\skills\superpowers

# 查看skill内容
Get-Content $env:USERPROFILE\.agents\skills\embedded\jlink-debugging\SKILL.md
```

---

### 第四步：重启Agent

安装完成后，需要重启AI Agent会话以加载新skills。

```
1. 关闭当前agent会话
2. 重新启动agent
3. Skills将自动根据任务描述被加载
```

---

## 📋 恢复检查清单

- [ ] 下载/克隆了skills仓库或release包
- [ ] 成功运行了安装脚本
- [ ] 所有8个skills出现在安装目录
- [ ] 可以读取skill文件内容
- [ ] 重启了agent会话
- [ ] 测试了一个skill是否被正确加载

---

## 🔍 故障排除

### 问题1: 安装脚本无法执行

**Linux/macOS:**
```bash
# 添加执行权限
chmod +x install.sh

# 或直接用bash运行
bash install.sh
```

**Windows PowerShell:**
```powershell
# 检查执行策略
Get-ExecutionPolicy

# 临时允许（当前会话）
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 永久允许（当前用户）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题2: Python未找到

```bash
# 检查Python安装
which python3   # Linux/macOS
where python    # Windows

# 使用python3
python3 install.py
```

### 问题3: 路径问题

**查看默认安装路径:**
```bash
# Linux/macOS
ls -la ~/.agents/skills/

# Windows
ls $env:USERPROFILE\.agents\skills
```

**手动指定路径:**
```bash
python install.py --target /your/custom/path
```

### 问题4: 文件权限

**Linux/macOS:**
```bash
# 修复权限
chmod -R 755 ~/.agents/skills
chmod -R 644 ~/.agents/skills/*/SKILL.md
```

**Windows:**
```powershell
# PowerShell中不需要特殊处理
# 确保不是"只读"属性
```

### 问题5: Skills未被加载

1. 检查skill文件是否存在且可读
2. 确认agent配置中skills路径正确
3. 重启agent会话
4. 检查agent日志是否有加载错误

---

## 🔄 更新Skills

当仓库有新版本时：

```bash
# 方法1: 重新下载Release
curl -L -o skills-new.tar.gz https://github.com/YOUR_USERNAME/ai-agent-skills/releases/download/v1.1.0/custom-skills-v1.1.0.tar.gz
tar -xzf skills-new.tar.gz
python install.py --force

# 方法2: git pull
cd ai-agent-skills
git pull origin main
python install.py --force
```

---

## 💾 备份当前配置

在恢复前备份现有skills：

```bash
# Linux/macOS
cp -r ~/.agents/skills ~/.agents/skills.backup.$(date +%Y%m%d)

# Windows PowerShell
Copy-Item -Path $env:USERPROFILE\.agents\skills -Destination "$env:USERPROFILE\.agents\skills.backup.$(Get-Date -Format 'yyyyMMdd')" -Recurse
```

---

## 📞 获取帮助

如果遇到问题：

1. 查看 [GitHub Issues](https://github.com/YOUR_USERNAME/ai-agent-skills/issues)
2. 检查 [README.md](./README.md) 的使用说明
3. 验证 [MANIFEST.json](./MANIFEST.json) 中的文件列表

---

## ✅ 验证技能列表

恢复完成后，确认以下8个技能都已安装：

### Embedded (4个)
1. ✅ embedded-serial-debugging
2. ✅ jlink-debugging
3. ✅ embedded-logging
4. ✅ embedded-gdb-debugging

### Superpowers (4个)
1. ✅ task-archiving
2. ✅ task-completion-hooks
3. ✅ parallel-task-decomposition
4. ✅ discussion-context-hook

---

**最后更新**: 2024-03-28
