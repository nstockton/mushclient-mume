-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2019 Nick Stockton <https://github.com/nstockton>


local getch = require("getch")
local lfs = require("lfs")
local sha2 = require("sha2")


local PATTERN_ESCAPE_REPLACEMENTS = {
	["%"] = "%%",
	["("] = "%(",
	[")"] = "%)",
	["."] = "%.",
	["+"] = "%+",
	["-"] = "%-",
	["*"] = "%*",
	["?"] = "%?",
	["["] = "%[",
	["]"] = "%]",
	["^"] = "%^",
	["$"] = "%$",
	["\0"] = "%z",
}


-- For compatibility with Lua >= 5.2.
unpack = rawget(table, "unpack") or unpack
pack = rawget(table, "pack") or function(...) return {n = select("#", ...), ...} end
unpack_packed = function(tbl) return unpack(tbl, 1, tbl.n) end


function clamp(value, low, high)
	-- Returns low if value < low, high if value > high, or value if value >= low and value <= high.
	return value < low and low or high < value and high or value
end


function printf(...)
	-- Prints a string formatted with format identifiers to standard output.
	-- Arguments to this function are first parsed by string.format and the result then passed to io.write,
	-- along with a trailing new-line character.
	io.stdout:write(string.format(...), "\n")
end


function url_quote(url)
	-- Replace non-supported characters in a string with their URL-encoded equivalents.
	local function byte2hex(char)
		return bit and "%" .. bit.tohex(string.byte(char), -2) or string.format("%%%02X", string.byte(char))
	end
	local result = string.gsub(url, "([^%w])", byte2hex)
	return result
end


function pause()
	-- Like the pause command in Windows batch script.
	io.stdout:write("Press any key to continue.")
	getch.getch()
	io.stdout:write("\n")
end


function os.type()
	-- Returns the OS type ('Darwin', 'Unix', 'Windows').
	local library_ext = package.cpath:match("%p[\\|/]?%p(%a+)")
	return (
		library_ext == "dll" and "Windows"
		or library_ext == "so" and "Unix"
		or library_ext == "dylib" and "Darwin"
		or nil
	)
end


function architecture()
	-- Returns the processor architecture, as reported by Windows.
	assert(os.type() == "Windows", "Error: this script only supports Windows.")
	if os.getenv("PROCESSOR_ARCHITEW6432") then
		-- Running under a 32-bit process on 64-bit Windows.
		return os.getenv("PROCESSOR_ARCHITEW6432")
	elseif os.getenv("PROCESSOR_ARCHITECTURE") then
		-- Running under a 32-bit process on 32-bit Windows, or a 64-bit process on 64-bit Windows.
		return os.getenv("PROCESSOR_ARCHITECTURE")
	else
		return nil
	end
end


function get_flags(as_set)
	local flags = {}
	for i, argument in ipairs(arg) do
		if string.match(argument, "^[/-]+.+") then
			if as_set then
				flags[string.gsub(string.strip(string.lower(argument)), "^[/-]+", "")] = true
			else
				table.insert(flags, string.gsub(string.strip(string.lower(argument)), "^[/-]+", ""))
			end
		end
	end
	return flags
end


function os.fileSize(name)
	-- Returns the size of a file.
	return lfs.attributes(name, "size")
end


function os.isFile(name)
	if type(name) ~= "string" then
		return false
	end
	if not os.isDir(name) then
		return os.rename(name, name) and true or false
	end
	return false
end


function os.isFileOrDir(name)
	if type(name) ~= "string" then
		return false
	end
	return os.rename(name, name) and true or false
end


function os.isDir(name)
	if type(name) ~= "string" then
		return false
	end
	local cd = lfs.currentdir()
	local is = lfs.chdir(name) and true or false
	lfs.chdir(cd)
	return is
end


function string:capitalize()
	-- Like the capitalize method on Python string objects
	return (self:lower():gsub("^%l", string.upper))
end


function string:contains(pattern, is_plain)
	return (self:find(pattern, nil, is_plain ~= false)) and true or false
