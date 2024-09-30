-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2019 Nick Stockton <https://github.com/nstockton>


local INFINITE = 0xffffffff

local ffi = require "ffi"
local ffiC = ffi.C

ffi.cdef[[
	typedef unsigned long DWORD;
	void Sleep(DWORD dwMilliseconds);
]]


local __all__ = {
	["sleep_ms"] = function (ms) return ffiC.Sleep(ms or 0) end,
	["sleep"] = function (ms) return ffiC.Sleep((ms or 0) * 1000) end
}

return __all__
