. .\src\Models\HPUnit.ps1
class UnitTattoo {
    [string] $SerialNumber = $null    # DONE 1
    [string] $ProductNumber = $null   # DONE 3
    [string] $ProductName = $null     # DONE 5
    [string] $BuildId = $null         # DONE 4
    [string] $FeatureByte = $null     # DONE 2
    [string] $SystemFamily = "HP"     # !

    static $MenuItems = @(
        $(New-UnitTattooOptionItem -DisplayName "New unit search" -MenuId 0),
        $(New-UnitTattooOptionItem -DisplayName "Write to file" -MenuId 1)
    )

    UnitTattoo([PSCustomObject] $unit) {
        try {
            $this.SerialNumber = $unit.SerialNo
            $this.ProductNumber = "$($unit.ProductNo)#$($unit.LanguageCode)"
            $this.ProductName = $unit.UserName
            $this.BuildId = $unit.BuildId
            $this.FeatureByte = $unit.FeatureByte
        }
        catch {
            Write-Host $_
        }
    }
    [void]WriteToFile([string]$drive) {
        if (Test-Path "$($drive):\EFI\Boot\bios.txt" -PathType Leaf) {

        } else {
            #TODO Message
        }
    }
}

class UnitTattooOption {
  
    [String]$DisplayName
    [String]$MenuId
  
    [String]ToString() {
        Return $This.DisplayName
    }
}

function New-UnitTattooOptionItem([String]$DisplayName, [String]$MenuId) {
    $MenuItem = [UnitTattooOption]::new()
    $MenuItem.DisplayName = $DisplayName
    $MenuItem.MenuId = $MenuId
    Return $MenuItem
}