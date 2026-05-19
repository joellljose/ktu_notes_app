@echo off
title KTU Notes AI Cluster
echo ==========================================
echo   STarting KTU Notes AI Backend Cluster
echo ==========================================

:: Change directory to where backends are
cd %~dp0

echo.
echo [0/6] Checking Ollama & Gemma Model...
:: Try to list models to see if Ollama is running
ollama list >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Ollama is not running! Starting Ollama server...
    start "" "ollama serve"
    timeout /t 5 /nobreak > nul
)

:: Ensure Gemma 2B is pulled (Used by Moderation)
echo [!] Ensuring gemma:2b is available (Moderation)...
ollama pull gemma:2b
:: Ensure Gemma 7B is pulled (Used by Gemma Backend)
echo [!] Ensuring gemma:7b is available (Gemma Backend)...
ollama pull gemma:7b

echo [1/6] Starting Gemini Backend (Port 5000)...
start "Gemini Backend" python gemini_backend.py
timeout /t 2 /nobreak > nul

echo [2/6] Starting Gemma Backend (Port 5001)...
start "Gemma Backend" python gemma_backend.py
timeout /t 2 /nobreak > nul

echo [3/6] Starting Moderation Backend (Port 5002)...
start "Moderation Backend" python moderation_backend.py
timeout /t 2 /nobreak > nul

echo [4/6] Starting Unified Gateway (Port 8000)...
start "API Gateway" python gateway.py
timeout /t 3 /nobreak > nul

echo.
echo ==========================================
echo   All backends started! 
echo   Now starting ngrok for PORT 8000...
echo ==========================================
echo.

:: Note: This assumes ngrok is in the system PATH
ngrok http 8000

pause
