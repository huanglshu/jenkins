param(
    [Parameter(Mandatory = $true)]
    [string] $MavenExecutable,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $MavenArguments
)

$ErrorActionPreference = 'Stop'
$workspaceFile = Join-Path $PSScriptRoot '../jenkins.local.code-workspace'
if (-not (Test-Path -LiteralPath $workspaceFile -PathType Leaf)) {
    throw "Missing $workspaceFile. Create a local workspace file with terminal.integrated.env.windows.JAVA_HOME set to JDK 21."
}

$workspace = Get-Content -LiteralPath $workspaceFile -Raw -Encoding UTF8 | ConvertFrom-Json
$javaHome = $workspace.settings.'terminal.integrated.env.windows'.JAVA_HOME
if (-not $javaHome -or -not (Test-Path -LiteralPath (Join-Path $javaHome 'bin/java.exe') -PathType Leaf)) {
    throw "Set terminal.integrated.env.windows.JAVA_HOME in $workspaceFile to a valid JDK directory."
}

$env:JAVA_HOME = $javaHome
& $MavenExecutable @MavenArguments
exit $LASTEXITCODE
