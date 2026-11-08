Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile('C:\Users\james\.gemini\antigravity\brain\f92c94d3-bbb5-4854-a8bd-365b1ee7c3dc\test_extracted.png')
$w = $src.Width
$h = $src.Height

# We will create an alpha mask using BFS flood fill from borders
$visited = New-Object 'bool[,]' $w, $h

# A pixel is considered background if it is light (R > 140, G > 140, B > 140) and not the cyan glow
# Notice the cyan glow has (G > 180 and B > 200 and (B - R) > 40)
# The dark background inside the icon has R < 80, G < 80, B < 80
function IsBg($c) {
    if ($c.A -eq 0) { return $true }
    # Cyan border check:
    $isCyan = ($c.B -gt 170 -and $c.G -gt 160 -and ($c.B - $c.R) -gt 30)
    if ($isCyan) { return $false }
    # Dark body:
    if ($c.R -lt 90 -and $c.G -lt 90 -and $c.B -lt 90) { return $false }
    # Otherwise if it's light grey/white background
    if ($c.R -gt 130 -and $c.G -gt 130 -and $c.B -gt 130) { return $true }
    return $false
}

$queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]

# Enqueue all border pixels
for ($x = 0; $x -lt $w; $x++) {
    $queue.Enqueue((New-Object System.Drawing.Point($x, 0)))
    $queue.Enqueue((New-Object System.Drawing.Point($x, $h - 1)))
    $visited[$x, 0] = $true
    $visited[$x, $h - 1] = $true
}
for ($y = 0; $y -lt $h; $y++) {
    $queue.Enqueue((New-Object System.Drawing.Point(0, $y)))
    $queue.Enqueue((New-Object System.Drawing.Point($w - 1, $y)))
    $visited[0, $y] = $true
    $visited[$w - 1, $y] = $true
}

$outBmp = New-Object System.Drawing.Bitmap($src)

while ($queue.Count -gt 0) {
    $pt = $queue.Dequeue()
    $px = $pt.X
    $py = $pt.Y
    $c = $src.GetPixel($px, $py)

    if (IsBg $c) {
        $outBmp.SetPixel($px, $py, [System.Drawing.Color]::Transparent)

        # Check 4 neighbors
        $neighbors = @(
            (New-Object System.Drawing.Point($px + 1, $py)),
            (New-Object System.Drawing.Point($px - 1, $py)),
            (New-Object System.Drawing.Point($px, $py + 1)),
            (New-Object System.Drawing.Point($px, $py - 1))
        )

        foreach ($n in $neighbors) {
            if ($n.X -ge 0 -and $n.X -lt $w -and $n.Y -ge 0 -and $n.Y -lt $h) {
                if (-not $visited[$n.X, $n.Y]) {
                    $visited[$n.X, $n.Y] = $true
                    $queue.Enqueue($n)
                }
            }
        }
    }
}

$src.Dispose()
$cleanPath = 'C:\Users\james\.gemini\antigravity\brain\f92c94d3-bbb5-4854-a8bd-365b1ee7c3dc\test_cleaned.png'
$outBmp.Save($cleanPath, [System.Drawing.Imaging.ImageFormat]::Png)
$outBmp.Dispose()
Write-Output "Cleaned image saved."
