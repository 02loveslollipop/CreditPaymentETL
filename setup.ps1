# Determine script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SCRIPT_DIR) { $SCRIPT_DIR = Get-Location }
Set-Location $SCRIPT_DIR

$ENV_DIR = Join-Path $SCRIPT_DIR ".venv"
$REQ_FILE = Join-Path $SCRIPT_DIR "requirements.txt"

Write-Host "=== Initializing Python Environment ===" -ForegroundColor Green

# Check for Conda / Anaconda / Miniconda
$condaCmd = Get-Command conda -ErrorAction SilentlyContinue

if ($condaCmd) {
    Write-Host "Conda detected." -ForegroundColor Cyan
    if (-not (Test-Path $ENV_DIR)) {
        Write-Host "Creating Conda environment at $ENV_DIR..." -ForegroundColor Yellow
        conda create --prefix "$ENV_DIR" python=3 -y
    } else {
        Write-Host "Conda environment directory already exists at $ENV_DIR." -ForegroundColor Yellow
    }

    Write-Host "Activating Conda environment..." -ForegroundColor Cyan
    conda activate "$ENV_DIR" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $env:CONDA_PREFIX) {
        $activatePs1 = Join-Path $ENV_DIR "Scripts\Activate.ps1"
        if (Test-Path $activatePs1) {
            & $activatePs1
        }
    }
} else {
    Write-Host "Conda not found. Falling back to Python venv." -ForegroundColor Yellow
    
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        $pythonCmd = Get-Command py -ErrorAction SilentlyContinue
    }
    
    if (-not $pythonCmd) {
        Write-Error "Error: Python executable not found on system PATH."
        exit 1
    }

    if (-not (Test-Path $ENV_DIR)) {
        Write-Host "Creating venv environment at $ENV_DIR..." -ForegroundColor Yellow
        & $pythonCmd.Source -m venv "$ENV_DIR"
    } else {
        Write-Host "venv environment directory already exists at $ENV_DIR." -ForegroundColor Yellow
    }

    Write-Host "Activating venv environment..." -ForegroundColor Cyan
    $activatePs1 = Join-Path $ENV_DIR "Scripts\Activate.ps1"
    if (Test-Path $activatePs1) {
        & $activatePs1
    } else {
        Write-Warning "Activation script not found at $activatePs1."
    }
}

# Check and install dependencies from requirements.txt
if (Test-Path $REQ_FILE) {
    Write-Host "Checking dependencies from requirements.txt..." -ForegroundColor Cyan
    python -m pip install --upgrade pip setuptools wheel --quiet 2>$null
    python -m pip install -r "$REQ_FILE"
} else {
    Write-Host "requirements.txt not found. Skipping dependency installation." -ForegroundColor Yellow
}

Write-Host "=== Environment setup complete! ===" -ForegroundColor Green
