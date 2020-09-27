;By halvis82, Created: 23.09.2020, Last edited: 27.09.2020, Screenshot tool to capture part of the screen (inspired by snapper 2 (jailbreak tweak for iOS))



;;;Settings
;/////////////////////////////////
#SingleInstance, Force
#NoEnv
#Include, Gdip_all.ahk
#Include, Gdip_ImageSearch.ahk
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetTitleMatchMode, 3
screenshot_initiated := False
lbutton_pressed := False
ini_save_screenshot_checked := 0
ini_screenshot_dimentions_checked := 0
ini_startup_checked := 0
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

;;;Set up default settings
;/////////////////////////////////
IfNotExist, %A_ScriptDir%\Snapper_settings.ini
{
    FileAppend,, %A_ScriptDir%\Snapper_settings.ini
    FileSetAttrib, +H, %A_ScriptDir%\Snapper_settings.ini

    ;Write default settings here
    IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
    IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
    IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked
    IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
    IniWrite, PrintScreen, %A_ScriptDir%\Snapper_settings.ini, settings, snapper_hotkey
    IniWrite, F0C30F, %A_ScriptDir%\Snapper_settings.ini, settings, filter_color
    
    IniWrite, C:\Windows\System32\mspaint.exe, %A_ScriptDir%\Snapper_settings.ini, image_gui_settings, editing_program
}
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



;Tray menu mod
;/////////////////////////////////
Menu, Tray, NoStandard
Menu, Tray, Add, Save screenshots, tray_save_screenshots
Menu, Tray, Add, Show screenshot after taking it, tray_show_screenshot_after
Menu, Tray, Add, Show screenshot dimentions, tray_screenshot_dimentions
Menu, Tray, Add, Startup with windows, tray_startup
Menu, Tray, Add,
Menu, Tray, Add, Custom hotkey, tray_custom_hotkey
Menu, Tray, Add, Custom filter color, tray_custom_filter_color
Menu, Tray, Add,
Menu, Tray, Add, Reset settings, tray_reset_settings
Menu, Tray, Add, Help, tray_help_menu
Menu, Tray, Add, Exit Snapper, tray_exit_app

;Apply settings from Snapper_settins.ini to menu
IniRead, ini_save_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
if (ini_save_screenshot_checked)
{
    Menu, Tray, Check, Save screenshots
    IfExist, %A_ScriptDir%\Snapper screenshots\
    {
        FileSetAttrib, -H, %A_ScriptDir%\Snapper screenshots, 1
    }
}
else
{
    StringReplace, my_pictures_dir, A_MyDocuments, Documents, Pictures, All
    IfExist, %my_pictures_dir%\Snapper screenshots.lnk
    {
        FileDelete, %my_pictures_dir%\Snapper screenshots.lnk
    }
    IfExist, %A_ScriptDir%\Snapper screenshots\
    {
        FileSetAttrib, +H, %A_ScriptDir%\Snapper screenshots, 1
    }
}
IniRead, ini_show_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
if (ini_show_screenshot_checked)
{
    Menu, Tray, Check, Show screenshot after taking it
}
IniRead, ini_screenshot_dimentions_checked, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked
if (ini_screenshot_dimentions_checked)
{
    Menu, Tray, Check, Show screenshot dimentions
    show_screenshot_dimentions := True
}
else
{
    show_screenshot_dimentions := False
}
IniRead, ini_startup_checked, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
if (ini_startup_checked)
{
    Menu, Tray, Check, Startup with windows
    FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\Snapper.lnk
}
else
{
    IfExist, %A_Startup%\Snapper.lnk
    {
        FileDelete, %A_Startup%\Snapper.lnk
    }
}
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



;;;Setup
;/////////////////////////////////
;Get task bar height on main monitor
SysGet, monitor_work_area, MonitorWorkArea, 1
if (A_ScreenHeight > monitor_work_areaBottom)
{
    bottom_offset := A_ScreenHeight - monitor_work_areaBottom
}

;Get monitor top left and bottom right
SysGet, monitor_count, MonitorCount
monitor_top := 0
monitor_bottom := 0
monitor_left := 0
monitor_right := 0

