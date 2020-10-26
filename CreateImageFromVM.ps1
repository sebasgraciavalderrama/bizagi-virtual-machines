Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 

#Variables a cambiar----------!!!!!!!!!!!!!!

#Nombre de la máquina
$vmName = "TRAINING"

#Nombre del resource group donde se encuentra la máquina
$rgName = "MachinetoGetImage"

#Nombre de la nueva imágen
$imageName = "MVBizagiTechNET11.1V9.0"



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