# AWS Learning Labs – Day 5

## Goal
Extend the infrastructure with an **Application Load Balancer (ALB)** to balance traffic between several EC2 instances running the Flask application.

## Steps taken
1. Add the `instance_count` variable → ability to run multiple EC2 instances.
2. Build **ALB** with HTTP listener.
3. Create **Target Group** and assign instances to it.
4. Configure **health checks**.
5. Test traffic distribution using PowerShell (`test.ps1`).

## Functionality test
Test script (`test.ps1`):

```powershell
param(
    [string]$AlbDnsName,
    [int]$Requests = 10)


Write-Host “Testing Load Balancer on address: http://$AlbDnsName”
Write-Host "-------------------------------- ------------"

for ($i = 1; $i -le $Requests; $i++) {
    Write-Host “Request $i:”
    try {
        $response = Invoke-WebRequest -Uri “http://$AlbDnsName” -UseBasicParsing -TimeoutSec 5
        Write-Host $response.Content
    } catch {
        Write-Host “Error: $($_.Exception.Message)”
    }
    Write-Host “--------------------------------------------”
}
```
Result:
```
Request 1: Hello from AWS Flask app! 🚀 (Instance: ip-10-0-1-172)
Request 2: Hello from AWS Flask app! 🚀 (Instance: ip-10-0-1-79)
Request 3: Hello from AWS Flask app! 🚀 (Instance: ip-10-0-1-172)
```

✅ Traffic is distributed between two instances – round robin is working correctly!