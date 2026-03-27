---
name: workspace-mandatory-archiving
description: Use when entering a workspace that requires mandatory task archiving, or when setting up forced archival for a project
---

# Workspace Mandatory Archiving

## Overview

强制性的工作区级别任务归档。进入配置了强制归档的工作区后，**所有任务完成后必须执行归档**，无需手动触发，不可跳过。

**工作原理：**
1. 工作区根目录存在 `.arch-config.yml` 配置文件
2. Agent检测到配置后自动启用强制归档模式
3. 每次任务完成后**必须**创建归档文档
4. 未归档的任务视为未完成

## 工作区配置文件

### `.arch-config.yml` 格式

```yaml
# 强制归档配置
archiving:
  # 是否启用强制归档（必须）
  enabled: true
  
  # 归档目录（相对于工作区根目录）
  directory: docs/arch
  
  # 归档模板路径（可选，使用默认模板）
  template: docs/arch/templates/archive-template.md
  
  # 强制归档触发条件
  triggers:
    # 文件变更类型触发
    on_file_change:
      - create    # 新建文件
      - modify    # 修改文件
      - delete    # 删除文件
    
    # 最小变更文件数（少于该数量可跳过）
    min_files_changed: 1
    
    # 路径排除（支持 glob）
    exclude_paths:
      - "*.log"
      - ".git/**"
      - "node_modules/**"
      - "build/**"
      - "dist/**"
  
  # 归档内容要求
  requirements:
    # 必填字段
    required_fields:
      - summary
      - problem_statement
      - solution
      - decisions
      - lessons
      - applicability
    
    # 最小描述长度
    min_description_length: 100
  
  # 自动生成的元数据
  metadata:
    # 自动捕获Git信息
    capture_git_info: true
    # 自动捕获修改的文件列表
    capture_changed_files: true
    # 自动捕获作者信息
    capture_author: true
```

### 简化配置（最常用）

```yaml
archiving:
  enabled: true
  directory: docs/arch
```

## Agent检测与执行流程

```
┌─────────────────────────────────────────┐
│  1. Agent进入工作区                      │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  2. 检测 .arch-config.yml               │
│     - 存在且 enabled: true?             │
└────────────────┬────────────────────────┘
                 │ 是
                 ▼
┌─────────────────────────────────────────┐
│  3. 启用强制归档模式                     │
│     - 加载配置                          │
│     - 验证归档目录结构                   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  4. 任务执行（正常流程）                  │
│     - 开发、测试、验证                   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  5. 任务完成？                          │
└────────┬─────────────────┬──────────────┘
         │是               │否
         ▼                 ▼
┌────────────────┐  ┌─────────────────────┐
│ 6. 强制归档检查 │  │ 返回步骤4继续任务   │
│    - 变更文件？ │  └─────────────────────┘
│    - 满足触发？ │
└────────┬───────┘
         │是
         ▼
┌─────────────────────────────────────────┐
│  7. 强制执行归档（SubAgent）             │
│     - 捕获任务上下文                     │
│     - 生成归档文档                       │
│     - 验证归档完整性                     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  8. 归档完成确认                         │
│     - 文档存在？                         │
│     - 必填字段完整？                     │
└────────┬─────────────────┬──────────────┘
         │通过             │失败
         ▼                 ▼
┌────────────────┐  ┌─────────────────────┐
│ 9. 任务正式完成 │  │ 补充归档内容        │
└────────────────┘  │ 返回步骤7重新归档   │
                    └─────────────────────┘
```

## Agent行为准则

### 检测到强制归档配置时

```typescript
// Agent检测到 .arch-config.yml 且 enabled: true
// 自动加载并启用强制归档模式

const archiveConfig = loadArchConfig('.arch-config.yml');
if (archiveConfig.enabled) {
  console.log(`📁 强制归档模式已启用: ${archiveConfig.directory}`);
  
  // 验证归档目录结构
  ensureArchiveStructure(archiveConfig.directory);
}
```

### 任务完成后强制执行

```typescript
// 任务完成后，必须执行归档
async function completeTaskWithMandatoryArchiving(taskContext) {
  // 1. 正常完成任务
  const result = await completeTask(taskContext);
  
  // 2. 检查是否需要归档
  if (!shouldArchive(result, archiveConfig)) {
    return result;  // 不满足触发条件
  }
  
  // 3. 强制归档（阻塞式，必须完成）
  console.log('📝 强制执行任务归档...');
  
  const archiveResult = await task(
    category="writing",
    load_skills=["superpowers/task-archiving"],
    run_in_background=false,  // 阻塞式，必须完成
    description="强制任务归档",
    prompt=buildMandatoryArchivePrompt(taskContext, archiveConfig)
  );
  
  // 4. 验证归档结果
  if (!verifyArchive(archiveResult, archiveConfig)) {
    throw new Error('归档验证失败，任务未完成');
  }
  
  console.log('✅ 归档完成，任务结束');
  return { ...result, archived: true };
}
```

