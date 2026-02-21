-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2026 Nick Stockton <https://github.com/nstockton>


local ffi = require("ffi")
local crypt32 = ffi.load("Crypt32")

ffi.cdef[[
	typedef unsigned long DWORD;
	typedef unsigned char BYTE;
	typedef int BOOL;

	BOOL CryptBinaryToStringA(
		const BYTE *pbBinary,
		DWORD cbBinary,
		DWORD dwFlags,
		char *pszString,
		DWORD *pcchString
	);

	BOOL CryptStringToBinaryA(
		const char *pszString,
		DWORD cchString,
		DWORD dwFlags,
		BYTE *pbBinary,
		DWORD *pcbBinary,
		DWORD *pdwSkip,
		DWORD *pdwFlags
	);
]]

-- Constants for base64 encoding/decoding.
local CRYPT_STRING_BASE64 = 0x00000001
local CRYPT_STRING_NOCRLF = 0x40000000

function decode(b64str)
	if type(b64str) ~= "string" then
		return nil, "expected string"
	elseif b64str == "" then
		return ""
	end
	local len = #b64str
	local bufLen = ffi.new("DWORD[1]", 0)
	-- Calculate buffer size needed.
	if crypt32.CryptStringToBinaryA(b64str, len, CRYPT_STRING_BASE64, nil, bufLen, nil, nil) == 0 then
		return nil, "size query failed"
	end
	local buffer = ffi.new("BYTE[?]", bufLen[0])
	-- Perform decoding.
	if crypt32.CryptStringToBinaryA(b64str, len, CRYPT_STRING_BASE64, buffer, bufLen, nil, nil) == 0 then
		return nil, "decoding failed"
	end
	return ffi.string(buffer, bufLen[0])
end

function encode(str)
	if type(str) ~= "string" then
		return nil, "expected string"
	elseif str == "" then
		return ""
	end
	local len = #str
	local bufLen = ffi.new("DWORD[1]", 0)
	-- Calculate buffer size needed.
	if crypt32.CryptBinaryToStringA(str, len, CRYPT_STRING_BASE64 + CRYPT_STRING_NOCRLF, nil, bufLen) == 0 then
		return nil, "size query failed"
	end
	local buffer = ffi.new("char[?]", bufLen[0])
	-- Perform encoding.
	if crypt32.CryptBinaryToStringA(str, len, CRYPT_STRING_BASE64 + CRYPT_STRING_NOCRLF, buffer, bufLen) == 0 then
		return nil, "encoding failed"
	end
	return ffi.string(buffer, bufLen[0])
end

return {
	["decode"] = decode,
	["encode"] = encode,
}