end


function string:count(pattern, is_plain)
	if is_plain ~= false then  -- Escape by default.
		pattern = string.pattern_safe(pattern)
	end
	return select(2, self:gsub(pattern, ""))
end


function string:endswith(end_str)
	return end_str == "" or self:sub(-string.len(end_str)) == end_str
end


function string:get_left(num)
	return self:sub(1, num)
end


function string:get_right(num)
	return self:sub(-num)
end


function string:isdigit()
	-- Like the isdigit method on Python string objects
	return self:match("^%d+$") ~= nil
end


function string:join(...)
	local result = {}
	local value
	for i = 1, select("#", ...) do
		value = select(i, ...)
		if value == nil then
			table.insert(result, "")
		else
			table.insert(result, tostring(value))
		end
	end
	return table.concat(result, self)
end


function string:lstrip(characters)
	characters = characters and ("[" .. string.pattern_safe(characters) .. "]") or "%s"
	return self:match("^" .. characters .. "*(.+)$") or self
end


function string:partition(pattern, is_plain)
	assert(pattern and pattern ~= "", "Empty pattern.")
	local start_pos, end_pos = self:find(pattern, nil, is_plain ~= false)
	if not start_pos then
		return self, "", ""
	end
	return self:sub(1, start_pos - 1), self:sub(start_pos, end_pos), self:sub(end_pos + 1)
end


function string:pattern_safe()
	return (self:gsub(".", PATTERN_ESCAPE_REPLACEMENTS))
end


function string:rstrip(characters)
	characters = characters and ("[" .. string.pattern_safe(characters) .. "]") or "%s"
	return self:match("^(.-)" .. characters .. "*$") or self
end


function string:simplify()
	return (self:gsub("%s+", " ")):strip()
end


function string:split(pattern, limit, is_plain)
	assert(pattern ~= "", "pattern must not be empty.")
	assert(limit == nil or type(limit) == "number", "Limit must be number or nil.")
	assert(is_plain == nil or type(is_plain) == "boolean", "is_plain must be boolean or nil.")
	local result = {}
	if self:len() > 0 then
		limit = limit or -1
		is_plain = is_plain ~= false  -- Default to true.
		if not pattern then
			-- Split words.
			pattern = "%s"
			is_plain = false
		end
		local field_start = 1
		local field_end = 1
		local found_start, found_end = self:find(pattern, field_start, is_plain)
		while found_start and limit ~= 0 do
			result[field_end] = self:sub(field_start, found_start - 1)
			field_end = field_end + 1
			field_start = found_end + 1
			found_start, found_end = self:find(pattern, field_start, is_plain)
			limit = limit - 1
		end
		result[field_end] = self:sub(field_start)
	end
	return result
end


function string:splitlines(keep_ends)
	local lines = {}
	for line, line_end in self:gmatch("([^\r\n]*)([\r]?[\n])") do
		table.insert(lines, line .. (keep_ends and line_end or ""))
	end
	local unterminated = self:match("[^\r\n]+$")
	if unterminated then
		table.insert(lines, unterminated)
	end
	return lines
end


function string:startswith(start_str)
	return self:sub(1, string.len(start_str)) == start_str
end


function string:strip(characters)
	characters = characters and ("[" .. string.pattern_safe(characters) .. "]") or "%s"
	return self:match("^" .. characters .. "*(.-)" .. characters .. "*$") or self
end


function table.isempty(tbl)
	return next(tbl) == nil
end


function table.slice(tbl, first, last)
	-- Like Python style list slicing, but inclusive.
	local size = #tbl
	if not first then
		first = 1
	elseif first < 0 then
		first = size + first + 1
	end
	if not last then
		last = size
	elseif last < 0 then
		last = size + last + 1
	end
	local newTbl = {}
	for i=first, last do
		table.insert(newTbl, tbl[i])
	end
	return newTbl
end


function table.invert(tbl)
	local result = {}
	for key, value in pairs(tbl) do
		result[value] = key
	end
	return result
end