Loop, %monitor_count%
{
    SysGet, monitor_work_area, MonitorWorkArea, %A_Index%
    if (monitor_work_areaLeft <= monitor_left)
    {
        monitor_left := monitor_work_areaLeft
    }
    if (monitor_work_areaRight >= monitor_right)
    {
        monitor_right := monitor_work_areaRight
    }
    if (monitor_work_areaTop <= monitor_top)
    {
        monitor_top := monitor_work_areaTop
    }
    if (monitor_work_areaBottom >= monitor_bottom)
    {
        monitor_bottom := monitor_work_areaBottom
    }
}
monitor_bottom := monitor_bottom + bottom_offset

;Get monitor width and height
if (monitor_left < 0)
{
    monitor_width := -monitor_left + monitor_right
}
else
{
    monitor_width := monitor_left + monitor_right
}

if (monitor_top < 0)
{
    monitor_height := -monitor_top + monitor_bottom
}
else
{
    monitor_height := monitor_top + monitor_bottom
}

;Gui setup
Gui, snapper_filter_gui: +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20 ;(+E0x20 to click through gui)
Gui, snapper_filter_gui: Margin, 0, 0
Gui, snapper_filter_gui: Color, F0F0F0, F0F0F0
IniRead, ini_filter_color, %A_ScriptDir%\Snapper_settings.ini, settings, filter_color
Gui, snapper_filter_gui: Add, Progress, x0 y0 w0 h0 c%ini_filter_color% Background%ini_filter_color% vvfilter_progress_bar Hidden, 100  ;default color: F0C30F (yellow ish)
gui, snapper_filter_gui: Font, s13 cWhite
Gui, snapper_filter_gui: Add, Text, vvcoordinates_text Hidden BackgroundTrans w80, 300x800
Winset, TransColor, F0F0F0 50 ;Sets color F0F0F0 to transparent and rest of gui to transparent: 50 (out of 255)

;Initiate screenshot setup
IniRead, ini_snapper_hotkey, %A_ScriptDir%\Snapper_settings.ini, settings, snapper_hotkey ;, PrintScreen
Hotkey, %ini_snapper_hotkey%, initiate_screenshot_label, UseErrorLevel
if ErrorLevel
{
    IniWrite, PrintScreen, %A_ScriptDir%\Snapper_settings.ini, settings, snapper_hotkey
    Run, https://www.autohotkey.com/docs/KeyList.htm ;AHK hotkey guide
    msgbox, 262160, Error!, Your custom Snapper hotkey is invalid. It's been reset to 'PrintScreen'.
    Reload
}

Return ;End of automatically run code
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



;;;Hotkeys
;/////////////////////////////////

;Initiate screenshot (label used for hotkey, not actual hotkey)
initiate_screenshot_label:
    screenshot_initiated := True
    SetCrossCursor()
    ;ToolTip, Hold left mouse down and drag across the screen to take a screenshot, 40, 40
    TrayTip, Snapper, Hold left mouse down and drag across the screen to take a screenshot, 3
Return

;Cancel screenshot
#If, (screenshot_initiated)
*esc::
    TrayTip,
    RestoreCursors()
    GuiControl, snapper_filter_gui: Hide, vcoordinates_text
    GuiControl, snapper_filter_gui: Hide, vfilter_progress_bar
    WinClose, Snapper filter window

    screenshot_initiated := False
    lbutton_pressed := False
Return
#If

