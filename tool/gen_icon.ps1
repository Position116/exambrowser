# Generate icon ExamBrow: topi wisuda putih di atas latar indigo.
# Output:
#   assets/icon/app_icon.png        (1024x1024, latar penuh - untuk Android legacy/iOS/Windows)
#   assets/icon/icon_foreground.png (1024x1024, transparan - foreground adaptive icon Android)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dir  = Join-Path $root 'assets\icon'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$indigoLight = [System.Drawing.Color]::FromArgb(255, 63, 81, 181)   # #3F51B5
$indigoDark  = [System.Drawing.Color]::FromArgb(255, 40, 53, 147)   # #283593
$white       = [System.Drawing.Color]::White

function New-RoundedRect([double]$x, [double]$y, [double]$w, [double]$h, [double]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Gambar glyph topi wisuda dalam koordinat kanvas 1024, dengan transform (skala+geser).
function Draw-Cap([System.Drawing.Graphics]$g, [double]$s, [System.Drawing.Color]$buttonColor) {
    $m = New-Object System.Drawing.Drawing2D.Matrix($s, 0, 0, $s, (512 - 531 * $s), (512 - 443 * $s))
    $g.MultiplyTransform($m)

    $brush = New-Object System.Drawing.SolidBrush($white)

    # Badan topi (mengambang di bawah papan)
    $body = New-RoundedRect 380 440 264 250 30
    $g.FillPath($brush, $body)
    $body.Dispose()

    # Papan mortarboard (belah ketupat)
    $pts = @(
        (New-Object System.Drawing.PointF(512, 196)),
        (New-Object System.Drawing.PointF(884, 362)),
        (New-Object System.Drawing.PointF(512, 528)),
        (New-Object System.Drawing.PointF(140, 362))
    )
    $g.FillPolygon($brush, $pts)

    # Kancing di tengah papan
    $b = New-Object System.Drawing.SolidBrush($buttonColor)
    $g.FillEllipse($b, (512 - 26), (362 - 26), 52, 52)
    $b.Dispose()

    # Tassel di sisi kanan
    $pen = New-Object System.Drawing.Pen($white, 24)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($pen, 884, 362, 884, 588)
    $pen.Dispose()
    $g.FillEllipse($brush, (884 - 38), (622 - 38), 76, 76)

    $brush.Dispose()
    $g.ResetTransform()
    $m.Dispose()
}

# --- 1) Icon utama: latar gradasi penuh ---
$bmp = New-Object System.Drawing.Bitmap(1024, 1024)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$rect = New-Object System.Drawing.Rectangle(0, 0, 1024, 1024)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $indigoLight, $indigoDark, 45)
$g.FillRectangle($bg, $rect)
$bg.Dispose()
Draw-Cap $g 1.0 $indigoDark
$g.Dispose()
$bmp.Save((Join-Path $dir 'app_icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# --- 2) Foreground adaptive: glyph di tengah area aman, latar transparan ---
$bmp2 = New-Object System.Drawing.Bitmap(1024, 1024)
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
Draw-Cap $g2 0.62 $indigoDark
$g2.Dispose()
$bmp2.Save((Join-Path $dir 'icon_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp2.Dispose()

Write-Host "OK: icon dibuat di $dir"
