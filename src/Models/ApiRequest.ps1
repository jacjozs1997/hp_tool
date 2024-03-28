. .\src\Common.ps1
. .\src\Models\ProductNumberOption.ps1
class ApiRequest {
    [string] $ApiServer
    [string] $SerialNumber
    [string] $ProductNumber

    hidden static [hashtable] $RequestHeader = @{
      "Accept" = "application/json, text/plain, */*"
      "Accept-Encoding" = "gzip, deflate, br"
      "Accept-Language" = "en-US,en;q=0.9"
      "Authorization" = "Basic MjAyMzEzNy1wYXJ0c3VyZmVyOlBTVVJGQCNQUk9E"
      "Host"="pro-psurf-app.glb.inc.hp.com"
      "Origin"="https://partsurfer.hp.com"
      "Referer"="https://partsurfer.hp.com/"
      "sec-ch-ua"='"Google Chrome";v="117", "Not;A=Brand";v="8", "Chromium";v="117"'
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"='"Windows"'
      "Sec-Fetch-Dest"="empty"
      "Sec-Fetch-Mode"="cors"
      "Sec-Fetch-Site"="same-site"
      "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
  }

    ApiRequest([string] $ApiServer) { 
      $this.ApiServer = $ApiServer
    }

    [Object] QueryGet([string] $SerialNumber) { 
      $this.SerialNumber = $SerialNumber
      # Primary Request
      Start-Job -Name PrimaryHPRequest -ScriptBlock { 
        param(
            $ApiServer,
            $SerialNumber,
            $Header)
        try {
            $result = (Invoke-WebRequest -Uri "$ApiServer/partsurferapi/SerialNumber/GetSerialNumber/$SerialNumber/country/US/usertype/EXT" -Method Get -Headers $Header).Content | ConvertFrom-Json   
        }
        catch {
            $result = $_
        }
        return $result;
      } -ArgumentList $this.ApiServer,$this.SerialNumber,(Invoke-Expression [ApiRequest]::RequestHeader) | Receive-Job
      
      Progress -Title "Searching..." -JobName PrimaryHPRequest

      $result = Receive-Job -Id (Get-Job -Name PrimaryHPRequest).Id

      if ($result.Body.SNRProductLists.Length -ne 0) {
        Write-Host "Multiple Products associated for above Serial Number."
        Write-Host "Please Select a Product Number."
        $Opts = @()
        foreach ($product in $result.Body.SNRProductLists) {
            $Opts += $(New-ProductNumberOptionItem -DisplayName $product.product_Desc -ProductId $product.product_Id)
        }
        $this.ProductNumber = (Show-Menu -MenuItems $Opts).ProductId
        if ($this.ProductNumber.Contains('#')) {
          $this.ProductNumber = $this.ProductNumber.Split('#')[0];
        }
      }

      # Secondary Request
      if ($this.ProductNumber -And $this.ProductNumber -ne "") {
        Start-Job -Name SecondaryHpRequest -ScriptBlock { 
            param(
                $ApiServer,
                $SerialNumber,
                $ProductNumber,
                $Header)
            try {
                $result = (Invoke-WebRequest -Uri $ApiServer/partsurferapi/SerialNumber/GetSerialNumber/$SerialNumber/ProductNumber/$ProductNumber/country/US/usertype/EXT -Method Get -Headers $Header).Content | ConvertFrom-Json
            }
            catch {
                $result = $_
            }
            return $result;
          } -ArgumentList $this.ApiServer,$this.SerialNumber,$this.ProductNumber,(Invoke-Expression [ApiRequest]::RequestHeader) | Receive-Job
        
          Progress -Title "Gathering data..." -JobName SecondaryHpRequest
        
        try {
            $result = Receive-Job -Id (get-job -name SecondaryHpRequest).Id
            if (($result.Body.SerialNumberBOM.unit_configuration.part_description).Length -eq 0) {
                return $null;
            }
        }
        catch {
            return $null;
        }
      }
      return $result
    }
  }