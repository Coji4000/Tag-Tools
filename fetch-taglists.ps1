<#
fetch-taglists.ps1

Checks for the `tag-list-processor` repo in the workspace parent folder, optionally clones and bootstraps it,
runs `main.py` with non-interactive answers, then finds the generated "merged" CSV and extracts the
first column (text before the first comma) into a cleaned output file.
#>

Set-StrictMode -Version Latest

$workspaceRoot = Get-Location
$repoPath = Join-Path $workspaceRoot 'tag-list-processor'

function Prompt-YesNo($msg) {
    $ans = Read-Host "$msg [Y/N]"
    return $ans.Trim().ToUpper().StartsWith('Y')
}

if (-not (Test-Path -Path $repoPath)) {
    Write-Host "Repository not found at: $repoPath"
    if (-not (Prompt-YesNo 'Clone tag-list-processor into workspace now?')) {
        Write-Host 'Aborting.'; exit 0
    }
    Write-Host 'Cloning repository...'
    git clone https://github.com/DraconicDragon/danbooru-e621-tag-list-processor.git "$repoPath"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git clone failed (exit $LASTEXITCODE)"
        exit 1
    }
}

# Ensure Python venv exists and requirements installed
$venvPath = Join-Path $repoPath '.venv'
$pythonExe = Join-Path $venvPath 'Scripts\python.exe'
$pipExe = Join-Path $venvPath 'Scripts\pip.exe'

if (-not (Test-Path -Path $pythonExe)) {
    Write-Host 'Creating Python virtual environment...'
    Push-Location $repoPath
    python -m venv .venv
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error 'Failed to create venv'; exit 1 }
    Pop-Location
}

Write-Host 'Installing Python requirements (this may take a minute)...'
& $pipExe install -r (Join-Path $repoPath 'requirements.txt') 2>&1 | Write-Host

# Run main.py non-interactively with options: 3, 3, 25, n, y
Write-Host 'Running tag-list-processor main.py with automated answers...'
$answers = "3`n3`n25`nn`ny`n"
Push-Location $repoPath
$python = $pythonExe
try {
    $procOutput = $answers | & $python main.py 2>&1
    $procOutput | Out-Host
} catch {
    Write-Error "Failed to run main.py: $_"
    Pop-Location
    exit 1
}
Pop-Location

Write-Host 'main.py finished. Searching for merged output file...'

# Find the most recent file with 'merged' in the name under the output folder
$outRoot = Join-Path $repoPath 'output'
if (-not (Test-Path $outRoot)) { $outRoot = $repoPath }

$mergedFile = Get-ChildItem -Path $outRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'merged' -and ($_.Extension -eq '.csv' -or $_.Extension -eq '.txt') } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $mergedFile) {
    Write-Error 'No merged file found in output. Check tag-list-processor output folder manually.'
    exit 1
}

Write-Host "Found merged file: $($mergedFile.FullName)"

# Process the merged file: keep text before first comma on each non-empty line
$lines = Get-Content -LiteralPath $mergedFile.FullName -ErrorAction Stop
$clean = $lines | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    ($_.Split(','))[0]
} | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$outFile = Join-Path $repoPath 'merged_tags_cleaned.txt'
$clean | Set-Content -LiteralPath $outFile -Encoding UTF8

Write-Host "Wrote cleaned tags (first column) to: $outFile"
Write-Host "Lines: $($clean.Count)"

if ($clean.Count -eq 0) { Write-Warning 'Cleaned file is empty — something may have gone wrong.' }

exit 0
