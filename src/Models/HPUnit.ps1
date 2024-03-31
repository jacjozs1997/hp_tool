class HPUnit {
    [string] $SerialNo = $null
    [string] $ProductNo = $null
    [string] $UserName = $null
    [UnitPart[]] $UnitConfiguration = @()

    [string] $BuildId = $null
    [string] $FeatureByte = $null
    [string] $BiosVersion = $null
    [string] $ImageVersion = $null
    [string] $LanguageCode = $null
    #TODO 
    static [hashtable] $LanguageCodes = @{
        "ALI" = "Albanian"
        "CLB" = "Arabic"
        "AGB" = "Austrian/ German"
        "AGI" = "Austrian/German (MNCS)"
        "BLI" = "Belgian MNCS"
        "BRB" = "Brazilian Portuguese"
        "BGB" = "Bulgarian"
        "CAB" = "Canadian French"
        "CAI" = "Canadian French MNCS"
        "CYB" = "Cyrillic"
        "CSB" = "Czech"
        "DMB" = "Danish"
        "DMI" = "Danish MNCS"
        "FNB" = "Finnish/Swedish"
        "FNI" = "Finnish/Swedish MNCS"
        "FAB" = "French (Azerty)"
        "FAI" = "French (Azerty) MNCS"
        "FQB" = "French (Qwerty)"
        "FQI" = "French (Qwerty) MNCS"
        "GNB" = "Greek (See note 2.)"
        "NCB" = "Hebrew"
        "HNB" = "Hungarian"
        "ICB" = "Icelandic"
        "ICI" = "Icelandic MNCS"
        "INB" = "International"
        "IRB" = "Farsi (Iran)"
        "ITB" = "Italian"
        "ITI" = "Italian MNCS"
        "JEB" = "Japanese-English"
        "JEI" = "Japanese- English MNCS"
        "JKB" = "Japanese Kanji and Katakana"
        "JUB" = "Japanese Kanji and US English"
        "KAB" = "Japanese Katakana"
        "JPB" = "Japanese Latin Extended"
        "KOB" = "Korean"
        "ROB" = "Latin 2"
        "MKB" = "Macedonian"
        "NEB" = "Dutch (Netherlands)"
        "NEI" = "Dutch (Netherlands) MNCS"
        "NWB" = "Norwegian"
        "NWI" = "Norwegian MNCS"
        "PLB" = "Polish"
        "PRB" = "Portuguese"
        "PRI" = "Portuguese MNCS"
        "RMB" = "Romanian"
        "RUB" = "Russian"
        "SQB" = "Serbian, Cyrillic"
        "YGI" = "Serbian, Latin"
        "RCB" = "Simplified Chinese"
        "SKB" = "Slovakian"
        "SPB" = "Spanish"
        "SPI" = "Spanish MNCS"
        "SSB" = "Spanish Speaking"
        "SSI" = "Spanish Speaking MNCS"
        "SWB" = "Swedish"
        "SWI" = "Swedish MNCS"
        "SFI" = "French (Switzerland) MNCS"
        "SGI" = "German (Switzerland) MNCS"
        "THB" = "Thai"
        "TAB" = "Traditional Chinese"
        "TKB" = "Turkish (Qwerty)"
        "TRB" = "Turkish (F)"
        "UKB" = "English (United Kingdom)"
        "UKI" = "English (United Kingdom) MNCS"
        "USB" = "English (United States and Canada)"
        "USI" = "English (United States and Canada) MNCS"
    }

    HPUnit($rawUnitData) {
        $this.SerialNo = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.serial_no
        $this.ProductNo = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.product_no
        $this.UserName = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.user_name

        if ($this.ProductNo.Contains('#')) {
            $array = $this.ProductNo.Split('#')
            $this.ProductNo = $array[0];
            $this.LanguageCode = $array[1];
        }

        foreach ($unit_part in $rawUnitData.Body.SerialNumberBOM.unit_configuration)
        {
            $newUnitPart = [UnitPart]::new($unit_part)

            if ($($newUnitPart.PartNumber) -eq "IMG_BUILDID") {
                $this.BuildId = $newUnitPart.PartDescription -Replace 'BID=', '';
                $this.LanguageCode = $this.BuildId -Replace '.*(.{3})', '$1';
                continue;
            }
            if ($($newUnitPart.PartNumber) -eq "BIOS_VERSION") {
                $this.BiosVersion = $newUnitPart.PartSerialNo;
                continue;
            }
            if ($($newUnitPart.PartDescription) -match "DPK, WIN") {
                $this.ImageVersion = $newUnitPart.PartSerialNo;
                continue;
            }
            if ($($newUnitPart.PartNumber).Contains("IMG_DESC")) {
                $this.FeatureByte += $($newUnitPart.PartDescription) -Replace ' ', '';
                continue;
            }

            if ($($newUnitPart.PartDescription) -eq "-N/A-" -Or $($newUnitPart.PartDescription) -eq "0" -Or $($newUnitPart.PartDescription) -eq "FEATUREBYTE") {
                continue;
            }
            $this.UnitConfiguration += $newUnitPart
        }
    }
}

class UnitPart {
    [string] $ParentPartNumber = $null
    [string] $PartNumber = $null
    [string] $PartDescription = $null
    [string] $PartSerialNo = $null
    [string] $PartQuantity = $null
    [string] $UC_RohsStatusCode = $null

    UnitPart($rawUnitPartData) {
        $this.ParentPartNumber = $rawUnitPartData.parent_part_number
        $this.PartNumber = $rawUnitPartData.part_number
        $this.PartDescription = $rawUnitPartData.part_description
        $this.PartSerialNo = $rawUnitPartData.part_serialno
        $this.PartQuantity = $rawUnitPartData.part_quantity
        $this.UC_rohsStatusCode = $rawUnitPartData.uc_rohs_status_code
    }
    [String]ToString() {
        Return $this.PartDescription
    }
}


function ValidateSerialNumber {
    param (
        [string] $InputSerialNumber
    )

    $InputSerialNumber = $InputSerialNumber -Replace '[áöé \-_.]', ''

    if ($InputProductNumber.Length -ne 10) { return $false; }
    return $true;
}

function ValidateProductNumber {
    param (
        [string] $InputProductNumber,
        [bool] $WithLang
    )
    $InputProductNumber = $InputProductNumber -Replace '[áöé \-_.]', ''

    if ($WithLang) {
        if ($InputProductNumber.Length -ne 11) { return $false; }
        if (!$InputProductNumber.Contains('#')) { return $false; }
    } else {
        if ($InputProductNumber.Length -ne 7) { return $false; }
    }
    return $true;
}