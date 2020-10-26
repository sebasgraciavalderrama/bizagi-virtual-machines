Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 

#Variables a cambiar----------!!!!!!!!!!!!!!

#Nombre de la m�quina
$vmName = "TRAINING"

#Nombre del resource group donde se encuentra la m�quina
$rgName = "MachinetoGetImage"

#Nombre de la nueva im�gen
$imageName = "MVBizagiTechNET11.1V9.0"



#De aqui en adelante no se debe modificar nada del c�digo

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