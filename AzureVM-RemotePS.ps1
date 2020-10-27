#requires -version 4


# Script to use Powershell remoting to Azure VM using certificate authentication
# Sam Boutros - 15 February, 2016 - v1.0
# See https://superwidgets.wordpress.com/2016/02/15/managing-azure-vms-using-powershell-from-your-local-desktop/ for more information


#region Input

$SubscriptionName = 'Sam Test 1'                        # Your Azure subscription name
$VMName           = 'Vertitech1SQL1'                    # The name of the VM to send PS commands to
$AdminName        = 'MyAdminName'                       # The VM local admin name
$PwdFile          = "d:\Sandbox\$VMName-$AdminName.txt" # Local path tp save encrypted VM admin pwd

#endregion


#region Initial VM connectivity

try { 
    Select-AzureSubscription -SubscriptionName $SubscriptionName -ErrorAction Stop 
} catch { 
    throw "unable to select Azure subscription '$SubscriptionName', check correct spelling.. " 
}
try { 
    $ServiceName = (Get-AzureVM -ErrorAction Stop | where { $_.Name -eq $VMName }).ServiceName 
} catch { 
    throw "unable to get Azure VM '$VMName', check correct spelling, or run Add-AzureAccount to enter Azure credentials.. " 
}
$objVM  = Get-AzureVM -Name $VMName -ServiceName $ServiceName
$VMFQDN = (Get-AzureWinRMUri -ServiceName $ServiceName).Host
$Port   = (Get-AzureWinRMUri -ServiceName $ServiceName).Port
    
# Get certificate for Powershell remoting to the Azure VM if not installed already
if ((Get-ChildItem -Path Cert:\LocalMachine\Root).Subject -notcontains "CN=$VMFQDN") {
    Write-Verbose "Adding certificate 'CN=$VMFQDN' to 'LocalMachine\Root' certificate store.." 
    $Thumbprint = (Get-AzureVM -ServiceName $ServiceName -Name $VMName | 
        select -ExpandProperty VM).DefaultWinRMCertificateThumbprint
    $Temp = [IO.Path]::GetTempFileName()
    (Get-AzureCertificate -ServiceName $ServiceName -Thumbprint $Thumbprint -ThumbprintAlgorithm sha1).Data | Out-File $Temp
    $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $Temp
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($Cert)
    $store.Close()
    Remove-Item $Temp -Force -Confirm:$false
}

#endregion


#region Open PS remote session

# Attempt to open Powershell session to Azure VM
Write-Verbose "Opening PS session with computer '$VMName'.." 
if (-not (Test-Path -Path $PwdFile)) { 
        Write-Verbose "Pwd file '$PwdFile' not found, prompting to pwd.."
        Read-Host "Enter the pwd for '$AdminName' on '$VMFQDN'" -AsSecureString | 
            ConvertFrom-SecureString | Out-File $PwdFile 
    }
$Pwd = Get-Content $PwdFile | ConvertTo-SecureString 
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminName, $Pwd

try { 
    $Session = New-PSSession -ComputerName $VMFQDN -Port $Port -UseSSL -Credential $Cred -ErrorAction Stop
    $Session
} catch {
    throw "Unable to establish PS remote session with '$VMName'.."
}

#endregion


#region Payload

<#
Here you issue the commands to the remote Azure VM, which is the purpose of the earlier parts of this script.

Example 1:
##########

Invoke-Command -Session $Session -ScriptBlock { Get-Process }

# This will run the cmdlet Get-Process on the remote Azure VM


Example 2:
##########

$Result = Invoke-Command -Session $Session -ScriptBlock { Get-Process }

# In this example, the serialized object(s) returned from the Get-Process cmdlet are saved in the $Result variable


Example 3:
##########

$Counter = '\Memory\Available MBytes'
Invoke-Command -Session $Session -ScriptBlock { (Get-Counter -Counter $Using:Counter).CounterSamples } 

# This is an example of passing variables from the current script to the remote script block


Example 4:
##########

$Counter = '\Processor(*)\% Processor Time'
$ScriptBlock = { 
    (Get-Counter -Counter $Using:Counter).CounterSamples | where { $_.InstanceName -eq '_total' }
}
$Result = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
"Processor time (all cores): $('{0:N1}' -f $Result.CookedValue)%"

# This example demonstrates passing a variable to the remote script block, receiving results back, and processing result.

#>

#endregion