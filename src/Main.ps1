Import-Module '.\src\Modules\PSMenu\0.2.0\PSMenu.psm1'
. .\src\Config\Config.ps1
. .\src\Models\HPUnit.ps1
. .\src\Models\UnitTattoo.ps1
. .\src\Models\ApiRequest.ps1

$Config = [Config]::new()
$Unit = $null
$ApiRequest = [ApiRequest]::new($Config.APIServer)

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
    Write-Host "Product Number`t: $($Unit.ProductNo) [ $($Unit.LanguageCode) ]" -ForegroundColor Cyan
    Write-Host "Product Name`t: $($Unit.UserName)" -ForegroundColor Cyan
    Write-Host "Build Id`t: $($Unit.BuildId)" -ForegroundColor Cyan
    Write-Host "Feature Byte`t: $($Unit.FeatureByte)" -ForegroundColor Cyan
    Write-Host "Bios Version`t: $($Unit.BiosVersion)" -ForegroundColor Cyan
    Write-Host "Image Version`t: $($Unit.ImageVersion)" -ForegroundColor Green
    
    $Unit.UnitConfiguration | Format-Table @{Label="Part Number"; Expression={"|$($_.PartNumber)"}}, @{Label="`Part Serial Number"; Expression={"|$($_.PartSerialNo)"}; Align='Center'}, @{Label="Component Name"; Expression={"|$($_.PartDescription)"}}
    
    switch ((Show-Menu -MenuItems (Invoke-Expression [UnitTattoo]::MenuItems)).MenuId)
    {
        0 { 
            Clear-Host;
            break 
        }
        1 { Write-Host "It is two." }
    }
}