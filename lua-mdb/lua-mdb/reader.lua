local parser = require "lua-mdb.parser"
local fmt = string.format

local PAGESIZE = 4096

local e_str = function(e)
    return type(e) == "string" and e or "unexpected error"
end

local dbg = function(self, ...)
    if self.DEBUG then print(fmt(...)) end
end

local raw_page = function(self, n)
    local f, r, e
    f, e = io.open(self.path, "rb")
    if not f then return nil, e end
    r, e = f:seek("set", n * PAGESIZE)
    if not r then
        f:close()
        return nil, e
    end
    r, e = f:read(PAGESIZE)
    f:close()
    return r, e
end

local page = function(self, n)
    assert(type(n) == "number" and n >= 0)
    local raw, e = raw_page(self, n)
    if not raw then return nil, e end
    local r, e = parser.page(raw)
    if not r then
        e = fmt("while parsing page %d: %s", n, e_str(e))
    end
    return r, e
end

local pick_meta_page = function(self)
    local m = {page(self, 0), page(self, 1)}
    if not (m[1] and m[2]) then
        return nil, fmt("could not read meta page: %s", e_str(m[3]))
    end
    local n = m[2].meta.mm_txnid > m[1].meta.mm_txnid and 2 or 1
    self:dbg("picked meta page %d", n - 1)
    return m[n]
end

local dump = function(self)
    local r = {}
    local meta, e = pick_meta_page(self)
    if not meta then return nil, e end
    local root_page_num = meta.meta.mm_dbs.main.md_root
    if root_page_num < 0 then return {} end
    local root_page, e = page(self, meta.meta.mm_dbs.main.md_root)
    if not root_page then return nil, e end
    local nodes = root_page.leaf.nodes
    for i=1,#nodes do
        r[nodes[i].data.k] = nodes[i].data.v
    end
    return r
end

local methods = {
    dump = dump,
    dbg = dbg,
}

local new = function(path)
    assert(type(path) == "string")
    local r = {path = path, DEBUG = false}
    return setmetatable(r, {__index = methods})
end

return {
    new = new,
}