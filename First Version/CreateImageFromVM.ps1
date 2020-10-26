

#Variables a cambiar----------!!!!!!!!!!!!!!

#Nombre de la máquina
$vmName = "myVM"

#Nombre del resource group donde se encuentra la máquina
$rgName = "MachineVHD"

#Nombre de la nueva imágen
$imageName = "MVBizagiTechNET11.1V3.0"



#De aqui en adelante no se debe modificar nada del código

$location = "WestUS"

Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force
Write-Host "Stopping machine" + $vmName

Set-AzureRmVm -ResourceGroupName $rgName -Name $vmName -Generalized
Write-Host "Set as Generalized" + $vmName

$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName
Write-Host "getting virtual machine"


$image = New-AzureRmImageConfig -Location $location -SourceVirtualMachineId $vm.ID 
Write-Host "Setting new image configuration"

New-AzureRmImage -Image $image -ImageName $imageName -ResourceGroupName "TrainingImages"
Write-Host "New image creted"