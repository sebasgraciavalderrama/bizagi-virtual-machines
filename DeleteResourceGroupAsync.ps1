


#Variables a modificar!!!!!!!!!

#Nombre del curso
$curso = "SG_WSTest_MV_"

#N�mero de grupos a borrar
$numMaquinas = 1





$scriptBlock = { 
param($ResourceGroupImage,$rgName,$vmName,$computerName)


Write-Host $ResourceGroupImage
Write-Host "Resource group to delete" $rgName
Write-Host $vmName

Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 


Get-AzureRmResourceGroup -Name $rgName | Remove-AzureRmResourceGroup -Verbose -Force


}

Write-Host "Deleting" + $numMaquinas  + "machines..."

for ($i=1; $i -le $numMaquinas; $i++)
{

$rgName = $curso + $i
$vmName = $rgName
#Inicio FOR

Write-Host "Deleting resource group" + $vmName  

Start-Job -ScriptBlock $scriptBlock -ArgumentList $ResourceGroupImage,$rgName,$vmName,$computerName
				

				
}

Get-Job | Wait-Job
Write-Host "Resource groups are deleted"
Get-Job | Receive-Job