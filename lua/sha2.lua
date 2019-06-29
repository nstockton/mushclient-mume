--sha256/384/512 hash and digest
local ffi = require'ffi'
local C = ffi.load'sha2.dll'

ffi.cdef[[
enum {
	SHA1_BLOCK_LENGTH  = 40,
	SHA1_DIGEST_LENGTH = 20,
	SHA224_BLOCK_LENGTH  = 56,
	SHA224_DIGEST_LENGTH = 28,
	SHA256_BLOCK_LENGTH  = 64,
	SHA256_DIGEST_LENGTH = 32,
	SHA384_BLOCK_LENGTH = 128,
	SHA384_DIGEST_LENGTH = 48,
	SHA512_BLOCK_LENGTH = 128,
	SHA512_DIGEST_LENGTH = 64,
};
typedef union _SHA_CTX {
	struct {
		uint32_t state[5];
		uint64_t bitcount;
		uint8_t  buffer[64];
	} s1;
	struct {
		uint32_t state[8];
		uint64_t bitcount;
		uint8_t  buffer[64];
	} s256;
	struct {
		uint64_t state[8];
		uint64_t bitcount[2];
		uint8_t  buffer[128];
	} s512;
} SHA_CTX;

void SHA1_Init(SHA_CTX*);
void SHA1_Update(SHA_CTX*, const uint8_t*, size_t);
void SHA1_Final(uint8_t[SHA1_DIGEST_LENGTH], SHA_CTX*);

void SHA224_Init(SHA_CTX*);
void SHA224_Update(SHA_CTX*, const uint8_t*, size_t);
void SHA224_Final(uint8_t[SHA224_DIGEST_LENGTH], SHA_CTX*);

void SHA256_Init(SHA_CTX*);
void SHA256_Update(SHA_CTX*, const uint8_t*, size_t);
void SHA256_Final(uint8_t[SHA256_DIGEST_LENGTH], SHA_CTX*);

void SHA384_Init(SHA_CTX*);
void SHA384_Update(SHA_CTX*, const uint8_t*, size_t);
void SHA384_Final(uint8_t[SHA384_DIGEST_LENGTH], SHA_CTX*);

void SHA512_Init(SHA_CTX*);
void SHA512_Update(SHA_CTX*, const uint8_t*, size_t);
void SHA512_Final(uint8_t[SHA512_DIGEST_LENGTH], SHA_CTX*);
]]

local function digest_function(Context, Init, Update, Final, DIGEST_LENGTH)
	return function()
		local ctx = ffi.new(Context)
		local result = ffi.new('uint8_t[?]', DIGEST_LENGTH)
		Init(ctx)
		return function(data, size)
			if data then
				Update(ctx, data, size or #data)
			else
				Final(result, ctx)
				return ffi.string(result, ffi.sizeof(result))
			end
		end
	end
end

local function hash_function(digest_function)
	return function(data, size)
		local d = digest_function(); d(data, size); return d()
	end
end

local M = {C = C}

M.sha1_digest = digest_function(ffi.typeof'SHA_CTX', C.SHA1_Init, C.SHA1_Update, C.SHA1_Final, C.SHA1_DIGEST_LENGTH)
M.sha224_digest = digest_function(ffi.typeof'SHA_CTX', C.SHA224_Init, C.SHA224_Update, C.SHA224_Final, C.SHA224_DIGEST_LENGTH)
M.sha256_digest = digest_function(ffi.typeof'SHA_CTX', C.SHA256_Init, C.SHA256_Update, C.SHA256_Final, C.SHA256_DIGEST_LENGTH)
M.sha384_digest = digest_function(ffi.typeof'SHA_CTX', C.SHA384_Init, C.SHA384_Update, C.SHA384_Final, C.SHA384_DIGEST_LENGTH)
M.sha512_digest = digest_function(ffi.typeof'SHA_CTX', C.SHA512_Init, C.SHA512_Update, C.SHA512_Final, C.SHA512_DIGEST_LENGTH)
M.sha1 = hash_function(M.sha1_digest)
M.sha224 = hash_function(M.sha224_digest)
M.sha256 = hash_function(M.sha256_digest)
M.sha384 = hash_function(M.sha384_digest)
M.sha512 = hash_function(M.sha512_digest)

return M
