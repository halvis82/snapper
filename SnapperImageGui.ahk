;By halvis82, Created: 27.09.2020, Last edited: 30.10.2020, Program to display image taken by Snapper (only used by Snapper)

;Consider adding hotkey, 'o', to use OCR on image.

;;;Settings
#SingleInstance, off
#NoTrayIcon
#NoEnv
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetTitleMatchMode, 3

;;;Main
arg1 = %1%
if (StrLen(arg1) == 0)
{
    msgbox, 262160, Snapper, An error occured while showing the Snapper screenshot.
    ExitApp
}
else
{
    IfNotExist, %arg1%
    {
        msgbox, 262160, Snapper, An error occured while showing the Snapper screenshot.
        ExitApp
    }
    else
    {
        ;Get image dimentions
        gui, get_image_size: add, picture, hwndpicture_hwnd_for_info, %arg1%
        ControlGetPos,,,image_width,image_height,, ahk_id %picture_hwnd_for_info%
        if (image_width >= image_height)
        {
            biggest_side := "width"
            if (image_width <= 200)
            {
                image_width_or_height := 200
            }
            else if (image_width <= 400)
            {
                image_width_or_height := 400
            }
            else if (image_width <= 600)
            {
                image_width_or_height := 600
            }
            else
            {
                image_width_or_height := 700
            }
        }
        else
        {
            biggest_side := "height"
            if (image_height <= 200)
            {
                image_width_or_height := 200
            }
            else if (image_height <= 400)
            {
                image_width_or_height := 400
            }
            else if (image_height <= 600)
            {
                image_width_or_height := 600
            }
            else
            {
                image_width_or_height := 700
            }
        }

        ;Main image gui
        Gui, snapper_image_gui: -Caption +AlwaysOnTop +LastFound +Border -DPIScale
        OnMessage(0x201, "WM_LBUTTONDOWN") ;Make gui movable
        Gui, snapper_image_gui: Margin, 0, 0
        if (biggest_side == "width")
        {
            Gui, snapper_image_gui: Add, Picture, x0 y0 w%image_width_or_height% h-1 hwndfinal_snapper_image_hwnd vvfinal_snapper_image, %arg1%
        }
        else
        {
            Gui, snapper_image_gui: Add, Picture, x0 y0 h%image_width_or_height% w-1 hwndfinal_snapper_image_hwnd, %arg1%
        }
        ControlGetPos,,,final_image_width,final_image_height,, ahk_id %final_snapper_image_hwnd%
        MouseGetPos, mouse_x, mouse_y
        snapper_image_x := mouse_x - (final_image_width / 2)
        snapper_image_y := mouse_y - (final_image_height / 2)
        Loop
        {
            IfWinNotExist, Snapper image %A_Index%
            {
                snapper_image_window_name = Snapper image %A_Index%
                Break
            }
        }
        Gui, snapper_image_gui: Show, x%snapper_image_x% y%snapper_image_y% Noactivate, %snapper_image_window_name%
    }
}
Return

;;;Hotkeys

;Close image with esc
#If, (WinActive(snapper_image_window_name))
*Esc::
    ExitApp
Return
#If

;Toggle alwaysontop image
#If, (WinActive(snapper_image_window_name))
*a::
    WinSet, AlwaysOnTop, Toggle, A
Return
#If

;Cycle through image sizes
#If, (WinActive(snapper_image_window_name))
*Space::
    ;Get previous gui's size
    if (image_width_or_height == 200)
    {
        image_width_or_height := 400
    }
    else if (image_width_or_height == 400)
    {
        image_width_or_height := 600
    }
    else if (image_width_or_height == 600)
    {
        image_width_or_height := 700
    }
    else if (image_width_or_height == 700)
    {
        image_width_or_height := 200
    }

    ;Destroying old one and making whole new gui
    WinGetPos, previous_snapper_image_x, previous_snapper_image_y,,, %snapper_image_window_name%

    Gui, snapper_image_gui: Destroy
    Gui, snapper_image_gui: -Caption +AlwaysOnTop +LastFound +Border -DPIScale
    OnMessage(0x201, "WM_LBUTTONDOWN") ;Make gui movable
    Gui, snapper_image_gui: Margin, 0, 0
    if (biggest_side == "width")
    {
        Gui, snapper_image_gui: Add, Picture, x0 y0 w%image_width_or_height% h-1 hwndfinal_snapper_image_hwnd vvfinal_snapper_image, %arg1%
    }
    else
    {
        Gui, snapper_image_gui: Add, Picture, x0 y0 h%image_width_or_height% w-1 hwndfinal_snapper_image_hwnd, %arg1%
    }
    Gui, snapper_image_gui: Show, x%previous_snapper_image_x% y%previous_snapper_image_y%, %snapper_image_window_name%
Return
#If

;Save image as
#If, (WinActive(snapper_image_window_name))
*s::    
    Gui, snapper_image_gui: Destroy
    FileSelectFile, save_as_snapper_file_path, S, %A_MyDocuments%\Snapper image.png, Select a folder you want to save the image in`, and image name., (*.png)
    if !ErrorLevel
    {
        SplitPath, save_as_snapper_file_path,, save_as_snapper_file_path_OutDir,, save_as_snapper_file_path_OutNameNoExt
        IfExist, %save_as_snapper_file_path_OutDir%\%save_as_snapper_file_path_OutNameNoExt%.png
        {
            Loop
            {
                IfNotExist, %save_as_snapper_file_path_OutDir%\%save_as_snapper_file_path_OutNameNoExt% (%A_Index%).png
                {
                    FileCopy, %arg1%, %save_as_snapper_file_path_OutDir%\%save_as_snapper_file_path_OutNameNoExt% (%A_Index%).png
                    Break
                }
            }
        }
        else
        {
            FileCopy, %arg1%, %save_as_snapper_file_path_OutDir%\%save_as_snapper_file_path_OutNameNoExt%.png
        }
    }
    ExitApp
Return
#If

;Edit image
#If, (WinActive(snapper_image_window_name))
*e::
    IfExist, %A_ScriptDir%\Snapper_settings.ini
    {
        IniRead, ini_editing_program, %A_ScriptDir%\Snapper_settings.ini, image_gui_settings, editing_program
        IfExist, %ini_editing_program%
        {
            Run, %ini_editing_program% "%arg1%"
            ExitApp
        }
        else
        {
            msgbox, 262160, Snapper, This editing program doesn't seem to be installed (or working) on this computer. You can change it in the hidden Snapper_settings.ini file in the folder Snapper is in.
        }
    }
    else
    {
        IfExist, C:\Windows\System32\mspaint.exe
        {
            Run, C:\Windows\System32\mspaint.exe "%arg1%"
            ExitApp
        }
        else
        {
            msgbox, 262160, Snapper, This editing program doesn't seem to be installed (or working) on this computer. You can change it in the hidden Snapper_settings.ini file in the folder Snapper is in.
        }
    }
Return
#If

;;;Functions/labels

;Make image movable
WM_LBUTTONDOWN()
{
    PostMessage, 0xA1, 2
}

;Exit app if image closed
snapper_image_guiGuiClose:
    ExitApp
Return