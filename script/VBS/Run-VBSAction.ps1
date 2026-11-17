[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Enable', 'Disable')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
$batchName = if ($Action -eq 'Enable') { 'Enable VBS.bat' } else { 'Disable VBS.bat' }
$batchPath = Join-Path $PSScriptRoot $batchName

if (-not (Test-Path -LiteralPath $batchPath -PathType Leaf)) {
    Write-Host "找不到必需的脚本：$batchPath" -ForegroundColor Red
    Read-Host '按回车键关闭'
    exit 1
}

$cmdExe = Join-Path $env:SystemRoot 'System32\cmd.exe'
$cmdArguments = "/d /c `"$batchPath`""

try {
    # The UAC prompt is shown here; the batch file itself runs in the elevated console.
    $process = Start-Process -FilePath $cmdExe -ArgumentList $cmdArguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
    exit $process.ExitCode
}
catch {
    Write-Host "无法启动所选操作：$_" -ForegroundColor Red
    Read-Host '按回车键关闭'
    exit 1
}