;Get first coordinates and show filter gui
#If, (screenshot_initiated && !(lbutton_pressed))
LButton::
    TrayTip,
    lbutton_pressed := True
    
    ;Show filter gui from initial mouse position
    Gui, snapper_filter_gui: show, x%monitor_left% y%monitor_top% w%monitor_width% h%monitor_height% NoActivate, Snapper filter window
    MouseGetPos, filter_start_x, filter_start_y
    filter_start_x := filter_start_x - monitor_left
    filter_start_y := filter_start_y - monitor_top
    GuiControl, snapper_filter_gui: Move, vfilter_progress_bar, x%filter_start_x% y%filter_start_y%
    GuiControl, snapper_filter_gui: Show, vfilter_progress_bar
    
    IniRead, ini_screenshot_dimentions_checked, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked

    ;Main filter update loop
    Loop
    {
        ;Break loop if filter window doesn't exist
        IfWinNotExist, Snapper filter window
        {
            Break
        }
        
        ;Get mouse position from top left coordinate
        MouseGetPos, filter_current_x, filter_current_y
        filter_current_x := filter_current_x - monitor_left
        filter_current_y := filter_current_y - monitor_top

        ;Get distance from start pos to current pos (width and height)
        filter_current_width := filter_current_x - filter_start_x
        filter_current_height := filter_current_y - filter_start_y

        ;Determine x-direction and change width and x-pos according to it
        if (filter_current_width < 0)
        {
            filter_current_width := -filter_current_width
            progress_x_pos := filter_current_x

            ;Update coordinates text
            if (ini_screenshot_dimentions_checked)
            {
                GuiControl, snapper_filter_gui: , vcoordinates_text, %filter_current_width%
                coordinates_text_x_pos := filter_start_x - 40
                GuiControl, snapper_filter_gui: Move, vcoordinates_text, x%coordinates_text_x_pos% y%coordinates_text_y_pos%
                GuiControl, snapper_filter_gui: Show, vcoordinates_text
            }
        }
        else
        {
            progress_x_pos := filter_start_x

            ;Update coordinates text
            if (ini_screenshot_dimentions_checked)
            {
                GuiControl, snapper_filter_gui: , vcoordinates_text, %filter_current_width%x%filter_current_height%
                coordinates_text_x_pos := filter_start_x - 40
                GuiControl, snapper_filter_gui: Move, vcoordinates_text, x%coordinates_text_x_pos% y%coordinates_text_y_pos%
                GuiControl, snapper_filter_gui: Show, vcoordinates_text
            }
        }
        ;Determine y-direction and change height and y-pos according to it
        if (filter_current_height < 0)
        {
            filter_current_height := -filter_current_height
            progress_y_pos := filter_current_y

            ;Update coordinates text
            if (ini_screenshot_dimentions_checked)
            {
                GuiControl, snapper_filter_gui: , vcoordinates_text, %filter_current_width%x%filter_current_height%
                coordinates_text_y_pos := filter_start_y + 30
                GuiControl, snapper_filter_gui: Move, vcoordinates_text, x%coordinates_text_x_pos% y%coordinates_text_y_pos%
                GuiControl, snapper_filter_gui: Show, vcoordinates_text
            }
        }
        else
        {
            progress_y_pos := filter_start_y

            ;Update coordinates text
            if (ini_screenshot_dimentions_checked)
            {
                GuiControl, snapper_filter_gui: , vcoordinates_text, %filter_current_width%x%filter_current_height%
                coordinates_text_y_pos := filter_start_y - 30
                GuiControl, snapper_filter_gui: Move, vcoordinates_text, x%coordinates_text_x_pos% y%coordinates_text_y_pos%
                GuiControl, snapper_filter_gui: Show, vcoordinates_text
            }
        }

        ;Display changes
        GuiControl, snapper_filter_gui: Move, vfilter_progress_bar, x%progress_x_pos% y%progress_y_pos% w%filter_current_width% h%filter_current_height%
        sleep, 1
    }
Return
#If

;Screenshot process
#If, (screenshot_initiated)
LButton up::
    ;Hide filter window
    RestoreCursors()
    GuiControl, snapper_filter_gui: Hide, vcoordinates_text
    GuiControl, snapper_filter_gui: Hide, vfilter_progress_bar
    WinClose, Snapper filter window

    ;Get x and y from x0 and y0
    x_pos_from_x0 := progress_x_pos + monitor_left
    y_pos_from_y0 := progress_y_pos + monitor_top

    ;Save screenshot
    if (filter_current_width > 0 && filter_current_height > 0)
    {
        screenshot(x_pos_from_x0, y_pos_from_y0, filter_current_width, filter_current_height)
    }

    screenshot_initiated := False
    lbutton_pressed := False
Return
#If
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



