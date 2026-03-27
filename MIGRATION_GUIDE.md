# Skills 迁移/恢复指南

## 📦 已创建的包

**包文件:** `custom-skills-YYYYMMDD_HHMMSS.tar.gz`

**包含内容:**
- 4个嵌入式开发skills
- 3个任务管理/工作流skills
- 跨平台安装脚本（Bash、PowerShell、Python）

---

## 🚀 快速恢复（新环境）

### 方法1: 使用Python安装（推荐，跨平台）

适用于 **Linux、macOS、Windows**

```bash
# 1. 复制包到新环境
scp custom-skills-*.tar.gz new-machine:~/
# Windows: 使用文件资源管理器或scp工具复制

# 2. 在新环境解压并安装
tar -xzf custom-skills-*.tar.gz        # Linux/macOS
# Windows: 使用7-Zip或WinRAR解压

# 3. 安装
python install.py                      # 所有平台

# 选项
python install.py --target ~/.my-skills   # 自定义路径
python install.py --force                 # 强制覆盖
python install.py --list                  # 查看包内容
```

### 方法2: 平台特定安装

#### Linux/macOS

```bash
tar -xzf custom-skills-*.tar.gz
./install.sh                           # 默认安装到 ~/.agents/skills
./install.sh ~/.custom/skills          # 自定义路径
./install.sh ~/.agents/skills true     # 强制覆盖
```

#### Windows (PowerShell)

```powershell
# 解压
tar -xzf custom-skills-*.tar.gz
# 或使用 Windows 资源管理器右键解压

# 安装
.\install.ps1                          # 默认安装
.\install.ps1 -Target C:\Users\YourName\.agents\skills  # 自定义路径
.\install.ps1 -Force                   # 强制覆盖
```

#### Windows (命令提示符 CMD)

```cmd
# 解压后执行
python install.py
```

---

## 📋 手动恢复步骤

如果不想使用安装脚本，可以手动复制：

### Linux/macOS

```bash
# 解压包
tar -xzf custom-skills-*.tar.gz

# 复制embedded skills
mkdir -p ~/.agents/skills/embedded
cp -r embedded/* ~/.agents/skills/embedded/

# 复制superpowers skills
mkdir -p ~/.agents/skills/superpowers
cp -r superpowers/* ~/.agents/skills/superpowers/
```

### Windows (PowerShell)

```powershell
# 解压包后执行
$target = "$env:USERPROFILE\.agents\skills"

# 复制 embedded skills
New-Item -ItemType Directory -Force -Path "$target\embedded"
Copy-Item -Path ".\embedded\*" -Destination "$target\embedded" -Recurse -Force

# 复制 superpowers skills
New-Item -ItemType Directory -Force -Path "$target\superpowers"
Copy-Item -Path ".\superpowers\*" -Destination "$target\superpowers" -Recurse -Force
```

### Windows (CMD/Batch)

```batch
:: 解压包后执行
set TARGET=%USERPROFILE%\.agents\skills

:: 创建目录
mkdir "%TARGET%\embedded"
mkdir "%TARGET%\superpowers"

:: 复制文件
xcopy /E /I /Y "embedded\*" "%TARGET%\embedded\"
xcopy /E /I /Y "superpowers\*" "%TARGET%\superpowers\"
```

---

## ✅ 验证安装

### Linux/macOS

```bash
# 列出所有安装的skills
ls -la ~/.agents/skills/embedded/
ls -la ~/.agents/skills/superpowers/

# 查看skill内容
cat ~/.agents/skills/embedded/jlink-debugging/SKILL.md
```

### Windows

```powershell
# 列出所有安装的skills
Get-ChildItem "$env:USERPROFILE\.agents\skills\embedded"
Get-ChildItem "$env:USERPROFILE\.agents\skills\superpowers"

# 查看skill内容
Get-Content "$env:USERPROFILE\.agents\skills\embedded\jlink-debugging\SKILL.md"
```

