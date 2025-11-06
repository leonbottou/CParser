#!/usr/bin/env lua

-- Test static member parsing

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Static Members ===\n")

-- Test 1: Static member functions
print("Test 1: Static member function")
local code1 = [[
class Math {
public:
    static int add(int a, int b);
    int multiply(int a, int b);
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- First member: static int add(int, int)
            local addType = decl.type[1][1]
            assert(addType.tag == 'Qualified', "add should be Qualified")
            assert(addType.static, "add() should be static")
            assert(addType.memberof, "add() should have memberof")

            local addFunc = cparser.unqualified(addType)
            assert(addFunc.tag == 'Function', "add should be Function")
            assert(not addFunc[0], "Static function should NOT have 'this' at index 0")
            assert(#addFunc == 2, "add should have 2 parameters")

            -- Second member: instance function
            local multType = decl.type[2][1]
            assert(multType.tag == 'Qualified', "multiply should be Qualified")
            assert(not multType.static, "multiply() should not be static")

            local multFunc = cparser.unqualified(multType)
            assert(multFunc[0], "Instance function SHOULD have 'this' at index 0")
            assert(#multFunc == 2, "multiply should have 2 visible parameters")

            print("  ✓ Static vs instance functions correctly distinguished")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Static member data
print("\nTest 2: Static member data")
local code2 = [[
class Counter {
public:
    static int count;
    int value;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- First member: static int count
            local countType = decl.type[1][1]
            assert(countType.tag == 'Qualified', "count should be Qualified")
            assert(countType.static, "count should be static")
            assert(countType.memberof, "count should have memberof")

            -- Second member: int value
            local valueType = decl.type[2][1]
            assert(valueType.tag == 'Qualified', "value should be Qualified")
            assert(not valueType.static, "value should not be static")

            print("  ✓ Static vs instance data correctly distinguished")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Type string representation
print("\nTest 3: Type string with static")
local code3 = [[
class Example {
public:
    static void foo();
    void bar();
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            assert(str:find("static void foo"), "Should show 'static void foo'")
            assert(str:find("void bar") and not str:find("static void bar"), "bar should not be static")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