;;;Functions
;/////////////////////////////////

;Main screenshot function
screenshot(x, y, w, h)
{
    pToken := Gdip_Startup()

    screenshot_dimentions := x "|" y "|" w "|" h
    snap := Gdip_BitmapFromScreen(screenshot_dimentions)
    
    ;Read save settings from .ini
    IniRead, ini_save_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked

    ;Create dirs and get file name
    if (ini_save_screenshot_checked)
    {
        IfNotExist, %A_ScriptDir%\Snapper screenshots\
        {
            FileCreateDir, %A_ScriptDir%\Snapper screenshots\
        }
        FileSetAttrib, -H, %A_ScriptDir%\Snapper screenshots, 1
        IfNotExist, %A_ScriptDir%\Snapper screenshots\Snap times\
        {
            FileCreateDir, %A_ScriptDir%\Snapper screenshots\Snap times\
        }
        StringReplace, my_pictures_dir, A_MyDocuments, Documents, Pictures, All
        IfNotExist, %my_pictures_dir%\
        {
            FileCreateDir, %my_pictures_dir%
        }
        FileCreateShortcut, %A_ScriptDir%\Snapper screenshots, %my_pictures_dir%\Snapper screenshots.lnk
        loop
        {
            IfNotExist, %A_ScriptDir%\Snapper screenshots\SnapperImage_%A_Index%.png
            {
                screenshot_file_name = %A_ScriptDir%\Snapper screenshots\SnapperImage_%A_Index%.png
                Break
            }
        }
    }
    else
    {
        screenshot_file_name = %A_ScriptDir%\Snapper_temp_image.png
        StringReplace, my_pictures_dir, A_MyDocuments, Documents, Pictures, All
        IfExist, %my_pictures_dir%\Snapper screenshots.lnk
        {
            FileDelete, %my_pictures_dir%\Snapper screenshots.lnk
        }
        IfExist, %A_ScriptDir%\Snapper screenshots\
        {
            FileSetAttrib, +H, %A_ScriptDir%\Snapper screenshots, 1
        }
    }
    
    ;Actually save to file
    Gdip_SaveBitmapToFile(snap, screenshot_file_name)

    ;Copy image to clipboard
    Gdip_SetBitmapToClipboard(snap)

    ;Create time shortcut in Snapper screenshots folder
    if (ini_save_screenshot_checked)
    {
        FormatTime, datetime,, MMM dd.yyyy - hh.mm tt
        IfNotExist, %A_ScriptDir%\Snapper screenshots\Snap times\%datetime%.lnk
        {
            FileCreateShortcut, %screenshot_file_name%, %A_ScriptDir%\Snapper screenshots\Snap times\%datetime%.lnk
        }
        else
        {
            loop
            {
                IfNotExist, %A_ScriptDir%\Snapper screenshots\Snap times\%datetime% (%A_Index%).lnk
                {
                    FileCreateShortcut, %screenshot_file_name%, %A_ScriptDir%\Snapper screenshots\Snap times\%datetime% (%A_Index%).lnk
                    Break
                }
            }
        }
    }
    else
    {
        FileSetAttrib, +H, %screenshot_file_name%
    }

    ;Show image gui
    IniRead, ini_show_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
    if (ini_show_screenshot_checked)
    {
        if (A_IsCompiled)
        {
            FileInstall, SnapperImageGui.exe, %A_ScriptDir%\SnapperImageGui.exe, 1
            FileSetAttrib, +H, %A_ScriptDir%\SnapperImageGui.exe
            Run, %A_ScriptDir%\SnapperImageGui.exe "%screenshot_file_name%"
        }
    }

    Gdip_DisposeImage(snap)
}

