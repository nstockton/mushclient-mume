-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- Copyright (C) 2023 Nick Stockton <https://github.com/nstockton>


require("mystdlib")
local lu = require("luaunit")


function test_clamp()
	lu.assertEquals(clamp(1, 2, 10), 2)
	lu.assertEquals(clamp(11, 2, 10), 10)
	for i = 2, 10, 1 do
		lu.assertEquals(clamp(i, 2, 10), i)
	end
end


function test_url_quote()
	lu.assertEquals(url_quote("https://google.com"), "https%3A%2F%2Fgoogle%2Ecom")
end


function test_string_capitalize()
	lu.assertEquals(string.capitalize("hello WORLD"), "Hello world")
end


function test_string_endswith()
	lu.assertTrue(string.endswith("hello", ""))
	lu.assertTrue(string.endswith("hello", "lo"))
	lu.assertFalse(string.endswith("hello", "x"))
end


function test_string_get_left()
	lu.assertEquals(string.get_left("hello", 2), "he")
end


function test_string_get_right()
	lu.assertEquals(string.get_right("hello", 2), "lo")
end


function test_string_isdigit()
	lu.assertFalse(string.isdigit(""))
	lu.assertFalse(string.isdigit("123.45"))
	lu.assertTrue(string.isdigit("12345"))
end


function test_string_lstrip()
	lu.assertEquals(string.lstrip(" \thello\t "), "hello\t ")
	lu.assertEquals(string.lstrip(" \thello\t ", " "), "\thello\t ")
	lu.assertEquals(string.lstrip(" \thello\t ", "\t "), "hello\t ")
end


function test_string_partition()
	local before, delimiter, after = string.partition("hello", "l")
	lu.assertEquals(before, "he")
	lu.assertEquals(delimiter, "l")
	lu.assertEquals(after, "lo")
	local before, delimiter, after = string.partition("he\tlo", "%s", false)
	lu.assertEquals(before, "he")
	lu.assertEquals(delimiter, "\t")
	lu.assertEquals(after, "lo")
end


function test_string_pattern_safe()
	lu.assertEquals(string.pattern_safe("hello?"), "hello%?")
end


function test_string_removeprefix()
	lu.assertEquals(string.removeprefix("hello", "he"), "llo")
	lu.assertEquals(string.removeprefix("hello", "xx"), "hello")
	lu.assertEquals(string.removeprefix("hello", ""), "hello")
end


function test_string_removesuffix()
	lu.assertEquals(string.removesuffix("hello", "lo"), "hel")
	lu.assertEquals(string.removesuffix("hello", "xx"), "hello")
	lu.assertEquals(string.removesuffix("hello", ""), "hello")
end


function test_string_rstrip()
	lu.assertEquals(string.rstrip(" \thello\t "), " \thello")
	lu.assertEquals(string.rstrip(" \thello\t ", " "), " \thello\t")
	lu.assertEquals(string.rstrip(" \thello\t ", " \t"), " \thello")
end


function test_string_simplify()
	lu.assertEquals(string.simplify(" \the\tllo\t "), "he llo")
end


function test_string_startswith()
	lu.assertTrue(string.startswith("hello", ""))
	lu.assertTrue(string.startswith("hello", "he"))
	lu.assertFalse(string.startswith("hello", "x"))
end


function test_string_strip()
	lu.assertEquals(string.strip(" \thello\t "), "hello")
	lu.assertEquals(string.strip(" \thello\t ", " "), "\thello\t")
	lu.assertEquals(string.strip(" \thello\t ", " \t"), "hello")
end


lu.LuaUnit.run()
