param([string]$VarFile = "config/demo.tfvars", [switch]$AutoApprove)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
function Assert-Exit { if ($LASTEXITCODE -ne 0) { throw "Command failed. Stop before continuing." } }
$stack = "infra/stacks/regional"
aws sts get-caller-identity --query Account --output text
Assert-Exit
terraform "-chdir=$stack" plan -destroy "-var-file=$VarFile" "-input=false" "-out=destroy.tfplan"
Assert-Exit
if (-not $AutoApprove) {
    $answer = Read-Host "Destroy the regional stack above? Aurora is deleted without a final snapshot. Type 'destroy' to continue"
    if ($answer -ne "destroy") { Remove-Item "$stack/destroy.tfplan"; throw "Cancelled." }
}
terraform "-chdir=$stack" apply "-input=false" destroy.tfplan
Assert-Exit
Remove-Item "$stack/destroy.tfplan"
Write-Host "Regional stack destroyed. Bootstrap (state bucket, KMS key, GitHub role) is untouched."
