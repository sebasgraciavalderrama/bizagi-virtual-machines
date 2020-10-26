
 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass




#Variables a modificar!!!!!!!!!

#Nombre del curso
$curso = "BizagiRPA_VM"
#Número de máquinas a crear
$numMaquinas = 1



#Nombre de la imagen  ----Consultar Excel con lista de imagenes
$imageName = "MVBizagiRPA11.2.3.2045V2.0"
#Tamaño de la máquina  ----Consultar Excel con lista de imagenes
#$vmSize = "Standard_B1s"
#$vmSize = "Standard_D2_V2"
$vmSize = "Standard_D2_V3"

#Nombre de la maquina TRAINING para funcionales BIZTRAINING para técnincas   ----Consultar Excel con lista de imagenes
#$computerName = "TRAINING"
$computerName = "BIZTRAINING"




#De aquí en adelante no deben modificar nada

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

#Nombre del grupo de recursos
$newResourceGroup = $rgName

$image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $ResourceGroupImage 
Write-Host "Image Id" + $image.Id

New-AzureRmResourceGroup -Name $newResourceGroup -Location "WestUS"
Write-Host "New Resource Group created" + $newResourceGroup

#Create the load balancer
Write-Host "Start Load Balancer creation"
$backendSubnetName= $computerName + "LoadBalancerSubnet"
$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix 10.0.2.0/24
Write-Host "Backend Sub Net " $backendSubnetName " created"

$vnetLoadBalancerName= $computerName + "LoadBalancerVnet"
$vnetLoadBalancer= New-AzureRmVirtualNetwork -Name $vnetLoadBalancerName -ResourceGroupName $newResourceGroup -Location "West US" -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet
Write-Host "VNet load balancer " $vnetLoadBalancerName " created"

$ipName = "PublicIP"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $newResourceGroup -Location $location -AllocationMethod Static
Write-Host "IP address created"


$frontendIPName= $computerName + "LoadBalancerFrontEndIp"
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $frontendIPName -PublicIpAddress $pip
Write-Host "Front End IP " $frontendIPName " created"

$backEndLoadBalancerName= $computerName + "LoadBalancerBackEnd"
$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $backEndLoadBalancerName
Write-Host "Back End Load Balancer " $backEndLoadBalancerName " created"

$inboundNATRuleName= $computerName + "inboundNATrule"
$inboundNATRule= New-AzureRmLoadBalancerInboundNatRuleConfig -Name $inboundNATRuleName -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 443 -BackendPort 3389
Write-Host "Inbound NAT Rule  " $inboundNATRuleName " created"

$NRPLBName = $computerName + "LoadBalancer"
$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $newResourceGroup -Name $NRPLBName -Location "West US" -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule -BackendAddressPool $beAddressPool
Write-Host "Load Balancer  " $NRPLBName " created"



#Create the virtual network using the load balancer
Write-Host "Creating IP config from network interface"
$VN = Get-AzureRmVirtualNetwork -Name $vnetLoadBalancerName -ResourceGroupName $newResourceGroup
$SubNetLB = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VN
$IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig1" -Subnet $SubNetLB -PrivateIpAddress "10.0.2.6" -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $nrplb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrplb.InboundNatRules[0]
Write-Host "Creating network interface"
$backendnic1= New-AzureRmNetworkInterface -Name "NetworkInterface1" -ResourceGroupName $newResourceGroup -Location "West US" -IpConfiguration $IPconfig
#$backendnic2= New-AzureRmNetworkInterface -ResourceGroupName $newResourceGroup -Name lb-nic2-be -Location "West US" -PrivateIpAddress 10.0.2.7 -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrplb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrplb.InboundNatRules[1]

$nsgName = "myNsg"
$ruleName = "myRdpRule"
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name $ruleName -Description "Allow RDP" `
	-Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
	-SourceAddressPrefix Internet -SourcePortRange * `
	-DestinationAddressPrefix * -DestinationPortRange 3389

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $newResourceGroup -Location $location `
	-Name $nsgName -SecurityRules $rdpRule
Write-Host "Network security group created"




Write-Host "Associate the security group to the network interface"
$backendnic1.NetworkSecurityGroup = $nsg
Set-AzureRmNetworkInterface -NetworkInterface $backendnic1
Write-Host "Associate the security group to the network interface done"

#Create the machine 
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType Standard_LRS -DiskSizeInGB 128 `
-CreateOption FromImage -Caching ReadWrite

Write-Host "Disk configuration set"

$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName `
-Credential $cred -ProvisionVMAgent 

#Associate the load balancer to the network interface

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $backendnic1.Id

Set-AzureRmVMBootDiagnostics -VM $vm -Disable

New-AzureRmVM -VM $vm -ResourceGroupName $newResourceGroup -Location $location -LicenseType "Windows_Server"
Write-Host "Virtual machine " + $vm + " created"



$rdpFolder='c:\scripts\rdpFolder\'
$rdpfilePath = $rdpFolder + $vmName + '.rdp'
Get-AzureRmRemoteDesktopFile -ResourceGroupName $newResourceGroup  -Name $vmName -LocalPath $rdpfilePath
Write-Host "RDP file downloaded"
Write-Host $rdpfilePath

}



for ($i=1; $i -le $numMaquinas; $i++)
{
		#Nombre de la maquina TRAINING para funcionales BIZTRAINING para técnincas
		Write-Host "Computar name" + $computerName

		$rgName = $curso + $i
		$vmName = $rgName
		#Inicio FOR
		
		Start-Job -ScriptBlock $scriptBlock -ArgumentList $location,$imageName,$ResourceGroupImage,$rgName,$vmName,$vmSize,$computerName,$cred
				

				
}

Get-Job | Wait-Job
Write-Host "Machines are ready"
Get-Job | Receive-Job
				
