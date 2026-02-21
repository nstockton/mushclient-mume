require("mystdlib")
local base64 = require("base64")
local getch = require("getch")
local json = require("dkjson")
local lfs = require("lfs")


local APP_NAME = "Mapper Proxy"
local SCRIPT_VERSION = "1.2"
local GITHUB_USER = "nstockton"
local REPO = "mapperproxy-mume"
local RELEASE_INFO_FILE = "update_info.ignore"
local ZIP_FILE = "mapper_proxy.zip"
local SYSTEM32_PATH = os.path_join(os.getenv("WINDIR"), "System32")
local CURL_PATH = os.path_join(SYSTEM32_PATH, "curl.exe")
local TAR_PATH = os.path_join(SYSTEM32_PATH, "tar.exe")
local XCOPY_PATH = os.path_join(SYSTEM32_PATH, "xcopy.exe")

local HELP_TEXT = [[
-h, --help:	Display this help.
]]


assert(os.isDir(SYSTEM32_PATH))
assert(os.isFile(CURL_PATH))
assert(os.isFile(TAR_PATH))
assert(os.isFile(XCOPY_PATH))


local function rm_tree(directory_path)
	if os.isDir(directory_path) then
		os.execute(string.format('rd /S /Q "%s"', directory_path))
	end
end


local function rm_file(file_path)
	if os.isFile(file_path) then
		os.remove(file_path)
	end
end


local function get_url(url, output_path)
	local command = {}
	table.insert(command, string.format('%s --silent --location --retry 999 --retry-max-time 0 --continue-at -', CURL_PATH))
	if output_path then
		table.insert(command, string.format('--output "%s"', output_path))
	end
	table.insert(command, string.format('"%s"', url))
	local handle = assert(io.popen(table.concat(command, " "), "rb"))
	local result = handle:read("*all")
	handle:close()
	if output_path then
		return os.fileSize(output_path)
	end
	return result
end


local function get_last_info()
	-- Return the previously stored release information as a table.
	if os.isFile(RELEASE_INFO_FILE) then
		local handle = assert(io.open(RELEASE_INFO_FILE, "rb"))
		local release_data, pos, err = json.decode(handle:read("*all"), 1, nil)
		handle:close()
		return assert(release_data, err)
	else
		return {}
	end
end


local function save_last_info(tbl)
	-- Encode the release information in tbl to JSon, and save it to a file.
	local data = string.gsub(json.encode(tbl, {indent=true, level=0, keyorder=table.keys(tbl)}), "\r?\n", "\r\n")
	local handle = assert(io.open(RELEASE_INFO_FILE, "wb"))
	handle:write(data)
	handle:close()
end


local function get_checksum(url)
	local result = string.lower(string.strip(get_url(url)))
	local hash = assert(string.match(result, "^([0-9a-f]+).+%.zip$"), string.format("Invalid checksum '%s'", result))
	return hash
end


local function get_latest_github()
	local project_url = string.format("https://api.github.com/repos/%s/%s/releases/latest", GITHUB_USER, REPO)
	local gh, pos, err = json.decode(get_url(project_url), 1, nil)
	assert(gh, err)
	local release_data = {}
	release_data.provider = "github"
	release_data.status = "success"
	release_data.tag_name = assert(gh.tag_name, "Error: 'tag_name' not in retrieved data.")
	assert(gh.assets, "Error: 'assets' not in retrieved data.")
	for i, asset in ipairs(gh.assets) do
		assert(asset.name, "Error: 'name' not in 'asset'.")
		if string.startswith(asset.name, "Mapper_Proxy_V") and string.endswith(asset.name, ".zip") then
			release_data.download_url = assert(asset.browser_download_url, "Error: 'browser_download_url' not in 'asset'.")
			release_data.size = assert(asset.size, "Error: 'size' not in 'asset'.")
			release_data.updated_at = assert(asset.updated_at, "Error: 'updated_at' not in 'asset'.")
		elseif string.startswith(asset.name, "Mapper_Proxy_V") and string.endswith(asset.name, ".zip.sha256") then
			release_data.sha256 = get_checksum(assert(asset.browser_download_url, "Error: 'browser_download_url' not in 'asset'."))
		end
	end
	return release_data
end


local function prompt_for_update()
	io.write("Update now? (Y to update, N to skip this release in future, Q to exit and do nothing) ")
	local response = string.lower(string.strip(getch.getch()))
	io.write("\n")
	local valid_responses = table.set("y", "n", "q")
	if valid_responses[response] then
		return response
	elseif response ~= "" then
		print("Invalid response. Please try again.")
	end
	return prompt_for_update()
end


local function do_download(release)
	printf("Downloading %s %s (%s) from GitHub.", APP_NAME, release.tag_name, release.updated_at)
	local downloaded_size = assert(get_url(release.download_url, ZIP_FILE))
	-- If GitHub for some reason did not send file size, release.size should be 0.
	assert(release.size > 0 and release.size == downloaded_size, "Error downloading release: Downloaded file size and reported size from GitHub do not match.")
	printf("Verifying download.")
	if sha256sum_file(ZIP_FILE) == release.sha256 then
		save_last_info(release)
		printf("OK.")
		return true
	else
		printf("Error: checksums do not match. Aborting.")
		rm_file(ZIP_FILE)
		return false
	end
