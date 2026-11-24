param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$iconProject=Split-Path (Split-Path $PSScriptRoot)
$iconDirectory=Join-Path $iconProject 'art/branding'
New-Item -ItemType Directory -Force -Path $iconDirectory | Out-Null
Copy-Item -LiteralPath $Source -Destination (Join-Path $iconDirectory 'mountain-gate-original.png') -Force
$iconImage=[Drawing.Image]::FromFile($Source)
function New-IconBitmap([int]$Pixels){
 $bitmap=[Drawing.Bitmap]::new($Pixels,$Pixels,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $graphics=[Drawing.Graphics]::FromImage($bitmap)
 $graphics.Clear([Drawing.Color]::Transparent)
 $graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality
 $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 $graphics.DrawImage($iconImage,[Drawing.Rectangle]::new(0,0,$Pixels,$Pixels))
 $graphics.Dispose()
 return $bitmap
}
$iconPng=New-IconBitmap 512
$iconPng.Save((Join-Path $iconDirectory 'huangdao.png'),[Drawing.Imaging.ImageFormat]::Png)
$iconPng.Dispose()
$iconSizes=@(16,32,48,64,128,256)
$iconFrames=@()
foreach($iconSize in $iconSizes){
 $iconBitmap=New-IconBitmap $iconSize
 $iconStream=[IO.MemoryStream]::new()
 $iconBitmap.Save($iconStream,[Drawing.Imaging.ImageFormat]::Png)
 $iconFrames+=,[byte[]]$iconStream.ToArray()
 $iconBitmap.Dispose();$iconStream.Dispose()
}
$iconFile=[IO.File]::Create((Join-Path $iconDirectory 'huangdao.ico'))
$iconWriter=[IO.BinaryWriter]::new($iconFile)
$iconWriter.Write([uint16]0);$iconWriter.Write([uint16]1);$iconWriter.Write([uint16]$iconSizes.Count)
$iconOffset=6+16*$iconSizes.Count
for($i=0;$i -lt $iconSizes.Count;$i++){
 $iconDimension=if($iconSizes[$i] -eq 256){0}else{$iconSizes[$i]}
 $iconWriter.Write([byte]$iconDimension);$iconWriter.Write([byte]$iconDimension)
 $iconWriter.Write([byte]0);$iconWriter.Write([byte]0)
 $iconWriter.Write([uint16]1);$iconWriter.Write([uint16]32)
 $iconWriter.Write([uint32]$iconFrames[$i].Length);$iconWriter.Write([uint32]$iconOffset)
 $iconOffset+=$iconFrames[$i].Length
}
foreach($iconFrame in $iconFrames){$iconWriter.Write([byte[]]$iconFrame)}
$iconWriter.Dispose();$iconFile.Dispose();$iconImage.Dispose()
Write-Output 'ICON_BUILT: PNG 512px; ICO 16/32/48/64/128/256px with alpha'
