 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


#Variables a modificar!!!!!!!!!

#Nombre del curso


$curso = "SG_WSTest_MV_"
#N�mero de m�quinas a crear
$numMaquinas = 1


#Nombre de la imagen   ----Consultar Excel con lista de imagenes
$imageName = "MVBizagiFunctional11.2.4.0268V2"
#Tama�o de la m�quina  ----Consultar Excel con lista de imagenes
$vmSize = "Standard_D2_V2"
#$vmSize = "Standard_D2_V3"
#Nombre de la maquina TRAINING para funcionales BIZTRAINING para t�cnincas   ----Consultar Excel con lista de imagenes
$computerName = "TRAINING"
#$computerName = "BIZTRAINING"





#De aqu� en adelante no deben modificar nada

#Variables fijas
$location = "WestUS"
$ResourceGroupImage = "TrainingImages"


$cred = Get-Credential


$scriptBlock = { 
param($location,$imageName,$ResourceGroupImage,$rgName,$vmName,$vmSize,$computerName,$cred)

Write-Host $location
Write-Host $imageName
Write-Host $ResourceGroupImage
Write-Host $rgName
Write-Host $vmName

Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 

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
	-AllocationMethod Static
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

$vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType Standard_LRS -DiskSizeInGB 128 `
-CreateOption FromImage -Caching ReadWrite

Write-Host "Disk configuration set"

$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName `
-Credential $cred -ProvisionVMAgent 

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

Set-AzureRmVMBootDiagnostics -VM $vm -Disable

New-AzureRmVM -VM $vm -ResourceGroupName $rgName -Location $location -LicenseType "Windows_Server"
Write-Host "Virtual machine " + $vm + " created"


$rdpFolder='c:\scripts\rdpFolder\'
$rdpfilePath = $rdpFolder + $vmName + '.rdp'
Get-AzureRmRemoteDesktopFile -ResourceGroupName $rgName  -Name $vmName -LocalPath $rdpfilePath
Write-Host "RDP file downloaded"
Write-Host $rdpfilePath


}

Write-Host "Creating" + $numMaquinas  + "machines..."

for ($i=1; $i -le $numMaquinas; $i++)
{

$rgName = $curso + $i
$vmName = $rgName
#Inicio FOR

Write-Host "Creating machine" + $vmName  

Start-Job -ScriptBlock $scriptBlock -ArgumentList $location,$imageName,$ResourceGroupImage,$rgName,$vmName,$vmSize,$computerName,$cred
				

				
}

Get-Job | Wait-Job
Write-Host "Machines are ready"
Get-Job | Receive-Job