param([string]$RunnerBundleId = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Command py -ErrorAction SilentlyContinue) {
    $locusPython = "py"
    $locusPythonArgs = @("-3")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $locusPython = "python"
    $locusPythonArgs = @()
} else {
    throw "Install Python 3.12 or newer for Windows from python.org, then run this file again."
}

Write-Host "Unlock your iPhone, connect it by USB, and trust this PC. Keep this window open."
& $locusPython @locusPythonArgs -m pip install --upgrade "pymobiledevice3==11.24.0"
if ($LASTEXITCODE -ne 0) { throw "Could not install pymobiledevice3." }

if (!$RunnerBundleId) {
    $locusAppsOutput = & $locusPython @locusPythonArgs -m pymobiledevice3 apps list
    if ($LASTEXITCODE -ne 0) { throw "Could not read installed apps. Check USB trust and the Apple Mobile Device Service." }
    $locusApps = ($locusAppsOutput -join "`n") | ConvertFrom-Json
    $locusMatches = @($locusApps.PSObject.Properties | Where-Object {
        $_.Name -like "*locus*nativespeed*" -or
        ($_.Value.PSObject.Properties["CFBundleDisplayName"] -and $_.Value.CFBundleDisplayName -eq "Locus Speed Helper")
    })
    if ($locusMatches.Count -ne 1) {
        throw "Install the Locus Speed Helper IPA first. If Sideloadly changed its name, run this script with -RunnerBundleId followed by its installed bundle identifier."
    }
    $RunnerBundleId = $locusMatches[0].Name
}
Write-Host "Using helper: $RunnerBundleId"
Write-Host "Preparing the developer disk image..."
& $locusPython @locusPythonArgs -m pymobiledevice3 mounter auto-mount
if ($LASTEXITCODE -ne 0) { throw "Developer image could not be mounted. Confirm Developer Mode and unlock the phone." }

Write-Host "Starting native speed helper. In Locus choose Settings > Location engine > Native speed helper, then Check native speed helper."
Write-Host "Stop the route in Locus before pressing Ctrl+C here."
& $locusPython @locusPythonArgs -m pymobiledevice3 developer dvt xcuitest $RunnerBundleId `
    --env USE_PORT=8100 --env USE_IP=127.0.0.1 --env "WDA_PRODUCT_BUNDLE_IDENTIFIER=$RunnerBundleId"
if ($LASTEXITCODE -ne 0) { throw "Helper launch failed. Save the error text from this window for troubleshooting." }
