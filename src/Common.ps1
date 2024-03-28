function Progress {
    param (
        $Title,
        [Parameter(Mandatory)]
        $JobName
    )
    $spinner = @("-----","\\\\\","|||||","/////")
    $oldPos = $host.UI.RawUI.CursorPosition
    do { 
        $spin = 0
        do {
            [Console]::CursorLeft = 0; [Console]::CursorTop = $oldPos.Y
            write-host $spinner[$spin] " $title " $spinner[$spin] -fore Cyan
            start-sleep -m 100; $spin++
        }
        while ($spin -ne 4)
    }
    while ((get-job -name $jobName).State -eq "Running")
    $host.UI.RawUI.CursorPosition = $oldPos
}