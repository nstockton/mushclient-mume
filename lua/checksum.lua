-- Code adapted from LJIT2WinCNG by William A Adams
-- https://github.com/Wiladams/LJIT2WinCNG
-- https://williamaadams.wordpress.com/2012/07/18/crypto-who/

local ffi = require "ffi"

local kernel32 = ffi.load("kernel32")

ffi.cdef[[
typedef long			BOOL;
typedef BOOL *			LPBOOL;
typedef unsigned int	UINT;
typedef unsigned long	DWORD;
typedef unsigned long	ULONG;
typedef const uint8_t *	PCUCHAR;
typedef uint8_t	*		PUCHAR;
typedef void *			PVOID;
typedef const char *	LPCSTR;
typedef const short *	LPCWSTR;
typedef char *			LPSTR;
typedef short *			LPWSTR, PWSTR;
int MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);
int WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);
]]

local CP_ACP 		= 0 -- default to ANSI code page

local function AnsiToUnicode16(in_Src)
	local nsrcBytes = #in_Src
	-- find out how many characters needed
	local charsneeded = kernel32.MultiByteToWideChar(CP_ACP, 0, in_Src, nsrcBytes, nil, 0);
	if charsneeded < 0 then
		return nil;
	end
	local buff = ffi.new("uint16_t[?]", charsneeded+1)
	local charswritten = kernel32.MultiByteToWideChar(CP_ACP, 0, in_Src, nsrcBytes, buff, charsneeded)
	buff[charswritten] = 0
	return buff;
end

local BCRYPT_HASH_LENGTH = AnsiToUnicode16("HashDigestLength")
local BCRYPT_MD2_ALGORITHM = AnsiToUnicode16("MD2")
local BCRYPT_MD4_ALGORITHM = AnsiToUnicode16("MD4")
local BCRYPT_MD5_ALGORITHM = AnsiToUnicode16("MD5")
local BCRYPT_SHA1_ALGORITHM = AnsiToUnicode16("SHA1")
local BCRYPT_SHA256_ALGORITHM = AnsiToUnicode16("SHA256")
local BCRYPT_SHA384_ALGORITHM = AnsiToUnicode16("SHA384")
local BCRYPT_SHA512_ALGORITHM = AnsiToUnicode16("SHA512")

local BCLib = ffi.load("Bcrypt.dll")

ffi.cdef[[
typedef uint32_t	NTSTATUS;
typedef NTSTATUS *PNTSTATUS;
typedef PVOID BCRYPT_HANDLE;
typedef PVOID BCRYPT_ALG_HANDLE;
typedef PVOID BCRYPT_HASH_HANDLE;
typedef struct {
	BCRYPT_HASH_HANDLE	Handle;
}BCryptHash;
typedef struct BCryptAlgorithm {
	BCRYPT_ALG_HANDLE Handle;
} BCryptAlgorithm;
NTSTATUS BCryptCreateHash(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_HASH_HANDLE *phHash, PUCHAR pbHashObject, ULONG cbHashObject, PUCHAR pbSecret, ULONG cbSecret, ULONG dwFlags);
NTSTATUS BCryptHashData(BCRYPT_HASH_HANDLE hHash, PCUCHAR pbInput, ULONG cbInput, ULONG dwFlags);
NTSTATUS BCryptFinishHash(BCRYPT_HASH_HANDLE hHash, PUCHAR pbOutput, ULONG cbOutput, ULONG dwFlags);
NTSTATUS BCryptDuplicateHash(BCRYPT_HASH_HANDLE hHash, BCRYPT_HASH_HANDLE *phNewHash, PUCHAR pbHashObject, ULONG cbHashObject, ULONG dwFlags);
NTSTATUS BCryptDestroyHash(BCRYPT_HASH_HANDLE hHash);
NTSTATUS BCryptOpenAlgorithmProvider(BCRYPT_ALG_HANDLE *phAlgorithm, LPCWSTR pszAlgId, LPCWSTR pszImplementation, ULONG dwFlags);
NTSTATUS BCryptCloseAlgorithmProvider(BCRYPT_ALG_HANDLE hAlgorithm, ULONG dwFlags);
NTSTATUS BCryptGetProperty(BCRYPT_HANDLE hObject, LPCWSTR pszProperty, PUCHAR pbOutput, ULONG cbOutput, ULONG *pcbResult, ULONG dwFlags);
]]

