#!/usr/bin/env python3
"""
Cross-platform skill installer
Works on Linux, macOS, and Windows
"""

import os
import sys
import json
import shutil
import argparse
from pathlib import Path


def get_default_install_dir():
    """Get default installation directory based on OS"""
    home = Path.home()

    if sys.platform == "win32":
        # Windows: %USERPROFILE%\.agents\skills
        return home / ".agents" / "skills"
    else:
        # Linux/macOS: ~/.agents/skills
        return home / ".agents" / "skills"


def install_skills(source_dir, install_dir, force=False):
    """Install skills from source to target directory"""

    print("🔧 Custom Skills Installer")
    print("=" * 40)
    print(f"Source: {source_dir}")
    print(f"Target: {install_dir}")
    print(f"Force: {force}")
    print()

    # Check if target exists
    if install_dir.exists() and not force:
        print(f"⚠️  Target directory already exists: {install_dir}")
        print("   Use --force to overwrite")
        return False

    # Create target directories
    embedded_target = install_dir / "embedded"
    superpowers_target = install_dir / "superpowers"

    embedded_target.mkdir(parents=True, exist_ok=True)
    superpowers_target.mkdir(parents=True, exist_ok=True)

    # Copy embedded skills
    embedded_source = source_dir / "embedded"
    if embedded_source.exists():
        print("📦 Installing embedded skills...")
        for item in embedded_source.iterdir():
            if item.is_dir():
                target = embedded_target / item.name
                if target.exists():
                    shutil.rmtree(target)
                shutil.copytree(item, target)
                print(f"   ✓ {item.name}")

    # Copy superpowers skills
    superpowers_source = source_dir / "superpowers"
    if superpowers_source.exists():
        print("📦 Installing superpowers skills...")
        for item in superpowers_source.iterdir():
            if item.is_dir():
                target = superpowers_target / item.name
                if target.exists():
                    shutil.rmtree(target)
                shutil.copytree(item, target)
                print(f"   ✓ {item.name}")

    # Load and display manifest
    manifest_file = source_dir / "MANIFEST.json"
    if manifest_file.exists():
        with open(manifest_file, "r") as f:
            manifest = json.load(f)
        print(f"\n📋 Version: {manifest.get('version', 'unknown')}")
        print(f"📅 Created: {manifest.get('created', 'unknown')}")

    print("\n✅ Installation complete!")
    print(f"\nInstalled to: {install_dir}")
    print("\nNext steps:")
    print("  1. Restart your agent session")
    print("  2. Skills will be automatically loaded when needed")

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Install custom skills for AI agent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Install to default location
  %(prog)s --target ~/.my-skills    # Install to custom location
  %(prog)s --force                  # Overwrite existing installation
  %(prog)s --source ./my-package    # Install from specific source
        """,
    )

    parser.add_argument(
        "--target",
        "-t",
        type=Path,
        default=None,
        help="Target installation directory (default: ~/.agents/skills)",
    )

    parser.add_argument(
        "--source",
        "-s",
        type=Path,
        default=None,
        help="Source directory containing skills (default: current directory)",
    )

    parser.add_argument(
        "--force", "-f", action="store_true", help="Force overwrite if target exists"
    )

    parser.add_argument(
        "--list",
        "-l",
        action="store_true",
        help="List available skills without installing",
    )

    args = parser.parse_args()

    # Determine source directory
    if args.source:
        source_dir = args.source.resolve()
    else:
        # Assume script is in the package directory
        source_dir = Path(__file__).parent.resolve()

    # Check if source exists
    if not source_dir.exists():
        print(f"❌ Source directory not found: {source_dir}")
        sys.exit(1)

    # List mode
    if args.list:
        print("📋 Available skills in package:")
        print()

        embedded_dir = source_dir / "embedded"
        if embedded_dir.exists():
            print("Embedded skills:")
            for item in sorted(embedded_dir.iterdir()):
                if item.is_dir():
                    print(f"  - {item.name}")

        superpowers_dir = source_dir / "superpowers"
        if superpowers_dir.exists():
            print("\nSuperpowers skills:")
            for item in sorted(superpowers_dir.iterdir()):
                if item.is_dir():
                    print(f"  - {item.name}")

        sys.exit(0)

    # Determine target directory
    if args.target:
        install_dir = args.target.expanduser().resolve()
    else:
        install_dir = get_default_install_dir()

    # Install
    success = install_skills(source_dir, install_dir, args.force)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
