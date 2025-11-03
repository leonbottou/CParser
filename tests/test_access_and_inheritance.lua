#!/usr/bin/env lua

-- Test access level tracking and inheritance parsing

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Access Levels and Inheritance ===\n")

-- Test 1: Access level tracking
print("Test 1: Access level tracking")
local code1 = [[
class MyClass {
private:
    int x;
public:
    int y;
    void foo();
protected:
    int z;
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            print("  Class:", decl.type.n, "- Kind:", decl.type.kind)
            print("  Members:")
            for i, member in ipairs(decl.type) do
                local access = member.access or "?"
                local name = member[2] or "(unnamed)"
                local mtype = member[1].tag or "?"
                print(string.format("    [%d] %s %s: %s", i, access, name, mtype))
            end
            -- Verify access levels
            assert(decl.type[1].access == 'private', "x should be private")
            assert(decl.type[2].access == 'public', "y should be public")
            assert(decl.type[3].access == 'public', "foo should be public")
            assert(decl.type[4].access == 'protected', "z should be protected")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Default access (class = private, struct = public)
print("\nTest 2: Default access levels")
local code2 = [[
class C {
    int x;
};
struct S {
    int y;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    local classes = {}
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            classes[decl.type.n] = decl.type
        end
    end
    print("  Class C, member x:", classes.C[1].access)
    print("  Struct S, member y:", classes.S[1].access)
    assert(classes.C[1].access == 'private', "class default should be private")
    assert(classes.S[1].access == 'public', "struct default should be public")
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Single inheritance
print("\nTest 3: Single inheritance")
local code3 = [[
class Base {};
class Derived : public Base {};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'Derived' then
            print("  Class:", decl.type.n)
            if decl.type.bases then
                print("  Inherits from:")
                for i, base in ipairs(decl.type.bases) do
                    print(string.format("    [%d] %s %s%s",
                        i,
                        base.access,
                        base.virtual and "virtual " or "",
                        base.type.n))
                end
                assert(#decl.type.bases == 1, "Should have 1 base class")
                assert(decl.type.bases[1].access == 'public', "Should be public inheritance")
                assert(decl.type.bases[1].type.n == 'Base', "Should inherit from Base")
            else
                error("No bases found")
            end
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 4: Multiple inheritance
print("\nTest 4: Multiple inheritance")
local code4 = [[
class A {};
class B {};
class C : public A, private B {};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'C' then
            print("  Class:", decl.type.n)
            print("  Inherits from:")
            for i, base in ipairs(decl.type.bases) do
                print(string.format("    [%d] %s %s", i, base.access, base.type.n))
            end
            assert(#decl.type.bases == 2, "Should have 2 base classes")
            assert(decl.type.bases[1].access == 'public', "A should be public")
            assert(decl.type.bases[2].access == 'private', "B should be private")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 5: Virtual inheritance
print("\nTest 5: Virtual inheritance")
local code5 = [[
class Base {};
class Derived : public virtual Base {};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code5:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'Derived' then
            print("  Class:", decl.type.n)
            print("  Virtual inheritance:", decl.type.bases[1].virtual and "yes" or "no")
            assert(decl.type.bases[1].virtual == true, "Should be virtual inheritance")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 6: Default inheritance access (class = private, struct = public)
print("\nTest 6: Default inheritance access")
local code6 = [[
class Base {};
class C : Base {};
struct S : Base {};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code6:gmatch("[^\n]+"), "test.cpp")
    local types = {}
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' and decl.type.bases then
            types[decl.type.n] = decl.type
        end
    end
    print("  Class C inherits:", types.C.bases[1].access)
    print("  Struct S inherits:", types.S.bases[1].access)
    assert(types.C.bases[1].access == 'private', "class default inheritance should be private")
    assert(types.S.bases[1].access == 'public', "struct default inheritance should be public")
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