local function BCRYPT_SUCCESS(Status)
	return Status >= 0
end

local function bintohex(bytes, len)
	local str = ffi.string(bytes, len)
	return (
		str:gsub("(.)", function(c) return string.format("%02x", string.byte(c)) end)
	)
end

local BCryptHash = ffi.typeof("BCryptHash")
local BCryptHash_mt = {
	__gc = function(self)
		local status = BCLib.BCryptDestroyHash(self.Handle)
	end,

	__new = function(ct, algorithm)
		local phHash = ffi.new("BCRYPT_HASH_HANDLE[1]");
		local pbHashObject = nil
		local cbHashObject = 0
		local pbSecret = nil
		local cbSecret = 0
		local flags = 0
		local status = BCLib.BCryptCreateHash(algorithm.Handle, phHash, pbHashObject, cbHashObject, pbSecret, cbSecret, flags)
		if status ~= 0 then
			return nil, status
		end
		return ffi.new(ct, phHash[0])
	end,

	__index = {
		GetProperty = function(self, name, buffer, size)
			local pcbResult = ffi.new("uint32_t[1]")
			local buffptr = ffi.cast("uint8_t *", buffer)
			local status = BCLib.BCryptGetProperty(self.Handle, name, buffptr, size, pcbResult, 0)
			if status ~= 0 then
				print("GetProperty, Error status: ", status)
				return nil, status
			end
			-- got the result back
			-- return it to the user
			return buffptr, pcbResult[0]
		end,

		GetPropertyBuffer = function(self, name)
			local pcbResult = ffi.new("uint32_t[1]")
			local status = BCLib.BCryptGetProperty(self.Handle, name, nil, 0, pcbResult, 0);
			if status ~= 0 then
				return nil, status
			end
			local bytesneeded = pcbResult[0]
			local pbOutput = ffi.new("uint8_t[?]", pcbResult[0])
			return pbOutput, bytesneeded
		end,

		GetHashDigestLength = function(self)
			local size = ffi.sizeof("int32_t")
			local buff = ffi.new("int[1]")
			local outbuff, byteswritten = self:GetProperty(BCRYPT_HASH_LENGTH, buff, size)
			if not outbuff then
				return nil, byteswritten
			end
			return buff[0]
		end,

		Clone = function(self)
			local phNewHash = ffi.new("BCRYPT_HASH_HANDLE[1]")
			local pbHashObject = nil
			local cbHashObject = 0
			local pbSecret = nil
			local cbSecret = 0
			local flags = 0
			local status = BCLib.BCryptDuplicateHash(self.Handle, phNewHash, pbHashObject, cbHashObject, flags)
			if status ~= 0 then
				return nil, status
			end
			return ffi.new("BCryptHash", phNewHash[0])
		end,

		HashMore = function(self, chunk, chunksize)
			local pbInput = chunk
			local cbInput
			local flags = 0
			if type(chunk) == "string" then
				pbInput = ffi.cast("const uint8_t *", chunk)
				if not chunksize then
					cbInput = #chunk
				end
			else
				cbInput = cbInput or 0
			end
			local status = BCLib.BCryptHashData(self.Handle, pbInput, cbInput, flags)
			return status == 0 or nil, status
		end,

		Finish = function(self, pbOutput, cbOutput)
			local flags = 0
			local status = BCLib.BCryptFinishHash(self.Handle, pbOutput, cbOutput, flags)
			return status == 0 or nil, status
		end,

		CreateDigest = function(self, input, inputLength)
			local outlen = self:GetHashDigestLength()
			local outbuff = ffi.new("uint8_t[?]", outlen)
			self:HashMore(input)
			self:Finish(outbuff, outlen)
			local hex = bintohex(outbuff, outlen)
			return hex
		end
	}
}
local BCryptHash = ffi.metatype(BCryptHash, BCryptHash_mt)

