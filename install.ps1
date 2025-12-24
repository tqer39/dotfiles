<#
.SYNOPSIS
    Dotfiles setup script for Windows PowerShell

.DESCRIPTION
    This script sets up dotfiles on Windows by creating symbolic links
    from the dotfiles repository to appropriate locations.

.PARAMETER Full
    Perform full setup including development environment

.PARAMETER Minimal
    Perform minimal setup (dotfiles only, default)

.PARAMETER SkipPackages
    Skip package installation

.PARAMETER DryRun
    Show what would be done without executing

.PARAMETER Uninstall
    Remove dotfiles symlinks

.EXAMPLE
    # Run from PowerShell:
    irm https://raw.githubusercontent.com/tqer39/dotfiles/main/install.ps1 | iex

    # Or download and run with options:
    .\install.ps1 -Full
    .\install.ps1 -DryRun
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$Minimal,
    [switch]$SkipPackages,
    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$CI,
    [switch]$Help
)

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
$ErrorActionPreference = "Stop"
$DotfilesRepo = "https://github.com/tqer39/dotfiles.git"
$DotfilesBranch = "main"
$DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { Join-Path $env:USERPROFILE ".dotfiles" }
$BackupDir = Join-Path $env:USERPROFILE ".dotfiles_backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Show-Help {
    @"
Dotfiles Setup Script for Windows

Usage:
    install.ps1 [OPTIONS]

Options:
    -Full           Full setup (dotfiles + development environment)
    -Minimal        Minimal setup (dotfiles only, default)
    -SkipPackages   Skip package installation
    -DryRun         Show what would be done without executing
    -Uninstall      Remove dotfiles symlinks
    -CI             CI mode (non-interactive, continue on errors)
    -Help           Show this help message

Examples:
    # Minimal install (dotfiles only)
    irm https://raw.githubusercontent.com/tqer39/dotfiles/main/install.ps1 | iex

    # Full install
    .\install.ps1 -Full

    # Preview changes
    .\install.ps1 -DryRun
"@
}

# ------------------------------------------------------------------------------
# Symlink Functions
# ------------------------------------------------------------------------------
function New-SymbolicLinkSafe {
    param(
        [string]$Source,
        [string]$Destination
    )

    # Check if source exists
    if (-not (Test-Path $Source)) {
        Write-Err "Source does not exist: $Source"
        return $false
    }

    # Check if destination already points to source (idempotent)
    if (Test-Path $Destination) {
        $item = Get-Item $Destination -Force
        if ($item.LinkType -eq "SymbolicLink") {
            $target = $item.Target
            if ($target -eq $Source) {
                Write-Info "Symlink already correct: $Destination -> $Source"
                return $true
            }
        }

        # Backup existing file/link
        $backupPath = Join-Path $BackupDir ($Destination -replace [regex]::Escape($env:USERPROFILE), "")
        $backupParent = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupParent)) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        }
        Move-Item -Path $Destination -Destination $backupPath -Force
        Write-Warn "Backed up: $Destination -> $backupPath"
    }

    # Create parent directory if needed
    $destParent = Split-Path $Destination -Parent
    if (-not (Test-Path $destParent)) {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would create directory: $destParent"
        } else {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }
    }

    # Create symlink
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would create symlink: $Destination -> $Source"
    } else {
        $isDirectory = (Get-Item $Source).PSIsContainer
        if ($isDirectory) {
            New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
        }
        Write-Success "Created symlink: $Destination -> $Source"
    }

    return $true
}

# ------------------------------------------------------------------------------
# Setup Functions
# ------------------------------------------------------------------------------
function Install-Repository {
    # Skip if dotfiles scripts already exist (e.g., running from source checkout)
    $scriptsPath = Join-Path $DotfilesDir "scripts"
    if (Test-Path (Join-Path $scriptsPath "dotfiles.sh")) {
        Write-Info "Using existing dotfiles at $DotfilesDir"
        return
    }

    if (Test-Path $DotfilesDir) {
        Write-Info "Dotfiles directory exists, updating..."
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would run: git -C $DotfilesDir pull"
        } else {
            Push-Location $DotfilesDir
            git pull --quiet
            Pop-Location
            Write-Success "Updated dotfiles repository"
        }
    } else {
        Write-Info "Cloning dotfiles repository..."
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would run: git clone $DotfilesRepo $DotfilesDir"
        } else {
            git clone --branch $DotfilesBranch $DotfilesRepo $DotfilesDir
            Write-Success "Cloned dotfiles repository"
        }
    }
}

