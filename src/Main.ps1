Import-Module 'PSMenu\0.2.0\PSMenu.psm1'
. .\src\Config\Config.ps1
. .\src\Models\HPUnit.ps1
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
    if ($rawUnit) {
        $Unit = [HPUnit]::new($rawUnit)

        Write-Host "Serial Number`t: $($Unit.SerialNo)" -ForegroundColor Cyan
        Write-Host "Product Number`t: $($Unit.ProductNo) [ $($Unit.LanguageCode) ]" -ForegroundColor Cyan
        Write-Host "Product Name`t: $($Unit.UserName)" -ForegroundColor Cyan
        Write-Host "Build Id`t: $($Unit.BuildId)" -ForegroundColor Cyan
        Write-Host "Feature Byte`t: $($Unit.FeatureByte)" -ForegroundColor Cyan
        Write-Host "Bios Version`t: $($Unit.BiosVersion)" -ForegroundColor Cyan
        Write-Host "Image Version`t: $($Unit.ImageVersion)" -ForegroundColor Green
    } else {
        #TODO Error message
    }
}