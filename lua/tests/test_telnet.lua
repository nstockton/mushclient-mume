-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2021 Nick Stockton <https://github.com/nstockton>


local lu = require("luaunit")
local Telnet = require("telnet")


local IAC = "\255"
local GA = "\249"
local CR = "\r"
local LF = "\n"
local NULL = "\0"
local SB = "\250"
local SE = "\240"
local WILL = "\251"
local WONT = "\252"
local DO = "\253"
local DONT = "\254"
local NEGOTIATION_BYTES = {
	[WILL] = true,
	[WONT] = true,
	[DO] = true,
	[DONT] = true,
}
local ECHO = "\1"


function test_escape_iac()
	local telnet = Telnet()
	lu.assertEquals(telnet:escape_iac("hello" .. IAC .. "world"), "hello" .. IAC .. IAC .. "world")
end


function test_encode_line_ends()
	local telnet = Telnet()
	lu.assertEquals(telnet:encode_line_ends("hello world" .. LF), "hello world" .. CR .. LF)
	lu.assertEquals(telnet:encode_line_ends("hello world" .. CR), "hello world" .. CR .. NULL)
end


function test_decode_line_ends()
	local telnet = Telnet()
	lu.assertEquals(telnet:decode_line_ends("hello world" .. CR .. LF), "hello world" .. LF)
	lu.assertEquals(telnet:decode_line_ends("hello world" .. CR .. NULL), "hello world" .. CR)
end


local function parse(data, state)
	local telnet = Telnet()
	local app_data_buffer = {}
	local mock_callback = function(data) 
		table.insert(app_data_buffer, data)
		return data
	end
	if state then
		telnet.state = state
	end
	local raw_output = telnet:parse(data, mock_callback)
	return {raw_output, table.concat(app_data_buffer), telnet.state}
end


function test_parse()
	local data = "Hello World!"
	-- 'data' state:
	lu.assertEquals(parse(data), {data, data, "data"})
	lu.assertEquals(parse(data .. IAC), {data, data, "command"})
	lu.assertEquals(parse(data .. CR), {data, data, "newline"})
	lu.assertEquals(parse(data .. CR .. LF), {data .. CR .. LF, data .. LF, "data"})
	lu.assertEquals(parse(data .. CR .. NULL), {data .. CR .. NULL, data .. CR, "data"})
	lu.assertEquals(parse(data .. CR .. IAC), {data .. CR .. NULL, data .. CR, "command"})
	-- 'command' and 'negotiation' states:
	lu.assertEquals(parse(data .. IAC .. IAC), {data .. IAC .. IAC, data .. IAC, "data"})
	lu.assertEquals(parse(data .. IAC .. GA), {data .. CR .. LF, data .. LF, "data"})
	lu.assertEquals(parse(data .. IAC .. SE), {data .. IAC .. SE, data, "data"})
	lu.assertEquals(parse(data .. IAC .. SB), {data, data, "subnegotiation"})
	for byte in pairs(NEGOTIATION_BYTES) do
		lu.assertEquals(parse(data .. IAC .. byte), {data, data, "negotiation"})
		lu.assertEquals(parse(data .. IAC .. byte .. ECHO), {data .. IAC .. byte .. ECHO, data, "data"})
	end
	lu.assertEquals(parse(data .. IAC .. NULL), {data .. IAC .. NULL, data, "data"})
	-- 'newline' state:
	-- This state is entered when a packet ends in CR (I.E. when new lines are broken over two packets).
	lu.assertEquals(parse(LF, "newline"), {CR .. LF, LF, "data"})
	lu.assertEquals(parse(NULL, "newline"), {CR .. NULL, CR, "data"})
	lu.assertEquals(parse(IAC, "newline"), {CR .. NULL, CR, "command"})
	lu.assertEquals(parse(IAC .. IAC, "newline"), {CR .. NULL .. IAC .. IAC, CR .. IAC, "data"})
	lu.assertEquals(parse(ECHO, "newline"), {CR .. NULL .. ECHO, CR .. ECHO, "data"})
	-- 'subnegotiation' state:
	lu.assertEquals(parse(data .. IAC .. SB .. IAC), {data, data, "subnegotiation-escaped"})
	lu.assertEquals(parse(data .. IAC .. SB .. "something"), {data, data, "subnegotiation"})
	-- 'subnegotiation-escaped' state:
	lu.assertEquals(parse(data .. IAC .. SB .. ECHO .. "something" .. IAC .. SE), {data .. IAC .. SB .. ECHO .. "something" .. IAC .. SE, data, "data"})
	lu.assertEquals(parse(data .. IAC .. SB .. ECHO .. "something" .. IAC .. IAC .. IAC .. SE), {data .. IAC .. SB .. ECHO .. "something" .. IAC .. IAC .. IAC .. SE, data, "data"})
	lu.assertEquals(parse(data .. IAC .. SB .. ECHO .. "something" .. CR .. NULL .. IAC .. SE), {data .. IAC .. SB .. ECHO .. "something" .. CR .. NULL .. IAC .. SE, data, "data"})
	-- Invalid state: This should never happen.
	lu.assertEquals(parse(data, "**junk**"), {data, data, "data"})
end


lu.LuaUnit.run()
