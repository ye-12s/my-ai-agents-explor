#!/bin/bash
set -e

INSTALL_DIR="${1:-$HOME/.agents/skills}"
FORCE="${2:-false}"

echo "🔧 Installing Custom Skills"
echo "==========================="
echo "Target directory: ${INSTALL_DIR}"
echo ""

# Check if directory exists
if [ -d "${INSTALL_DIR}" ] && [ "${FORCE}" != "true" ]; then
    echo "⚠️  Target directory already exists: ${INSTALL_DIR}"
    echo "   Use './install.sh <dir> true' to force overwrite"
    exit 1
fi

mkdir -p "${INSTALL_DIR}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Installing embedded skills..."
mkdir -p "${INSTALL_DIR}/embedded"
cp -r "${SCRIPT_DIR}/embedded/"* "${INSTALL_DIR}/embedded/"

echo "📦 Installing superpowers skills..."
mkdir -p "${INSTALL_DIR}/superpowers"
cp -r "${SCRIPT_DIR}/superpowers/"* "${INSTALL_DIR}/superpowers/"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Installed skills:"
echo "  Embedded:"
ls -1 "${INSTALL_DIR}/embedded/" | sed 's/^/    - /'
echo "  Superpowers:"
ls -1 "${INSTALL_DIR}/superpowers/" | sed 's/^/    - /'
echo ""
echo "Next steps:"
echo "  1. Restart your agent session"
echo "  2. Skills will be automatically loaded when needed"
