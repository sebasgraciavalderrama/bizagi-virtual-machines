Login-AzureRmAccount

$cred = Get-Credential


#Variables a modificar!!!!!!!!!

#Nombre del curso
$curso = "PruebaIvanMachines"

#Nombre de la imagen
$ResourceGroupImage = "TrainingImages"
$imageName = "MVBizagiTechNET11.1V5.0"

#Número de máquinas a crear
$numMaquinas = 1

#Tamaño de la máquina
$vmSize = "Standard_D2_v2"

#Nombre de la maquina TRAINING para funcionales BIZTRAINING para técnincas
$computerName = "BIZTRAINING"





#De aquí en adelante no deben modificar nada
$location = "WestUS"






for ($i=1; $i -le $numMaquinas; $i++)
{

$rgName = $curso + $i
$vmName = $rgName
#Inicio FOR
				$image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $ResourceGroupImage 
				Write-Host "Image Id" + $image.Id

				New-AzureRmResourceGroup -Name $rgName -Location "WestUS"


				$subnetName = "mySubnet"
				$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
				Write-Host "Subnet Created"

				$vnetName = "myVnet"
				$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location `
					-AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
				Write-Host "Virtual Network created"

				$ipName = "myPip"
				$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location `
					-AllocationMethod Dynamic
				Write-Host "IP address created"
				
				$nicName = "myNic"
				$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location `
					-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
				Write-Host "Network card created"

				$nsgName = "myNsg"
				$ruleName = "myRdpRule"
				$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name $ruleName -Description "Allow RDP" `
					-Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
					-SourceAddressPrefix Internet -SourcePortRange * `
					-DestinationAddressPrefix * -DestinationPortRange 3389

				$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
					-Name $nsgName -SecurityRules $rdpRule
				Write-Host "Network security group created"


				$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
				
				$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
				
				$vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id
				
				$vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType StandardLRS -DiskSizeInGB 128 `
				-CreateOption FromImage -Caching ReadWrite
				
				Write-Host "Disk configuration set"

				$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName `
				-Credential $cred -ProvisionVMAgent 

				$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
				
				New-AzureRmVM -VM $vm -ResourceGroupName $rgName -Location $location
				Write-Host "Virtual machine " + $vm + " created"
				
				
				$rdpFolder='c:\scripts\rdpFolder\'
				$rdpfilePath = $rdpFolder + $vmName + '.rdp'
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $rgName  -Name $vmName -LocalPath $rdpfilePath
				Write-Host "RDP file downloaded"
				Write-Host $rdpfilePath
}