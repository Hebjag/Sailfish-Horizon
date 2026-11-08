Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile('C:\Users\james\.gemini\antigravity\brain\f92c94d3-bbb5-4854-a8bd-365b1ee7c3dc\test_extracted.png')
$w = $src.Width
$h = $src.Height

$dst = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Lock bits
$srcData = $src.LockBits((New-Object System.Drawing.Rectangle(0, 0, $w, $h)), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$dstData = $dst.LockBits((New-Object System.Drawing.Rectangle(0, 0, $w, $h)), [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

$stride = $srcData.Stride
$srcBytes = New-Object byte[] ($stride * $h)
$dstBytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($srcData.Scan0, $srcBytes, 0, $srcBytes.Length)
[System.Runtime.InteropServices.Marshal]::Copy($srcBytes, 0, $dstBytes, 0, $dstBytes.Length)

# Icon roughly occupies y = 60 to 1340
for ($y = 0; $y -lt $h; $y++) {
    if ($y -lt 55 -or $y -gt 1345) {
        # Clear entire row
        for ($x = 0; $x -lt $w; $x++) {
            $dstBytes[$y * $stride + $x * 4 + 3] = 0
        }
        continue
    }

    # Find left outer edge
    # Scan from center x = 600 moving left
    $foundCyan = $false
    $outerLeftX = -1
    for ($x = 600; $x -ge 10; $x--) {
        $idx = $y * $stride + $x * 4
        $b = $srcBytes[$idx]
        $g = $srcBytes[$idx + 1]
        $r = $srcBytes[$idx + 2]

        $cyan = ($g + $b) / 2.0
        if (-not $foundCyan) {
            if ($cyan -gt 215 -and $b -gt 225) {
                $foundCyan = $true
            }
        } else {
            # Once in cyan, the outer edge is where cyan drops below 195
            if ($cyan -lt 190 -or $b -lt 200) {
                $outerLeftX = $x
                break
            }
        }
    }

    if ($outerLeftX -gt 0) {
        for ($x = 0; $x -le $outerLeftX; $x++) {
            $dstBytes[$y * $stride + $x * 4 + 3] = 0
        }
    }

    # Find right outer edge
    $foundCyanR = $false
    $outerRightX = -1
    for ($x = 600; $x -lt $w - 10; $x++) {
        $idx = $y * $stride + $x * 4
        $b = $srcBytes[$idx]
        $g = $srcBytes[$idx + 1]
        $r = $srcBytes[$idx + 2]

        $cyan = ($g + $b) / 2.0
        if (-not $foundCyanR) {
            if ($cyan -gt 215 -and $b -gt 225) {
                $foundCyanR = $true
            }
        } else {
            if ($cyan -lt 190 -or $b -lt 200) {
                $outerRightX = $x
                break
            }
        }
    }

    if ($outerRightX -gt 0) {
        for ($x = $outerRightX; $x -lt $w; $x++) {
            $dstBytes[$y * $stride + $x * 4 + 3] = 0
        }
    }
}

[System.Runtime.InteropServices.Marshal]::Copy($dstBytes, 0, $dstData.Scan0, $dstBytes.Length)
$src.UnlockBits($srcData)
$dst.UnlockBits($dstData)
$src.Dispose()

$testClean = 'C:\Users\james\.gemini\antigravity\brain\f92c94d3-bbb5-4854-a8bd-365b1ee7c3dc\test_cleaned_v2.png'
$dst.Save($testClean, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose()
Write-Output "Cleaned v2 saved."
