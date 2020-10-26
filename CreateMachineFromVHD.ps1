
Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 

#Variables a cambiar----------!!!!!!!!!!!!!!

#Nombre de la máquina BIZTRAINING para técnicas y TRAINING para funcionales
$vmName = "TRAINING"
#URI del disco VHD
$osDiskUri = "https://bizagiimagesrepository.blob.core.windows.net/images111/MVTechnical111-21112017.vhd"
#Nombre del disco
$osDiskName = "MVTechnical111-21112017.vhd"



#De aqui en adelante no se debe modificar nada del código


Select-AzureSubscription -Current -SubscriptionName "Bizagi Training Subscription 1"
$rgName = "MachinetoGetImage"
New-AzureRmResourceGroup -Name $rgName -Location "WestUS"
Write-Host "Resource group created"

$subnetName = "mySubNet"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
Write-Host "sub net created"


$location = "WestUS"
Write-Host "location" + $location 
$vnetName = "myVnetName"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location `
    -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
Write-Host "Virtual network created" 


$ipName = "myIP"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location `
    -AllocationMethod Dynamic
Write-Host "Public IP created" 


$nicName = "myNicName"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName `
-Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
Write-Host "Interface created"

$nsgName = "myNsg"
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name myRdpRule -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
    -Name $nsgName -SecurityRules $rdpRule
Write-Host "security rule created" 

$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_D2_v2"
Write-Host "Virtual machine= " + $vmName

$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id
Write-Host "Add network interface"


$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Windows


Write-Host "OS disk set"
Write-Host "URI=" + $osDiskUri
Write-Host "Disk name=" + $osDiskName 
Write-Host "Resource group=" + $rgName

Set-AzureRmVMBootDiagnostics -VM $vm -Disable

$vm = New-AzureRmVM -VM $vm -Location WestUS -ResourceGroupName $rgName 


Write-Host "Machine Created"