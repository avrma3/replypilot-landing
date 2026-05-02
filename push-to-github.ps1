# ReplyPilot landing -> GitHub + Pages (run after: gh auth login)
# Usage: .\push-to-github.ps1
# Optional: .\push-to-github.ps1 -RepoName "my-landing"

param(
  [string]$RepoName = "replypilot-landing"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$gh = "${env:ProgramFiles}\GitHub CLI\gh.exe"

if (-not (Test-Path $gh)) {
  Write-Error "GitHub CLI not found at $gh. Install: winget install GitHub.cli"
}

& $gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "Pehle ek baar login karo (browser khulega):" -ForegroundColor Yellow
  Write-Host "  & `"$gh`" auth login" -ForegroundColor Cyan
  Write-Host ""
  exit 1
}

Set-Location $Root

$hasRemote = $false
git remote get-url origin 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $hasRemote = $true }

if (-not $hasRemote) {
  Write-Host "Creating repo $RepoName and pushing..." -ForegroundColor Green
  & $gh repo create $RepoName --public --source=. --remote=origin --push --description "ReplyPilot Chrome extension landing page"
} else {
  Write-Host "Pushing to existing origin..." -ForegroundColor Green
  git push -u origin main
}

$userRepo = (& $gh repo view --json nameWithOwner -q .nameWithOwner).Trim()
if (-not $userRepo) {
  Write-Error "Could not read repo name."
}

Write-Host ""
Write-Host "Enabling GitHub Pages (main / root)..." -ForegroundColor Green
$src = '{"source":{"branch":"main","path":"/"}}'
$src | & $gh api "repos/$userRepo/pages" -X POST --input - 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
  Write-Host "(Pages API skip — ho sakta hai pehle se on ho, ya manually kholna pade)" -ForegroundColor DarkYellow
}

$owner, $name = $userRepo -split "/", 2
$pagesUrl = "https://${owner}.github.io/${name}/"

Write-Host ""
Write-Host "Done. Repo: https://github.com/$userRepo" -ForegroundColor Cyan
Write-Host "Landing URL (1–3 min baad try karo): $pagesUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agar site na khule: GitHub repo -> Settings -> Pages -> Build: Deploy from branch -> main, / (root)" -ForegroundColor Yellow
