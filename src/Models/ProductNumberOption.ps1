class ProductNumberOption {
  
    [String]$DisplayName
    [String]$ProductId
  
    [String]ToString() {
        Return $This.DisplayName
    }
  }
function New-ProductNumberOptionItem([String]$DisplayName, [String]$ProductId) {
    $MenuItem = [ProductNumberOption]::new()
    $MenuItem.DisplayName = $DisplayName
    $MenuItem.ProductId = $ProductId
    Return $MenuItem
}