end


local function do_extract()
	local pwd = lfs.currentdir()
	printf("Extracting files.")
	rm_tree("tempmapper")
	lfs.mkdir(os.path_join(pwd, "tempmapper"))
	os.execute(string.format('%s -xf "%s" --directory "tempmapper"', TAR_PATH, ZIP_FILE))
	rm_file(ZIP_FILE)
	assert(lfs.chdir(os.path_join(pwd, "tempmapper")))
	local copy_from
	for item in lfs.dir(lfs.currentdir()) do
		if lfs.attributes(item, "mode") == "directory" and string.startswith(string.lower(item), "mapper_proxy") then
			copy_from = os.path_join("tempmapper", item)
			break
		end
	end
	lfs.chdir(pwd)
	os.execute(string.format('%s "%s" "mapper_proxy" /E /V /I /Q /R /Y', XCOPY_PATH, copy_from))
	rm_tree("tempmapper")
	printf("Done.")
end


local function called_by_script()
	return get_flags(true)["calledbyscript"] or false
end


local function needs_help()
	local flags = get_flags(true)
	return flags["help"] or flags["h"] or flags["?"] or false
end


local function needs_script_update()
	local flags = get_flags(true)
	return flags["update"] or flags["u"] or false
end


local function script_update()
	local project_url = string.format("https://api.github.com/repos/%s/mushclient-mume/contents/update_checker.lua?ref=master", GITHUB_USER)
	local script_path = assert(get_script_path(), "Error: Unable to retrieve path of the updater script.")
	assert(os.isFile(script_path), string.format("Error: '%s' is not a file.", script_path))
	local script_size = assert(os.fileSize(script_path))
	local handle = assert(io.open(script_path, "rb"))
	local script_data = assert(handle:read("*all"), string.format("Error: Unable to read data from '%s'.", script_path))
	handle:close()
	local gh, pos, err = json.decode(get_url(project_url), 1, nil)
	assert(gh, err)
	-- GitHub might return an error message if the path was invalid, ETC.
	assert(gh.encoding and gh.content and gh.size, gh.message or "Error: unknown data returned.")
	assert(gh.size > 0, "Error: reported size by GitHub is 0.")
	assert(gh.encoding == "base64", string.format("Error: unknown encoding '%s', should be 'base64'.", gh.encoding))
	local content, err = base64.decode(gh.content)
	assert(content, err)
	assert(string.len(content) == gh.size, "Error: size of retrieved content and reported size by GitHub do not match.")
	if script_data ~= content then
		local handle = assert(io.open(script_path, "wb"))
		handle:write(content)
		handle:close()
		printf("The update script has been successfully updated.")
	elseif not called_by_script() then
		printf("The update script is up to date.")
	end
end


local last = get_last_info()


if needs_help() then
	printf("%s Updater V%s.", APP_NAME, SCRIPT_VERSION)
	printf(HELP_TEXT)
	os.exit(0)
elseif needs_script_update() then
	script_update()
	os.exit(0)
end


-- Clean up previously left junk.
rm_file(ZIP_FILE)
rm_tree("tempmapper")


local latest = get_latest_github()


if os.isDir("mapper_proxy") and not called_by_script() then
	printf("Checking for updates to %s.", APP_NAME)
end
if latest.status ~= "success" then
	printf("Error: unable to update at this time. Please try again in a few minutes.")
	printf("Build status returned by the server was (%s).", latest.status or "unknown")
	os.exit(1)
elseif not os.isDir("mapper_proxy") then
	printf("%s not found. This is normal for new installations.", APP_NAME)
	if do_download(latest) then
		do_extract()
	end
elseif last.skipped_release and last.skipped_release == latest.tag_name .. latest.sha256 then
	printf("The update to %s (%s) dated %s from GitHub was previously skipped.", APP_NAME, latest.tag_name, latest.updated_at)
	if called_by_script() then
		os.exit(0)
	end
elseif last.tag_name and last.sha256 and last.tag_name .. last.sha256 == latest.tag_name .. latest.sha256 then
	printf("You are currently running the latest %s (%s) dated %s from GitHub.", APP_NAME, latest.tag_name, latest.updated_at)
	if called_by_script() then
		os.exit(0)
	end
else
	printf("A new version of %s (%s) dated %s from GitHub was found.", APP_NAME, latest.tag_name, latest.updated_at)
	local user_choice = prompt_for_update()
	if user_choice == "y" then
		if do_download(latest) then
			do_extract()
		end
	elseif user_choice == "n" then
		printf("You will no longer be prompted to download this version of %s.", APP_NAME)
		last.skipped_release = latest.tag_name .. latest.sha256
		save_last_info(last)
	end
end


pause()
os.exit(0)
