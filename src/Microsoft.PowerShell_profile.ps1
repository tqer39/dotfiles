# ------------------------------------------------------------------------------
# PowerShell Profile
# ------------------------------------------------------------------------------

# mise (tool version manager) - must be activated early
if (Get-Command mise -ErrorAction SilentlyContinue) {
    # Suppress chpwd warning for PowerShell 5.x (Windows PowerShell)
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $env:MISE_PWSH_CHPWD_WARNING = 0
    }
    (& mise activate pwsh) | Out-String | Invoke-Expression
}

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# PSFzf (fzf integration for PowerShell)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    if (Get-Module -ListAvailable -Name PSFzf) {
        Import-Module PSFzf

        # Key bindings
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

        # Alt+C for directory change
        Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock {
            $result = Get-ChildItem -Directory -Recurse | Select-Object -ExpandProperty FullName | fzf
            if ($result) {
                Set-Location $result
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            }
        }
    }
}

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------

# Unix-like commands
function which($command) { Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition }

# eza (modern ls replacement)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -la --icons --git @args }
    function la { eza -a --icons @args }
    function lt { eza --tree --icons @args }
    Set-Alias -Name ls -Value eza -Option AllScope
}

# bat (modern cat replacement)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope
}

# Git aliases (aligned with src/.shell_common)
if (Get-Command git -ErrorAction SilentlyContinue) {
    function g { git @args }
    function ga { git add @args }
    function gc { git commit @args }
    function gd { git diff @args }
    function gpl { git pull @args }
    function gps { git push @args }
    function gs { git status @args }
    function gsw { git switch @args }
    function gl { git log --oneline -20 @args }
    function gnf { git new-feature-branch @args }

    function gclean {
        param(
            [switch]$f,
            [switch]$force
        )

        $useForce = $f -or $force
        git fetch -p | Out-Null
        $branches = git branch -vv | Select-String ': gone\]' | ForEach-Object {
            ($_.Line -split '\s+')[0]
        } | Where-Object { $_ }

        if (-not $branches) {
            Write-Host "No stale branches to clean up."
            return
        }

        Write-Host "Deleting stale branches:"
        $branches | ForEach-Object { Write-Host $_ }

        foreach ($branch in $branches) {
            if ($useForce) {
                git branch -D $branch | Out-Null
            } else {
                git branch -d $branch | Out-Null
            }
        }
    }
}
