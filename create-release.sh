#!/bin/bash
# Quick script to create GitHub release
# Run this manually after setting GH_TOKEN

echo "GitHub Release Creator"
echo "======================"
echo ""
echo "Repository: ye-12s/my-ai-agents-explor"
echo "Tag: v1.0.0"
echo "Package: releases/custom-skills-v1.0.0.tar.gz"
echo ""

# Check if GH_TOKEN is set
if [ -z "$GH_TOKEN" ]; then
    echo "⚠️  GH_TOKEN environment variable not set"
    echo ""
    echo "To create release automatically, run:"
    echo "  export GH_TOKEN=your_github_token_here"
    echo "  ./create-release.sh"
    echo ""
    echo "Or create manually at:"
    echo "  https://github.com/ye-12s/my-ai-agents-explor/releases/new"
    exit 1
fi

# Create release using GitHub API
echo "Creating release..."
curl -X POST \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/ye-12s/my-ai-agents-explor/releases \
  -d '{
    "tag_name": "v1.0.0",
    "name": "v1.0.0 - AI Agent Skills Collection",
    "body": "# AI Agent Skills Collection v1.0.0\n\nPersonal collection of AI agent skills for embedded development and workflow optimization.\n\n## 📦 Included Skills (8 total)\n\n### 🔌 Embedded Development (4)\n- **embedded-serial-debugging** - UART/serial debugging\n- **jlink-debugging** - J-Link probe usage\n- **embedded-logging** - Lightweight logging\n- **embedded-gdb-debugging** - GDB debugging\n\n### ⚡ Superpowers (4)\n- **task-archiving** - Task documentation\n- **task-completion-hooks** - Automated hooks\n- **parallel-task-decomposition** - Parallel execution\n- **discussion-context-hook** - Context preservation\n\n## 🚀 Quick Start\n\n```bash\ntar -xzf custom-skills-v1.0.0.tar.gz\npython install.py\n```"
  }'

echo ""
echo "Release created! Now upload the package..."

# Get release ID and upload URL (simplified - would need parsing)
echo "To upload the package, use:"
echo "  gh release upload v1.0.0 releases/custom-skills-v1.0.0.tar.gz"
