﻿function InstallXrmDataModule{
    $moduleName = "Microsoft.Xrm.Data.Powershell"
    $moduleVersion = "2.8.8"
    $module = Get-Module -ListAvailable -Name $moduleName
    if (!($module.Version -ge $moduleVersion )) {
        Write-host "Module $moduleName version $moduleVersion or higher not found, installing now"
        Install-Module -Name $moduleName -RequiredVersion $moduleVersion -Force -Scope CurrentUser
    }
    else
    {
    Write-host "Module $moduleName version $moduleVersion or higher Found"
    }
    }
    
    function InstallDevOpsDataModule{
    $moduleName = "Microsoft.Xrm.DevOps.Data.Powershell"
    $moduleVersion = "1.3.0"
    $module = Get-Module -ListAvailable -Name $moduleName
    if (!($module.Version -ge $moduleVersion )) {
        Write-host "Module $moduleName version $moduleVersion or higher not found, installing now"
        Install-Module -Name $moduleName -MinimumVersion $moduleVersion -Force -Scope CurrentUser
    }
    else
    {
    Write-host "Module $moduleName version $moduleVersion or higher Found"
    }
    }
    
    function InstallCoreTools{
    $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $targetNugetExe = ".\nuget.exe"
    Remove-Item .\Tools -Force -Recurse -ErrorAction Ignore
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
    Set-Alias nuget $targetNugetExe -Scope Global 
    
    ##
    ##Download CoreTools
    ##
    ./nuget install Microsoft.CrmSdk.CoreTools -O .\Tools
    $coreToolsFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.CoreTools.'}
    Move-Item .\Tools\$coreToolsFolder\content\bin\coretools\*.* .\Tools\ -Force -ErrorAction SilentlyContinue
    Remove-Item .\Tools\$coreToolsFolder -Force -Recurse
    }
    
    function InstallXrmDeployModule {
    $moduleName = "Microsoft.Xrm.Tooling.PackageDeployment.Powershell"
    $moduleVersion = "3.3.0.891"
    $module = Get-Module -ListAvailable -Name $moduleName
    if (!($module.Version -ge $moduleVersion )) {
        Write-host "Module $moduleName version $moduleVersion or higher not found, installing now"
        Install-Module -Name $moduleName -RequiredVersion $moduleVersion -Force -Scope CurrentUser
    }
    else
    {
    Write-host "Module $moduleName version $moduleVersion or higher Found"
    }
    }
    
    function InstallXrmConnectModule {
        $moduleName = "Microsoft.Xrm.Tooling.CrmConnector.PowerShell"
        $moduleVersion = "3.3.0.891"
        $module = Get-Module -ListAvailable -Name $moduleName
        if (!($module.Version -ge $moduleVersion )) {
            Write-host "Module $moduleName version $moduleVersion or higher not found, installing now"
            Install-Module -Name $moduleName -RequiredVersion $moduleVersion -Force -Scope CurrentUser
        }
        else
        {
        Write-host "Module $moduleName version $moduleVersion or higher Found"
        }
        }
    
    function InstallPowerAppsCheckerModule{
    $moduleName = "Microsoft.PowerApps.Checker.PowerShell"
    if (!(Get-Module -ListAvailable -Name $moduleName )) {
    Write-host "Module $moduleName Not found, installing now"
    Install-Module -Name $moduleName -Force -Scope CurrentUser
    }
    else
    {
    Write-host "Module $moduleName Found"
    }
    }
    
    $ProgressPreference = 'SilentlyContinue'
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    
    
    