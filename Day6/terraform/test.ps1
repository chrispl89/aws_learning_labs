<#
  Day6/terraform/test.ps1

  What it does:
    1) Reads Terraform outputs (ALB URL, ALB DNS, EC2 public IPs)
    2) Sends N requests to ALB (shows HTTP codes / errors)
    3) Verifies SG hardening:
       - HTTP:80 directly to EC2 should be BLOCKED
       - SSH:22 to EC2 should be OPEN (from your /32)
    4) Resolves ALB ARN by DNS and prints Target Group health via AWS CLI

  Requirements:
    - Terraform in PATH
    - AWS CLI in PATH (optionally AWS_PROFILE / AWS_REGION set)
#>

[CmdletBinding()]
param(
  # Default to the directory where this script lives
  [string]$TfDir      = $PSScriptRoot,
  [int]   $Requests   = 10,
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

function Get-TfOutputJson([string]$name) {
  $json = (& terraform output -json $name) 2>$null
  if (-not $json) { throw "Terraform output '$name' not found." }
  return ($json | ConvertFrom-Json)
}

# Work from the Terraform directory without using -chdir
Push-Location -LiteralPath $TfDir
try {
  Write-Host "==> Reading Terraform outputs..."
  $albUrl     = Get-TfOutputRaw  -name "alb_url"
  $albDnsName = Get-TfOutputRaw  -name "alb_dns_name"
  $ec2Ips     = Get-TfOutputJson -name "ec2_public_ips"

  Write-Host "ALB: $albUrl"
  Write-Host "ALB DNS: $albDnsName"
  Write-Host ("EC2 IPs: " + ($ec2Ips -join ", "))

  Write-Host "`n==> Hitting ALB $Requests times (show HTTP codes/errors)..."
  $results = 1..$Requests | ForEach-Object {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri $albUrl -TimeoutSec 8
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
    Write-Warning "Some requests did not return HTTP 200 (app may not be ready or targets unhealthy)."
  } else {
    Write-Host "OK: all returned 200"
  }

  Write-Host "`n==> Verifying SG hardening (HTTP to EC2 should be BLOCKED)..."
  $httpChecks = @()
  foreach ($ip in $ec2Ips) {
    $httpChecks += (Test-NetConnection -ComputerName $ip -Port 80 | Select-Object ComputerName, TcpTestSucceeded)
  }
  $httpChecks | Format-Table -AutoSize
  if ((@($httpChecks | Where-Object { $_.TcpTestSucceeded -eq $true })).Count -gt 0) {
    Write-Warning "Expected HTTP:80 to be blocked, but some hosts are open."
  } else {
    Write-Host "OK: HTTP:80 blocked for direct EC2 access"
  }

  Write-Host "`n==> Verifying SSH access (should be OPEN from your /32)..."
  $sshChecks = @()
  foreach ($ip in $ec2Ips) {
    $sshChecks += (Test-NetConnection -ComputerName $ip -Port 22 | Select-Object ComputerName, TcpTestSucceeded)
  }
  $sshChecks | Format-Table -AutoSize
  if ((@($sshChecks | Where-Object { $_.TcpTestSucceeded -ne $true })).Count -gt 0) {
    Write-Warning "SSH:22 did not succeed to some hosts. Check your IP or SG."
  } else {
    Write-Host "OK: SSH:22 reachable"
  }

  Write-Host "`n==> Resolving ALB ARN by DNSName..."
  $lbsJson = Invoke-Aws elbv2 describe-load-balancers --output json
  $lbs     = $lbsJson | ConvertFrom-Json
  $lb      = $lbs.LoadBalancers | Where-Object { $_.DNSName -eq $albDnsName }
  if (-not $lb) { throw "Load balancer with DNS '$albDnsName' not found." }
  $lbArn = $lb.LoadBalancerArn
  Write-Host "ALB ARN: $lbArn"

  Write-Host "==> Fetching Target Group ARN associated with ALB..."
  $tgsJson = Invoke-Aws elbv2 describe-target-groups --load-balancer-arn $lbArn --output json
  $tgs     = $tgsJson | ConvertFrom-Json
  if (-not $tgs.TargetGroups -or $tgs.TargetGroups.Count -lt 1) {
    throw "No target groups found for ALB."
  }
  $tgArn = $tgs.TargetGroups[0].TargetGroupArn
  Write-Host "TG ARN: $tgArn"

  Write-Host "==> Target health:"
  Invoke-Aws elbv2 describe-target-health --target-group-arn $tgArn `
    --query 'TargetHealthDescriptions[].{Id:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}' `
    --output table

  Write-Host "`n==> Done."
}
finally {
  Pop-Location
}
