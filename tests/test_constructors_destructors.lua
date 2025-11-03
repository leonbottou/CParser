#!/usr/bin/env lua

-- Test constructor and destructor recognition

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Constructors and Destructors ===\n")

-- Test 1: Basic constructor and destructor
print("Test 1: Basic constructor and destructor")
local code1 = [[
class MyClass {
public:
    MyClass();
    ~MyClass();
    void method();
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            print("  Class:", decl.type.n)
            print("  Members:")
            for i, member in ipairs(decl.type) do
                local name = member[2] or "?"
                local mtype = member[1].tag or "?"
                local special = ""
                if member[1].constructor then
                    special = " [CONSTRUCTOR]"
                elseif member[1].destructor then
                    special = " [DESTRUCTOR]"
                end
                print(string.format("    [%d] %s: %s%s", i, name, mtype, special))
            end
            -- Verify
            assert(decl.type[1][2] == "MyClass", "First member should be named MyClass")
            assert(decl.type[1][1].constructor == true, "Should be tagged as constructor")
            assert(decl.type[2][2] == "~MyClass", "Second member should be ~MyClass")
            assert(decl.type[2][1].destructor == true, "Should be tagged as destructor")
            assert(decl.type[3][2] == "method", "Third member should be method")
            assert(not decl.type[3][1].constructor and not decl.type[3][1].destructor,
                   "Regular method should not be tagged")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Constructor with parameters
print("\nTest 2: Constructor with parameters")
local code2 = [[
class Point {
public:
    Point(int x, int y);
    int x, y;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            print("  Constructor:", decl.type[1][2])
            print("  Is constructor:", decl.type[1][1].constructor or false)
            print("  Type:", decl.type[1][1].tag)
            assert(decl.type[1][1].constructor == true, "Should be constructor")
            assert(decl.type[1][1].tag == 'Function', "Should be function type")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Multiple constructors (overloading)
print("\nTest 3: Multiple constructors (overloading)")
local code3 = [[
class Widget {
public:
    Widget();
    Widget(int size);
    Widget(int width, int height);
    ~Widget();
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local ctor_count = 0
            local dtor_count = 0
            for i, member in ipairs(decl.type) do
                if member[1].constructor then ctor_count = ctor_count + 1 end
                if member[1].destructor then dtor_count = dtor_count + 1 end
            end
            print("  Constructors found:", ctor_count)
            print("  Destructors found:", dtor_count)
            assert(ctor_count == 3, "Should have 3 constructors")
            assert(dtor_count == 1, "Should have 1 destructor")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 4: Inline constructor/destructor
print("\nTest 4: Inline constructor/destructor")
local code4 = [[
class Inline {
public:
    Inline() { }
    ~Inline() { }
    void foo() { }
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            print("  Members:", #decl.type)
            for i, member in ipairs(decl.type) do
                local special = member[1].constructor and "CTOR" or
                               member[1].destructor and "DTOR" or
                               "METHOD"
                print(string.format("    [%d] %s: %s", i, member[2], special))
            end
            assert(decl.type[1][1].constructor, "First should be constructor")
            assert(decl.type[2][1].destructor, "Second should be destructor")
            assert(not decl.type[3][1].constructor and not decl.type[3][1].destructor,
                   "Third should be regular method")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
