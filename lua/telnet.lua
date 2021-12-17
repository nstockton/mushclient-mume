-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2021 Nick Stockton <https://github.com/nstockton>


require("mystdlib")


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
local ENCODE_LINE_END_REPLACEMENTS = {
	[LF] = CR .. LF,
	[CR] = CR .. NULL,
}
local DECODE_LINE_END_REPLACEMENTS = {
	[CR .. LF] = LF,
	[CR .. NULL] = CR,
}


local Telnet = {} -- Class.
	setmetatable(Telnet, {__call = function() return Telnet:__init__() end})

	function Telnet.__init__(parent)
		local self = setmetatable({}, {__index = parent})
		self.state = "data"
		self.negotiation_command = ""
		self.subnegotiation_data = {}
		return self
	end

	function Telnet.escape_iac(self, data)
		data = string.gsub(data, IAC, IAC .. IAC)
		return data
	end

	function Telnet.encode_line_ends(self, data)
		data = string.gsub(data, "[\r\n]", ENCODE_LINE_END_REPLACEMENTS)
		return data
	end

	function Telnet.decode_line_ends(self, data)
		data = string.gsub(data, "[\r].", DECODE_LINE_END_REPLACEMENTS)
		return data
	end

	function Telnet.parse(self, data, app_data_callback)
		local state = self.state
		local output_buffer = {}
		local app_data_buffer = {}
		while data ~= "" do
			if state == "data" then
				local app_data, separator
				app_data, separator, data = string.partition(data, IAC)
				if separator ~= "" then
					state = "command"
				elseif string.endswith(app_data, CR) then
					state = "newline"
					app_data = string.sub(app_data, 1, -2) -- Delete CR from the end.
				end
				table.insert(app_data_buffer, self:decode_line_ends(app_data))
			else
				local byte = string.sub(data, 1, 1) -- The first byte of data.
				data = string.sub(data, 2) -- Delete the first byte.
				if state == "command" then
					if byte == IAC then
						-- Escaped IAC.
						state = "data"
						table.insert(app_data_buffer, byte)
					elseif byte == GA then
						state = "data"
						table.insert(app_data_buffer, LF)
					elseif byte == SB then
						state = "subnegotiation"
					elseif NEGOTIATION_BYTES[byte] then
						state = "negotiation"
						self.negotiation_command = byte
					else
						-- unhandled command.
						state = "data"
						if not table.isempty(app_data_buffer) then
							table.insert(output_buffer, self:escape_iac(app_data_callback(table.concat(app_data_buffer))))
							table.clear(app_data_buffer)
						end
						table.insert(output_buffer, IAC .. byte)
					end
				elseif state == "negotiation" then
					state = "data"
					if not table.isempty(app_data_buffer) then
						table.insert(output_buffer, self:escape_iac(app_data_callback(table.concat(app_data_buffer))))
						table.clear(app_data_buffer)
					end
					table.insert(output_buffer, IAC .. self.negotiation_command .. byte)
					self.negotiation_command = ""
				elseif state == "newline" then
					state = "data"
					if byte == LF then
						table.insert(app_data_buffer, byte)
					elseif byte == NULL then
						table.insert(app_data_buffer, CR)
					elseif byte == IAC then
						-- A properly implemented Telnet server should never send IAC CR, but just in case.
						state = "command"
						table.insert(app_data_buffer, CR)
					else
						-- A properly implemented Telnet server should always send either LF or NULL after a CR, but just in case.
						table.insert(app_data_buffer, CR .. byte)
					end
				elseif state == "subnegotiation" then
					if byte == IAC then
						state = "subnegotiation-escaped"
					else
						table.insert(self.subnegotiation_data, byte)
					end
				elseif state == "subnegotiation-escaped" then
					if byte == SE then
						-- End of subnegotiation.
						state = "data"
						if not table.isempty(app_data_buffer) then
							table.insert(output_buffer, self:escape_iac(app_data_callback(table.concat(app_data_buffer))))
							table.clear(app_data_buffer)
						end
						table.insert(output_buffer, IAC .. SB .. self:escape_iac(table.concat(self.subnegotiation_data)) .. IAC .. SE)
						table.clear(self.subnegotiation_data)
					else
						state = "subnegotiation"
						table.insert(self.subnegotiation_data, byte)
					end
				else
					-- Invalid Telnet state. This should be impossible to reach.
					state = "data"
					table.insert(app_data_buffer, byte)
				end
			end
		end -- while
		if not table.isempty(app_data_buffer) then
			table.insert(output_buffer, self:escape_iac(app_data_callback(table.concat(app_data_buffer))))
			table.clear(app_data_buffer)
		end
		self.state = state
		return self:encode_line_ends(table.concat(output_buffer))
	end
-- end class Telnet


return Telnet
