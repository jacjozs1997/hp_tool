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