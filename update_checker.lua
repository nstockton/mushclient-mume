require("mystdlib")
local getch = require("getch")
local json = require("dkjson")
local lfs = require("lfs")

local APP_NAME = "Mapper Proxy"
local SCRIPT_VERSION = "1.0"
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
	local release_data = {}
	if os.isFile(RELEASE_INFO_FILE) then
		local fileObj = io.open(RELEASE_INFO_FILE, "rb")
		release_data = json.decode(fileObj:read("*all"), 1, nil)
		fileObj:close()
	end
	return release_data
end

local function save_last_info(tbl)
	-- Encode the release information in tbl to JSon, and save it to a file.
	local ordered_keys = {}
	for k, v in pairs(tbl) do
		table.insert(ordered_keys, k)
	end
	table.sort(ordered_keys)
	local data = string.gsub(json.encode(tbl, {indent=true, level=0, keyorder=ordered_keys}), "\r?\n", "\r\n")
	local handle = io.open(RELEASE_INFO_FILE, "wb")
	handle:write(data)
	handle:close()
end

local function _get_latest_github()
	local project_url = string.format("https://api.github.com/repos/%s/%s/releases/latest", GITHUB_USER, REPO)
	local command = string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", project_url)
	local handle = io.popen(command)
	local result = handle:read("*all")
	local gh = json.decode(result, 1, nil)
	handle:close()
	local release_data = {}
	release_data.status = "success"
	if gh then
		release_data.tag_name = gh.tag_name
		for i, asset in ipairs(gh.assets) do
			if string.startswith(asset.name, "Mapper_Proxy_V") and string.endswith(asset.name, ".zip") then
				release_data.download_url = asset.browser_download_url
				release_data.size = asset.size
				release_data.updated_at = asset.updated_at
			elseif string.startswith(asset.name, "Mapper_Proxy_V") and string.endswith(asset.name, ".zip.sha256") then
				release_data.sha256_url = asset.browser_download_url
			end
		end
	end
	release_data.tag_name = release_data.tag_name or ""
	release_data.download_url = release_data.download_url or ""
	release_data.size = release_data.size or 0
	release_data.updated_at = release_data.updated_at or ""
	release_data.sha256_url = release_data.sha256_url or ""
	release_data.provider = "github"
	return release_data
end

local function _get_latest_appveyor()
	local project_url = string.format("https://ci.appveyor.com/api/projects/%s/%s", APPVEYOR_USER, REPO)
	local command = string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", project_url)
	local handle = io.popen(command)
	local result = handle:read("*all")
	local av = json.decode(result, 1, nil)
	handle:close()
	local release_data = {}
	release_data.status = av and av.build.status or nil
	if release_data.status == "success" then
		release_data.tag_name = string.gsub(string.match(av.build.version, "^[vV]([%w.-]+)$"), "-", "_")
		release_data.updated_at = av.build.updated
		for i, job in ipairs(av.build.jobs) do
			if job.status == "success" then
				release_data.download_url = string.format("%s/artifacts/Mapper_Proxy_V%s.zip?branch=%s", project_url, release_data.tag_name, av.build.branch)
				release_data.sha256_url = string.format("%s/artifacts/Mapper_Proxy_V%s.zip.sha256?branch=%s", project_url, release_data.tag_name, av.build.branch)
			end
		end
	end
	release_data.tag_name = release_data.tag_name or ""
	release_data.download_url = release_data.download_url or ""
	release_data.size = nil
	release_data.updated_at = release_data.updated_at or ""
	release_data.sha256_url = release_data.sha256_url or ""
	release_data.provider = "appveyor"
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
	local hash
	printf("Downloading %s %s (%s) from %s.", APP_NAME, release.tag_name, release.updated_at, release.provider == "github" and "GitHub" or release.provider == "appveyor" and "AppVeyor" or string.capitalize(release.provider))
	if release.sha256_url ~= "" then
		local handle = io.popen(string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - \"%s\"", release.sha256_url))
		hash = string.lower(string.strip(handle:read("*all")))
		handle:close()
		if not string.endswith(hash, ".zip") then
			print(string.format("Invalid checksum '%s'", hash))
			return false
		end
		hash = string.match(hash, "^%S+")
	end
	os.execute(string.format("curl.exe --silent --location --retry 999 --retry-max-time 0 --continue-at - --output %s \"%s\"", ZIP_FILE, release.download_url))
	local downloaded_size , error = os.fileSize(ZIP_FILE)
	-- release.size should be nil if the provider's API doesn't support retrieving file size.
	-- If the provider does support retrieving file size, but for some reason did not send it, release.size should be 0.
	if downloaded_size and downloaded_size > 0 and downloaded_size == release.size or not release.size then
		printf("Verifying download.")
		if not hash then
			printf("Error: no checksum available. Aborting.")
		elseif sha256sum_file(ZIP_FILE) == hash then
			save_last_info(release)
			printf("OK.")
			return true
		else
			printf("Error: checksums do not match. Aborting.")
		end
	elseif error then
		printf(error)
	else
		printf("Error downloading release: Downloaded file size and reported size from provider API do not match.")
	end
	if os.isFile(ZIP_FILE) then
		os.remove(ZIP_FILE)
	end
	return false
end

function do_extract()
	local pwd = lfs.currentdir()
	printf("Extracting files.")
	os.execute(string.format("unzip.exe -qq \"%s\" -d \"tempmapper\"", ZIP_FILE))
	if os.isFile(ZIP_FILE) then
		os.remove(ZIP_FILE)
	end
	if not lfs.chdir(pwd .. "\\tempmapper") then
		return printf("Error: failed to change directory to '%s\\tempmapper'", pwd)
	end
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
elseif last.skipped_release and last.skipped_release == latest.tag_name .. latest.updated_at then
	printf("The update to %s (%s) dated %s from %s was previously skipped.", APP_NAME, latest.tag_name, latest.updated_at, latest.provider == "github" and "GitHub" or latest.provider == "appveyor" and "AppVeyor" or string.capitalize(latest.provider))
	if called_by_script() then
		os.exit(0)
	end
elseif last.tag_name and last.updated_at and last.tag_name .. last.updated_at == latest.tag_name .. latest.updated_at then
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
		last.skipped_release = latest.tag_name .. latest.updated_at
		save_last_info(last)
	end
end

pause()
os.exit(0)
