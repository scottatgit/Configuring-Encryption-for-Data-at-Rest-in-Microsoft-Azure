#Log into Azure
Add-AzAccount

#Select the correct subscription
Get-AzSubscription -SubscriptionName "SUB_NAME" | Select-AzSubscription

#Set some basic variables
$prefix = "ced"
$Location = "eastus"
$ResourceGroupName = "$prefix-recovery-vault"
$id = Get-Random -Minimum 1000 -Maximum 9999

#Create the necessary resource groups
$rvRG = New-AzResourceGroup -Name $ResourceGroupName -Location $Location

$RecoveryVaultParameters = @{
    Name = "$prefix-vault-$id"
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}

$rv = New-AzRecoveryServicesVault @RecoveryVaultParameters

#Grant Recovery Vault access to Key Vault
$VaultName = "KEY_VAULT_NAME"
$VaultResourceGroup = "KEY_VAULT_RESOURCE_GROUP"

$VaultPolicyParameters = @{
    VaultName = $VaultName
    ResourceGroupName = $VaultResourceGroup
    PermissionsToKeys = @("backup","get","list")
    PermissionsToSecrets = @("backup","get","list")
    ServicePrincipalName = "262044b1-e2ce-469f-a196-69ab7ada62d3"
}

Set-AzKeyVaultAccessPolicy @VaultPolicyParameters

#Configure Backup of Windows VM
$pol = Get-AzRecoveryServicesBackupProtectionPolicy -WorkloadType "AzureVM" -VaultId $rv.ID
$VMName = "WIN_VM_NAME"
$VMResourceGroup = "VM_RESOURCE_GROUP"
Enable-AzRecoveryServicesBackupProtection -Policy $pol -Name $VMName -ResourceGroupName $VMResourceGroup

$container = Get-AzRecoveryServicesBackupContainer -VaultId $rv.id -ContainerType AzureVM -FriendlyName $VMName
$item = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType "AzureVM"
$endDate = (Get-Date).AddDays(60).ToUniversalTime()
$job = Backup-AzRecoveryServicesBackupItem -Item $item -VaultId $rv.ID -ExpiryDateTimeUTC $endDate

Wait-AzRecoveryServicesBackupJob -Job $job -Timeout 43200