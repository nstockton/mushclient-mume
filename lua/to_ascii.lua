-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2025 Nick Stockton <https://github.com/nstockton>


-- Module for normalizing MUME output to ASCII.
-- MUME can output text in either UTF-8 or Latin-1 encoding, with characters within the Latin-1 range (0x00-0xFF).
-- This module:
--  - Decodes input as UTF-8, falling back to single-byte interpretation for invalid sequences (handling Latin-1).
--  - Maps Latin-1 characters (0xA0-0xFF) to ASCII approximations using a replacement table.
--  - Preserves ASCII characters (0x00-0x7F) as is.
--  - Replaces any characters that cannot be normalized to ASCII with "?" (0x3F).


require("mystdlib")


-- Make local references of functions for speed.
local char = string.char
local ipairs = ipairs
local StripANSI = StripANSI  -- Part of MUSHClient.
local Trim = Trim  -- Part of MUSHClient.
local utf8valid = utils.utf8valid  -- Part of MUSHClient.
local utf8decode = utils.utf8decode  -- Part of MUSHClient.


-- Characters outside of the ASCII or Latin-1 ranges will be normalized (replaced) with this character.
local INVALID_CHARACTER_REPLACEMENT = 0x3f  -- ?
-- Replacement table mapping Latin-1 characters (0xA0-0xFF) to ASCII equivalents.
local LATIN_CHARACTER_REPLACEMENTS = {
	[0xa0] = 0x20,  -- space
	[0xa1] = 0x21,  -- !
	[0xa2] = 0x63,  -- c
	[0xa3] = 0x4c,  -- L
	[0xa4] = 0x24,  -- $
	[0xa5] = 0x59,  -- Y
	[0xa6] = 0x7c,  -- |
	[0xa7] = 0x50,  -- P
	[0xa8] = 0x22,  -- "
	[0xa9] = 0x43,  -- C
	[0xaa] = 0x61,  -- a
	[0xab] = 0x3c,  -- <
	[0xac] = 0x2c,  -- ,
	[0xad] = 0x2d,  -- -
	[0xae] = 0x52,  -- R
	[0xaf] = 0x2d,  -- -
	[0xb0] = 0x64,  -- d
	[0xb1] = 0x2b,  -- +
	[0xb2] = 0x32,  -- 2
	[0xb3] = 0x33,  -- 3
	[0xb4] = 0x27,  -- '
	[0xb5] = 0x75,  -- u
	[0xb6] = 0x50,  -- P
	[0xb7] = 0x2a,  -- *
	[0xb8] = 0x2c,  -- ,
	[0xb9] = 0x31,  -- 1
	[0xba] = 0x6f,  -- o
	[0xbb] = 0x3e,  -- >
	[0xbc] = 0x34,  -- 4
	[0xbd] = 0x32,  -- 2
	[0xbe] = 0x33,  -- 3
	[0xbf] = 0x3f,  -- ?
	[0xc0] = 0x41,  -- A
	[0xc1] = 0x41,  -- A
	[0xc2] = 0x41,  -- A
	[0xc3] = 0x41,  -- A
	[0xc4] = 0x41,  -- A
	[0xc5] = 0x41,  -- A
	[0xc6] = 0x41,  -- A
	[0xc7] = 0x43,  -- C
	[0xc8] = 0x45,  -- E
	[0xc9] = 0x45,  -- E
	[0xca] = 0x45,  -- E
	[0xcb] = 0x45,  -- E
	[0xcc] = 0x49,  -- I
	[0xcd] = 0x49,  -- I
	[0xce] = 0x49,  -- I
	[0xcf] = 0x49,  -- I
	[0xd0] = 0x44,  -- D
	[0xd1] = 0x4e,  -- N
	[0xd2] = 0x4f,  -- O
	[0xd3] = 0x4f,  -- O
	[0xd4] = 0x4f,  -- O
	[0xd5] = 0x4f,  -- O
	[0xd6] = 0x4f,  -- O
	[0xd7] = 0x2a,  -- *
	[0xd8] = 0x4f,  -- O
	[0xd9] = 0x55,  -- U
	[0xda] = 0x55,  -- U
	[0xdb] = 0x55,  -- U
	[0xdc] = 0x55,  -- U
	[0xdd] = 0x59,  -- Y
	[0xde] = 0x54,  -- T
	[0xdf] = 0x73,  -- s
	[0xe0] = 0x61,  -- a
	[0xe1] = 0x61,  -- a
	[0xe2] = 0x61,  -- a
	[0xe3] = 0x61,  -- a
	[0xe4] = 0x61,  -- a
	[0xe5] = 0x61,  -- a
	[0xe6] = 0x61,  -- a
	[0xe7] = 0x63,  -- c
	[0xe8] = 0x65,  -- e
	[0xe9] = 0x65,  -- e
	[0xea] = 0x65,  -- e
	[0xeb] = 0x65,  -- e
	[0xec] = 0x69,  -- i
	[0xed] = 0x69,  -- i
	[0xee] = 0x69,  -- i
	[0xef] = 0x69,  -- i
	[0xf0] = 0x64,  -- d
	[0xf1] = 0x6e,  -- n
	[0xf2] = 0x6f,  -- o
	[0xf3] = 0x6f,  -- o
	[0xf4] = 0x6f,  -- o
	[0xf5] = 0x6f,  -- o
	[0xf6] = 0x6f,  -- o
	[0xf7] = 0x2f,  -- /
	[0xf8] = 0x6f,  -- o
	[0xf9] = 0x75,  -- u
	[0xfa] = 0x75,  -- u
	[0xfb] = 0x75,  -- u
	[0xfc] = 0x75,  -- u
	[0xfd] = 0x79,  -- y
	[0xfe] = 0x74,  -- t
	[0xff] = 0x79   -- y
}


function from_utf8(data)
	--[[
	Normalizes an input string to ASCII, handling both UTF-8 and Latin-1 encodings.

	Args:
		data: The input string to normalize.

	Returns:
		normalized_string: The ASCII-normalized string.
	--]]
	-- This function makes use of the MUSHClient API.
	-- Note that length will be nil if Latin-1.
	local length, err_col = utf8valid(data)
	if length == #data then
		-- Only ASCII characters were found, no need to convert.
		return data
	end
	local invalid_character_replacement = INVALID_CHARACTER_REPLACEMENT
	local decoded_bytes = length and utf8decode(data) or pack(string.byte(data, 1, -1))
	for i, ordinal in ipairs(decoded_bytes) do
		-- Don't replace if ordinal < 128, otherwise replace with corresponding replacement, or with default replacement.
		if ordinal >= 128 then
			decoded_bytes[i] = LATIN_CHARACTER_REPLACEMENTS[ordinal] or invalid_character_replacement
		end
	end
	return char(unpack(decoded_bytes))
end


function normalize(text)
	-- This function makes use of the MUSHClient API.
	return Trim(StripANSI(from_utf8(text)))
end


local __all__ = {
	["normalize"] = normalize,
	["from_utf8"] = from_utf8,
}

return __all__
