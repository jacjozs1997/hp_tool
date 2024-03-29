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

    static $KeyboardTypeItems = @(
        $(New-UnitKeyboardTypeOptionItem -DisplayName "New unit search" -KeyboardId 0),
        $(New-UnitKeyboardTypeOptionItem -DisplayName "New unit search" -KeyboardId 0)
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
        if (!($drive -match '[A-Z]')) {
            Write-Error "Bad User Config in efi drive" -ForegroundColor Red
            exit
        }
        if (Test-Path "$($drive):\EFI\Boot\bios.txt" -PathType Leaf) {
            Write-Host "The specified drive could not be found." -ForegroundColor Green
        } else {
            Write-Host "`nThe specified drive could not be found.`n" -ForegroundColor Red
            Write-Host "Select a drive.`n" -ForegroundColor Green
            $drive = "None"
            while ($drive -eq "None") {
                $usbs = Get-Volume | Where-Object -FilterScript {$_.DriveType -Eq "Removable"}
                $Opts = @($(New-UsbDriveOptionItem -DisplayName "Update" -Drive "None"))
                foreach ($usb in $usbs) {
                    $Opts += $(New-UsbDriveOptionItem -DisplayName $usb.FileSystemLabel -Drive $usb.DriveLetter)
                }
                $drive = (Show-Menu -MenuItems $Opts).Drive
                
                Clear-Host
            }
        }
    }

    [String]ToString() {
        $result = '';
        
        $result 


        return $result;
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

class UsbDriveOption {
  
    [String]$DisplayName
    [String]$Drive
  
    [String]ToString() {
        Return $This.DisplayName
    }
}

function New-UsbDriveOptionItem([String]$DisplayName, [String]$Drive) {
    $MenuItem = [UsbDriveOption]::new()
    $MenuItem.DisplayName = $DisplayName
    $MenuItem.Drive = $Drive
    Return $MenuItem
}

class UnitKeyboardTypeOption {
  
    [String]$DisplayName
    [String]$KeyboardId
  
    [String]ToString() {
        Return $This.DisplayName
    }
}

function New-UnitKeyboardTypeOptionItem([String]$DisplayName, [String]$KeyboardId) {
    $MenuItem = [UnitKeyboardTypeOption]::new()
    $MenuItem.DisplayName = $DisplayName
    $MenuItem.KeyboardId = $KeyboardId
    Return $MenuItem
}