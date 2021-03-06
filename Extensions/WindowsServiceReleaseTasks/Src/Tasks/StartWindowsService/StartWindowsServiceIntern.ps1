function StartStopServices(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic")] $startupType,
	[int][Parameter(Mandatory=$true)] $waitTimeoutInSeconds,
	[string][Parameter(Mandatory=$true)] $killIfTimedOut
)
{
	[string[]] $servicesNamesArray = ($serviceNames -split ',' -replace '"').Trim()

	[bool] $atLeastOneServiceWasNotFound = $false
	$presentServicesArray = $null
	$servicesNamesArray | ForEach-Object {
		$serviceName = $_
		$matchingServices = [PSCustomObject[]] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)

		if ($matchingServices -eq $null)
		{
			Write-Error "No services match the name: $serviceName"
			$atLeastOneServiceWasNotFound = $true
		}
		else
		{
			$presentServicesArray += $matchingServices
		}
	}

	if ($atLeastOneServiceWasNotFound)
	{
		return -1;
	}

	Write-Verbose ("The following services were found: {0}" -f ($presentServicesArray -join ','))

	$presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType }
	$presentServicesArray | Where-Object { $_.Status -ne "Running" } | % { $_.Start() }
	$presentServicesArray | % { $_.WaitForStatus("Running", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }
}