local BCryptAlgorithm = ffi.typeof("struct BCryptAlgorithm")
local BCryptAlgorithm_mt = {
	__gc = function(self)
		if self.Handle ~= nil then
			BCLib.BCryptCloseAlgorithmProvider(self.Handle, 0)
		end
	end,

	__new = function(ctype, ...)
		local params = {...}
		local algoid = params[1]
		local impl = params[2]
		if not algoid then
			return nil
		end
		local lphAlgo = ffi.new("BCRYPT_ALG_HANDLE[1]")
		local algoidptr = ffi.cast("const uint16_t *", algoid)
		local status = BCLib.BCryptOpenAlgorithmProvider(lphAlgo, algoidptr, impl, 0)
		if not BCRYPT_SUCCESS(status) then
			print("BCryptAlgorithm(), status: ", status)
			return nil
		end
		local newone = ffi.new("struct BCryptAlgorithm", lphAlgo[0])
		return newone
	end,

	__index = {
		CreateHash = function(self)
			return BCryptHash(self)
		end,

		CreateKeyPair = function(self, length, flags)
			length = length or 384
			flags = flags or 0
			local fullKey = ffi.new("BCRYPT_KEY_HANDLE[1]")
			local status = BCLib.BCryptGenerateKeyPair(self.Handle, fullKey, length, flags)
			if status ~= 0 then
				return nil, status
			end
			-- create the key pair
			local fullKey = fullKey[0]
		end
	}
}
local BCryptAlgorithm = ffi.metatype(BCryptAlgorithm, BCryptAlgorithm_mt)

local function checksum(algorithm, content, len)
	local hasher = BCryptAlgorithm(algorithm)
	local hash = hasher:CreateHash()
	return hash:CreateDigest(content, len)
end

local function checksum_from_file(algorithm, file_name, chunk_size)
	local chunk_size = chunk_size or 2 ^ 16
	local hasher = BCryptAlgorithm(algorithm)
	local hash = hasher:CreateHash()
	local outlen = hash:GetHashDigestLength()
	local outbuff = ffi.new("uint8_t[?]", outlen)
	local file = assert(io.open(file_name, "rb"))
	for chunk in file:lines(chunk_size) do
		hash:HashMore(chunk)
	end
	assert(file:close())
	hash:Finish(outbuff, outlen)
	local hex = bintohex(outbuff, outlen)
	return hex
end

local __all__ = {
	["md2sum"] = function(...) return checksum(BCRYPT_MD2_ALGORITHM, ...) end,
	["md4sum"] = function(...) return checksum(BCRYPT_MD4_ALGORITHM, ...) end,
	["md5sum"] = function(...) return checksum(BCRYPT_MD5_ALGORITHM, ...) end,
	["sha1sum"] = function(...) return checksum(BCRYPT_SHA1_ALGORITHM, ...) end,
	["sha256sum"] = function(...) return checksum(BCRYPT_SHA256_ALGORITHM, ...) end,
	["sha384sum"] = function(...) return checksum(BCRYPT_SHA384_ALGORITHM, ...) end,
	["sha512sum"] = function(...) return checksum(BCRYPT_SHA512_ALGORITHM, ...) end,
	["md2sum_file"] = function(...) return checksum_from_file(BCRYPT_MD2_ALGORITHM, ...) end,
	["md4sum_file"] = function(...) return checksum_from_file(BCRYPT_MD4_ALGORITHM, ...) end,
	["md5sum_file"] = function(...) return checksum_from_file(BCRYPT_MD5_ALGORITHM, ...) end,
	["sha1sum_file"] = function(...) return checksum_from_file(BCRYPT_SHA1_ALGORITHM, ...) end,
	["sha256sum_file"] = function(...) return checksum_from_file(BCRYPT_SHA256_ALGORITHM, ...) end,
	["sha384sum_file"] = function(...) return checksum_from_file(BCRYPT_SHA384_ALGORITHM, ...) end,
	["sha512sum_file"] = function(...) return checksum_from_file(BCRYPT_SHA512_ALGORITHM, ...) end,
}

return __all__