## 归档Prompt模板（强制模式）

```typescript
function buildMandatoryArchivePrompt(taskContext, config) {
  return `
    ⚠️ 强制归档任务 - 必须完成
    
    工作区要求：所有完成的任务必须归档到 ${config.directory}
    
    任务信息（自动捕获）：
    ─────────────────────────
    任务描述：${taskContext.description}
    开始时间：${taskContext.startTime}
    完成时间：${new Date().toISOString()}
    
    修改的文件（Git diff）：
    ${taskContext.changedFiles.join('\n')}
    
    Git信息：
    - 分支：${taskContext.gitBranch}
    - 最新提交：${taskContext.latestCommit}
    
    必填字段（${config.requirements.required_fields.join(', ')}）：
    ─────────────────────────
    
    ## Summary（概述）
    一句话描述本次任务完成了什么。
    
    ## Problem Statement（问题陈述）
    本次任务解决了什么问题？为什么需要这个变更？
    
    ## Solution（解决方案）
    如何实现的高层次描述，包含关键代码片段。
    
    ## Technical Decisions（技术决策）
    做了哪些关键选择？为什么？考虑过哪些替代方案？
    
    ## Lessons Learned（经验教训）
    什么方法有效？什么无效？有什么意外发现？
    
    ## Applicability（适用场景）
    什么时候应该/不应该使用这种方法？
    
    归档文件路径：
    ${config.directory}/${formatDate(new Date())}-${taskContext.slug}.md
    
    ⚠️ 要求：
    1. 所有必填字段必须完整
    2. 每个字段至少100个字符
    3. 必须包含具体的代码示例
    4. 必须说明适用/不适用场景
    5. 完成后验证文件存在且非空
  `;
}
```

## 设置工作区强制归档

### 方法一：使用init脚本（推荐）

```bash
# 在项目根目录执行
~/.agents/skills/superpowers/task-archiving/init-workspace-archive.sh

# 输出：
# ✅ 工作区强制归档已启用
# 📁 归档目录: docs/arch/
# 📄 配置文件: .arch-config.yml
```

### 方法二：手动配置

```bash
# 1. 在工作区根目录创建配置文件
cat > .arch-config.yml << 'EOF'
archiving:
  enabled: true
  directory: docs/arch
EOF

# 2. 创建归档目录结构
mkdir -p docs/arch/{templates,examples}

# 3. 复制模板文件
cp ~/.agents/skills/superpowers/task-archiving/templates/*.md docs/arch/templates/
```

### 方法三：项目模板（新建项目）

在项目模板中包含 `.arch-config.yml`：

```
project-template/
├── .arch-config.yml          # 强制归档配置
├── docs/
│   └── arch/                 # 归档目录
│       ├── index.md
│       └── templates/
│           └── archive-template.md
└── ...
```

## 跳过归档的特殊情况

即使启用了强制归档，以下情况可以跳过：

| 情况 | 说明 |
|------|------|
| 纯文档修改 | 只修改README、注释等 |
| 配置文件更新 | .gitignore, .editorconfig等 |
| 临时文件清理 | 删除日志、缓存等 |
| 小于最小变更数 | 配置中 `min_files_changed` 未满足 |

**跳过方式：**
```yaml
# 在 .arch-config.yml 中配置
archiving:
  triggers:
    skip_patterns:
      - "*.md"
      - ".gitignore"
      - "docs/**"
```

## 验证归档完整性

Agent会自动验证：

```typescript
function verifyArchive(archivePath, config) {
  // 1. 文件存在
  if (!fs.existsSync(archivePath)) {
    return { valid: false, error: '归档文件不存在' };
  }
  
  // 2. 非空文件
  const content = fs.readFileSync(archivePath, 'utf-8');
  if (content.length < config.requirements.min_description_length) {
    return { valid: false, error: '归档内容太短' };
  }
  
  // 3. 必填字段检查
  for (const field of config.requirements.required_fields) {
    if (!content.includes(`## ${field}`)) {
      return { valid: false, error: `缺少必填字段: ${field}` };
    }
  }
  
  return { valid: true };
}
```

## 最佳实践

### 工作区配置
1. **在项目初始化时启用** - 从第一天开始积累知识
2. **团队共享模板** - 统一归档格式和风格
3. **定期审查归档** - 每月回顾，确保质量
4. **链接外部资源** - PR、Issue、设计文档

### 归档内容
1. **具体而非抽象** - "使用X库因为Y原因" 而非 "优化了性能"
2. **包含失败尝试** - 记录尝试过但无效的方法
3. **量化结果** - "减少50%加载时间" 而非 "变快了"
4. **可搜索关键词** - 便于后续检索

### 团队协作
1. **Code Review检查归档** - 归档不完整不合并
2. **新人必读归档** - 加速 onboarding
3. **技术分享来源** - 从归档中提取分享内容
