
. .\src\Common.ps1
. .\src\Models\HPUnit.ps1
class UnitTattoo {
    [string] $SerialNumber = $null    # DONE 1
    [string] $ProductNumber = $null   # DONE 3
    [string] $ProductName = $null     # DONE 5
    [string] $BuildId = $null         # DONE 4
    [string] $FeatureByte = $null     # DONE 2
    [string] $KeyboardId = $null     # DONE 2
    [string] $SystemFamily = "HP"     # !

    static [string] $EfiPath = "\EFI\Boot"
    static [string] $EfiFile = "bios.txt"

    static $MenuItems = @(
        $([UnitTattooOption]::new("New unit search", 0)),
        $([UnitTattooOption]::new("Write to file", 1))
    )

    static $KeyboardTypeItems = @(
        $([UnitKeyboardTypeOption]::new("Type 1", 00)),
        $([UnitKeyboardTypeOption]::new("Type 2", 01))
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
        if (!(Test-Path -Path "$($drive):\")) {
            Write-Host "`nThe specified drive could not be found.`n" -ForegroundColor Red

            try {
                $drive = "None"
                while ($drive -eq "None") {
                    Start-Job -Name HP_SelectDrive -ScriptBlock {
                        Write-Host "Select a drive.`n" -ForegroundColor Green
                        try {
                            $result = Get-Volume | Where-Object -FilterScript {$_.DriveType -Eq "Removable"}
                        }
                        catch {
                            $result = $_
                        }
                        return $result;
                    } | Receive-Job
                    
                    Progress -Title "Searching drives..." -JobName HP_SelectDrive
                
                    $usbs = Receive-Job -Id (Get-Job -Name HP_SelectDrive).Id
                    $Opts = @($([UsbDriveOption]::new("Update", "None")))
                    foreach ($usb in $usbs) {
                        $Opts += $([UsbDriveOption]::new("$($usb.DriveLetter):$($usb.FileSystemLabel)", $usb.DriveLetter))
                    }
                    $drive = (Show-Menu -MenuItems $Opts).Drive
                    
                    Clear-Host
                }
            }
            catch {
                $drive = $_
            }
        }
        
        Write-Host "Selected drive: $($drive):\";

        if (!(Test-Path -Path "$($drive):$([UnitTattoo]::EfiPath)")) {
            New-Item -ItemType "directory" -Path "$($drive):$([UnitTattoo]::EfiPath)"
            Write-Host "Create folder: $($drive):$([UnitTattoo]::EfiPath)";
        }
        # TODO Condition
        $this.KeyboardId = $this.SelectKeyboardType();
        $this.GetTattooText() | Out-File -FilePath "$($drive):$([UnitTattoo]::EfiPath)\$([UnitTattoo]::EfiFile)"
        
        Write-Host "Create file: $($drive):$([UnitTattoo]::EfiPath)\$([UnitTattoo]::EfiFile)";
    }

    [string]SelectKeyboardType() {
        Write-Host "Select keyboard type:";
        return (Show-Menu -MenuItems (Invoke-Expression [UnitTattoo]::KeyboardTypeItems)).KeyboardId
    }

    [string]GetTattooText() {
        $result = '';
        
        $result 


        return $result;
    }
}

class UnitTattooOption {
  
    [String]$DisplayName
    [String]$MenuId

    UnitTattooOption([string]$DisplayName, [string]$MenuId) {
        $this.DisplayName = $DisplayName;
        $this.MenuId = $MenuId;
    }
  
    [String]ToString() {
        Return $This.DisplayName
    }
}

class UsbDriveOption {
          
    [String]$DisplayName
    [String]$Drive

    UsbDriveOption([string]$DisplayName, [string]$Drive) {
        $this.DisplayName = $DisplayName;
        $this.Drive = $Drive;
    }
  
    [String]ToString() {
        Return $This.DisplayName
    }
}

class UnitKeyboardTypeOption {
  
    [String]$DisplayName
    [String]$KeyboardId

    UnitKeyboardTypeOption([string]$DisplayName, [string]$KeyboardId) {
        $this.DisplayName = $DisplayName;
        $this.KeyboardId = $KeyboardId;
    }
  
    [String]ToString() {
        Return $This.DisplayName
    }
}