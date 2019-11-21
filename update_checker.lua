require("mystdlib")
local base64 = require("ee5_base64")
local getch = require("getch")
local json = require("dkjson")
local lfs = require("lfs")


local APP_NAME = "Mapper Proxy"
local SCRIPT_VERSION = "1.1"
local GITHUB_USER = "nstockton"
local APPVEYOR_USER = "NickStockton"
local REPO = "mapperproxy-mume"
local RELEASE_INFO_FILE = "update_info.ignore"
local ZIP_FILE = "mapper_proxy.zip"

local HELP_TEXT = [[
-h, --help:	Display this help.
-release, -dev:	 Specify whether the latest stable release from GitHub should be used, or the latest development build from AppVeyor (defaults to release).
]]


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
	local ordered_keys = {}
	for k, v in pairs(tbl) do
		table.insert(ordered_keys, k)
	end
	table.sort(ordered_keys)
	local data = string.gsub(json.encode(tbl, {indent=true, level=0, keyorder=ordered_keys}), "\r?\n", "\r\n")
	local handle = assert(io.open(RELEASE_INFO_FILE, "wb"))
	handle:write(data)
	handle:close()
end


local function get_checksum(url)
	local handle = assert(io.popen(string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", url)))
	local result = string.lower(string.strip(handle:read("*all")))
	handle:close()
	local hash = assert(string.match(result, "^([0-9a-f]+).+%.zip$"), string.format("Invalid checksum '%s'", result))
	return hash
end


local function _get_latest_github()
	local project_url = string.format("https://api.github.com/repos/%s/%s/releases/latest", GITHUB_USER, REPO)
	local command = string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", project_url)
	local handle = assert(io.popen(command))
	local gh, pos, err = json.decode(handle:read("*all"), 1, nil)
	handle:close()
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


local function _get_latest_appveyor()
	local project_url = string.format("https://ci.appveyor.com/api/projects/%s/%s", APPVEYOR_USER, REPO)
	local command = string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", project_url)
	local handle = assert(io.popen(command))
	local av, pos, err = json.decode(handle:read("*all"), 1, nil)
	handle:close()
	assert(av, err)
	local release_data = {}
	release_data.provider = "appveyor"
	release_data.size = nil
	assert(av.build, "Error: 'build' not in retrieved data.")
	release_data.status = assert(av.build.status, "Error: 'status' not in 'build'.")
	assert(type(av.build.isTag) ~= "nil", "Error: 'isTag' not in 'build'.")
	if release_data.status == "success" and av.build.isTag then
		assert(av.build.version, "Error: 'version' not in 'build'.")
		release_data.tag_name = string.match(av.build.version, "^[vV]([%d.]+[-]%w+)")
		release_data.tag_name = string.gsub(release_data.tag_name, "-", "_")
		release_data.updated_at = assert(av.build.updated, "Error: 'updated' not in 'build'.")
		assert(av.build.jobs, "Error: 'jobs' not in 'build'.")
		for i, job in ipairs(av.build.jobs) do
			assert(job.status, "Error: 'status' not in job.")
			if job.status == "success" then
				assert(av.build.branch, "Error: 'branch' not in 'build'.")
				release_data.download_url = string.format("%s/artifacts/Mapper_Proxy_V%s.zip?branch=master", project_url, release_data.tag_name)
				release_data.sha256 = get_checksum(string.format("%s/artifacts/Mapper_Proxy_V%s.zip.sha256?branch=master", project_url, release_data.tag_name))
			end
		end
	else
		release_data.updated_at = assert(av.build.updated, "Error: 'updated' not in 'build'.")
		release_data.tag_name = "master"
		release_data.download_url = string.format("%s/artifacts/MapperProxy.zip?branch=master&pr=false", project_url)
		release_data.sha256 = get_checksum(string.format("%s/artifacts/MapperProxy.zip.sha256?branch=master&pr=false", project_url))
	end
	return release_data
end


local function prompt_for_update()
	io.write("Update now? (Y to update, N to skip this release in future, Q to exit and do nothing) ")
	local response = string.lower(string.strip(getch.getch()))
	io.write("\n")
	if response == "" then
		return prompt_for_update()
	elseif response == "y" then
		return "y"
	elseif response == "n" then
		return "n"
	elseif response == "q" then
		return "q"
	else
		print("Invalid response. Please try again.")
		return prompt_for_update()
	end
end


local function do_download(release)
	printf("Downloading %s %s (%s) from %s.", APP_NAME, release.tag_name, release.updated_at, release.provider == "github" and "GitHub" or release.provider == "appveyor" and "AppVeyor" or string.capitalize(release.provider))
	os.execute(string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - --output %s \"%s\"", ZIP_FILE, release.download_url))
	local downloaded_size = assert(os.fileSize(ZIP_FILE))
	-- release.size should be nil if the provider's API doesn't support retrieving file size.
	-- If the provider does support retrieving file size, but for some reason did not send it, release.size should be 0.
	assert(not release.size or downloaded_size and downloaded_size > 0 and downloaded_size == release.size, "Error downloading release: Downloaded file size and reported size from provider API do not match.")
	printf("Verifying download.")
	if sha256sum_file(ZIP_FILE) == release.sha256 then
		save_last_info(release)
		printf("OK.")
		return true
	else
		printf("Error: checksums do not match. Aborting.")
		if os.isFile(ZIP_FILE) then
			os.remove(ZIP_FILE)
		end
		return false
	end
end


local function do_extract()
	local pwd = lfs.currentdir()
	printf("Extracting files.")
	os.execute(string.format("unzip.exe -qq \"%s\" -d \"tempmapper\"", ZIP_FILE))
	if os.isFile(ZIP_FILE) then
		os.remove(ZIP_FILE)
	end
	assert(lfs.chdir(pwd .. "\\tempmapper"))
	local copy_from
	for item in lfs.dir(lfs.currentdir()) do
		if lfs.attributes(item, "mode") == "directory" and string.startswith(string.lower(item), "mapper_proxy_v") then
			copy_from = string.format("tempmapper\\%s", item)
			break
		end
	end
	lfs.chdir(pwd)
	os.execute(string.format("xcopy \"%s\" \"mapper_proxy\" /E /V /I /Q /R /Y", copy_from))
	os.execute("rd /S /Q \"tempmapper\"")
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
	local command = string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", project_url)
	local handle = assert(io.popen(command))
	local gh, pos, err = json.decode(handle:read("*all"), 1, nil)
	handle:close()
	assert(gh, err)
	-- GitHub might return an error message if the path was invalid, ETC.
	assert(gh.encoding and gh.content and gh.size, gh.message or "Error: unknown data returned.")
	assert(gh.encoding == "base64", string.format("Error: unknown encoding '%s', should be 'base64'.", gh.encoding))
	local content = base64.decode(gh.content)
	assert(gh.size > 0, "Error: reported size by GitHub is 0.")
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


local function get_latest_info(last_provider)
	local flags = get_flags(true)
	local use_github = flags["release"]
	local use_appveyor = flags["dev"] or flags["devel"] or flags["development"]
	assert(not (use_github and use_appveyor), "Error: release and development are mutually exclusive.")
	local provider = use_github and "github" or use_appveyor and "appveyor" or last_provider or "github"
	if provider == "github" then
		return _get_latest_github()
	elseif provider == "appveyor" then
		return _get_latest_appveyor()
	else
		assert(nil, string.format("Invalid provider: '%s'.", provider))
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
if os.isFile(ZIP_FILE) then
	os.remove(ZIP_FILE)
end
if os.isDir("tempmapper") then
	os.execute("rd /S /Q \"tempmapper\"")
end


local latest = get_latest_info(last.provider)


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
	printf("The update to %s (%s) dated %s from %s was previously skipped.", APP_NAME, latest.tag_name, latest.updated_at, latest.provider == "github" and "GitHub" or latest.provider == "appveyor" and "AppVeyor" or string.capitalize(latest.provider))
	if called_by_script() then
		os.exit(0)
	end
elseif last.tag_name and last.sha256 and last.tag_name .. last.sha256 == latest.tag_name .. latest.sha256 then
	printf("You are currently running the latest %s (%s) dated %s from %s.", APP_NAME, latest.tag_name, latest.updated_at, latest.provider == "github" and "GitHub" or latest.provider == "appveyor" and "AppVeyor" or string.capitalize(latest.provider))
	if called_by_script() then
		os.exit(0)
	end
else
	printf("A new version of %s (%s) dated %s from %s was found.", APP_NAME, latest.tag_name, latest.updated_at, latest.provider == "github" and "GitHub" or latest.provider == "appveyor" and "AppVeyor" or string.capitalize(latest.provider))
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
