Write-Host ""
Write-Host "Loading azd .env file from current environment"
Write-Host ""

foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
        Set-Item -Path "env:\$key" -Value $value
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to load environment variables from azd environment"
    exit $LASTEXITCODE
}


Write-Host 'Creating python virtual environment "web/web_env"'
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # fallback to python3 if python not found
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}
Start-Process -FilePath ($pythonCmd).Source -ArgumentList "-m venv ./web/web_env" -Wait -NoNewWindow

Write-Host ""
Write-Host "Restoring web python packages"
Write-Host ""

Set-Location web
$venvPythonPath = "./web_env/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./web_env/bin/python"
}

Start-Process -FilePath $venvPythonPath -ArgumentList "-m pip install -r requirements.txt" -Wait -NoNewWindow
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to restore web python packages"
    exit $LASTEXITCODE
}

# Write-Host ""
# Write-Host "Restoring frontend npm packages"
# Write-Host ""
# Set-Location ../frontend
# npm install
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "Failed to restore frontend npm packages"
#     exit $LASTEXITCODE
# }

# Write-Host ""
# Write-Host "Building frontend"
# Write-Host ""
# npm run build
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "Failed to build frontend"
#     exit $LASTEXITCODE
# }

Write-Host ""
Write-Host "Starting web"
Write-Host ""
Set-Location ../web
Start-Process http://127.0.0.1:5000

# Start-Process -FilePath $venvPythonPath -ArgumentList "./app.py" -Wait -NoNewWindow
Start-Process -FilePath $venvPythonPath -ArgumentList "streamlit run app.py" -Wait -NoNewWindow

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start web"
    exit $LASTEXITCODE
}
