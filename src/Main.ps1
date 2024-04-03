Import-Module '.\src\Modules\PSMenu\0.2.0\PSMenu.psm1'
. .\src\Config\Config.ps1
. .\src\Models\HPUnit.ps1
. .\src\Models\UnitTattoo.ps1
. .\src\Models\ApiRequest.ps1

[Config] $Config = [Config]::new()
$Unit = $null
[ApiRequest] $ApiRequest = [ApiRequest]::new($Config.APIServer)
$ImageIp = '10.222.245.225'
$ImageDrive = 'Z'
$ImagesPath = 'images'
#TODO Test
if ($Config.ImageEnabled) {
    if (!(Test-Path -Path "$($ImageDrive):\")) {
        Start-Job -Name ConImageServer -ScriptBlock { 
            param(
                $ImageDrive,
                $ImageIp,
                $ImagesPath)
            try {
                #$Password="rs" | ConvertTo-SecureString -AsPlainText -Force
                #$Credential = New-Object System.Management.Automation.PsCredential('readshare', $Password)
                #New-PSDrive -Name $ImageDrive -Root "\\$ImageIp\$ImagesPath" -Credential $Credential -PSProvider filesystem
                #net use z: \\10.222.245.225\images /u:readshare rs
                #New-SmbMapping -LocalPath "$($ImageDrive):" -RemotePath "\\$ImageIp\$ImagesPath" -UserName 'readshare' -Password 'rs'
            }
            catch {
                Write-Host "Connection fails" -ForegroundColor Red
            }
        } -ArgumentList $ImageDrive,$ImageIp,$ImagesPath | Receive-Job

        Progress -Title "Connecting image server..." -JobName ConImageServer
    }
}

function Tattoo {
    param (
        [Parameter(Mandatory)]
        $Drive,
        [Parameter(Mandatory)]
        $Unit
    )
    Clear-Host;
    $Tattoo = [UnitTattoo]::new($Unit)
    $Tattoo.WriteToFile($Drive)
    Pause
    Clear-Host;
}

while ($true) {
    Write-Host "----------------`t-----------------------------------------"
    $readSerialNumber = Read-Host "SERIAL NUMBER`t"
    while (ValidateSerialNumber -InputSerialNumber $readSerialNumber) {
        $readSerialNumber = Read-Host "SERIAL NUMBER`t"
    }
    $rawUnit = $ApiRequest.QueryGet($readSerialNumber)
    if (!$rawUnit) {
        #TODO Message
        continue
    }
    $Unit = [HPUnit]::new($rawUnit)

    Write-Host "Serial Number`t: $($Unit.SerialNo)" -ForegroundColor Cyan
    Write-Host "Product Number`t: $($Unit.ProductNo) " -ForegroundColor Cyan -NoNewline
    Write-Host "[$($Unit.LanguageCode)]" -ForegroundColor Green
    Write-Host "Product Name`t: $($Unit.UserName)" -ForegroundColor Cyan
    if ($Unit.BuildId -ne "") {
        Write-Host "Build Id`t: $($Unit.BuildId)" -ForegroundColor Cyan
    }
    if ($Unit.FeatureByte -ne "") {
        Write-Host "Feature Byte`t: $($Unit.FeatureByte)" -ForegroundColor Cyan
    }
    if ($Unit.BiosVersion -ne "") {
        Write-Host "Bios Version`t: $($Unit.BiosVersion)" -ForegroundColor Cyan
    }

    if ($Unit.ImageVersion -ne '') {
        Write-Host "Image Version`t: $($Unit.ImageVersion)" -ForegroundColor Green
        if ($Config.ImageEnabled) {
            if (Test-Path -Path "$($drive):\") {
                if (Test-Path -Path "$($ImageDrive):$($ImagesPath)\$($Unit.ProductNo)#$($Unit.LanguageCode).rdr") {
                    Write-Host "Image exists" -ForegroundColor Blue
                } else {
                    Write-Host "Image not exists" -ForegroundColor Red
                }
            } else {
                Write-Host "Image server not available" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Image Version`t: FreeDos" -ForegroundColor Red
    }
    
    $Unit.UnitConfiguration | Format-Table @{Label="Part Number"; Expression={"|$($_.PartNumber)"}; Width=15}, @{Label="Part Serial Number"; Expression={"|$($_.PartSerialNo)"}; Width=25}, @{Label="Component Name"; Expression={"|$($_.PartDescription)"}}, @{Label="Quantity"; Expression={"$($_.PartQuantity)"}; Align="Center"}
    if ($Config.OnlyWriteToEfiBoot) {
        Tattoo -Drive $Config.Efi_Drive -Unit $Unit
    } else {
        switch ((Show-Menu -MenuItems (Invoke-Expression [UnitTattoo]::MenuItems)).MenuId)
        {
            0 { 
                Clear-Host;
                break 
            }
            1 { 
                Tattoo -Drive $Config.Efi_Drive -Unit $Unit
            }
        }
    }
}