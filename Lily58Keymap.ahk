#Requires AutoHotkey v2.0
#SingleInstance Force

global keymapPath := "C:\Users\roxas\zmk-config\config\lily58.keymap"
global viewer := 0

; F13 toggles the graphical viewer
$*~F13::ToggleViewer()

ToggleViewer(*) {
    global viewer, keymapPath

    ; Close if already open
    if IsObject(viewer) {
        CloseViewer()
        return
    }

    if !FileExist(keymapPath) {
        MsgBox("Cannot find:`n" keymapPath, "Lily58")
        return
    }

    layers := LoadLayers()

    if (layers.Length = 0) {
        MsgBox("Couldn't parse the keymap layers.", "Lily58")
        return
    }

    viewer := Gui("+AlwaysOnTop +Resize", "Lily58 Visual Keymap")
    viewer.BackColor := "18212F"
    viewer.SetFont("s9 bold", "Segoe UI")

    tabNames := []
    for layer in layers
        tabNames.Push(layer.name)

    tabs := viewer.Add("Tab3", "x12 y12 w850 h425", tabNames)
	tabs.SetFont("cAAB8CA s9 bold", "Segoe UI")

    for index, layer in layers {
        tabs.UseTab(index)
        RenderLayer(viewer, layer.keys)
    }

    tabs.UseTab()

    viewer.OnEvent("Close", CloseViewer)
    viewer.OnEvent("Escape", CloseViewer)

    viewer.Show("w880 h470")

    ; Approximately 93% opacity
    WinSetTransparent(238, "ahk_id " viewer.Hwnd)
}

CloseViewer(*) {
    global viewer

    if !IsObject(viewer)
        return

    old := viewer
    viewer := 0

    try old.Destroy()
}


LoadLayers() {
    global keymapPath

    source := FileRead(keymapPath, "UTF-8")

    ; Remove comments before parsing
    source := RegExReplace(source,
        "(?s)/\*.*?\*/|//[^\r\n]*", "")

    layers := []
    pos := 1

    pattern := '(?s)[A-Za-z_]\w*\s*\{[^{}]*?display-name\s*=\s*"([^"]+)"\s*;[^{}]*?bindings\s*=\s*<([\s\S]*?)>\s*;'

    while RegExMatch(source, pattern, &m, pos) {
        layers.Push({
            name: m[1],
            keys: ParseBindings(m[2])
        })

        pos := m.Pos + m.Len
    }

    return layers
}

ParseBindings(bindings) {
    bindings := RegExReplace(bindings, "\s+", " ")
    tokens := StrSplit(Trim(bindings), " ")
    keys := []

    i := 1

    while (i <= tokens.Length) {
        token := tokens[i]

        if (token = "") {
            i++
            continue
        }

        if (SubStr(token, 1, 1) != "&") {
            i++
            continue
        }

        behavior := SubStr(token, 2)
        args := []

        switch behavior {
            case "kp":       arity := 1
            case "mt":       arity := 2
            case "mo":       arity := 1
            case "to":       arity := 1
            case "tog":      arity := 1
            case "lt":       arity := 2
            case "kt":       arity := 1
            case "trans":    arity := 0
            case "caps_word": arity := 0
            default:         arity := 0
        }

        Loop arity {
            i++
            if (i <= tokens.Length)
                args.Push(tokens[i])
        }

        label := behavior

        if (behavior = "kp" && args.Length >= 1)
            label := KeyLabel(args[1])

        else if (behavior = "mt" && args.Length >= 2)
            label := KeyLabel(args[2]) "`n" KeyLabel(args[1])

        else if (behavior = "mo" && args.Length >= 1) {
            label := args[1] = "1" ? "LOWER" : "RAISE"
        }

        else if (behavior = "trans")
            label := "·"

        else if (behavior = "caps_word")
            label := "CAPS`nWORD"

        else if (behavior = "kt" && args.Length >= 1)
            label := "TOGGLE`n" KeyLabel(args[1])

        keys.Push(label)
        i++
    }

    return keys
}

KeyLabel(code) {
    static names := Map(
		"LEFT", "←",
		"RIGHT", "→",
		"UP", "↑",
		"DOWN", "↓",
		"HOME", "HOME",
		"END", "END",
		"PG_UP", "PGUP",
		"PG_DN", "PGDN",
		"INS", "INS",
		"DEL", "DEL",
		"RET", "ENTER",
		"ESC", "ESC",
		"TAB", "TAB",
		"BSPC", "BACK",
		"SPACE", "SPACE",
		"LSHFT", "SHIFT",
		"RSHFT", "SHIFT",
		"LCTRL", "CTRL",
		"RCTRL", "CTRL",
		"LALT", "ALT",
		"RALT", "ALT",
		"LGUI", "WIN",
		"RGUI", "WIN",
		"CAPS", "CAPS",
		"DQT", Chr(34),
		"SQT", "'",
		"BSLH", "\",
		"FSLH", "/",
		"N7", "7",
		"N8", "8",
		"N9", "9",
		"N0", "0",
		"EQUAL", "=",
		"MINUS", "-",
		"COMMA", ",",
		"DOT", ".",
		"LBKT", "[",
		"RBKT", "]",
		"SEMI", ";",
	)

    if names.Has(code)
        return names[code]

    if RegExMatch(code, "^NUMBER_(\d)$", &m)
        return m[1]

    return StrReplace(code, "_", " ")
}

