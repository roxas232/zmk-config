
#Requires AutoHotkey v2.0
#SingleInstance Force

keymapPath := "C:\Users\roxas\zmk-config\config\lily58.keymap"

global keymapGui := 0

; F13 toggles the keymap window
F13::
{
    global keymapGui, keymapPath

    ; Close if already open
    if IsObject(keymapGui) {
        keymapGui.Destroy()
        keymapGui := 0
        return
    }

    ; Verify the file exists
    if !FileExist(keymapPath) {
        MsgBox("Cannot find keymap:`n" keymapPath,
            "Lily58 Keymap", "Icon!")
        return
    }

    ; Read the latest version every time
    contents := FileRead(keymapPath, "UTF-8")

    ; Create the window
    keymapGui := Gui("+AlwaysOnTop +Resize",
        "Lily58 Keymap - F13 to close")

    keymapGui.SetFont("s10", "Consolas")

    keymapGui.AddEdit(
        "w1100 h760 ReadOnly -Wrap HScroll VScroll",
        contents
    )

    keymapGui.OnEvent("Escape", CloseKeymap)
    keymapGui.OnEvent("Close", CloseKeymap)

    keymapGui.Show()
}

CloseKeymap(*) {
    global keymapGui

    if IsObject(keymapGui) {
        keymapGui.Destroy()
        keymapGui := 0
    }
}
