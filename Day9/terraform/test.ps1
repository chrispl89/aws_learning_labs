param(
  [string]$Profile = $env:AWS_PROFILE,
  [string]$Region  = $env:AWS_REGION
)

Write-Host "==> Reading Terraform outputs..."
$albUrl = terraform output -raw alb_url
$albDns = terraform output -raw alb_dns_name
$dbEp   = terraform output -raw db_endpoint
$dbPort = terraform output -raw db_port

"ALB: $albUrl"
"ALB DNS: $albDns"
"DB:  $dbEp"
"Port: $dbPort"

# -------------------------
# ALB HTTP check (5x)
# -------------------------
Write-Host "`n==> Hitting ALB 5x (expect 200)..."
$results = 1..5 | ForEach-Object {
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri $albUrl -TimeoutSec 8
    [pscustomobject]@{ Try=$_; Code=[int]$r.StatusCode; Error=$null }
  } catch {
    [pscustomobject]@{ Try=$_; Code=$null; Error=$_.Exception.Message }
  }
}
$results | Format-Table
if ($results.Where({ $_.Code -ne 200 }).Count -gt 0) {
  Write-Warning "Some requests != 200 (targets may still be warming up)."
} else {
  Write-Host "OK: ALB 200"
}

# -------------------------
# ALB -> TG health
# -------------------------
Write-Host "`n==> Target Group health..."
$lbsJson = aws elbv2 describe-load-balancers --output json --region $Region --profile $Profile
$lbs     = $lbsJson | ConvertFrom-Json
$lb      = $null
foreach ($x in $lbs.LoadBalancers) { if ($x.DNSName -eq $albDns) { $lb = $x; break } }
if (-not $lb) { throw "Cannot find ALB by DNSName: $albDns" }
$albArn = $lb.LoadBalancerArn

$tgsJson = aws elbv2 describe-target-groups --load-balancer-arn $albArn --output json --region $Region --profile $Profile
$tgs     = $tgsJson | ConvertFrom-Json
$tgArn   = $tgs.TargetGroups[0].TargetGroupArn

aws elbv2 describe-target-health --target-group-arn $tgArn `
  --query 'TargetHealthDescriptions[].{Id:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}' `
  --output table --region $Region --profile $Profile

# -------------------------
# RDS details (by endpoint.host) – PS 5.1-safe
# -------------------------
Write-Host "`n==> RDS instance details..."
$dbHost = ($dbEp -split ':')[0]
$rdsJson = aws rds describe-db-instances --output json --region $Region --profile $Profile
$rds = $rdsJson | ConvertFrom-Json
$inst = $null
foreach ($i in $rds.DBInstances) {
  if ($i.Endpoint -and $i.Endpoint.Address -eq $dbHost) { $inst = $i; break }
}
if ($inst) {
  $vpcId = $null
  if ($inst.DBSubnetGroup -and $inst.DBSubnetGroup.VpcId) { $vpcId = $inst.DBSubnetGroup.VpcId }
  [pscustomobject]@{
    Identifier = $inst.DBInstanceIdentifier
    Status     = $inst.DBInstanceStatus
    Engine     = $inst.Engine
    Version    = $inst.EngineVersion
    Public     = $inst.PubliclyAccessible
    VpcId      = $vpcId
  } | Format-Table
} else {
  Write-Warning "Could not find RDS by endpoint host: $dbHost"
}

Write-Host "`n==> Done."
