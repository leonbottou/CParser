#!/usr/bin/env lua

-- Test member function parsing

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Member Function Parsing ===\n")

local code = [[
class Point {
public:
    int x, y;
    void setX(int newX);
    void setY(int newY);
    int getX();
};
]]

print("Test: Class with member functions")
local success, err = pcall(function()
    local di = cparser.declarationIterator(
        {"-std=c++11"},
        code:gmatch("[^\n]+"),
        "test.cpp"
    )

    for decl in di do
        print("Declaration:", decl.tag or "unknown")
        if decl.type and decl.type.tag == 'Struct' then
            print("  Class name:", decl.type.n or "(anonymous)")
            print("  Kind:", decl.type.kind or "struct")
            print("  Members:")
            for i, member in ipairs(decl.type) do
                local mtype = member[1]
                local mname = member[2]
                local underlyingType = cparser.unqualified(mtype)
                print(string.format("    [%d] %s: %s", i, mname or "(unnamed)", underlyingType.tag or "?"))
                if underlyingType.tag == 'Function' then
                    print("         ^ This is a member function!")
                end
            end
        end
    end
end)

if not success then
    print("  ✗ Parse failed:", err)
else
    print("  ✓ Parse successful")
end

print("\n=== Test Complete ===")
