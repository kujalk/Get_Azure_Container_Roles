<#
Purpose - To collect all the Role permission assigned for the blob containers
Date - 20/6/2021
Developer - K.Janarthanan
#>

try 
{
    Write-Host "Started the script`n" -ForegroundColor Green

    #Importing required modules
    Import-Module -Name Az.Accounts -ErrorAction Stop
    Import-Module -Name Az.Resources -ErrorAction Stop
    Import-Module -Name Az.Storage -ErrorAction Stop

    #Connecting to Azure
    Connect-AzAccount

    $All_Objects = @() #Array to strore all objects
    $All_Subscriptions = Get-AzSubscription -EA Stop #Get all subscription

    #Loop all subscriptions
    foreach($Sub in $All_Subscriptions)
    {
        Write-Host "Working on Subscription - $($Sub.Name)" -ForegroundColor Magenta
        #Select the subscription
        Select-AzSubscription -SubscriptionName $Sub.Name -EA Stop | Out-Null

        #Get all Storage account
        $All_Storage = Get-AzStorageAccount -EA Stop

        #Check any storage account exists
        if($All_Storage.Count -gt 0)
        {
            #Loop all storage account
            foreach($SA in $All_Storage)
            {
                #Create a context based on Stroage account
                $Context = (Get-AzStorageAccount -AccountName $SA.StorageAccountName -ResourceGroupName $SA.ResourceGroupName -EA Stop).context
                
                #Get the list of Containers
                $Containers = Get-AzStorageContainer -Context $Context -EA Stop

                #Check any containers exists
                if($Containers.Count -gt 0)
                {
                    #Loop all containers
                    foreach($Container in $Containers)
                    {

                        Write-Host "`nWorking on Container $($Container.Name) in Storage Account $($SA.StorageAccountName)" -ForegroundColor Green

                        #Get all Azure Roles for container
                        $ID = "/subscriptions/$($Sub.ID)/resourceGroups/$($SA.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($SA.StorageAccountName)/blobServices/default/containers/$($Container.Name)"
                        $AllRoles = Get-AzRoleAssignment -Scope $ID

                        #Check any Azure blob file exists
                        if($AllRoles.Count -gt 0)
                        {
                            #Loop all Azure blob files
                            foreach($Role in $AllRoles)
                            {
                                #Create a Custom PowerShell object and store the items
                                Write-Host "Object ID - $($Role.ObjectID) with Role $($Role.RoleDefinitionName) " -ForegroundColor Green

                                $File_Object = New-Object psobject
                                $File_Object | Add-Member -membertype noteproperty -name Subscription -value $Sub.Name
                                $File_Object | Add-Member -membertype noteproperty -name ResourceGroup -value $SA.ResourceGroupName
                                $File_Object | Add-Member -membertype noteproperty -name StorageAccount -value $SA.StorageAccountName
                                $File_Object | Add-Member -membertype noteproperty -name Region -value $SA.PrimaryLocation
                                $File_Object | Add-Member -membertype noteproperty -name Container -value $Container.Name
                                $File_Object | Add-Member -membertype noteproperty -name DisplayName -value $Role.DisplayName
                                $File_Object | Add-Member -membertype noteproperty -name ObjectID -value $Role.ObjectId
                                $File_Object | Add-Member -membertype noteproperty -name RoleDefinitionName -value $Role.RoleDefinitionName

                                #Put all the Powershell object into array
                                $All_Objects += $File_Object
                            }
                        }
                        #No any Azure blobs found
                        else 
                        {
                            Write-Host "No any roles found in the container $($Container.Name) inside the storage account $($SA.StorageAccountName) in resource group $($SA.ResourceGroupName)" -ForegroundColor Yellow  
                        }
                    }
                }
                #No any Containers found
                else 
                {
                    Write-Host "No any Storage container found inside the storage account $($SA.StorageAccountName) in resource group $($SA.ResourceGroupName)" -ForegroundColor Yellow  
                }              
            }      
        }
        #No any Storage account found
        else 
        {
            Write-Host "Subscription $($Sub.Name) does not have Storage Account" -ForegroundColor Yellow 
        }
    }

    #If Array conists more than 1 item then create a CSV
    if($All_Objects.Count -gt 0)
    {
        $All_Objects | Export-Csv -NoTypeInformation -Path "All_Roles.csv"
        Write-Host "`nCreated the CSV"
    }
}
catch 
{
    Write-Host "Error - $_" -ForegroundColor Red
}