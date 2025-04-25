require ("mystdlib")
local json = require("dkjson").use_lpeg()


local GMCP_HANDLER_ID = "74f8c420df7d59ad5aa66246"

-- The packages we declare to support (name, version).
local SUPPORTED_PACKAGES = {
	["char"] = 1,
	["comm.channel"] = 1,
	["event"] = 1,
	["group"] = 1,
	["mmapper.comm"] = 1,
	["mpm"] = 1,
	["room"] = 1,
}

local MESSAGE_SUBSCRIPTIONS = {
	"char_name",
	"char_statusvars",
	"char_vitals",
	"comm_channel_list",
	"comm_channel_text",
	"event_darkness",
	"event_moon",
	"event_moved",
	"event_sun",
	"mmapper_comm_grouptell",
	"mpm_event",
	"mpm_message",
	"room_info",
	"room_updateexits",
}
local MESSAGE_SUBSCRIPTION_NAMES = table.invert(MESSAGE_SUBSCRIPTIONS)
local CLEAR_ON_NEW = table.set_create({MESSAGE_SUBSCRIPTION_NAMES["event_moved"], MESSAGE_SUBSCRIPTION_NAMES["room_info"]})


local function get_handler_id()
	return GMCP_HANDLER_ID
end


local function get_handler_name()
	return GetPluginInfo (GMCP_HANDLER_ID, 1)
end


local function get_supported_packages()
	return SUPPORTED_PACKAGES
end


local function id_to_name(id)
	return MESSAGE_SUBSCRIPTIONS[id]
end


local function name_to_id(name)
	return MESSAGE_SUBSCRIPTION_NAMES[string.lower(name)]
end


local function parse(cache_tbl, message_id, value)
	local is_valid_json, new_tbl = pcall(json.decode, value, 1, json.null)
	assert(is_valid_json, "Malformed JSON in GMCP data from server.")
	if CLEAR_ON_NEW[message_id] then
		table.clear(cache_tbl)
	end
	table.update(cache_tbl, json.null, new_tbl)
end



local __all__ = {
	["get_handler_id"] = get_handler_id,
	["get_handler_name"] = get_handler_name,
	["get_supported_packages"] = get_supported_packages,
	["parse"] = parse,
	["id_to_name"] = id_to_name,
	["name_to_id"] = name_to_id,
}

return __all__
