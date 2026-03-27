#!/bin/bash
# Initialize docs/arch/ directory structure for task archiving

set -e

ARCH_DIR="${1:-docs/arch}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 Initializing task archive structure in: $ARCH_DIR"

# Create directory structure
mkdir -p "$ARCH_DIR"
mkdir -p "$ARCH_DIR/templates"
mkdir -p "$ARCH_DIR/examples"

# Copy templates
cp "$SCRIPT_DIR/templates/archive-template.md" "$ARCH_DIR/templates/"
cp "$SCRIPT_DIR/templates/index-template.md" "$ARCH_DIR/index.md"

# Create .gitkeep for empty directories
touch "$ARCH_DIR/.gitkeep"

echo "✅ Archive structure created:"
echo ""
echo "  $ARCH_DIR/"
echo "  ├── index.md              # Archive index (update manually)"
echo "  ├── templates/"
echo "  │   └── archive-template.md  # Template for new archives"
echo "  └── examples/             # Example archive entries"
echo ""
echo "Next steps:"
echo "  1. Update docs/arch/index.md with your first entry"
echo "  2. Use 'superpowers/task-archiving' skill after task completion"
echo "  3. See examples/example-archive.md for reference"
