-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2023 Nick Stockton <https://github.com/nstockton>


require("mystdlib")


-- Make local references of functions for speed.
local char = string.char
local ipairs = ipairs
local StripANSI = StripANSI
local strip = string.strip
local table_concat = table.concat
local table_insert = table.insert
local utf8valid = utils.utf8valid
local utf8decode = utils.utf8decode


-- Latin-1 replacement values taken from the MUME help page.
-- https://mume.org/help/latin1
local LATIN_CHARACTER_REPLACEMENTS = {
	[0xa0] = 0x20,
	[0xa1] = 0x21,
	[0xa2] = 0x63,
	[0xa3] = 0x4c,
	[0xa4] = 0x24,
	[0xa5] = 0x59,
	[0xa6] = 0x7c,
	[0xa7] = 0x50,
	[0xa8] = 0x22,
	[0xa9] = 0x43,
	[0xaa] = 0x61,
	[0xab] = 0x3c,
	[0xac] = 0x2c,
	[0xad] = 0x2d,
	[0xae] = 0x52,
	[0xaf] = 0x2d,
	[0xb0] = 0x64,
	[0xb1] = 0x2b,
	[0xb2] = 0x32,
	[0xb3] = 0x33,
	[0xb4] = 0x27,
	[0xb5] = 0x75,
	[0xb6] = 0x50,
	[0xb7] = 0x2a,
	[0xb8] = 0x2c,
	[0xb9] = 0x31,
	[0xba] = 0x6f,
	[0xbb] = 0x3e,
	[0xbc] = 0x34,
	[0xbd] = 0x32,
	[0xbe] = 0x33,
	[0xbf] = 0x3f,
	[0xc0] = 0x41,
	[0xc1] = 0x41,
	[0xc2] = 0x41,
	[0xc3] = 0x41,
	[0xc4] = 0x41,
	[0xc5] = 0x41,
	[0xc6] = 0x41,
	[0xc7] = 0x43,
	[0xc8] = 0x45,
	[0xc9] = 0x45,
	[0xca] = 0x45,
	[0xcb] = 0x45,
	[0xcc] = 0x49,
	[0xcd] = 0x49,
	[0xce] = 0x49,
	[0xcf] = 0x49,
	[0xd0] = 0x44,
	[0xd1] = 0x4e,
	[0xd2] = 0x4f,
	[0xd3] = 0x4f,
	[0xd4] = 0x4f,
	[0xd5] = 0x4f,
	[0xd6] = 0x4f,
	[0xd7] = 0x2a,
	[0xd8] = 0x4f,
	[0xd9] = 0x55,
	[0xda] = 0x55,
	[0xdb] = 0x55,
	[0xdc] = 0x55,
	[0xdd] = 0x59,
	[0xde] = 0x54,
	[0xdf] = 0x73,
	[0xe0] = 0x61,
	[0xe1] = 0x61,
	[0xe2] = 0x61,
	[0xe3] = 0x61,
	[0xe4] = 0x61,
	[0xe5] = 0x61,
	[0xe6] = 0x61,
	[0xe7] = 0x63,
	[0xe8] = 0x65,
	[0xe9] = 0x65,
	[0xea] = 0x65,
	[0xeb] = 0x65,
	[0xec] = 0x69,
	[0xed] = 0x69,
	[0xee] = 0x69,
	[0xef] = 0x69,
	[0xf0] = 0x64,
	[0xf1] = 0x6e,
	[0xf2] = 0x6f,
	[0xf3] = 0x6f,
	[0xf4] = 0x6f,
	[0xf5] = 0x6f,
	[0xf6] = 0x6f,
	[0xf7] = 0x2f,
	[0xf8] = 0x6f,
	[0xf9] = 0x75,
	[0xfa] = 0x75,
	[0xfb] = 0x75,
	[0xfc] = 0x75,
	[0xfd] = 0x79,
	[0xfe] = 0x74,
	[0xff] = 0x79,
}


function from_utf8(data)
	-- This function makes use of the MushClient API.
	local length, err_col = utf8valid(data)
	assert(not err_col, string.format("Invalid UTF-8 string '%s', (column %s)", data, err_col))
	if length == #data then
		-- Only ASCII characters were found, no need to convert.
		return data
	end
	local char = char
	local table_insert = table_insert
	local invalid_character_replacement = 0x3f  -- "?"
	result = {}
	for _, ordinal in ipairs(utf8decode(data)) do
		-- Don't replace if ordinal < 128, otherwise replace with corresponding replacement, or with default replacement.
		ordinal = ordinal < 128 and ordinal or LATIN_CHARACTER_REPLACEMENTS[ordinal] or invalid_character_replacement
		table_insert(result, char(ordinal))
	end
	return table_concat(result)
end


function normalize(text)
	-- This function makes use of the MushClient API.
	return strip(StripANSI(from_utf8(text)))
end


local __all__ = {
	["normalize"] = normalize,
	["from_utf8"] = from_utf8,
}

return __all__
