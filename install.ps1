#Requires -Version 5.1
<#
.SYNOPSIS
    Install custom skills for AI agent (Windows)
.DESCRIPTION
    Cross-platform skill installer for Windows PowerShell
    Works on Windows 10/11 with PowerShell 5.1+
.PARAMETER Target
    Target installation directory (default: ~\.agents\skills)
.PARAMETER Source
    Source directory containing skills (default: current directory)
.PARAMETER Force
    Force overwrite if target exists
.PARAMETER List
    List available skills without installing
.EXAMPLE
    .\install.ps1
    Installs skills to default location
.EXAMPLE
    .\install.ps1 -Target C:\Users\Me\CustomSkills
    Installs to custom location
.EXAMPLE
    .\install.ps1 -Force
    Overwrites existing installation
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Target,
    
    [Parameter()]
    [string]$Source,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$List
)

function Get-DefaultInstallDir {
    $homeDir = $env:USERPROFILE
    return Join-Path $homeDir ".agents\skills"
}

function Install-Skills {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceDir,
        
        [Parameter(Mandatory=$true)]
        [string]$InstallDir,
        
        [switch]$Force
    )
    
    Write-Host "🔧 Custom Skills Installer (Windows)" -ForegroundColor Cyan
    Write-Host "=" * 40
    Write-Host "Source: $SourceDir"
    Write-Host "Target: $InstallDir"
    Write-Host "Force: $Force"
    Write-Host ""
    
    # Check if target exists
    if ((Test-Path $InstallDir) -and -not $Force) {
        Write-Host "⚠️  Target directory already exists: $InstallDir" -ForegroundColor Yellow
        Write-Host "   Use -Force to overwrite"
        return $false
    }
    
    # Create target directories
    $embeddedTarget = Join-Path $InstallDir "embedded"
    $superpowersTarget = Join-Path $InstallDir "superpowers"
    
    New-Item -ItemType Directory -Force -Path $embeddedTarget | Out-Null
    New-Item -ItemType Directory -Force -Path $superpowersTarget | Out-Null
    
    # Copy embedded skills
    $embeddedSource = Join-Path $SourceDir "embedded"
    if (Test-Path $embeddedSource) {
        Write-Host "📦 Installing embedded skills..." -ForegroundColor Green
        Get-ChildItem -Path $embeddedSource -Directory | ForEach-Object {
            $target = Join-Path $embeddedTarget $_.Name
            if (Test-Path $target) {
                Remove-Item -Path $target -Recurse -Force
            }
            Copy-Item -Path $_.FullName -Destination $target -Recurse
            Write-Host "   ✓ $($_.Name)" -ForegroundColor Green
        }
    }
    
    # Copy superpowers skills
    $superpowersSource = Join-Path $SourceDir "superpowers"
    if (Test-Path $superpowersSource) {
        Write-Host "📦 Installing superpowers skills..." -ForegroundColor Green
        Get-ChildItem -Path $superpowersSource -Directory | ForEach-Object {
            $target = Join-Path $superpowersTarget $_.Name
            if (Test-Path $target) {
                Remove-Item -Path $target -Recurse -Force
            }
            Copy-Item -Path $_.FullName -Destination $target -Recurse
            Write-Host "   ✓ $($_.Name)" -ForegroundColor Green
        }
    }
    
    # Load and display manifest
    $manifestFile = Join-Path $SourceDir "MANIFEST.json"
    if (Test-Path $manifestFile) {
        $manifest = Get-Content $manifestFile | ConvertFrom-Json
        Write-Host ""
        Write-Host "📋 Version: $($manifest.version)"
        Write-Host "📅 Created: $($manifest.created)"
    }
    
    Write-Host ""
    Write-Host "✅ Installation complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed to: $InstallDir"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Restart your agent session"
    Write-Host "  2. Skills will be automatically loaded when needed"
    
    return $true
}

function Show-SkillList {
    param([string]$SourceDir)
    
    Write-Host "📋 Available skills in package:" -ForegroundColor Cyan
    Write-Host ""
    
    $embeddedDir = Join-Path $SourceDir "embedded"
    if (Test-Path $embeddedDir) {
        Write-Host "Embedded skills:" -ForegroundColor Yellow
        Get-ChildItem -Path $embeddedDir -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    }
    
    $superpowersDir = Join-Path $SourceDir "superpowers"
    if (Test-Path $superpowersDir) {
        Write-Host ""
        Write-Host "Superpowers skills:" -ForegroundColor Yellow
        Get-ChildItem -Path $superpowersDir -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    }
}

# Main execution
$ErrorActionPreference = "Stop"

# Determine source directory
if ($Source) {
    $sourceDir = Resolve-Path $Source
} else {
    $sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Check if source exists
if (-not (Test-Path $sourceDir)) {
    Write-Host "❌ Source directory not found: $sourceDir" -ForegroundColor Red
    exit 1
}

# List mode
if ($List) {
    Show-SkillList -SourceDir $sourceDir
    exit 0
}

# Determine target directory
if ($Target) {
    $installDir = $Target
} else {
    $installDir = Get-DefaultInstallDir
}

# Create target if it doesn't exist
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

$installDir = Resolve-Path $installDir

# Install
$success = Install-Skills -SourceDir $sourceDir -InstallDir $installDir -Force:$Force

exit ($success ? 0 : 1)
