<#
===============================================================================
NEXORA-WINDOWS v20.0 APEX - LOCAL WEB DASHBOARD HOST (Pure PowerShell HttpListener)
===============================================================================
Zero dependencies required! Runs natively on any Windows 10/11/Server machine,
serves the NEXORA Web Dashboard at http://localhost:7788, and executes the
16-Layer "Complete Device Guide (دليل الجهاز الكامل)" collector on demand!
===============================================================================
#>
param(
    [int]$Port = 7788
)

$ErrorActionPreference = "Continue"
$RootDir   = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PublicDir = Join-Path $RootDir "public"
$AgentDir  = Join-Path $RootDir "windows-agent"
$CollectorScript = Join-Path $AgentDir "Generate-Complete-Device-Guide.ps1"

$Url = "http://localhost:$Port/"
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add($Url)
$Listener.Start()

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "  NEXORA-WINDOWS v20.0 APEX - LOCAL STUDIO SERVER RUNNING" -ForegroundColor Green
Write-Host "  Dashboard URL: $Url" -ForegroundColor Yellow
Write-Host "===============================================================================" -ForegroundColor Cyan

Start-Process $Url

while ($Listener.IsListening) {
    try {
        $Context  = $Listener.GetContext()
        $Request  = $Context.Request
        $Response = $Context.Response
        $Path     = $Request.Url.AbsolutePath

        if ($Path -eq "/api/generate-guide" -and $Request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($Request.InputStream)
            $bodyText = $reader.ReadToEnd()
            $targetDir = [Environment]::GetFolderPath("Desktop")
            try {
                if ($bodyText) {
                    $parsed = $bodyText | ConvertFrom-Json
                    if ($parsed.outputDir) { $targetDir = $parsed.outputDir }
                }
            } catch {}

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $CollectorScript -OutputDirectory $targetDir -IncludeJsonExport
            $latestMd = Get-ChildItem -Path $targetDir -Filter "Complete_Device_Guide_*.md" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1

            $payload = @{
                ok        = ($null -ne $latestMd)
                filePath  = if ($latestMd) { $latestMd.FullName } else { "" }
                fileName  = if ($latestMd) { $latestMd.Name } else { "" }
                content   = if ($latestMd) { Get-Content -LiteralPath $latestMd.FullName -Raw -Encoding UTF8 } else { "" }
            } | ConvertTo-Json -Depth 4

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($payload)
            $Response.ContentType = "application/json; charset=utf-8"
            $Response.ContentLength64 = $buffer.Length
            $Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $Response.Close()
            continue
        }

        if ($Path -eq "/") { $Path = "/index.html" }
        $LocalPath = Join-Path $PublicDir ($Path.TrimStart('/') -replace '/', '\')

        if (Test-Path $LocalPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
            $ext = [System.IO.Path]::GetExtension($LocalPath).ToLower()
            $Response.ContentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".json" { "application/json; charset=utf-8" }
                ".md"   { "text/markdown; charset=utf-8" }
                ".txt"  { "text/plain; charset=utf-8" }
                default { "application/octet-stream" }
            }
            $Response.ContentLength64 = $bytes.Length
            $Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $Response.StatusCode = 404
        }
        $Response.Close()
    } catch {
        Write-Warning $_.Exception.Message
    }
}
