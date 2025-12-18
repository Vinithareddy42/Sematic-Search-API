@echo off
setlocal ENABLEDELAYEDEXPANSION

echo [setup] Creating/activating virtualenv...

REM Check Python version compatibility
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [setup] Detected Python version: %PYTHON_VERSION%

REM PyTorch requires Python 3.9-3.12, warn about 3.13+
python -c "import sys; v=sys.version_info; sys.exit(0 if v.major==3 and v.minor<=12 else 1)" 2>nul
if errorlevel 1 (
    echo [setup] WARNING: Python 3.13+ detected. PyTorch may not have wheels available.
    echo [setup] Consider using Python 3.11 or 3.12 for best compatibility.
)

REM Use .venv in project root
if not exist ".venv" (
    python -m venv .venv
    if errorlevel 1 (
        echo [setup] FAILED: Could not create virtualenv. Ensure Python is on PATH.
        exit /b 1
    )
)

call ".venv\Scripts\activate.bat"

echo [setup] Upgrading pip, setuptools, and wheel...
python -m pip install --upgrade pip setuptools wheel
if errorlevel 1 (
    echo [setup] FAILED: pip upgrade failed.
    exit /b 1
)

echo [setup] Installing PyTorch (CPU - universally compatible)...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
if errorlevel 1 (
    echo [setup] WARNING: PyTorch CPU installation encountered issues. Trying fallback without dependencies...
    pip install torch --no-deps --index-url https://download.pytorch.org/whl/cpu
    if errorlevel 1 (
        echo [setup] WARNING: Trying alternative PyTorch source...
        pip install torch torchvision torchaudio
        if errorlevel 1 (
            echo [setup] WARNING: Could not install PyTorch wheels. Trying CPU-only build...
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --no-cache-dir
            if errorlevel 1 (
                echo [setup] FAILED: Could not install PyTorch. 
                echo [setup] Troubleshooting: 
                echo [setup]   1. Use Python 3.11 or 3.12 (currently running Python 3.14+)
                echo [setup]   2. Check internet connectivity
                echo [setup]   3. Try installing manually: pip install torch torchvision torchaudio
                exit /b 1
            )
        )
    )
)

echo [setup] Installing remaining dependencies from requirements.txt...
pip install -r requirements.txt
if errorlevel 1 (
    echo [setup] FAILED: Dependency installation failed.
    exit /b 1
)

echo [setup] Ensuring .env configuration...
if not exist ".env" (
    if exist ".env.example" (
        copy /Y ".env.example" ".env" >nul
        echo [setup] Created .env from .env.example. Edit to add OPENAI_API_KEY, etc.
    ) else (
        echo [setup] WARNING: .env and .env.example not found. Using only process env vars.
    )
)

echo [setup] Building vector index (Chroma)...
python -m scripts.build_index
if errorlevel 1 (
    echo [setup] FAILED: Index build failed.
    exit /b 1
)

echo [setup] SUCCESS: All setup complete!
echo [setup] Starting FastAPI with Uvicorn on http://localhost:8000 ...
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

endlocal
