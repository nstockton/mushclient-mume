-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

require("lfs")
stringy = require("stringy")

string.count = stringy.count
string.endswith = stringy.endswith
string.findpos = stringy.find
string.split = stringy.split
string.startswith = stringy.startswith
string.strip = stringy.strip

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
