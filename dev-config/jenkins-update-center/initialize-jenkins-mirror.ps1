param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

$ErrorActionPreference = 'Stop'
$jenkinsHome = Join-Path $PSScriptRoot '../../war/work'
$force = $false

for ($i = 0; $i -lt $Arguments.Count; $i++) {
    switch ($Arguments[$i]) {
        { $_ -in '--jenkins-home', '-JenkinsHome' } {
            if ($i + 1 -ge $Arguments.Count -or [string]::IsNullOrEmpty($Arguments[$i + 1])) {
                [Console]::Error.WriteLine('Error: --jenkins-home requires a directory.')
                exit 2
            }
            $i++
            $jenkinsHome = $Arguments[$i]
        }
        { $_ -in '--force', '-Force' } { $force = $true }
        { $_ -in '--help', '-h', '-Help' } {
            Write-Output 'Usage: pwsh -File initialize-jenkins-mirror.ps1 [-JenkinsHome DIRECTORY] [-Force]'
            exit 0
        }
        default {
            [Console]::Error.WriteLine("Error: unknown argument: $($Arguments[$i])")
            exit 2
        }
    }
}

try {
    if (-not [System.IO.Path]::IsPathRooted($jenkinsHome)) {
        $jenkinsHome = Join-Path (Get-Location).ProviderPath $jenkinsHome
    }
    $jenkinsHome = [System.IO.Path]::GetFullPath($jenkinsHome)

    $configSource = Join-Path $PSScriptRoot 'hudson.model.UpdateCenter.xml'
    $certSource = Join-Path $PSScriptRoot 'huawei-mirror-leops.crt'
    foreach ($sourceFile in @($configSource, $certSource)) {
        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            throw "Error: missing source file: $sourceFile"
        }
    }

    $certDirectory = Join-Path $jenkinsHome 'update-center-rootCAs'
    $null = New-Item -ItemType Directory -Path $certDirectory -Force

    function Install-File([string] $Source, [string] $Destination) {
        $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            if (-not $force) {
                Write-Output "Preserved existing file: $Destination"
                return
            }
            if ($existing -isnot [System.IO.FileInfo] -or
                ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                throw "Error: refusing to overwrite a non-regular file: $Destination"
            }
        }

        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Output "Installed: $Destination"
    }

    Install-File $configSource (Join-Path $jenkinsHome 'hudson.model.UpdateCenter.xml')
    Install-File $certSource (Join-Path $certDirectory 'huawei-mirror-leops.crt')
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
