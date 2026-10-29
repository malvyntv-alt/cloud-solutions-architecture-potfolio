param([Parameter(Mandatory = $true)][ValidatePattern("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$")][string]$Tag, [string]$Region = "us-east-1")
$ErrorActionPreference = "Stop"
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
function Assert-Exit { if ($LASTEXITCODE -ne 0) { throw "Command failed. Stop before continuing." } }
$appRepo = terraform -chdir=infra/stacks/regional output -raw app_repository
Assert-Exit
$emailRepo = terraform -chdir=infra/stacks/regional output -raw email_repository
Assert-Exit
$registry = $appRepo.Split('/')[0]
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry
Assert-Exit
docker build --platform linux/amd64 -f containers/Dockerfile.web -t "${appRepo}:$Tag" .
Assert-Exit
docker push "${appRepo}:$Tag"
Assert-Exit
docker build --platform linux/amd64 --provenance=false -f containers/Dockerfile.notifier -t "${emailRepo}:$Tag" .
Assert-Exit
docker push "${emailRepo}:$Tag"
Assert-Exit
Write-Host "Images pushed. Run the migration task before enable_runtime=true. Immutable tags require a new tag for a new release."
