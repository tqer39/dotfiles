# ------------------------------------------------------------------------------
# PowerShell Profile
# ------------------------------------------------------------------------------

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
