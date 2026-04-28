#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

; = CONFIG =
ImageFile := "buff.png" ; make sure this file exists AND DO NOT CHANGE
SoundFile := "alarm.mp3" ; make sure this file exists
TargetColor := 0x9456B6
ColorTolerance := 15

; TRIGGER POSITION
OffX := 2
OffY := 0

; Variables
TimerStart := 0
LastX := 0
LastY := 0
IsActive := false
MissedFrames := 0
IsAlarmPlaying := false

; = GUI =
MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Precise Timer")
MyGui.BackColor := "1A1A2E"
WinSetTransparent(240, MyGui)

; - Title Bar -
MyGui.SetFont("s8 bold", "Segoe UI")
TitleLabel := MyGui.Add("Text", "x10 y9 w125 c8080AA", "PRECISE TIMER")

; Exit button
MyGui.SetFont("s11 bold", "Segoe UI")
ExitBtn := MyGui.Add("Text", "x150 y4 w22 h20 Center c6A4A8A", "×")
ExitBtn.OnEvent("Click", (*) => ExitApp())

OnMessage(0x0200, WM_MOUSEMOVE)

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global ExitBtn
    if (hwnd = ExitBtn.Hwnd)
        ExitBtn.SetFont("cE080C0")
    else
        ExitBtn.SetFont("c6A4A8A")
}

; Divider line
MyGui.Add("Text", "x0 y29 w178 h1 Background404060", "")

; --- Timer Display ---
MyGui.SetFont("s28 bold", "Segoe UI")
TimeText := MyGui.Add("Text", "x0 y36 w178 cWhite Center", "--")

; Status label
MyGui.SetFont("s7", "Segoe UI")
StatusText := MyGui.Add("Text", "x0 y83 w178 c505070 Center", "Scanning...")

; Default position / top right
GuiX := A_ScreenWidth - 215
MyGui.Show("x" GuiX " y50 w178 h100 NoActivate")

; = DRAG TO MOVE =
OnMessage(0x0201, WM_LBUTTONDOWN)

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global MyGui
    if (hwnd = MyGui.Hwnd)
        PostMessage(0x00A1, 2, 0,, "ahk_id " hwnd)
}

; = MAIN LOOP =
SetTimer(MainLoop, 50)

MainLoop() {
    global LastX, LastY, OffX, OffY, TimerStart, IsActive, MissedFrames
    global TimeText, StatusText, TargetColor, ColorTolerance
    global IsAlarmPlaying
    
    FoundNow := false
    
    ; 1. FIND ICON USING buff.png
    if ImageSearch(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, "*75 " ImageFile) {
        FoundNow := true
        LastX := X
        LastY := Y
        MissedFrames := 0
    } else {
        MissedFrames += 1
    }
    
    ; 2. LOGIC
    if (FoundNow || (IsActive && MissedFrames < 60)) {
        IsActive := true
        
        CheckX := LastX + OffX 
        CheckY := LastY + OffY
        
        ; 3. READ PIXEL
        SeenColor := PixelGetColor(CheckX, CheckY, "RGB")
        Diff := CompareColors(TargetColor, SeenColor)
        
        ; 4. COMPARE
        if (Diff <= ColorTolerance) {
            TimerStart := A_TickCount 
            TimeText.Value := "60"
            TimeText.SetFont("cLime")
            StatusText.Value := "Healty State"
            StatusText.SetFont("c306030")
            StopAlarm() 
        } 
        else {
            TimePassed := (A_TickCount - TimerStart) / 1000
            TimeLeft := 60 - TimePassed
            
            if (TimeLeft < 0) 
                TimeLeft := 0
            
            TimeText.Value := Integer(TimeLeft)
            
            if (TimeLeft > 30) {
                TimeText.SetFont("cLime")
                StatusText.Value := "Healthy State"
                StatusText.SetFont("c306030")
            } else if (TimeLeft > 20) {
                TimeText.SetFont("cYellow")
                StatusText.Value := "About to expire"
                StatusText.SetFont("c807030")
            } else {
                TimeText.SetFont("cRed")
                StatusText.Value := "▲ REFRESH NOW!"
                StatusText.SetFont("c903030")
            }

            if (TimeLeft <= 20) {
                StartAlarm()
            } else {
                StopAlarm()
            }
        }
        
    } else {
        IsActive := false
        TimeText.Value := "--"
        TimeText.SetFont("cGray")
        StatusText.Value := "Scanning..."
        StatusText.SetFont("c505070")
        StopAlarm()
    }
}

; = SOUND FUNCTIONS =
StartAlarm() {
    global IsAlarmPlaying
    if (!IsAlarmPlaying) {
        IsAlarmPlaying := true
        SetTimer PlayLoop, 2500 
        PlayLoop() 
    }
}

StopAlarm() {
    global IsAlarmPlaying
    if (IsAlarmPlaying) {
        IsAlarmPlaying := false
        SetTimer PlayLoop, 0 
    }
}

PlayLoop() {
    global SoundFile
    if FileExist(SoundFile) {
        SoundPlay SoundFile
    } else {
        SoundBeep 750, 300 
    }
}

CompareColors(c1, c2) {
    r1 := (c1 >> 16) & 0xFF, g1 := (c1 >> 8) & 0xFF, b1 := c1 & 0xFF
    r2 := (c2 >> 16) & 0xFF, g2 := (c2 >> 8) & 0xFF, b2 := c2 & 0xFF
    return Abs(r1-r2) + Abs(g1-g2) + Abs(b1-b2)
}

; = F1: TEACH COLOR =
F1:: {
    global TargetColor
    MouseGetPos(&MX, &MY)
    TargetColor := PixelGetColor(MX, MY, "RGB")
    SoundBeep 1000, 200
}

; = ARROW KEY OFFSET CONTROLS =
Up:: {
    global OffY
    OffY -= 1
}
Down:: {
    global OffY
    OffY += 1
}
Left:: {
    global OffX
    OffX -= 1
}
Right:: {
    global OffX
    OffX += 1
}

; = EXIT =
PgUp::ExitApp