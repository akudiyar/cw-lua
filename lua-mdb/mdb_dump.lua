local reader = require "lua-mdb.reader"
local to_hex = assert((require "cwbase").to_hex)
local sorted_pairs = (require "lua-mdb.util").sorted_pairs

local r = reader.new(arg[1] .. "/data.mdb", {bits = tonumber(arg[2])})
local mp = r:pick_meta_page()

print("VERSION=3")
print("format=bytevalue")
print("type=btree")
print("mapsize=1048576")
print("maxreaders=126")
print("db_pagesize=4096")
print("HEADER=END")

local t = assert(r:dump())

for k, v in sorted_pairs(t) do
    print(" " .. to_hex(k))
    print(" " .. to_hex(v))
end
print("DATA=END")
