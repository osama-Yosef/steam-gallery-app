# Packages the Windows release build into a folder anyone can copy onto a PC
# and run — no installer, no admin rights.
#
# `flutter build windows` does NOT copy the MSVC runtime next to the exe, so a
# machine without the Visual C++ Redistributable installed just fails to start
# with a missing-DLL dialog. App-local deployment of these DLLs is what
# Microsoft's redistributable licence allows, so they get bundled here.
#
# Usage:  pwsh -File tool/package_windows.ps1
param(
  [string]$Version = "1.0.0",
  [string]$OutDir = "dist"
)
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$release = Join-Path $repo "build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $release "steam_gallery_app.exe"))) {
  throw "No release build found. Run: flutter build windows --release"
}

$name = "MadinaSteamGallery-Windows-v$Version"
$stage = Join-Path $repo "$OutDir\$name"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Copy-Item "$release\*" $stage -Recurse -Force

# Newest installed VC runtime; matches whatever this machine compiled with.
$crt = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\*\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT" -Directory -ErrorAction SilentlyContinue |
  Sort-Object FullName | Select-Object -Last 1
if (-not $crt) { throw "Visual C++ redistributable DLLs not found." }
foreach ($dll in "msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll") {
  Copy-Item (Join-Path $crt.FullName $dll) $stage -Force
}

$readme = @'
معرض المدينة المنورة لمكاوي بخار — نسخة ويندوز

التشغيل
  افتح ملف  steam_gallery_app.exe

  مش محتاج تثبيت ولا صلاحيات مدير. انسخ الفولدر ده كله في أي مكان على
  الجهاز (مثلاً على سطح المكتب) وشغّل البرنامج منه.

اختصار على سطح المكتب
  كليك يمين على  steam_gallery_app.exe  ثم "إرسال إلى" > "سطح المكتب
  (إنشاء اختصار)".

مهم
  لازم تنسخ الفولدر كامل — الملف التنفيذي لوحده مش هيشتغل، لأنه محتاج
  مجلد data وملفات الـ dll اللي جنبه.

المتطلبات
  ويندوز 10 أو أحدث (64-bit) + اتصال بالإنترنت.
  البرنامج بيتصل بقاعدة البيانات أونلاين، فمن غير إنترنت مش هيفتح.

الدعم
  https://github.com/osama-Yosef/steam-gallery-app
'@
# UTF-8 with BOM so Notepad renders the Arabic instead of mojibake.
[System.IO.File]::WriteAllText(
  (Join-Path $stage "اقرأني.txt"),
  ($readme -replace "`r?`n", "`r`n"),
  (New-Object System.Text.UTF8Encoding $true))

$zip = Join-Path $repo "$OutDir\$name.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal

$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Output "folder : $stage"
Write-Output "zip    : $zip ($mb MB)"
