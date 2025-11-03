#!/usr/bin/env lua

-- Test fake semicolon injection after inline member function bodies

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Fake Semicolon Injection ===\n")

-- Test 1: Single inline function followed by variable
print("Test 1: Inline function followed by variable")
local code1 = [[
class Test {
    void foo() { }
    int x;
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
            for i, member in ipairs(decl.type) do
                print(string.format("    [%d] %s: %s", i, member[2] or "?", member[1].tag or "?"))
            end
        end
    end
    assert(count == 2, "Expected 2 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Multiple consecutive inline functions
print("\nTest 2: Multiple consecutive inline functions")
local code2 = [[
class Test {
    void foo() { }
    void bar() { }
    void baz() { }
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
        end
    end
    assert(count == 3, "Expected 3 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Inline function followed by another inline function
print("\nTest 3: Inline function followed by another inline function with nested braces")
local code3 = [[
class Test {
    void foo() { if (x) { y = 1; } }
    void bar() { return; }
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
        end
    end
    assert(count == 2, "Expected 2 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 4: Mix of declarations and inline functions
print("\nTest 4: Mix of declarations and inline functions")
local code4 = [[
class Test {
    int x;
    void foo() { x = 1; }
    int y;
    void bar() { }
    int z;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
            for i, member in ipairs(decl.type) do
                print(string.format("    [%d] %s: %s", i, member[2] or "?", member[1].tag or "?"))
            end
        end
    end
    assert(count == 5, "Expected 5 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 5: Inline function at end of class
print("\nTest 5: Inline function at end of class")
local code5 = [[
class Test {
    int x;
    void foo() { }
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code5:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
        end
    end
    assert(count == 2, "Expected 2 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 6: Access specifier after inline function
print("\nTest 6: Access specifier after inline function")
local code6 = [[
class Test {
public:
    void foo() { }
private:
    int x;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code6:gmatch("[^\n]+"), "test.cpp")
    local count = 0
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            count = #decl.type
            print("  Members found:", count)
        end
    end
    assert(count == 2, "Expected 2 members, got " .. count)
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
