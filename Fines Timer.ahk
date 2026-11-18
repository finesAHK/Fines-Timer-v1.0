#NoEnv
#SingleInstance Force
SetBatchLines, -1

UiHtmlPath := A_Temp "\fin_timer_ui.html"

htmlCode =
( %
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<style>
    body {
        background-color: #010101;
        color: #ffffff;
        font-family: 'Segoe UI', Consolas, monospace;
        margin: 0;
        padding: 8px 14px;
        overflow: hidden;
        -ms-user-select: none;
        user-select: none;
        cursor: move;
    }
    .timer-box {
        display: inline-block;
    }
    .time-main {
        font-size: 46px;
        font-weight: 900;
        letter-spacing: 1px;
        color: #ffffff;
        text-shadow: 2px 2px 0px #000000, -1px -1px 0px #000000, 1px -1px 0px #000000, -1px 1px 0px #000000, 0 0 12px rgba(0,0,0,0.9);
        line-height: 1;
    }
    .time-ms {
        font-size: 28px;
        font-weight: 800;
        color: #cccccc;
    }
    .running .time-main {
        color: #87CEEB;
        text-shadow: 2px 2px 0px #000000, -1px -1px 0px #000000, 0 0 14px rgba(135, 206, 235, 0.6);
    }
    .running .time-ms {
        color: #87CEEB;
    }
    .paused .time-main, .paused .time-ms {
        color: #ffd166;
    }
    .hint {
        font-size: 11px;
        font-weight: bold;
        color: #aaaaaa;
        margin-top: 4px;
        text-shadow: 1px 1px 2px #000000;
        letter-spacing: 0.5px;
    }
</style>
<script>
    function startDrag() {
        document.title = "cmd:drag";
    }
    function updateTime(mainStr, msStr, state) {
        document.getElementById('tMain').innerHTML = mainStr;
        document.getElementById('tMs').innerHTML = msStr;
        var box = document.getElementById('tBox');
        box.className = 'timer-box ' + state;
    }
</script>
</head>
<body onmousedown="startDrag()">
    <div id="tBox" class="timer-box">
        <div><span id="tMain" class="time-main">00:00</span><span id="tMs" class="time-ms">.00</span></div>
        <div class="hint">F4 — Старт/Пауза &nbsp;|&nbsp; F5 — Сброс</div>
    </div>
</body>
</html>
)

FileDelete, %UiHtmlPath%
FileAppend, %htmlCode%, %UiHtmlPath%, UTF-8

SysGet, Mon, MonitorWorkArea
WinW := 310
WinH := 85
StartX := MonRight - WinW - 25
StartY := MonTop + 25

Gui, -DPIScale -Caption +AlwaysOnTop +ToolWindow
Gui, Color, 010101
Gui, Margin, 0, 0

Gui, Add, ActiveX, w%WinW% h%WinH% vWB, Shell.Explorer
WB.Silent := True
WB.Navigate(UiHtmlPath)
while WB.ReadyState != 4
    Sleep, 10

Menu, Tray, NoStandard
Menu, Tray, Add, Старт / Пауза (F4), ToggleTimer
Menu, Tray, Add, Сброс (F5), ResetTimer
Menu, Tray, Add
Menu, Tray, Add, Выход, GuiClose

Gui, Show, x%StartX% y%StartY% w%WinW% h%WinH%, Fines Timer
WinSet, TransColor, 010101 245, Fines Timer

IsRunning := 0
StartTick := 0
SavedElapsed := 0

SetTimer, WatchDrag, 30
return

WatchDrag:
    try {
        if (WB.Document.title = "cmd:drag") {
            WB.Document.title := ""
            PostMessage, 0xA1, 2,,, Fines Timer
        }
    }
return

$F4::
ToggleTimer:
    if (IsRunning = 0) {
        IsRunning := 1
        StartTick := A_TickCount
        SetTimer, TickStopwatch, 25
        SoundBeep, 1100, 70
    } else {
        IsRunning := 0
        SavedElapsed += (A_TickCount - StartTick)
        SetTimer, TickStopwatch, Off
        GoSub, RenderPaused
        SoundBeep, 750, 70
    }
return

$F5::
ResetTimer:
    IsRunning := 0
    SavedElapsed := 0
    SetTimer, TickStopwatch, Off
    try WB.Document.parentWindow.updateTime("00:00", ".00", "")
    SoundBeep, 550, 90
return

TickStopwatch:
    TotalMs := SavedElapsed + (A_TickCount - StartTick)
    FormatStopwatch(TotalMs, mainPart, msPart)
    try WB.Document.parentWindow.updateTime(mainPart, msPart, "running")
return

RenderPaused:
    FormatStopwatch(SavedElapsed, mainPart, msPart)
    try WB.Document.parentWindow.updateTime(mainPart, msPart, "paused")
return

FormatStopwatch(ms, ByRef outMain, ByRef outMs) {
    totalSec := ms // 1000
    centi := Mod(ms // 10, 100)
    hours := totalSec // 3600
    mins := Mod(totalSec // 60, 60)
    secs := Mod(totalSec, 60)

    if (hours > 0)
        outMain := Format("{:d}:{:02d}:{:02d}", hours, mins, secs)
    else
        outMain := Format("{:02d}:{:02d}", mins, secs)

    outMs := Format(".{:02d}", centi)
}

GuiClose:
    ExitApp
