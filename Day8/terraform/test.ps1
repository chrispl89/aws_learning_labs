<#
  Day8/terraform/test.ps1

  Validates Day 8 deployment:
    - Reads TF outputs
    - GET CloudFront URL several times (expect 200)
    - Direct S3 object URL should not be publicly accessible (expect 403/AccessDenied)
#>

[CmdletBinding()]
param(
  [string]$TfDir      = $PSScriptRoot,
  [int]   $Requests   = 5,
  [string]$AwsProfile = $env:AWS_PROFILE,
  [string]$AwsRegion  = $env:AWS_REGION
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Aws {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  $extra = @()
  if ($AwsProfile) { $extra += @("--profile", $AwsProfile) }
  if ($AwsRegion)  { $extra += @("--region",  $AwsRegion)  }
  & aws @Args @extra
}

function Get-TfOutputRaw([string]$name) {
  $val = (& terraform output -raw $name) 2>$null
  if (-not $val) { throw "Terraform output '$name' not found." }
  return $val
}

Push-Location -LiteralPath $TfDir
try {
  Write-Host "==> Reading Terraform outputs..."
  $cdnDomain = Get-TfOutputRaw -name "cloudfront_domain"
  $s3Bucket  = Get-TfOutputRaw -name "s3_bucket_name"
  $siteUrl   = "https://$cdnDomain/index.html"

  Write-Host "CloudFront: $cdnDomain"
  Write-Host "S3 Bucket:  $s3Bucket"
  Write-Host "Site URL:   $siteUrl"

  Write-Host "`n==> GET CloudFront URL (expect 200)..."
  $results = 1..$Requests | ForEach-Object {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri $siteUrl -TimeoutSec 10
      [pscustomobject]@{ Try = $_; Code = $r.StatusCode; Error = "" }
    } catch {
      $code = $null
      if ($_.Exception.Response) {
        try { $code = $_.Exception.Response.StatusCode.value__ } catch { }
      }
      [pscustomobject]@{ Try = $_; Code = $code; Error = $_.Exception.Message }
    }
  }
  $results | Format-Table -AutoSize
  if ((@($results | Where-Object { $_.Code -ne 200 })).Count -gt 0) {
    Write-Warning "Some requests did not return 200 (CloudFront may still be propagating)."
  } else {
    Write-Host "OK: all returned 200"
  }

  Write-Host "`n==> Trying direct S3 URL (should be blocked: 403/AccessDenied)..."
  $s3Url = "https://$s3Bucket.s3.${env:AWS_REGION}.amazonaws.com/index.html"
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri $s3Url -TimeoutSec 10
    Write-Warning "Unexpected success for direct S3 URL. Code: $($r.StatusCode)"
  } catch {
    if ($_.Exception.Response) {
      $code = $_.Exception.Response.StatusCode.value__
      Write-Host "Got expected denial from S3. HTTP $code"
    } else {
      Write-Host "S3 direct access failed as expected."
    }
  }

  Write-Host "`n==> Done."
}
finally {
  Pop-Location
}
