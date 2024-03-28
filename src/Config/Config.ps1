class Config {
    [string] $Efi_Drive
    [bool] $WriteToEfiBoot
    [bool] $ImageEnabled
    [string] $APIServer

    Config() {
        try {
            $userConfig = (Get-Content -Path ".\config.json" -Raw | ConvertFrom-Json)

            $this.Efi_Drive = $userConfig.Efi_Drive
            $this.WriteToEfiBoot = $userConfig.WriteToEfiBoot
            $this.ImageEnabled = $userConfig.ImageEnabled
            $this.APIServer = $userConfig.APIServer
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
    }
}