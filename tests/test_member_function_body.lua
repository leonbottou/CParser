#!/usr/bin/env lua

-- Test member function with inline body

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Member Function with Body ===\n")

local code = [[
class Point {
public:
    int x, y;
    void setX(int newX) { x = newX; }
    int getX() { return x; }
};
]]

print("Test: Class with inline member function bodies")
local success, err = pcall(function()
    local di = cparser.declarationIterator(
        {"-std=c++11"},
        code:gmatch("[^\n]+"),
        "test.cpp"
    )

    for decl in di do
        print("Declaration:", decl.tag)
        if decl.type and decl.type.tag == 'Struct' then
            print("  Members:", #decl.type)
        end
    end
end)

if not success then
    print("  ✗ Parse failed:", err)
else
    print("  ✓ Parse successful")
end