function Install-Dotfiles {
    Write-Info "Installing dotfiles..."

    $configFile = Join-Path $DotfilesDir "config\platform-files.conf"
    if (-not (Test-Path $configFile)) {
        Write-Err "Config file not found: $configFile"
        return
    }

    $content = Get-Content $configFile
    foreach ($line in $content) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        # Parse line: SOURCE:DESTINATION:PLATFORMS
        $parts = $line.Split(":")
        if ($parts.Count -lt 3) {
            continue
        }

        $src = $parts[0].Trim()
        $dest = $parts[1].Trim()
        $platforms = $parts[2].Trim()

        # Check if Windows is supported
        if ($platforms -ne "all" -and $platforms -notmatch "windows") {
            continue
        }

        # Expand paths
        $fullSrc = Join-Path $DotfilesDir "src\$src"
        $fullDest = $dest -replace "~", $env:USERPROFILE

        # Handle VS Code path
        if ($fullDest -match "VSCODE_USER_DIR") {
            $vscodeDir = Join-Path $env:APPDATA "Code\User"
            $fullDest = $fullDest -replace "VSCODE_USER_DIR", $vscodeDir
        }

        # Convert forward slashes to backslashes
        $fullSrc = $fullSrc -replace "/", "\"
        $fullDest = $fullDest -replace "/", "\"

        if (Test-Path $fullSrc) {
            New-SymbolicLinkSafe -Source $fullSrc -Destination $fullDest | Out-Null
        } else {
            Write-Warn "Source not found: $fullSrc"
        }
    }

    Write-Success "Dotfiles installation complete!"
}

function Uninstall-Dotfiles {
    Write-Info "Uninstalling dotfiles..."

    $configFile = Join-Path $DotfilesDir "config\platform-files.conf"
    if (-not (Test-Path $configFile)) {
        Write-Warn "Config file not found"
        return
    }

    $content = Get-Content $configFile
    foreach ($line in $content) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $parts = $line.Split(":")
        if ($parts.Count -lt 3) {
            continue
        }

        $dest = $parts[1].Trim()
        $platforms = $parts[2].Trim()

        if ($platforms -ne "all" -and $platforms -notmatch "windows") {
            continue
        }

        $fullDest = $dest -replace "~", $env:USERPROFILE
        if ($fullDest -match "VSCODE_USER_DIR") {
            $vscodeDir = Join-Path $env:APPDATA "Code\User"
            $fullDest = $fullDest -replace "VSCODE_USER_DIR", $vscodeDir
        }
        $fullDest = $fullDest -replace "/", "\"

        if (Test-Path $fullDest) {
            $item = Get-Item $fullDest -Force
            if ($item.LinkType -eq "SymbolicLink") {
                if ($DryRun) {
                    Write-Info "[DRY-RUN] Would remove: $fullDest"
                } else {
                    Remove-Item $fullDest -Force
                    Write-Info "Removed: $fullDest"
                }
            }
        }
    }

    Write-Success "Dotfiles uninstalled"
}

function Install-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Info "Scoop is already installed"
        return $true
    }

    Write-Info "Installing Scoop..."
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would install Scoop"
        return $true
    }

    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Success "Scoop installed"
        return $true
    } catch {
        Write-Warn "Failed to install Scoop: $_"
        return $false
    }
}