;Set cross cursor
SetCrossCursor( Cursor = "IDC_CROSS", cx = 32, cy = 32 ) ;Stolen from autohotkey.com/board/topic/32608-changing-the-system-cursor/
{
	BlankCursor := 0, SystemCursor := 0, FileCursor := 0 ; init
	
	SystemCursors = 32512IDC_ARROW,32513IDC_IBEAM,32514IDC_WAIT,32515IDC_CROSS
	,32516IDC_UPARROW,32640IDC_SIZE,32641IDC_ICON,32642IDC_SIZENWSE
	,32643IDC_SIZENESW,32644IDC_SIZEWE,32645IDC_SIZENS,32646IDC_SIZEALL
	,32648IDC_NO,32649IDC_HAND,32650IDC_APPSTARTING,32651IDC_HELP
	
	If Cursor = ; empty, so create blank cursor 
	{
		VarSetCapacity( AndMask, 32*4, 0xFF ), VarSetCapacity( XorMask, 32*4, 0 )
		BlankCursor = 1 ; flag for later
	}
	Else If SubStr( Cursor,1,4 ) = "IDC_" ; load system cursor
	{
		Loop, Parse, SystemCursors, `,
		{
			CursorName := SubStr( A_Loopfield, 6, 15 ) ; get the cursor name, no trailing space with substr
			CursorID := SubStr( A_Loopfield, 1, 5 ) ; get the cursor id
			SystemCursor = 1
			If ( CursorName = Cursor )
			{
				CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )	
				Break					
			}
		}	
		If CursorHandle = ; invalid cursor name given
		{
			Msgbox,, SetCursor, Error: Invalid cursor name
			CursorHandle = Error
		}
	}	
	Else If FileExist( Cursor )
	{
		SplitPath, Cursor,,, Ext ; auto-detect type
		If Ext = ico 
			uType := 0x1	
		Else If Ext in cur,ani
			uType := 0x2		
		Else ; invalid file ext
		{
			Msgbox,, SetCursor, Error: Invalid file type
			CursorHandle = Error
		}		
		FileCursor = 1
	}
	Else
	{	
		Msgbox,, SetCursor, Error: Invalid file path or cursor name
		CursorHandle = Error ; raise for later
	}
	If CursorHandle != Error 
	{
		Loop, Parse, SystemCursors, `,
		{
			If BlankCursor = 1 
			{
				Type = BlankCursor
				%Type%%A_Index% := DllCall( "CreateCursor"
				, Uint,0, Int,0, Int,0, Int,32, Int,32, Uint,&AndMask, Uint,&XorMask )
				CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
				DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
			}			
			Else If SystemCursor = 1
			{
				Type = SystemCursor
				CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )	
				%Type%%A_Index% := DllCall( "CopyImage"
				, Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )		
				CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
				DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
			}
			Else If FileCursor = 1
			{
				Type = FileCursor
				%Type%%A_Index% := DllCall( "LoadImageA"
				, UInt,0, Str,Cursor, UInt,uType, Int,cx, Int,cy, UInt,0x10 ) 
				DllCall( "SetSystemCursor", Uint,%Type%%A_Index%, Int,SubStr( A_Loopfield, 1, 5 ) )			
			}          
		}
	}	
}