function table.update(tbl, nil_value, ...)
	-- Updates a table in-place with values from tables passed as variable arguments.
	-- nil_value specifies an optional sentinel value that will be replaced with nil in the returned table (useful in conjunction with a json library or similar).
	-- https://stackoverflow.com/questions/1283388/how-to-merge-two-tables-overwriting-the-elements-which-are-in-both
	local new
	for i = 1, select("#", ...) do
		new = select(i, ...)
		for key, value in pairs(new) do
			if (type(value) == "table") and (type(tbl[key] or false) == "table") then
				table.update(tbl[key], nil_value, new[key])
			elseif value == nil_value then
				tbl[key] = nil
			else
				tbl[key] = value
			end
		end
	end
end


function table.set_create(tbl)
	local result = {}
	for _, item in ipairs(tbl) do
		result[item] = true
	end
	return result
end


function table.set_add(set, key)
	set[key] = true
end


function table.set_remove(set, key)
	set[key] = nil
end


function table.uniqueItems(tbl)
	local uniqueSet = {}
	local uniqueKey = ""
	local outputTbl = {}
	for key, value in ipairs(tbl) do
		if type(value) == "string" then
			uniqueKey = value
		elseif type(value) == "table" then
			uniqueKey = table.concat(value, "\0")
		else
			uniqueKey = tostring(value)
		end
		if uniqueSet[uniqueKey] == nil then
			uniqueSet[uniqueKey] = true
			table.insert(outputTbl, value)
		end
	end
	return outputTbl
end


function table.index(tbl, item)
	for i, value in ipairs(tbl) do
		if value == item then
			return i
		end
	end
end


function table.count(tbl, item)
	local count = 0
	for i, value in ipairs(tbl) do
		if value == item then
			count = count + 1
		end
	end
	return count
end


function table.clear(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end


function table.keys(tbl)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end


function table.values(tbl)
	local values = {}
	for _, value in pairs(tbl) do
		table.insert(values, value)
	end
	table.sort(values)
	return values
end


function get_script_path()
	return debug.getinfo(2, "S").short_src
end


function spairs(t, order)
	-- https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
	-- Collect the keys.
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	-- If order function given, sort by it by passing the table and keys a, b, otherwise just sort the keys.
	if order then
		table.sort(keys, function(a, b) return order(t, a, b) end)
	else
		table.sort(keys)
	end
	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end


function bool(item)
	--[[
	Behaves like the `bool` function in Python.

	Args:
		item (nil | boolean | number | string | table): The item to be evaluated.

	Returns:
		boolean: false if item is nil, false, 0, empty string, or empty table, true otherwise.
	--]]
	return (
		item and item ~= 0 and item ~= "" and (type(item) ~= "table" or not table.isempty(item)) and true
		or false
	)
end


function int(number)
	local integral, fractional = math.modf(number)
	return integral
end


function len(item)
	if type(item) == "string" then
		return string.len(item)
	elseif type(item) == "table" then
		local keys = {}
		for key, value in pairs(item) do
			table.insert(keys, key)
		end
		return table.getn(keys)
	end
end


function timeit(loops, func, ...)
	-- Time execution of a function.
	local start = os.clock()
	for i = 1, loops do
		func(...)
	end
	return os.clock() - start
end


local function _shasum_file(hasher, file_name, block_size)
	local block_size = block_size or 2 ^ 16
	local file = assert(io.open(file_name, "rb"))
	for block in file:lines(block_size) do
		hasher(block)
	end
	file:close()
	return string.gsub(hasher(), ".", function(c) return bit.tohex(string.byte(c), 2) end)
end


sha1sum_file = function (...) return _shasum_file(sha2.sha1_digest(), ...) end
sha224sum_file = function (...) return _shasum_file(sha2.sha224_digest(), ...) end
sha256sum_file = function (...) return _shasum_file(sha2.sha256_digest(), ...) end
sha384sum_file = function (...) return _shasum_file(sha2.sha384_digest(), ...) end
sha512sum_file = function (...) return _shasum_file(sha2.sha512_digest(), ...) end