KeyColor(label) {
    if RegExMatch(label, "^(←|↓|↑|→|HOME|END|PG UP|PG DN)$")
        return "245C72"

    if RegExMatch(label, "^F\d{1,2}$")
        return "365D83"

    if InStr(label, "VOL") || InStr(label, "PLAY")
        || InStr(label, "MUTE") || InStr(label, "PREV")
        || InStr(label, "NEXT")
        return "80602F"

    if (label = "CAPS`nWORD")
        return "27634F"

    if (StrLen(label) = 1 && !RegExMatch(label, "^[A-Za-z0-9]$"))
        return "65518A"

    if (label = "·")
        return "303947"

    return "263449"
}




RenderLayer(gui, keys) {
    gui.SetFont("s9 bold", "Segoe UI")

    gui.Add("Text",
        "x24 y43 w800 h22 cAAB8CA",
        "LILY58  /  " keys.Length " KEYS")

    if (keys.Length != 58) {
        gui.Add("Text", "x24 y90 cFF8888",
            "Expected 58 keys, found " keys.Length)
        return
    }

    keyW := 48
    keyH := 42
    pitch := 53

    leftX := 24
    rightX := 448

    ; Standard Lily58 row stagger
    rowY := [82, 134, 186]
    stagger := [0, 5, 10, 10, 5, 0]

    keyIndex := 1

    ; -----------------------------------------
    ; ROWS 1-3: Six keys per half
    ; -----------------------------------------
    Loop 3 {
        row := A_Index

        Loop 12 {
            col := Mod(A_Index - 1, 6) + 1
            rightSide := A_Index > 6

            x := (rightSide ? rightX : leftX)
                + (col - 1) * pitch

            y := rowY[row] + stagger[col]

            DrawKey(gui, keys[keyIndex],
                x, y, keyW, keyH)

            keyIndex++
        }
    }

    ; -----------------------------------------
    ; ROW 4: Seven keys per half
    ;
    ; The extra keys sit at the inner edges
    ; of the two halves.
    ; -----------------------------------------

    ; Left half: SHIFT Z X C V B LBKT
    Loop 6 {
        col := A_Index

        x := leftX + (col - 1) * pitch
        y := 238 + stagger[col]

        DrawKey(gui, keys[keyIndex],
            x, y, keyW, keyH)

        keyIndex++
    }

    ; Left inner key: LBKT
    DrawKey(gui, keys[keyIndex],
        342, 248, keyW, keyH)
    keyIndex++

    ; Right inner key: RBKT
    DrawKey(gui, keys[keyIndex],
        395, 248, keyW, keyH)
    keyIndex++

    ; Right half: N M COMMA DOT FSLH BSLH
    Loop 6 {
        col := A_Index

        x := rightX + (col - 1) * pitch
        y := 238 + stagger[col]

        DrawKey(gui, keys[keyIndex],
            x, y, keyW, keyH)

        keyIndex++
    }

    ; -----------------------------------------
    ; THUMB CLUSTERS: Four keys per half
    ;
    ; Inner keys are offset toward the center
    ; to approximate the angled thumb keys.
    ; -----------------------------------------

    thumbPositions := [
        [130, 310],
        [183, 310],
        [236, 310],
        [315, 328],

        [420, 328],
        [501, 310],
        [554, 310],
        [607, 310]
    ]

    Loop 8 {
        pos := thumbPositions[A_Index]

        DrawKey(gui,
            keys[keyIndex],
            pos[1],
            pos[2],
            keyW,
            keyH)

        keyIndex++
    }

    ; -----------------------------------------
    ; Footer
    ; -----------------------------------------

    gui.Add("Text",
        "x24 y400 w800 h20 cAAB8CA",
        "F13: Toggle viewer    |    ESC: Close    |    Reloads file on next open")
}


DrawKey(gui, label, x, y, w, h) {
    color := KeyColor(label)

    ; Background and border
    gui.Add("Text",
        "x" x " y" y " w" w " h" h
        " Border Background" color)

    if InStr(label, "`n") {
        parts := StrSplit(label, "`n")

        ; Tap key (top)
        gui.Add("Text",
            "x" (x+2) " y" (y+3) " w" (w-4) " h18"
            " Center cFFFFFF BackgroundTrans",
            parts[1])

        ; Hold modifier (bottom)
        gui.Add("Text",
            "x" (x+2) " y" (y+21) " w" (w-4) " h16"
            " Center cAAB8CA BackgroundTrans",
            parts[2])
    } else {
        gui.Add("Text",
            "x" x " y" y " w" w " h" h
            " Center BackgroundTrans cFFFFFF",
            label)
    }
}
