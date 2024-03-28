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

    HPUnit($rawUnitData) {
        $this.SerialNo = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.serial_no
        $this.ProductNo = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.product_no
        $this.UserName = $rawUnitData.Body.SerialNumberBOM.wwsnrsinput.user_name

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