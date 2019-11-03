-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2019 Nick Stockton <https://github.com/nstockton>


local getch = require("getch")
local lfs = require("lfs")
local sha2 = require("sha2")
local stringy = require("stringy")

string.count = stringy.count
string.endswith = stringy.endswith
string.findpos = stringy.find
string.split = stringy.split
string.startswith = stringy.startswith
string.strip = stringy.strip

function printf(...)
	-- Prints a string formatted with format identifiers to standard output.
	-- Arguments to this function are first parsed by string.format and the result then passed to io.write, along with a trailing new-line character.
	io.output(io.stdout)
	io.write(string.format(...), "\n")
end

function url_quote(url)
	-- Replace non-supported characters in a string with their URL-encoded equivalents.
	local byte2hex = function (c) return bit and "%" .. bit.tohex(string.byte(c), -2) or string.format("%%%02X", string.byte(c)) end
	return string.gsub(url, "([^%w])", byte2hex)
end

function pause()
	-- Like the pause command in Windows batch script.
	io.write("Press any key to continue.")
	getch.getch()
	io.write("\n")
end

function os.type()
	local library_ext = package.cpath:match("%p[\\|/]?%p(%a+)")
	return library_ext == "dll" and "Windows" or library_ext == "so" and "Unix" or library_ext == "dylib" and "Darwin" or nil
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

function string.capitalize(str)
	-- Like the capitalize method on Python string objects
	return (string.lower(str):gsub("^%l", string.upper))
end

function string.isdigit(str)
	-- Like the isdigit method on Python string objects
	return string.match(str, "^%d+$") ~= nil
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

function table.addToSet(set, key)
	set[key] = true
end

function table.removeFromSet(set, key)
	set[key] = nil
end

function table.setContains(set, key)
	return set[key] ~= nil
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
	local index = false
	for i, value in ipairs(tbl) do
		if value == item then
			index = i
			break
		end
	end
	return index or nil
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

function get_script_path()
	return debug.getinfo(2, "S").short_src
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
