


#Variables a modificar!!!!!!!!!

#Nombre del curso
$curso = "PruebaIvanMachines"


#Número de máquinas a crear
$numMaquinas = 2




$scriptBlock = { 
param($ResourceGroupImage,$rgName,$vmName)


Write-Host $ResourceGroupImage
Write-Host $rgName
Write-Host $vmName

Import-AzureRmContext -Path C:\scripts\profile.json

Set-AzureRmContext -SubscriptionId "1fa98db2-7020-4dc3-a098-76bcf63669bb" 


Start-AzureRmVM -ResourceGroupName $rgName -Name $vmName 

$rdpFolder='c:\scripts\rdpFolder\'
$rdpfilePath = $rdpFolder + $vmName + '.rdp'
Get-AzureRmRemoteDesktopFile -ResourceGroupName $rgName  -Name $vmName -LocalPath $rdpfilePath



}

Write-Host "Starting" + $numMaquinas  + "machines..."

for ($i=1; $i -le $numMaquinas; $i++)
{

$rgName = $curso + $i
$vmName = $rgName
#Inicio FOR

Write-Host "Starting machine" + $vmName  

Start-Job -ScriptBlock $scriptBlock -ArgumentList $ResourceGroupImage,$rgName,$vmName
				

				
}

Get-Job | Wait-Job
Write-Host "Machines are started"
Get-Job | Receive-Job