#!/bin/bash
set -e

WORKSPACE_DIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Initializing workspace mandatory archiving..."
echo "   Workspace: $WORKSPACE_DIR"
echo ""

# Create .arch-config.yml
if [ -f "$WORKSPACE_DIR/.arch-config.yml" ]; then
    echo "⚠️  .arch-config.yml already exists"
    echo "   To reinitialize, delete it first: rm .arch-config.yml"
    exit 1
fi

cat > "$WORKSPACE_DIR/.arch-config.yml" << 'EOF'
# Workspace Mandatory Archiving Configuration
# This file enables forced task archiving for this workspace
# Once present, ALL qualifying tasks must be archived before completion

archiving:
  enabled: true
  directory: docs/arch
  
  triggers:
    on_file_change:
      - create
      - modify
      - delete
    min_files_changed: 1
    exclude_paths:
      - "*.log"
      - ".git/**"
      - "node_modules/**"
      - "build/**"
      - "dist/**"
      - "tmp/**"
      - "*.tmp"
  
  requirements:
    required_fields:
      - Summary
      - Problem Statement
      - Solution
      - Technical Decisions
      - Lessons Learned
      - Applicability
    min_description_length: 100
  
  metadata:
    capture_git_info: true
    capture_changed_files: true
    capture_author: true
EOF

echo "✅ Created .arch-config.yml"

# Create directory structure
mkdir -p "$WORKSPACE_DIR/docs/arch"
mkdir -p "$WORKSPACE_DIR/docs/arch/templates"
mkdir -p "$WORKSPACE_DIR/docs/arch/examples"

echo "✅ Created docs/arch/ directory structure"

# Copy templates
cp "$SCRIPT_DIR/templates/archive-template.md" "$WORKSPACE_DIR/docs/arch/templates/"
cp "$SCRIPT_DIR/templates/index-template.md" "$WORKSPACE_DIR/docs/arch/index.md"
cp "$SCRIPT_DIR/examples/example-archive.md" "$WORKSPACE_DIR/docs/arch/examples/" 2>/dev/null || true

echo "✅ Copied templates and examples"

# Create .gitignore entry
if [ -f "$WORKSPACE_DIR/.gitignore" ]; then
    if ! grep -q "^docs/arch/.gitkeep" "$WORKSPACE_DIR/.gitignore"; then
        echo "" >> "$WORKSPACE_DIR/.gitignore"
        echo "# Task archiving" >> "$WORKSPACE_DIR/.gitignore"
        echo "!docs/arch/.gitkeep" >> "$WORKSPACE_DIR/.gitignore"
        echo "✅ Updated .gitignore"
    fi
fi

# Add README
if [ ! -f "$WORKSPACE_DIR/docs/arch/README.md" ]; then
cat > "$WORKSPACE_DIR/docs/arch/README.md" << 'EOF'
# Task Archive

This directory contains archived task documentation for traceability.

## Structure

- `YYYY-MM-DD-feature-name.md` - Individual task archives
- `index.md` - Archive index (update manually)
- `templates/` - Archive templates
- `examples/` - Example archives

## For Developers

When you complete a task in this workspace, it will be automatically archived.
The agent will prompt you for required information.

## Quick Links

- [Index](index.md) - Browse all archives
- [Template](templates/archive-template.md) - Archive format
- [Example](examples/example-archive.md) - Sample archive

---

**Note:** This workspace uses mandatory archiving (`.arch-config.yml`).
All qualifying tasks must be archived before completion.
EOF
    echo "✅ Created docs/arch/README.md"
fi

# Touch .gitkeep
touch "$WORKSPACE_DIR/docs/arch/.gitkeep"

echo ""
echo "🎉 Workspace mandatory archiving initialized!"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Configuration: .arch-config.yml"
echo "  Archive Dir:   docs/arch/"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Commit the configuration:"
echo "     git add .arch-config.yml docs/arch/"
echo "     git commit -m 'Enable mandatory task archiving'"
echo ""
echo "  2. Start working - archiving will be enforced automatically"
echo ""
echo "  3. See full documentation:"
echo "     ~/.agents/skills/superpowers/task-archiving/workspace-mandatory-archiving/SKILL.md"
echo ""
echo "To disable mandatory archiving:"
echo "  rm .arch-config.yml"
