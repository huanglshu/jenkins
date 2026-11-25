$ErrorActionPreference = 'Stop'

try {
    $workspaceFile = Join-Path $PSScriptRoot '../jenkins.local.code-workspace'
    if (-not (Test-Path -LiteralPath $workspaceFile -PathType Leaf)) {
        throw "Missing $workspaceFile. Configure terminal.integrated.env.windows.JAVA_HOME in the local workspace file."
    }

    $workspace = Get-Content -LiteralPath $workspaceFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $javaHome = $workspace.settings.'terminal.integrated.env.windows'.JAVA_HOME
    if (-not $javaHome -or -not (Test-Path -LiteralPath (Join-Path $javaHome 'bin/java.exe') -PathType Leaf)) {
        throw "Set terminal.integrated.env.windows.JAVA_HOME in $workspaceFile to a valid JDK directory."
    }
    $javaHome = (Resolve-Path -LiteralPath $javaHome).ProviderPath.TrimEnd('\', '/')

    $localDirectory = Join-Path $PSScriptRoot 'target'
    $localDirectoryItem = Get-Item -LiteralPath $localDirectory -Force -ErrorAction SilentlyContinue
    if ($localDirectoryItem -and ($localDirectoryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Refusing to use a linked directory: $localDirectory"
    }
    $null = New-Item -ItemType Directory -Path $localDirectory -Force
    $jdkLink = Join-Path $localDirectory 'jenkins-jdk'
    $existing = Get-Item -LiteralPath $jdkLink -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -ne 'Junction') {
            throw "Refusing to replace a non-junction path: $jdkLink"
        }
        $currentTarget = [System.IO.Path]::GetFullPath([string] $existing.Target).TrimEnd('\', '/')
        if (-not [string]::Equals($currentTarget, $javaHome, [System.StringComparison]::OrdinalIgnoreCase)) {
            [System.IO.Directory]::Delete($jdkLink)
            $existing = $null
        }
    }
    if (-not $existing) {
        $null = New-Item -ItemType Junction -Path $jdkLink -Target $javaHome
    }

    Write-Output "Jenkins JDK: $javaHome"
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
