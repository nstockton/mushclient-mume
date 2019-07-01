-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2019 Nick Stockton <https://github.com/nstockton>


-- For compatibility with Lua >= 5.2.
local unpack = rawget(table, "unpack") or unpack

local ffi = require "ffi"
local msvcrt = ffi.load("msvcrt.dll")

ffi.cdef[[
	typedef wchar_t wint_t;
	int __stdcall _getch(void);
	int __stdcall _getche(void);
	wint_t __stdcall _getwch(void);
	wint_t __stdcall _getwche(void);
]]


local function _getch(func)
	local result = {}
	table.insert(result, func())
	if result[1] < 0 or result[1] >= 256 then
		return nil
	elseif result[1] == 0 or result[1] == 224 then
		-- It is likely that one of the function keys or arrows was pressed.
		-- If this is the case, _getch needs to be called again to get the second character in the 2-character sequence.
		local char = func()
		table.insert(result, char >= 0 and char < 256 and char or nil)
	end
	return string.char(unpack(result))
end


local __all__ = {
	["getch"] = function () return _getch(msvcrt._getch) end,
	["getche"] = function () return _getch(msvcrt._getche) end,
	["getwch"] = function () return _getch(msvcrt._getwch) end,
	["getwche"] = function () return _getch(msvcrt._getwche) end
}

return __all__