;Restore cursors
RestoreCursors() 
{
	SPI_SETCURSORS := 0x57
	DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

;Tray menu functions
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tray_save_screenshots:
    IniRead, ini_save_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
    if (ini_save_screenshot_checked)
    {
        Menu, Tray, UnCheck, Save screenshots
        IniWrite, 0, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
    }
    else
    {
        Menu, Tray, Check, Save screenshots
        IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
    }

    ;Apply settings
    IniRead, ini_save_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, save_screenshot_checked
    if (ini_save_screenshot_checked)
    {
        IfExist, %A_ScriptDir%\Snapper screenshots\
        {
            FileSetAttrib, -H, %A_ScriptDir%\Snapper screenshots, 1
            StringReplace, my_pictures_dir, A_MyDocuments, Documents, Pictures, All
            IfNotExist, %my_pictures_dir%\
            {
                FileCreateDir, %my_pictures_dir%
            }
            FileCreateShortcut, %A_ScriptDir%\Snapper screenshots, %my_pictures_dir%\Snapper screenshots.lnk
        }
    }
    else
    {
        IfExist, %A_ScriptDir%\Snapper screenshots\
        {
            FileSetAttrib, +H, %A_ScriptDir%\Snapper screenshots, 1
        }
        StringReplace, my_pictures_dir, A_MyDocuments, Documents, Pictures, All
        IfExist, %my_pictures_dir%\Snapper screenshots.lnk
        {
            FileDelete, %my_pictures_dir%\Snapper screenshots.lnk
        }
    }
Return

tray_show_screenshot_after: 
    IniRead, ini_show_screenshot_checked, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
    if (ini_show_screenshot_checked)
    {
        Menu, Tray, Uncheck, Show screenshot after taking it
        IniWrite, 0, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
    }
    else
    {
        Menu, Tray, Check, Show screenshot after taking it
        IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, show_screenshot_checked
    }
Return

tray_screenshot_dimentions:
    IniRead, ini_screenshot_dimentions_checked, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked
    if (ini_screenshot_dimentions_checked)
    {
        Menu, Tray, UnCheck, Show screenshot dimentions
        IniWrite, 0, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked
    }
    else
    {
        Menu, Tray, Check, Show screenshot dimentions
        IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, screenshot_dimentions_checked
    }
Return

tray_startup:
    IniRead, ini_startup_checked, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
    if (ini_startup_checked)
    {
        Menu, Tray, UnCheck, Startup with windows
        IniWrite, 0, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
    }
    else
    {
        Menu, Tray, Check, Startup with windows
        IniWrite, 1, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
    }

    ;Apply settings
    IniRead, ini_startup_checked, %A_ScriptDir%\Snapper_settings.ini, settings, startup_checked
    if (ini_startup_checked)
    {
        FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\Snapper.lnk
    }
    else
    {
        IfExist, %A_Startup%\Snapper.lnk
        {
            FileDelete, %A_Startup%\Snapper.lnk
        }
    }
Return

tray_custom_hotkey:
    InputBox, input_custom_hotkey, Custom hotkey, Input a hotkey (AutoHotKey) to start a screenshot:,, 200, 140
    if !ErrorLevel
    {
        IniWrite, %input_custom_hotkey%, %A_ScriptDir%\Snapper_settings.ini, settings, snapper_hotkey

        Reload
    }
Return

tray_custom_filter_color:
    InputBox, input_custom_filter_color, Custom color, Input a hexadecimal color with 6 characters:,, 200, 140
    if !ErrorLevel
    {
        ;Check if string length is 6 (valid length)
        if (StrLen(input_custom_filter_color) != 6)
        {
            msgbox, 262144, Error!, The custom color input be a 6 character long valid hexadecimal number without special characters.
            Exit
        }
        
        ;Convert to rgb and check if valid color
        color = 0x%input_custom_filter_color%
        global red:="0x" SubStr(color,3,2)
        red:=red+0
        global green:="0x" SubStr(color,5,2)
        green:=green+0
        global blue:="0x" SubStr(color,7,2)
        blue:=blue+0
        if (StrLen(red) == 0 or StrLen(green) == 0 or StrLen(blue) == 0)
        {
            msgbox, 262144, Error!, The custom color input be a 6 character long valid hexadecimal number without special characters.
            Exit
        }

        IniWrite, %input_custom_filter_color%, %A_ScriptDir%\Snapper_settings.ini, settings, filter_color

        Reload
    }
Return

tray_reset_settings:
    IfExist, %A_ScriptDir%\Snapper_settings.ini
    {
        FileDelete, %A_ScriptDir%\Snapper_settings.ini
    }
    Reload
Return

tray_help_menu:
    msgbox, 262208, Snapper, Snapper is a snipping tool app that allows you to take a screenshot of a portion of the screen. It is started with a hotkey of your choice (default: 'PrintScreen'). Screenshots will be saved to the 'Pictures' folder (if enabled), and copied to clipboard. You can change settings in the tray/services menu (or the hidden Snapper_settings.ini file in Snapper's folder). After the screenshot is taken the image will show up as a separate window you can move around. It has multiple hotkeys:`n- esc: Close`n- s: Save as`n- e: Edit`n- Space: Toggle image sizes
Return

tray_exit_app:
    msgbox, 262177, Snapper, Are you sure you want to exit Snapper?
    IfMsgBox, OK
    {
        ExitApp
    }
Return
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\