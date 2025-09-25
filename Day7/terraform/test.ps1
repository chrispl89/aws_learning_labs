<#
  Day7/terraform/test.ps1

  Validates Day 7 (modules) deployment:
    1) Reads TF outputs (ALB URL/DNS, EC2 public IPs)
    2) Hits ALB (N times) -> expect 200
    3) Verifies EC2 hardening: HTTP:80 blocked from Internet
    4) Verifies SSH:22 reachable from your /32 (if my_ip matches)
    5) Resolves ALB ARN by DNS and prints Target Group health
    6) Confirms IMDSv2 (HttpTokens=required) on TG instances
    7) Confirms ALB spans two subnets / AZs
    8) Validates SG rule: app port allowed ONLY from ALB SG

  Requirements:
    - Terraform & AWS CLI in PATH
    - AWS_PROFILE / AWS_REGION set (or pass as params)
#>

[CmdletBinding()]
param(
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

function Invoke-AwsWithList {
  param(
    [string[]]$Head,         # e.g. 'ec2','describe-instances'
    [string]  $ListSwitch,   # e.g. '--instance-ids'
    [string[]]$List,         # e.g. @('i-123','i-456')
    [string[]]$Tail          # e.g. @('--query','...','--output','json')
  )
  $extra = @()
  if ($AwsProfile) { $extra += @('--profile', $AwsProfile) }
  if ($AwsRegion)  { $extra += @('--region',  $AwsRegion)  }
  & aws @Head $ListSwitch @List @Tail @extra
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

Push-Location -LiteralPath $TfDir
try {
  Write-Host "==> Reading Terraform outputs..."
  $albUrl     = Get-TfOutputRaw  -name "alb_url"
  $albDnsName = Get-TfOutputRaw  -name "alb_dns_name"
  $ec2Ips     = Get-TfOutputJson -name "ec2_public_ips"

  Write-Host "ALB: $albUrl"
  Write-Host "ALB DNS: $albDnsName"
  Write-Host ("EC2 IPs: " + ($ec2Ips -join ", "))

  Write-Host "`n==> Hitting ALB $Requests times (expect HTTP 200)..."
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
    Write-Warning "Some requests did not return 200."
  } else {
    Write-Host "OK: all returned 200"
  }

  Write-Host "`n==> Verifying EC2 hardening: HTTP:80 directly to EC2 should be BLOCKED..."
  $httpChecks = foreach ($ip in $ec2Ips) {
    Test-NetConnection -ComputerName $ip -Port 80 | Select-Object ComputerName, TcpTestSucceeded
  }
  $httpChecks | Format-Table -AutoSize
  if ((@($httpChecks | Where-Object { $_.TcpTestSucceeded -eq $true })).Count -gt 0) {
    Write-Warning "Expected HTTP:80 to be blocked, but some hosts are open."
  } else {
    Write-Host "OK: HTTP:80 blocked"
  }

  Write-Host "`n==> Verifying SSH:22 reachable from your /32 (depending on my_ip)..."
  $sshChecks = foreach ($ip in $ec2Ips) {
    Test-NetConnection -ComputerName $ip -Port 22 | Select-Object ComputerName, TcpTestSucceeded
  }
  $sshChecks | Format-Table -AutoSize
  if ((@($sshChecks | Where-Object { $_.TcpTestSucceeded -ne $true })).Count -gt 0) {
    Write-Warning "SSH:22 did not succeed to some hosts (check your public IP or tfvars my_ip)."
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

  Write-Host "==> Fetching Target Group ARN & health..."
  $tgsJson = Invoke-Aws elbv2 describe-target-groups --load-balancer-arn $lbArn --output json
  $tgs     = $tgsJson | ConvertFrom-Json
  if (-not $tgs.TargetGroups -or $tgs.TargetGroups.Count -lt 1) {
    throw "No target groups found for ALB."
  }
  $tgArn = $tgs.TargetGroups[0].TargetGroupArn
  Invoke-Aws elbv2 describe-target-health --target-group-arn $tgArn `
    --query 'TargetHealthDescriptions[].{Id:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}' `
    --output table

  Write-Host "`n==> Checking IMDSv2 enforcement on EC2 (HttpTokens=required) for TG instances..."
  $targetIds = Invoke-Aws elbv2 describe-target-health --target-group-arn $tgArn `
    --query 'TargetHealthDescriptions[].Target.Id' --output json | ConvertFrom-Json
  if (-not $targetIds -or $targetIds.Count -lt 1) { throw "No targets registered in TG." }

  $res = Invoke-AwsWithList -Head @('ec2','describe-instances') -ListSwitch '--instance-ids' -List $targetIds `
    -Tail @('--query','Reservations[].Instances[].{Id:InstanceId,Tokens:MetadataOptions.HttpTokens}','--output','json')
  ($res | ConvertFrom-Json) | Sort-Object Id | Format-Table -AutoSize


  Write-Host "`n==> Checking ALB availability zones / subnets..."
  Invoke-Aws elbv2 describe-load-balancers --load-balancer-arns $lbArn `
    --query 'LoadBalancers[0].AvailabilityZones[].{AZ:ZoneName, SubnetId:SubnetId}' --output table

  Write-Host "`n==> Validating SG rule: App SG ingress on app port only from ALB SG..."
  # ALB SG directly from LB description
  $albSgId = $lb.SecurityGroups[0]
  Write-Host "ALB SG: $albSgId"

  # Derive APP SG from one of the instances behind ALB
  $oneInstanceId = $targetIds[0]
  $appSgId = Invoke-Aws ec2 describe-instances --instance-ids $oneInstanceId `
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text
  Write-Host "APP SG: $appSgId"

  # Describe APP SG and check ingress on app_port
  $appSgDesc = Invoke-Aws ec2 describe-security-groups --group-ids $appSgId --output json | ConvertFrom-Json
  $ing = $appSgDesc.SecurityGroups[0].IpPermissions

  # Read app_port from TF output (fallback 80)
  $appPort = 80
  try { $appPort = [int](Get-TfOutputRaw -name "app_port") } catch {}

  # Match: app_port from ALB SG
  $fromAlb = @($ing | Where-Object {
    $_.FromPort -eq $appPort -and $_.ToPort -eq $appPort -and ($_.UserIdGroupPairs | ForEach-Object { $_.GroupId }) -contains $albSgId
  })

  # Ensure no 0.0.0.0/0 is allowed on app_port (IpRanges may be null)
  $worldOnApp = @()
  foreach ($perm in $ing) {
    if ($perm.FromPort -eq $appPort -and $perm.ToPort -eq $appPort -and $perm.IpRanges) {
      $cidrs = @($perm.IpRanges | ForEach-Object { $_.CidrIp })
      if ($cidrs -contains "0.0.0.0/0") { $worldOnApp += $perm }
    }
  }

  if ($fromAlb.Count -ge 1 -and $worldOnApp.Count -eq 0) {
    Write-Host "OK: App port is allowed only from ALB SG."
  } else {
    Write-Warning "App port ingress check failed: expected only from ALB SG and no 0.0.0.0/0."
  }

  Write-Host "`n==> Done."
}
finally {
  Pop-Location
}
