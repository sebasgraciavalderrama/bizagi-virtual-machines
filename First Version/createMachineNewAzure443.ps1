Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 

$cred = Get-Credential


#Variables a modificar!!!!!!!!!

#Nombre del curso
$curso = "PruebaIvanMachinesLB"

#Nombre del grupo de recursos
$newResourceGroup = "PruebaIvanMachinesRG"

#Nombre de la imagen
$ResourceGroupImage = "TrainingImages"
$imageName = "MVBizagiFunctional11.1V4.0"

#Número de máquinas a crear
$numMaquinas = 1

#Tamaño de la máquina
$vmSize = "Standard_D2_v2"

#De aquí en adelante no deben modificar nada
$location = "WestUS"


New-AzureRmResourceGroup -Name $newResourceGroup -Location "WestUS"
Write-Host "New Resource Group created" + $newResourceGroup


for ($i=1; $i -le $numMaquinas; $i++)
{
#Nombre de la maquina TRAINING para funcionales BIZTRAINING para técnincas
$computerName = "BIZTRAINING" + $i
Write-Host "Computar name" + $computerName

$rgName = $curso + $i
$vmName = $rgName
#Inicio FOR
				$image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $ResourceGroupImage 
				Write-Host "Image Id" + $image.Id
				
				
				#Create the load balancer
				Write-Host "Start Load Balancer creation"
				$backendSubnetName= $computerName + "LoadBalancerSubnet"
				$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix 10.0.2.0/24
				Write-Host "Backend Sub Net " + $backendSubnet+ " created"
				
				$vnetLoadBalancerName= $computerName + "LoadBalancerVnet"
				$vnetLoadBalancer= New-AzureRmVirtualNetwork -Name $vnetLoadBalancerName -ResourceGroupName $newResourceGroup -Location "West US" -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet
				Write-Host "VNet load balancer " + $vnetLoadBalancer+ " created"
				
				$ipName = "PublicIP"
				$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $newResourceGroup -Location $location -AllocationMethod Dynamic
				Write-Host "IP address created"
				
				
				$frontendIPName= $computerName + "LoadBalancerFrontEndIp"
				$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $frontendIPName -PublicIpAddress $pip
				Write-Host "Front End IP " + $frontendIP+ " created"
				
				$backEndLoadBalancerName= $computerName + "LoadBalancerBackEnd"
				$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $backEndLoadBalancerName
				Write-Host "Back End Load Balancer " + $beaddresspool+ " created"
				
				$inboundNATRuleName= $computerName + "inboundNATrule"
				$inboundNATRule= New-AzureRmLoadBalancerInboundNatRuleConfig -Name $inboundNATRuleName -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 443 -BackendPort 3389
				Write-Host "Inbound NAT Rule  " + $inboundNATRule+ " created"
				
				$NRPLBName = $computerName + "LoadBalancer"
				$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $newResourceGroup -Name $NRPLBName -Location "West US" -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule -BackendAddressPool $beAddressPool
				Write-Host "Load Balancer  " + $NRPLB+ " created"
				
				
				
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
				
				$vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType StandardLRS -DiskSizeInGB 128 `
				-CreateOption FromImage -Caching ReadWrite
				
				Write-Host "Disk configuration set"

				$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName `
				-Credential $cred -ProvisionVMAgent 

				#Associate the load balancer to the network interface
				
				$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $backendnic1.Id
				
				New-AzureRmVM -VM $vm -ResourceGroupName $newResourceGroup -Location $location
				Write-Host "Virtual machine " + $vm + " created"
				
				
				
				$rdpFolder='c:\scripts\rdpFolder\'
				$rdpfilePath = $rdpFolder + $vmName + '.rdp'
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $newResourceGroup  -Name $vmName -LocalPath $rdpfilePath
				Write-Host "RDP file downloaded"
				Write-Host $rdpfilePath
}