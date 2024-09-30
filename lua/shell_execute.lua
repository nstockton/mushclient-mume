-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2019 Nick Stockton <https://github.com/nstockton>


-- Example: to open a cmd window elevated:
-- shell_execute("cmd", nil, nil, "runas", SW_SHOWNORMAL)


local SW_HIDE = 0 -- Hides the window and activates another window.
local SW_SHOWNORMAL = 1 -- Activates and displays a window. If the window is minimized or maximized, Windows restores it to its original size and position. An application should specify this flag when displaying the window for the first time.
local SW_SHOWMINIMIZED = 2 -- Activates the window and displays it as a minimized window.
local SW_SHOWMAXIMIZED = 3 -- Activates the window and displays it as a maximized window.
local SW_SHOWNOACTIVATE = 4 -- Displays a window in its most recent size and position. The active window remains active.
local SW_SHOW = 5 -- Activates the window and displays it in its current size and position.
local SW_MINIMIZE = 6 -- Minimizes the specified window and activates the next top-level window in the z-order.
local SW_SHOWMINNOACTIVE = 7 -- Displays the window as a minimized window. The active window remains active.
local SW_SHOWNA = 8 -- Displays the window in its current state. The active window remains active.
local SW_RESTORE = 9 -- Activates and displays the window. If the window is minimized or maximized, Windows restores it to its original size and position. An application should specify this flag when restoring a minimized window.
local SW_SHOWDEFAULT = 10 -- Sets the show state based on the SW_ flag specified in the STARTUPINFO structure passed to the CreateProcess function by the program that started the application. An application should call ShowWindow with this flag to set the initial show state of its main window.

local ffi = require "ffi"
local shell32 = ffi.load("shell32.dll")
local user32 = ffi.load("user32.dll")

ffi.cdef[[
	typedef void *PVOID;
	typedef PVOID HANDLE;
	typedef HANDLE HWND, HINSTANCE;
	typedef char CHAR;
	typedef const CHAR *PCSTR, *LPCSTR;
	HWND GetDesktopWindow();
	HWND GetForegroundWindow();
	HINSTANCE ShellExecuteA(HWND hwnd, LPCSTR lpOperation, LPCSTR lpFile, LPCSTR lpParameters, LPCSTR lpDirectory, int nShowCmd);
	bool IsUserAnAdmin();
]]

local function shell_execute(file, parameters, directory, operation, show_cmd)
	shell32.ShellExecuteA(user32.GetForegroundWindow(), operation, file, parameters, directory, show_cmd or SW_SHOWNORMAL)
end


local __all__ = {
	["is_user_an_admin"] = shell32.IsUserAnAdmin,
	["shell_execute"] = shell_execute
}

return __all__