function Install-ScoopPackages {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Warn "Scoop is not installed. Skipping Scoop package installation."
        return
    }

    Write-Info "Installing packages with Scoop..."

    # Add buckets for additional packages
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would add extras and nerd-fonts buckets"
    } else {
        scoop bucket add extras 2>$null
        scoop bucket add nerd-fonts 2>$null
    }

    # Scoop packages (prefer these over winget)
    $packages = @(
        "git",
        "gh",
        "starship",
        "mise",
        "fzf",
        "HackGen-NF",
        "aws-vault",
        "ripgrep"
    )

    foreach ($package in $packages) {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would install: $package"
        } else {
            Write-Info "Installing: $package"
            try {
                scoop install $package 2>$null
            } catch {
                if ($CI) {
                    Write-Warn "Failed to install $package (CI mode, continuing): $_"
                } else {
                    throw
                }
            }
        }
    }

    Write-Success "Scoop packages installed"
}

function Install-PowerShellModules {
    Write-Info "Installing PowerShell modules..."

    # PSFzf for fzf integration
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        if (-not (Get-Module -ListAvailable -Name PSFzf)) {
            if ($DryRun) {
                Write-Info "[DRY-RUN] Would install PSFzf module"
            } else {
                Write-Info "Installing PSFzf module..."
                try {
                    Install-Module -Name PSFzf -Scope CurrentUser -Force -AllowClobber
                    Write-Success "PSFzf module installed"
                } catch {
                    if ($CI) {
                        Write-Warn "Failed to install PSFzf module (CI mode, continuing): $_"
                    } else {
                        throw
                    }
                }
            }
        } else {
            Write-Info "PSFzf module already installed"
        }
    } else {
        Write-Warn "fzf not found. Skipping PSFzf module installation."
    }
}

function Install-WingetPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn "winget is not installed. Skipping winget package installation."
        return
    }

    Write-Info "Installing packages with winget..."

    # Packages that are better installed via winget (GUI apps, etc.)
    $packages = @(
        "Microsoft.VisualStudioCode",
        "Raycast.Raycast",
        "AgileBits.1Password",
        "Amazon.AWSCLI"
    )

    foreach ($package in $packages) {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would install: $package"
        } else {
            Write-Info "Installing: $package"
            try {
                $result = winget install --id $package --accept-source-agreements --accept-package-agreements --silent 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "winget exited with code $LASTEXITCODE"
                }
            } catch {
                if ($CI) {
                    Write-Warn "Failed to install $package (CI mode, continuing): $_"
                } else {
                    throw
                }
            }
        }
    }

    Write-Success "winget packages installed"
}

function Install-VSCodeExtensions {
    $codePath = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codePath) {
        Write-Warn "VS Code is not installed. Skipping extension installation."
        return
    }

    $extensionsFile = Join-Path $DotfilesDir "src\.vscode\extensions.json"
    if (-not (Test-Path $extensionsFile)) {
        Write-Warn "extensions.json not found"
        return
    }

    Write-Info "Installing VS Code extensions..."

    $content = Get-Content $extensionsFile -Raw | ConvertFrom-Json
    foreach ($extension in $content.recommendations) {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would install extension: $extension"
        } else {
            Write-Info "Installing: $extension"
            code --install-extension $extension --force 2>$null
        }
    }

    Write-Success "VS Code extensions installed"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    # Header
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Dotfiles Setup Script (Windows)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Mode: $(if ($Full) { 'full' } else { 'minimal' })"
    Write-Host "  Dry run: $DryRun"
    Write-Host "  CI mode: $CI"
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check for git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Err "Git is required but not installed."
        Write-Info "Install Git via Scoop: scoop install git"
        Write-Info "Or via winget: winget install Git.Git"
        exit 1
    }

    # Setup repository
    Install-Repository

    if ($Uninstall) {
        Uninstall-Dotfiles
        exit 0
    }

    # Install dotfiles
    Install-Dotfiles

    # Full installation
    if ($Full) {
        if (-not $SkipPackages) {
            # Install Scoop first (if not present)
            Install-Scoop | Out-Null
            # Install packages via Scoop (preferred)
            Install-ScoopPackages
            # Install remaining packages via winget (GUI apps)
            Install-WingetPackages
            # Install PowerShell modules (PSFzf, etc.)
            Install-PowerShellModules
        }
        Install-VSCodeExtensions
    }

    # Complete
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Info "Please restart your PowerShell session."

    # Explicitly exit with success code to ensure $LASTEXITCODE from native commands doesn't affect script exit
    exit 0
}

# Run main function
Main
