#!/usr/bin/env lua

-- Test const member function parsing

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Const Member Functions ===\n")

-- Test 1: Basic const member function
print("Test 1: Const member function")
local code1 = [[
class Point {
public:
    int getX() const;
    void setX(int x);
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- First member: int getX() const
            local getXType = decl.type[1][1]
            assert(getXType.tag == 'Qualified', "getX should be Qualified")
            assert(getXType.const, "getX() should be const")
            assert(getXType.memberof, "getX() should have memberof")

            local getXFunc = cparser.unqualified(getXType)
            assert(getXFunc.tag == 'Function', "getX should be Function")
            assert(getXFunc[0], "Const member function should have 'this' at index 0")

            -- Check that 'this' parameter is const
            local thisParam = getXFunc[0]
            local thisType = thisParam[1]  -- Pointer type
            assert(thisType.tag == 'Pointer', "'this' should be Pointer")
            local pointedTo = thisType.t
            if pointedTo.tag == 'Qualified' then
                assert(pointedTo.const, "'this' should point to const")
            end

            -- Second member: void setX(int) - non-const
            local setXType = decl.type[2][1]
            assert(not setXType.const, "setX() should not be const")

            local setXFunc = cparser.unqualified(setXType)
            local setXThisParam = setXFunc[0]
            local setXThisType = setXThisParam[1]
            local setXPointedTo = setXThisType.t
            -- Non-const member function should have non-const 'this'
            if setXPointedTo.tag == 'Qualified' then
                assert(not setXPointedTo.const, "'this' should not point to const for non-const function")
            end

            print("  ✓ Const qualification correctly set on member functions and 'this' parameter")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Const and volatile
print("\nTest 2: Const volatile member function")
local code2 = [[
class Test {
public:
    void foo() const volatile;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local fooType = decl.type[1][1]
            assert(fooType.const, "foo() should be const")
            assert(fooType.volatile, "foo() should be volatile")

            local fooFunc = cparser.unqualified(fooType)
            local thisType = fooFunc[0][1].t
            if thisType.tag == 'Qualified' then
                assert(thisType.const, "'this' should be const")
                assert(thisType.volatile, "'this' should be volatile")
            end

            print("  ✓ Both const and volatile correctly set")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Overloading on const
print("\nTest 3: Overloading on const qualifier")
local code3 = [[
class String {
public:
    char& at(int index);
    const char& at(int index) const;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- Should have 2 overloads of 'at'
            assert(#decl.type == 2, "Should have 2 members")
            assert(decl.type[1][2] == "at", "First should be 'at'")
            assert(decl.type[2][2] == "at", "Second should be 'at'")

            -- First is non-const, second is const
            assert(not decl.type[1][1].const, "First at() should not be const")
            assert(decl.type[2][1].const, "Second at() should be const")

            print("  ✓ Const overloading works correctly")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
