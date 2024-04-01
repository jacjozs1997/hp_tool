
. .\src\Common.ps1
. .\src\Models\HPUnit.ps1
class UnitTattoo {
    [string] $SerialNumber = $null
    [string] $ProductNumber = $null
    [string] $ProductName = $null
    [string] $BuildId = $null
    [string] $FeatureByte = $null
    [string] $KeyboardId = $null
    [string] $SystemFamily = "HP"

    [hashtable]$AnalizeTattooProps = @{
        "Serial Number" = $([TattooProperty]::new("Serial Number", 'None'))
        "Feature Byte" = $([TattooProperty]::new("Feature Byte", 'None'))
        "SKU Number" = $([TattooProperty]::new("SKU Number", 'None'))
        "Product Number" = $([TattooProperty]::new("Product Number", 'None'))
        "Build ID" = $([TattooProperty]::new("Build ID", 'None'))
        "Product Name" = $([TattooProperty]::new("Product Name", 'None'))
        "System Family" = $([TattooProperty]::new("System Family", 'None'))
        "Keyboard Type" = $([TattooProperty]::new("Keyboard Type", 'None'))
    }

    static [string] $EfiPath = "\EFI\Boot"
    static [string] $EfiFile = "bios.txt"

    static $MenuItems = @(
        $([UnitTattooOption]::new("New unit search", 0)),
        $([UnitTattooOption]::new("Write to file", 1))
    )

    static $DefaultKeyboardTypeItems = @(
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
        $this.AnalizeTattooFile($drive);
        $this.GetTattooText() | Out-File -FilePath "$($drive):$([UnitTattoo]::EfiPath)\$([UnitTattoo]::EfiFile)"
        
        Write-Host "Create file: $($drive):$([UnitTattoo]::EfiPath)\$([UnitTattoo]::EfiFile)";
    }

    [void]AnalizeTattooFile([string]$drive) {
        [TattooProperty] $prop = $null;
        foreach ($line in Get-Content "$($drive):$([UnitTattoo]::EfiPath)\$([UnitTattoo]::EfiFile)") {

            if ($line.Contains("`t")) {
                if ($prop) {
                    [string]$option = $line.Replace("`t", "")
                    if ($option.StartsWith('*')) {
                        $option = $option.Substring(1)
                    }
                    if ($prop.OptionalValues.Count -eq 0) {
                        if ($prop.Value -ne "None") {
                            $prop.OptionalValues += $prop.Value
                            $prop.OptionalValues += $option
                        } else {
                            $prop.Value = $option;
                        }
                    } else {
                        $prop.OptionalValues += $option
                    }
                }
            } elseif ($this.AnalizeTattooProps.Contains($line)) {
                $prop = $this.AnalizeTattooProps[$line]
            } else {
                continue
            }
        }
        $props = $this.AnalizeTattooProps.Values
        foreach ($tattooProp in $this.AnalizeTattooProps.Values) {
            if ($tattooProp.Value -eq "None") {
                continue
            }
            switch ($tattooProp.Name) {
                "Serial Number" { 
                    $tattooProp.Value = $this.SerialNumber;
                    break;
                }
                "Feature Byte" { 
                    $tattooProp.Value = $this.FeatureByte;
                    break;
                }
                "SKU Number" { 
                    $tattooProp.Value = $this.ProductNumber;
                    break;
                }
                "Product Number" { 
                    $tattooProp.Value = $this.ProductNumber;
                    break;
                }
                "Build ID" { 
                    $tattooProp.Value = $this.BuildId;
                    break;
                }
                "Product Name" { 
                    $tattooProp.Value = $this.ProductName;
                    break;
                }
                "System Family" { 
                    $tattooProp.Value = $this.SystemFamily;
                    break;
                }
                "Keyboard Type" { 
                    $tattooProp.Value = $this.SelectKeyboardType($tattooProp.OptionalValues);
                    break;
                }
            }
        }
    }

    [string]SelectKeyboardType([array] $types) {
        Write-Host "Select keyboard type:";
        $Ops = @();
        foreach ($type in $types) {
            $Ops += [UnitKeyboardTypeOption]::new($type, 0)
        }
        if ($Ops.Count -gt 0) {
            return (Show-Menu -MenuItems $Ops).DisplayName
        } else {
            return '{0:d2}' -f [int]$((Show-Menu -MenuItems (Invoke-Expression [UnitTattoo]::DefaultKeyboardTypeItems)).KeyboardId)
        }
    }

    [string]GetTattooText() {
        $result = '';
        
        foreach ($prop in $this.AnalizeTattooProps.Values) {
            if ($prop.Value -ne "None") {
                $result += "$($prop.Name)`r`n";
                if ($prop.OptionalValues.Count -gt 0) {
                    foreach ($option in $prop.OptionalValues) {
                        if ($option -eq $prop.Value) {
                            $result += "`t*$option`r`n";
                        } else {
                            $result += "`t$option`r`n";
                        }
                    }
                } else {
                    $result += "`t$($prop.Value)`r`n";
                }
            }
        }
        return $result.Substring(0, $result.Length-2)
    }
}

class TattooProperty {
    [String]$Name
    [String]$Value
    [Array]$OptionalValues

    TattooProperty([string]$Name, [string]$Value) {
        $this.Name = $Name;
        $this.Value = $Value;
        $this.OptionalValues = @();
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
    [int]$KeyboardId

    UnitKeyboardTypeOption([string]$DisplayName, [int]$KeyboardId) {
        $this.DisplayName = $DisplayName;
        $this.KeyboardId = $KeyboardId;
    }
  
    [String]ToString() {
        Return $This.DisplayName
    }
}