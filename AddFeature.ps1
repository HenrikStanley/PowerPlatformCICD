
$Text = "Power Platform DevOps"
$UniqueId = "PPDevOps"

function InstallXrmModule{
    $moduleName = "Microsoft.Xrm.Data.Powershell"
    $moduleVersion = "2.8.5"
    $module = Get-Module -ListAvailable -Name $moduleName
    if (!($module.Version -ge $moduleVersion )) {
        Write-host "Module $moduleName version $moduleVersion or higher not found, installing now"
        Install-Module -Name $moduleName -MinimumVersion $moduleVersion -Force -Scope CurrentUser
    }
    else
    {
        Write-host "Module $moduleName Found"
    }
}

Function InstallToastModule{
    $moduleName = "BurntToast"
    if (!(Get-Module -ListAvailable -Name $moduleName )) {
        Write-host "Module $moduleName Not found, installing now"
        Install-Module -Name $moduleName -Force -Scope CurrentUser
    }
    else
    {
        Write-host "Module $moduleName Found"
    }
}


function Add-Feature
{

$message = "Connecting to Power Platform"
Write-Host $message
$ProgressBar = New-BTProgressBar -Status $message -Value 0.10
New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId

$quit = Read-Host -Prompt "Press Enter to Connect to your CDS / D365 Tenant or [Q]uit"
if ($quit -eq "Q")
{
    exit
}

if (!$Credentials)
{
	Do {
	$Credentials = Get-Credential
    } Until (($Credentials.GetNetworkCredential().UserName -ne "") -and ($Credentials.GetNetworkCredential().Password -ne "")) 
}
if (!$username)
{
$username =  $Credentials.GetNetworkCredential().UserName
$password =  $Credentials.GetNetworkCredential().Password
}

        InstallXrmModule

    $message = "Connecting to Development Environment"
    Write-Host $message
    $ProgressBar = New-BTProgressBar -Status $message -Value 0.20
    New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId

    Write-Host ""
    Write-Host "---- Please Select your Development Environment ------"
    Do {
    $conn = Connect-CrmOnlineDiscovery -Credential $Credentials
    If (!$conn.IsReady)
        {
            Do {
	         $Credentials = Get-Credential
            } Until (($Credentials.GetNetworkCredential().UserName -ne "") -and ($Credentials.GetNetworkCredential().Password -ne "")) 
            if (!$username)
            {
                $username =  $Credentials.GetNetworkCredential().UserName
                $password =  $Credentials.GetNetworkCredential().Password
            }
        }
	} Until ($conn.IsReady) 

    $CreateOrSelect = Read-Host -Prompt "Development Environment : Would you like to [C]reate a New Solution or [S]elect an Existing One (Default [S])"
if ($CreateOrSelect -eq "C"){

    $message = "Creating Solution and Publisher"
    Write-Host $message
    $ProgressBar = New-BTProgressBar -Status $message -Value 0.25
    New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId

    $PublisherName = Read-Host -Prompt "Enter a Name for your Solution Publisher"
    $PublisherPrefix = Read-Host -Prompt "Enter a Publisher Prefix"

    $PublisherId = New-CrmRecord -EntityLogicalName publisher -Fields @{"uniquename"=$PublisherName.Replace(' ','').ToLower();"friendlyname"=$PublisherName;"customizationprefix"=$PublisherPrefix.Replace(' ','').ToLower()}

    $SolutionName = Read-Host -Prompt "Enter a Name for your Unmanaged Development Solution"
    $PubLookup = New-CrmEntityReference -EntityLogicalName publisher -Id $PublisherId.Guid
    $SolutionId = New-CrmRecord -EntityLogicalName solution -Fields @{"uniquename"=$SolutionName.Replace(' ','').ToLower();"friendlyname"=$SolutionName;"version"="1.0.0.0";"publisherid"=$PubLookup}
    $chosenSolution = $SolutionName.Replace(' ','').ToLower()
    }
    else{

    $solutionFetch = @"
    <fetch>
    <entity name='solution' >
        <filter type='and' >
        <condition attribute='ismanaged' operator='eq' value='0' />
        <condition attribute='isvisible' operator='eq' value='1' />
        </filter>
    </entity>
    </fetch>
"@

    $solutions = (Get-CrmRecordsByFetch -conn $conn -Fetch $solutionFetch).CrmRecords

    $choiceIndex = 0
    $options = $solutions | ForEach-Object { write-host "[$($choiceIndex)] $($_.uniquename)"; $choiceIndex++; }  


    $success = $false
    do {
        $choice = read-host "Enter your selection"
        if (!$choice) {
            Write-Host "Invalid selection (null)"
        }
        else {
            $choice = $choice -as [int];
            if ($choice -eq $null) {
                Write-Host "Invalid selection (not number)"
            }
            elseif ($choice -le -1) {
                Write-Host "Invalid selection (negative)"
            }
            else {
                $chosenSolution = $solutions[$choice].uniquename
                if ($null -ne $chosenSolution) {
                    $PublisherPrefix = (Get-CrmRecord -conn $conn -EntityLogicalName publisher -Id $solutions[$choice].publisherid_Property.Value.Id -Fields customizationprefix).customizationprefix
                    $success = $true
                }
                else {
                    Write-Host "Invalid selection (index out of range)"
                }
            } 
        }
    } while (!$success)
}

#update values in Solution files 
$TextInfo = (Get-Culture).TextInfo

$chosenSolution = $TextInfo.ToTitleCase($chosenSolution.ToLower())
$message = "Adding Feature to Git Repo locally"
Write-Host $message
Write-Host "If prompted for credentials, enter the same credentials you used for dev.azure.com"
$ProgressBar = New-BTProgressBar -Status $message -Value 0.30
New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId

git clone https://github.com/dylanhaskins/FeatureTemplate.git $chosenSolution
Remove-Item $chosenSolution\.git -Recurse -Force

$message = "Setting Configurations in Source Code"
Write-Host $message
$ProgressBar = New-BTProgressBar -Status $message -Value 0.40
New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId

Write-Host "Updating config.json ..."
(Get-Content -Path .\$chosenSolution\Scripts\config.json) -replace "https://AddServer.crm6.dynamics.com",$conn.ConnectedOrgPublishedEndpoints["WebApplication"] | Set-Content -Path .\$chosenSolution\Scripts\config.json
(Get-Content -Path .\$chosenSolution\Scripts\config.json) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\Scripts\config.json

Write-Host "Updating spkl.json ..."
(Get-Content -Path .\$chosenSolution\spkl.json) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\spkl.json
(Get-Content -Path .\$chosenSolution\spkl.json) -replace "prefix",$PublisherPrefix.Replace(' ','').ToLower() | Set-Content -Path .\$chosenSolution\spkl.json

Write-Host "Updating ImportConfig.xml ..."
Move-Item .\$chosenSolution\Deployment\FeatureTemplate .\$chosenSolution\Deployment\$chosenSolution
Move-Item .\$chosenSolution\Deployment\FeatureTemplate.cs .\$chosenSolution\Deployment\$chosenSolution.cs
(Get-Content -Path .\$chosenSolution\Deployment\$chosenSolution\ImportConfig.xml) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\Deployment\$chosenSolution\ImportConfig.xml
(Get-Content -Path .\$chosenSolution\Deployment\$chosenSolution.cs) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\Deployment\$chosenSolution.cs

Write-Host "Updating XrmContext.exe.config ..."
(Get-Content -Path .\$chosenSolution\XrmContext\XrmContext.exe.config) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\XrmContext\XrmContext.exe.config

Write-Host "Updating XrmDefinitelyTyped.exe.config ..."
(Get-Content -Path .\$chosenSolution\XrmDefinitelyTyped\XrmDefinitelyTyped.exe.config) -replace "AddName",$chosenSolution | Set-Content -Path .\$chosenSolution\XrmDefinitelyTyped\XrmDefinitelyTyped.exe.config

Write-Host "Rename FeatureTemplate.csproj to $chosenSolution.csproj"
Rename-Item -Path .\$chosenSolution\FeatureTemplate.csproj -NewName "$chosenSolution.csproj"

Write-Host "Rename FeatureTemplate.snk to $chosenSolution.snk"
Rename-Item -Path .\$chosenSolution\FeatureTemplate.snk -NewName "$chosenSolution.snk"

Write-Host "Updating $chosenSolution.csproj ..."
(Get-Content -Path .\$chosenSolution\$chosenSolution.csproj) -replace "FeatureTemplate",$chosenSolution | Set-Content -Path .\$chosenSolution\$chosenSolution.csproj

chdir $chosenSolution
Write-Host "Installing Node module dependencies ..."
npm install

Write-Host "Adding $chosenSolution Project to Solution"
chdir ..
$sln = ls *.sln
dotnet sln $sln.Name add $chosenSolution\$chosenSolution.csproj

#commit repo and update VariableGroup in DevOps

git add -A
git commit -m "Added Feature $chosenSolution"

$message = "Complete ... Enjoy !!!"
Write-Host $message
$ProgressBar = New-BTProgressBar -Status $message -Value 1
New-BurntToastNotification -Text $Text -ProgressBar $ProgressBar -Silent -UniqueIdentifier $UniqueId
}

$message = @"
____                          ____  _       _    __                        ____              ___            
|  _ \ _____      _____ _ __  |  _ \| | __ _| |_ / _| ___  _ __ _ __ ___   |  _ \  _____   __/ _ \ _ __  ___ 
| |_) / _ \ \ /\ / / _ \ '__| | |_) | |/ _` | __| |_ / _ \| '__| '_ ` _ \  | | | |/ _ \ \ / / | | | '_ \/ __|
|  __/ (_) \ V  V /  __/ |    |  __/| | (_| | |_|  _| (_) | |  | | | | | | | |_| |  __/\ V /| |_| | |_) \__ \
|_|   \___/ \_/\_/ \___|_|    |_|   |_|\__,_|\__|_|  \___/|_|  |_| |_| |_| |____/ \___| \_/  \___/| .__/|___/
                                                                                                  |_|        



Welcome to the Power Platform DevOps Feature Add script. This script will perform the following steps automatically :

 
"@

Write-Host $message

$quit = Read-Host -Prompt "Press Enter to Continue or [Q]uit"
if ($quit -eq "Q")
{
    exit
}
    
Write-Host("Performing Checks....")
InstallToastModule
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Add-Feature