#!/usr/bin/env lua

-- Test virtual function support

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Virtual Functions ===\n")

-- Test 1: Virtual method
print("Test 1: Virtual method")
local code1 = [[
class Base {
public:
    virtual void foo();
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local qualType = decl.type[1][1]  -- Qualified wrapper
            assert(qualType.virtual, "foo() should be virtual")
            local str = cparser.typeToString(decl.type)
            assert(str:find("virtual void foo"), "typeToString should show virtual")
            print("  Type string:", str)
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Virtual destructor
print("\nTest 2: Virtual destructor")
local code2 = [[
class Base {
public:
    virtual ~Base();
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local qualType = decl.type[1][1]  -- Qualified wrapper
            assert(qualType.virtual, "~Base() should be virtual")
            assert(qualType.destructor, "Should be marked as destructor")
            local str = cparser.typeToString(decl.type)
            assert(str:find("virtual") and str:find("~Base"), "typeToString should show virtual destructor")
            print("  Type string:", str)
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Mix of virtual and non-virtual
print("\nTest 3: Mix of virtual and non-virtual methods")
local code3 = [[
class Shape {
public:
    virtual void draw();
    void move();
    virtual ~Shape();
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            assert(decl.type[1][1].virtual, "draw() should be virtual")
            assert(decl.type[1][2] == "draw", "First member should be draw")
            assert(not decl.type[2][1].virtual, "move() should not be virtual")
            assert(decl.type[2][2] == "move", "Second member should be move")
            assert(decl.type[3][1].virtual, "~Shape() should be virtual")
            assert(decl.type[3][1].destructor, "Third should be destructor")
            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            assert(str:find("virtual void draw"), "Should show virtual draw()")
            assert(str:find("void move") and not str:find("virtual void move"), "move() should not be virtual")
            assert(str:find("virtual") and str:find("~Shape"), "Should show virtual destructor")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 4: Virtual with inline body
print("\nTest 4: Virtual function with inline body")
local code4 = [[
class Inline {
public:
    virtual void foo() { }
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            assert(decl.type[1][1].virtual, "foo() should be virtual")
            print("  Type string:", cparser.typeToString(decl.type))
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Note: Pure virtual functions (= 0) are not yet supported

print("\n=== All Tests Complete ===")
