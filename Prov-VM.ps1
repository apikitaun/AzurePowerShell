Import-Module AzureRm
# Nedeed:
# Resource Group
#     |----------- Storage Account
#     |----------- VirtualNetwork

$ResourceGroupName = "DemoAlexResources"
$StorageAccountName = "demoalexstorage"
$VirtualNetworkName = "DemoAlexVirtualNetwork"
$storageURL = "https://demoalexstorage.blob.core.windows.net/vhds/alexdemovhd-"

$localAdminUser = "jorge"
$localAdminSecurePassword = ConvertTo-SecureString "123abc.123abc." -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($localAdminUser, $localAdminSecurePassword)



$sub=Login-AzureRMAccount

Get-AzureRmSubscription -SubscriptionName $sub.SubscriptionName | Select-AzureRmSubscription
$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
$storageAccount = Get-AzureRmStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName
$vnetwork = Get-AzureRmVirtualNetwork -Name $VirtualNetworkName -ResourceGroupNAme $ResourceGroupName
for ($i=1 ; $i -le 1 ; $i++) { 
    $vmName = "alexvmdef"+$i
    $osDiskName = "OS"+$vmName
    $publicIP = "PI"+$vmName
    $IpConfig = "IC"+$vmName
    $networInterface = "NI"+$vmName
    $sub=9+$i
    $ipAddress  = "10.0.1."+$sub
    $vhdname=$storageURL+$i+".vhd"
    Write-Host "======================================================"
    Write-Host "Creating VM:  "$vmName
    Write-Host "======================================================"
    Write-Host " +Creating Public IP"
    $pip = New-AzureRmPublicIpAddress -Name $publicIP -ResourceGroupName $resourceGroup.ResourceGroupName -AllocationMethod Static -Location "westeurope"
    $IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name $IPConfig -PrivateIpAddressVersion IPv4 -PrivateIpAddress $ipAddress -SubnetId $vnetwork.Id
    $sub = New-AzureRMNetworkInterface -Name $networInterface -ResourceGroupName $resourceGroup.ResourceGroupName -Location "westeurope" -SubnetId $vnetwork.Subnets[0].Id -IpConfigurationName $ipConfig.Name -DnsServer "8.8.8.8" -PublicIpAddressId $pip.Id
    $myVm = New-AzureRmVMConfig -VMName $vmName -VMSize "Basic_A0"
    $myVM = Set-AzureRmVMOperatingSystem -VM $myVM -Windows -ComputerName $vmName -ProvisionVMAgent -EnableAutoUpdate -Credential $Credential
    $myVM = Set-AzureRmVMSourceImage -VM $myVM -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
    $myVM = Add-AzureRmVMNetworkInterface -VM $myVM -Id $sub.Id
    # -StorageAccountType Standard
    $myVM = Set-AzureRmVMOSDisk -VM $myVM -Name $osDiskName -DiskSizeInGB 40 -CreateOption FromImage -Caching ReadWrite -VhdUri $vhdname
    Write-Host "   + Creating VM"
    New-AzureRmVM -ResourceGroupName $resourceGroup.ResourceGroupName -Location "westeurope" -VM $myVM -Verbose
}