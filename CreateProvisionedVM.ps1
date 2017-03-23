$resourceGroupName = "xxxMyRG" 
$location = "West Europe" 
$capturedImageStorageAccount = "xxxstorage1"
$capturedImageUri ="https://devdisks242.blob.core.windows.net/system/Microsoft.Compute/Images/tecnocomcursost/imgmv-osDisk.10f625b3-a635-4b87-be00-dc4b6e11fd7c.vhd"
$catpuredImageStorageAccountResourceGroup = "xxxMYRG" 
New-AzureRmResourceGroup -Name $resourceGroupName -Location  $location
$srcKey = Get-AzureRmStorageAccountKey -StorageAccountName $capturedImageStorageAccount -ResourceGroupName $catpuredImageStorageAccountResourceGroup
$srcContext = New-AzureStorageContext -StorageAccountName $capturedImageStorageAccount -StorageAccountKey $srcKey.Value[0]



$publicIp = New-AzureRmPublicIpAddress -Name "xxxMyPublicIp1" ` -ResourceGroupName $resourceGroupName ` -Location $location -AllocationMethod Dynamic 
$subnetConfiguration = New-AzureRmVirtualNetworkSubnetConfig -Name "xxxMySubnet1" ` -AddressPrefix "10.0.0.0/24" 
$virtualNetworkConfiguration = New-AzureRmVirtualNetwork -Name "xxxMyVNET1"  -ResourceGroupName $resourceGroupName  -Location $location  -AddressPrefix "10.0.0.0/16" ` -Subnet $subnetConfiguration 
$nic = New-AzureRmNetworkInterface -Name "xxxMyServerNIC01"  -ResourceGroupName $resourceGroupName  -Location $location  -SubnetId $virtualNetworkConfiguration.Subnets[0].Id  -PublicIpAddressId $publicIp.Id

# Get the storage account for the captured VM image 
$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name "xxxStorage1" -Location $location -Type Standard_LRS 
# Copy the captured image from the source storage account to the destination storage account 
$destImageName = $capturedImageUri.Substring($capturedImageUri.LastIndexOf('/') + 1) 
New-AzureStorageContainer -Name "images" -Context $storageAccount.Context[0] 
Start-AzureStorageBlobCopy -AbsoluteUri $capturedImageUri -DestContainer "images" -DestBlob $destImageName -DestContext $storageAccount.Context -Context $srcContext -Verbose -Debug 
Get-AzureStorageBlobCopyState -Context $storageAccount.Context -Container "images" -Blob $destImageName -WaitForComplete 

# Build the URI for the image in the new storage account 
$imageUri = '{0}images/{1}' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $destImageName 

# Set the VM configuration details 
$vmConfig = New-AzureRmVMConfig -VMName "xxxvm2" -VMSize "Standard_D1" 
#Create credential using: $adminCredential = Get-Credential
# Set the operating system details 
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmConfig.Name -Credential $adminCredential -TimeZone "Eastern Standard Time" -ProvisionVMAgent -EnableAutoUpdate 

# Set the NIC 

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id 
# Create the OS disk URI 
$osDiskUri = '{0}vhds/{1}_{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vm.Name.ToLower(), ($vm.Name + "_OSDisk") 

# Configure the OS disk to use the previously saved image 
$vm = Set-AzureRmVMOSDisk -vm $vm -Name $vm.Name -VhdUri $osDiskUri -CreateOption FromImage -SourceImageUri $imageUri -Windows 

# Create the VM 
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm
