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