---

## 🔧 重新打包（如果修改了skills）

```bash
# 运行打包脚本
~/.agents/skills/export/package-skills.sh

# 新的包将生成在 ~/.agents/skills/export/
```

---

## 📁 文件清单

### Embedded Skills
| Skill | 文件 |
|-------|------|
| embedded-serial-debugging | `embedded/embedded-serial-debugging/SKILL.md` |
| jlink-debugging | `embedded/jlink-debugging/SKILL.md` |
| embedded-logging | `embedded/embedded-logging/SKILL.md` |
| embedded-gdb-debugging | `embedded/embedded-gdb-debugging/SKILL.md` |

### Superpowers Skills
| Skill | 文件 |
|-------|------|
| task-archiving | `superpowers/task-archiving/SKILL.md` + templates + scripts |
| task-completion-hooks | `superpowers/task-completion-hooks/SKILL.md` |
| parallel-task-decomposition | `superpowers/parallel-task-decomposition/SKILL.md` + examples |

---

## 📝 包结构

```
custom-skills-*.tar.gz
├── MANIFEST.json              # 包清单
├── README.md                  # 使用说明
├── install.sh                 # Linux/macOS 安装脚本
├── install.ps1                # Windows PowerShell 安装脚本 ⭐
├── install.py                 # 跨平台 Python 安装脚本 ⭐
├── embedded/                  # 嵌入式skills
│   ├── embedded-serial-debugging/
│   ├── jlink-debugging/
│   ├── embedded-logging/
│   └── embedded-gdb-debugging/
└── superpowers/               # 工作流skills
    ├── task-archiving/
    ├── task-completion-hooks/
    └── parallel-task-decomposition/
```

---

## 💡 备份建议

### 定期备份

#### Linux/macOS

```bash
# 添加到crontab (每周备份)
0 0 * * 0 ~/.agents/skills/export/package-skills.sh

# 备份到云端
rsync -av ~/.agents/skills/export/ ~/Dropbox/skills-backup/
```

#### Windows

```powershell
# PowerShell 脚本备份
$source = "$env:USERPROFILE\.agents\skills\export"
$dest = "$env:USERPROFILE\OneDrive\skills-backup"
Copy-Item -Path $source\*.tar.gz -Destination $dest -Force
```

### Git版本控制

```bash
# 初始化git仓库跟踪skills
cd ~/.agents/skills
git init
git add .
git commit -m "Initial skills collection"

# 定期提交更改
git add .
git commit -m "Update skills $(date +%Y-%m-%d)"
```

---

## ⚠️ 平台特定注意事项

### Windows

1. **PowerShell 执行策略**: 如果遇到执行限制，先运行：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Python 安装**: 确保 Python 3.6+ 已安装并添加到 PATH

3. **路径长度**: Windows 有最大路径长度限制(260字符)，如果遇到问题：
   ```powershell
   # 在 PowerShell 管理员模式启用长路径
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
   ```

4. **软链接**: Windows 的 `.agents/skills/superpowers` 如果是软链接，可能需要手动创建：
   ```powershell
   # 以管理员身份运行
   cmd /c mklink /D "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
   ```

### Linux/macOS

1. **权限**: 确保skills文件有读取权限
   ```bash
   chmod -R 644 ~/.agents/skills/*
   ```

2. **软链接**: 如果 `superpowers` 是软链接，确保目标存在

---

## 🔗 相关文件

- **打包脚本**: `~/.agents/skills/export/package-skills.sh`
- **最新包**: `~/.agents/skills/export/custom-skills-*.tar.gz`
- **Python安装器**: `~/.agents/skills/export/install.py`
- **PowerShell安装器**: `~/.agents/skills/export/install.ps1`
- **原始位置**: 
  - Linux/macOS: `~/.agents/skills/`
  - Windows: `%USERPROFILE%\.agents\skills\`
