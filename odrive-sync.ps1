# powershell -command "& {$syncpath=\"D:\odrive\Dropbox\";$syncbin=\"$HOME\.odrive-agent\bin\";while ((Get-ChildItem $syncpath -Filter \"*.cloud*\" -Recurse | Measure-Object).Count){Get-ChildItem -Path \"$syncpath\" -Filter \"*.cloud*\" -Recurse | % {echo \"Syncing: $($_.FullName)\";& \"$syncbin\" \"sync\" \"$($_.FullName)\"\";}}}"
$syncpath = "D:\odrive\Dropbox"
$syncbin = ".odrive-agent\bin\odrive.exe"

while ((Get-ChildItem $syncpath -Filter "*.cloud*" -Recurse | Measure-Object).Count -gt 0) {
    Get-ChildItem -Path $syncpath -Filter "*.cloud*" -Recurse | ForEach-Object {
        echo "Syncing: $($_.FullName)`n"
        & $syncbin "sync" $_.FullName
    }
}