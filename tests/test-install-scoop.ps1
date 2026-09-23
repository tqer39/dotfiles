# Test only the bootstrap function; never run Main or install real packages.
$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$installer = Join-Path $PSScriptRoot '../install.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw $parseErrors }
foreach ($name in @('Install-Scoop', 'Write-Info', 'Write-Success', 'Write-Warn')) {
    $definition = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true)
    if (-not $definition) { throw "Missing function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

# Replace external operations with fixtures, including the host output sink.
function Get-Command { param($Name, $ErrorAction) return $script:scoopAvailable }
function Set-ExecutionPolicy { param($ExecutionPolicy, $Scope, [switch]$Force) }
function Invoke-RestMethod {
    param($Uri)
    $script:downloads++
    if ($script:downloadFails) { throw 'Fixture download failure' }
    return "Write-Output 'Scoop bootstrap diagnostic'"
}
function Out-Host {
    param([Parameter(ValueFromPipeline)]$InputObject)
    process { $script:diagnostics.Add([string]$InputObject) }
}

$script:scoopAvailable = $false
$script:downloads = 0
$script:downloadFails = $false
$script:diagnostics = [System.Collections.Generic.List[string]]::new()
$DryRun = $false

$result = @(Install-Scoop)
if ($result.Count -ne 1 -or $result[0] -isnot [bool] -or -not $result[0]) {
    throw 'Bootstrap output must not pollute the Boolean return value'
}
if ($script:diagnostics -notcontains 'Scoop bootstrap diagnostic') {
    throw 'Bootstrap diagnostics were swallowed'
}

# Main discards the Boolean result; diagnostics must still reach the host.
$script:diagnostics.Clear()
Install-Scoop | Out-Null
if ($script:diagnostics -notcontains 'Scoop bootstrap diagnostic') {
    throw 'Bootstrap diagnostics were swallowed by the caller'
}

$script:downloadFails = $true
if ((Install-Scoop) -ne $false) { throw 'Download failure must return false' }
$downloadsBeforeSkip = $script:downloads
$DryRun = $true
if ((Install-Scoop) -ne $true) { throw 'Dry run must succeed' }
$DryRun = $false
$script:scoopAvailable = $true
if ((Install-Scoop) -ne $true) { throw 'Existing Scoop must succeed' }
if ($script:downloads -ne $downloadsBeforeSkip) { throw 'Skipped bootstrap downloaded a script' }
Write-Host 'PASS: Scoop diagnostics, return value, failure, dry run, and existing install'
