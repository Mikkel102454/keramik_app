param([Parameter(Mandatory=$true)][string]$DefinesFile,
      [Parameter(Mandatory=$true)][int]$VersionCode,
      [Parameter(Mandatory=$true)][string]$VersionName)
$ErrorActionPreference='Stop'
if (git status --porcelain) { throw 'A clean reviewed revision is required before release verification' }
if ($VersionCode -lt 1 -or $VersionName -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version' }
$defines=Get-Content -LiteralPath $DefinesFile -Raw | ConvertFrom-Json
foreach ($key in @('API_BASE_URL','WEBSITE_BASE_URL')) {
  $uri=[Uri]$defines.$key
  if ($uri.Scheme -ne 'https' -or -not $uri.IsAbsoluteUri -or $uri.Host.EndsWith('.invalid') -or $uri.UserInfo -or $uri.Query -or $uri.Fragment) {
    throw "Set a real HTTPS $key in the external defines file"
  }
}
foreach ($key in @('CLAYDOCK_UPLOAD_KEYSTORE','CLAYDOCK_UPLOAD_KEY_ALIAS','CLAYDOCK_UPLOAD_STORE_PASSWORD','CLAYDOCK_UPLOAD_KEY_PASSWORD')) {
  if (-not [Environment]::GetEnvironmentVariable($key)) { throw "Missing $key" }
}
$toolchain=Get-Content -LiteralPath "$PSScriptRoot/toolchain.json" -Raw | ConvertFrom-Json
$installed=python "$PSScriptRoot/run_bounded.py" --seconds 30 --cwd (Get-Location).Path -- flutter.bat --version --machine | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $installed.frameworkRevision -ne $toolchain.flutterRevision) { throw 'Use the pinned Flutter revision' }
python "$PSScriptRoot/run_bounded.py" --seconds 120 --cwd (Get-Location).Path -- flutter.bat pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
python "$PSScriptRoot/run_bounded.py" --seconds 300 --cwd (Get-Location).Path -- flutter.bat analyze
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
python "$PSScriptRoot/run_bounded.py" --seconds 300 --cwd (Get-Location).Path -- flutter.bat test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
python "$PSScriptRoot/run_bounded.py" --seconds 900 --cwd (Get-Location).Path -- flutter.bat build appbundle --release "--dart-define-from-file=$DefinesFile" "--build-number=$VersionCode" "--build-name=$VersionName"
if ($LASTEXITCODE -ne 0) { throw 'AAB build failed' }
$artifact=Resolve-Path 'build/app/outputs/bundle/release/app-release.aab'
$revision=git rev-parse HEAD
$status=git status --porcelain
if ($status) { throw 'Release manifest requires a clean reviewed revision; build was local only' }
$manifest=@{revision=$revision;versionCode=$VersionCode;versionName=$VersionName;applicationId='nu.miguel.claydock';
  sha256=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash;toolchain=$toolchain}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath 'build/release-manifest.json' -Encoding UTF8
Write-Output 'AAB and traceable manifest ready. Publishing requires separate authorization.'
