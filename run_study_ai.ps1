# Run Study AI on Windows from a PowerShell command such as:
# irm https://raw.githubusercontent.com/Sanjeev-Karnatapu/rag-document-chatbot/main/run_study_ai.ps1 | iex

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Find-PythonRuntime {
    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if ($null -ne $launcher) {
        foreach ($selector in @('-3.11', '-3')) {
            try {
                $versionText = (& $launcher.Source $selector --version | Out-String).Trim()
                if ($LASTEXITCODE -eq 0 -and $versionText -match 'Python\s+(\d+\.\d+\.\d+)') {
                    $version = [version]$Matches[1]
                    if ($version -ge [version]'3.10') {
                        return [pscustomobject]@{ Exe = $launcher.Source; Prefix = @($selector); Version = $version }
                    }
                }
            }
            catch { continue }
        }
    }

    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $pythonCommand) {
        try {
            $versionText = (& $pythonCommand.Source --version | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $versionText -match 'Python\s+(\d+\.\d+\.\d+)') {
                $version = [version]$Matches[1]
                if ($version -ge [version]'3.10') {
                    return [pscustomobject]@{ Exe = $pythonCommand.Source; Prefix = @(); Version = $version }
                }
            }
        }
        catch { }
    }

    return $null
}

function Find-OllamaExecutable {
    $ollamaCommand = Get-Command ollama -ErrorAction SilentlyContinue
    if ($null -ne $ollamaCommand) {
        return $ollamaCommand.Source
    }

    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'),
        (Join-Path $env:LOCALAPPDATA 'Ollama\ollama.exe'),
        (Join-Path $env:ProgramFiles 'Ollama\ollama.exe')
    )
    foreach ($candidate in $candidatePaths) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return $null
}

$installRoot = Join-Path $env:USERPROFILE 'StudyAI'
$appFile = Join-Path $installRoot 'app.py'

if (-not (Test-Path -LiteralPath $appFile -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $installRoot 'requirements.txt') -PathType Leaf)) {
    Write-Host 'Downloading the Study AI repository...'
    $bootstrapTemp = Join-Path $env:TEMP ("study-ai-" + [guid]::NewGuid().ToString('N'))
    $extractRoot = Join-Path $bootstrapTemp 'source'
    $archivePath = Join-Path $bootstrapTemp 'repository.zip'
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

    Invoke-WebRequest `
        -Uri 'https://github.com/Sanjeev-Karnatapu/rag-document-chatbot/archive/refs/heads/main.zip' `
        -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force
    $downloadedRoot = Join-Path $extractRoot 'rag-document-chatbot-main'
    if (-not (Test-Path -LiteralPath (Join-Path $downloadedRoot 'app.py'))) {
        throw 'The downloaded GitHub archive did not contain app.py.'
    }

    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $downloadedRoot -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $installRoot $_.Name) -Recurse -Force
    }
    Write-Host "Repository installed at $installRoot"
} else {
    Write-Host "Using the existing Study AI copy at $installRoot"
}

$requirementsFile = Join-Path $installRoot 'requirements.txt'
if (-not (Test-Path -LiteralPath $requirementsFile -PathType Leaf)) {
    throw "requirements.txt was not found in $installRoot."
}

$pythonRuntime = Find-PythonRuntime
if ($null -eq $pythonRuntime) {
    $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $wingetCommand) {
        throw 'Python 3.10 or newer is required. Install Python from https://www.python.org/downloads/windows/ and rerun this command.'
    }

    Write-Host 'Installing Python 3.11...'
    & $wingetCommand.Source install --id Python.Python.3.11 --exact --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw 'Python installation through Windows Package Manager failed.'
    }
    Update-ProcessPath
    $pythonRuntime = Find-PythonRuntime
    if ($null -eq $pythonRuntime) {
        throw 'Python was installed, but this PowerShell session could not find it. Open a new PowerShell window and rerun the command.'
    }
}

Write-Host "Using Python $($pythonRuntime.Version)"
$venvRoot = Join-Path $installRoot '.venv'
$venvPython = Join-Path $venvRoot 'Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
    $venvCreateArgs = @($pythonRuntime.Prefix) + @('-m', 'venv', $venvRoot)
    & $pythonRuntime.Exe @venvCreateArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not create the Study AI virtual environment.'
    }
}

Write-Host 'Installing Python dependencies...'
& $venvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw 'Could not upgrade pip.' }
& $venvPython -m pip install -r $requirementsFile
if ($LASTEXITCODE -ne 0) { throw 'Python dependency installation failed.' }

$ollamaExe = Find-OllamaExecutable
if ($null -eq $ollamaExe) {
    Write-Host 'Installing Ollama using its official Windows installer...'
    $ollamaInstaller = Invoke-RestMethod -Uri 'https://ollama.com/install.ps1'
    Invoke-Expression $ollamaInstaller
    Update-ProcessPath
    $ollamaExe = Find-OllamaExecutable
}
if ($null -eq $ollamaExe) {
    throw 'Ollama was not found after installation. Install it from https://ollama.com/download/windows and rerun this command.'
}

$apiReady = $false
try {
    Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 3 | Out-Null
    $apiReady = $true
} catch {
    Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden
}

if (-not $apiReady) {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Seconds 2
        try {
            Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 3 | Out-Null
            $apiReady = $true
            break
        } catch { }
    }
}
if (-not $apiReady) {
    throw 'The Ollama service did not become ready at http://localhost:11434.'
}

Write-Host 'Downloading the required local models (this may take a while)...'
& $ollamaExe pull 'llama3.2:3b'
if ($LASTEXITCODE -ne 0) { throw 'Could not download the llama3.2:3b model.' }
& $ollamaExe pull 'nomic-embed-text'
if ($LASTEXITCODE -ne 0) { throw 'Could not download the nomic-embed-text model.' }

Set-Location -LiteralPath $installRoot
Write-Host 'Starting Study AI. Stop it with Ctrl+C.'
& $venvPython -m streamlit run (Join-Path $installRoot 'app.py')
