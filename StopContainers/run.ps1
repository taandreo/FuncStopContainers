# Input bindings are passed in via param block.
param($Timer)

# # Get the current universal time in the default string format.
# $currentUTCtime = (Get-Date).ToUniversalTime()

# # The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
# if ($Timer.IsPastDue) {
#     Write-Host "PowerShell timer is running late!"
# }

# # Write an information log with the current time.
# Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$time = Get-Date
$time = $time.AddMinutes(- $MINUTES)

function Main(){
    Write-Host "Getting Container instances information ..."
    $conts = Get-AzContainerGroup
    if ($conts){
        foreach($cont in $conts){
            Write-Host "Getting state for $($cont.name) from resoruce group $($cont.ResourceGroupName) ... " -NoNewline
            Get-ContainerStatus -ResourcegroupName $cont.ResourceGroupName -Name $cont.Name
        }
    } else {
        Write-Host "Containers not Founded."
    }
}
function Get-ContainerStatus($ResourcegroupName, $Name){
    $contWithState = Get-AzContainerGroup -Name $Name -ResourceGroupName $ResourcegroupName
    $resourceId = $contWithState.Id
    if ($contWithState.State -eq "Running"){
        Write-Host "$Name ($ResourceGroupName): Running"
        $logs = Get-AzLog -ResourceId $resourceId -StartTime $time
        $start_action = "Microsoft.ContainerInstance/containerGroups/start/action"
        Write-Host "$Name ($ResourceGroupName): Checking if the container needs to be stoppped ..."               
        if (-Not ($start_action -in $logs.Authorization.Action)){
            Write-Host "$Name ($ResourceGroupName): Stopping Container ..."
            $response = Stop-Container -rgName $ResourcegroupName -containerName $Name
            if ($response.StatusCode -eq "204"){
                Write-Host "OK Command sent."
            } else {
                Write-Host "`nError: $response.StatusDescription"
            }
        } else {
            Write-Host "$Name ($ResourceGroupName): Active less than $minutes minutes."
        }
    } else {
        Write-Host "$Name ($ResourceGroupName): Not running"
    }
}

# Stops the container with api call
function Stop-Container($rgName, $containerName){
    # Log in first with Connect-AzAccount if not using Cloud Shell
    $azContext = Get-AzContext
    $subscriptionId = $azContext.Subscription.Id
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }
    # Invoke the REST API
    $restUri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.ContainerInstance/containerGroups/$($containerName)/stop?api-version=2019-12-01"
    $response = Invoke-WebRequest -Uri $restUri -Method Post -Headers $authHeader
    return $response
}

Main