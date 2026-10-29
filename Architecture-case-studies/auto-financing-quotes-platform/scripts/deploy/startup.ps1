param([string]$VarFile = "config/demo.tfvars", [string]$Region = "us-east-1", [string]$Project = "auto-financing-quote", [string]$Tag = "release-001")
$ErrorActionPreference = "Stop"
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
function Assert-Exit { if ($LASTEXITCODE -ne 0) { throw "Command failed. Stop before continuing." } }
$stack = "infra/stacks/regional"

Write-Host "1/4 Foundation with runtime off"
terraform "-chdir=$stack" init "-input=false" "-backend-config=backend.hcl"
Assert-Exit
terraform "-chdir=$stack" apply "-input=false" "-var-file=$VarFile" "-var=enable_runtime=false"
Assert-Exit

Write-Host "2/4 Images: run the build-images workflow on main with tag $Tag, then press Enter."
Read-Host | Out-Null
foreach ($repo in "$Project-app", "$Project-email") {
    $found = aws ecr describe-images --repository-name $repo --image-ids imageTag=$Tag --region $Region --query "imageDetails[0].imageTags" --output text
    Assert-Exit
    if (-not $found) { throw "Image $repo`:$Tag not found in ECR." }
}

Write-Host "3/4 Migration"
python scripts/deploy/run-migration.py --region $Region
Assert-Exit

Write-Host "4/4 Activate runtime"
terraform "-chdir=$stack" apply "-input=false" "-var-file=$VarFile" "-var=enable_runtime=true"
Assert-Exit
Write-Host "Started. Confirm the SES sender email if AWS sent a new verification message, and recreate Cognito users."
