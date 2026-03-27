# GitHub 仓库设置指南

本指南说明如何将AI Agent Skills上传到GitHub。

## 📦 本地仓库已准备就绪

本地仓库位置: `/home/ans/workspace/ai-agent-skills`

仓库内容:
- ✅ 8个skills（4个embedded + 4个superpowers）
- ✅ 跨平台安装脚本（install.py, install.ps1, install.sh）
- ✅ 完整文档（README.md, RECOVERY.md, MIGRATION_GUIDE.md）
- ✅ Release包（custom-skills-v1.0.0.tar.gz）
- ✅ MIT许可证

## 🚀 方法1: 使用GitHub CLI (推荐)

### 安装 GitHub CLI

**Linux:**
```bash
# Debian/Ubuntu
sudo apt install gh

# Fedora
sudo dnf install gh

# Arch
sudo pacman -S github-cli

# 或使用官方脚本
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**macOS:**
```bash
brew install gh
```

**Windows:**
```powershell
# 使用 winget
winget install --id GitHub.cli

# 或使用 scoop
scoop install gh
```

### 登录 GitHub

```bash
gh auth login
# 按照提示选择：
# - GitHub.com
# - HTTPS
# - 使用浏览器登录 或 粘贴token
```

### 创建并推送仓库

```bash
cd /home/ans/workspace/ai-agent-skills

# 创建GitHub仓库（public）
gh repo create ai-agent-skills --public --source=. --remote=origin --push

# 或创建 private 仓库
gh repo create ai-agent-skills --private --source=. --remote=origin --push

# 添加描述
gh repo edit --description "Personal AI Agent Skills Collection for Embedded Development and Workflow Optimization"
```

### 创建Release

```bash
# 创建标签
git tag -a v1.0.0 -m "Initial release v1.0.0"
git push origin v1.0.0

# 创建Release并上传包
gh release create v1.0.0 \
  --title "v1.0.0 - Initial Release" \
  --notes "First release of AI Agent Skills Collection

## Included Skills (8 total)

### Embedded (4)
- embedded-serial-debugging
- jlink-debugging  
- embedded-logging
- embedded-gdb-debugging

### Superpowers (4)
- task-archiving
- task-completion-hooks
- parallel-task-decomposition
- discussion-context-hook

## Installation
See RECOVERY.md for detailed instructions." \
  releases/custom-skills-v1.0.0.tar.gz
```

## 🌐 方法2: 手动网页操作

### 步骤1: 创建GitHub仓库

1. 访问 https://github.com/new
2. 填写信息：
   - **Repository name**: `ai-agent-skills`
   - **Description**: "Personal AI Agent Skills Collection"
   - **Visibility**: Public 或 Private
   - **Initialize**: 不要勾选（本地已有仓库）
3. 点击 **Create repository**

### 步骤2: 推送本地代码

```bash
cd /home/ans/workspace/ai-agent-skills

# 添加远程仓库（替换 YOUR_USERNAME）
git remote add origin https://github.com/YOUR_USERNAME/ai-agent-skills.git

# 推送代码
git push -u origin master
# 或
git push -u origin main
```

### 步骤3: 创建Release

1. 在GitHub仓库页面点击 **Releases** (右侧)
2. 点击 **Create a new release**
3. 填写：
   - **Tag version**: `v1.0.0`
   - **Release title**: `v1.0.0 - Initial Release`
   - **Description**: 复制上面的release notes
4. 上传文件：
   - 将 `releases/custom-skills-v1.0.0.tar.gz` 拖入上传区域
5. 点击 **Publish release**

## 📋 验证上传

### 检查仓库

```bash
# 查看远程URL
git remote -v

# 应该显示:
# origin  https://github.com/YOUR_USERNAME/ai-agent-skills.git (fetch)
# origin  https://github.com/YOUR_USERNAME/ai-agent-skills.git (push)
```

### 检查Release

1. 访问 `https://github.com/YOUR_USERNAME/ai-agent-skills/releases`
2. 应该看到 v1.0.0 release
3. 点击release应该能下载 `custom-skills-v1.0.0.tar.gz`

## 🔗 仓库URL格式

上传后，你的仓库可以通过以下方式访问：

- **主页**: `https://github.com/YOUR_USERNAME/ai-agent-skills`
- **Release下载**: `https://github.com/YOUR_USERNAME/ai-agent-skills/releases/download/v1.0.0/custom-skills-v1.0.0.tar.gz`
- **README**: `https://github.com/YOUR_USERNAME/ai-agent-skills#readme`

## 💡 后续维护

### 更新skills后重新打包

```bash
# 1. 修改skills
# 2. 重新打包
~/.agents/skills/export/package-skills.sh

# 3. 复制新包到仓库
cp ~/.agents/skills/export/custom-skills-*.tar.gz /home/ans/workspace/ai-agent-skills/releases/custom-skills-v1.1.0.tar.gz

# 4. 提交更改
cd /home/ans/workspace/ai-agent-skills
git add .
git commit -m "Update skills to v1.1.0"
git push

# 5. 创建新release
gh release create v1.1.0 --title "v1.1.0" --notes "Update notes" releases/custom-skills-v1.1.0.tar.gz
```

### 添加README徽章

在README.md顶部添加：

```markdown
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Skills](https://img.shields.io/badge/skills-8-orange.svg)
```

## 🆘 故障排除

### 权限错误

```bash
# 使用token登录
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/ai-agent-skills.git

# 或使用SSH
git remote set-url origin git@github.com:YOUR_USERNAME/ai-agent-skills.git
```

### 分支名称不匹配

```bash
# 如果GitHub默认分支是main，本地是master
git branch -m main
git push -u origin main
```

### 大文件问题

Release包(47KB)可以直接上传。如果将来有更大文件，考虑：
- 使用 Git LFS
- 分开发布二进制文件

---

**完成这些步骤后，你的skills就可以通过GitHub在任何环境恢复了！**
