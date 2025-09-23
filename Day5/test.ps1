param (
    [Parameter(Mandatory = $true)]
    [string]$AlbDnsName
)

$albUrl = "http://$AlbDnsName"

Write-Host "Testing Load Balancer on address: $albUrl"
Write-Host "--------------------------------------------"

for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request ${i}:"
    try {
        $response = Invoke-WebRequest -Uri $albUrl -UseBasicParsing
        Write-Host $response.Content
    }
    catch {
        Write-Host "Error: $_"
    }
    Write-Host "--------------------------------------------"
    Start-Sleep -Seconds 1
}
