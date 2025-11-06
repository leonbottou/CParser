#!/usr/bin/env lua

-- Test pure virtual function support (= 0, = default, = delete)

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing Pure Virtual Functions ===\n")

-- Test 1: Pure virtual method
print("Test 1: Pure virtual method")
local code1 = [[
class Abstract {
public:
    virtual void foo() = 0;
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local mtype = decl.type[1][1]
            assert(mtype.virtual == true, "foo() should be virtual")
            assert(mtype.pure == "0", "foo() should be pure virtual")
            local str = cparser.typeToString(decl.type)
            assert(str:find("virtual void foo%("), "typeToString should show virtual void foo()")
            assert(str:find("= 0"), "typeToString should show = 0")
            print("  Type string:", str)
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 2: Pure virtual destructor
print("\nTest 2: Pure virtual destructor")
local code2 = [[
class Abstract {
public:
    virtual ~Abstract() = 0;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            local mtype = decl.type[1][1]
            assert(mtype.virtual == true, "~Abstract() should be virtual")
            assert(mtype.pure == "0", "~Abstract() should be pure virtual")
            assert(mtype.destructor == true, "Should be marked as destructor")
            local str = cparser.typeToString(decl.type)
            assert(str:find("virtual") and str:find("~Abstract"), "Should show virtual destructor")
            assert(str:find("= 0"), "Should show = 0")
            print("  Type string:", str)
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 3: Mix of pure virtual, virtual, and non-virtual
print("\nTest 3: Mix of pure virtual, virtual, and non-virtual methods")
local code3 = [[
class Shape {
public:
    virtual void draw() = 0;
    virtual void move();
    void reset();
    virtual ~Shape();
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- draw() - pure virtual
            assert(decl.type[1][1].virtual == true, "draw() should be virtual")
            assert(decl.type[1][1].pure == "0", "draw() should be pure virtual")
            assert(decl.type[1][2] == "draw", "First member should be draw")

            -- move() - virtual but not pure
            assert(decl.type[2][1].virtual == true, "move() should be virtual")
            assert(not decl.type[2][1].pure or decl.type[2][1].pure ~= "0", "move() should not be pure virtual")
            assert(decl.type[2][2] == "move", "Second member should be move")

            -- reset() - not virtual
            assert(not decl.type[3][1].virtual, "reset() should not be virtual")
            assert(decl.type[3][2] == "reset", "Third member should be reset")

            -- ~Shape() - virtual destructor (not pure)
            assert(decl.type[4][1].virtual == true, "~Shape() should be virtual")
            assert(not decl.type[4][1].pure or decl.type[4][1].pure ~= "0", "~Shape() should not be pure virtual")
            assert(decl.type[4][1].destructor == true, "Fourth should be destructor")

            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            assert(str:find("virtual void draw%(") and str:find("= 0"), "Should show pure virtual draw()")
            assert(str:find("virtual void move%(") and not str:match("move%([^)]*%)[^;]*= 0"),
                   "move() should be virtual but not pure")
            assert(str:find("void reset%(") and not str:find("virtual void reset"),
                   "reset() should not be virtual")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 4: Abstract interface (all pure virtual)
print("\nTest 4: Abstract interface with all pure virtual methods")
local code4 = [[
class IInterface {
public:
    virtual void method1() = 0;
    virtual int method2(int x) = 0;
    virtual ~IInterface() = 0;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- All methods should be pure virtual
            for i = 1, #decl.type do
                assert(decl.type[i][1].virtual == true,
                       "Member " .. i .. " should be virtual")
                assert(decl.type[i][1].pure == "0",
                       "Member " .. i .. " should be pure virtual")
            end
            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            -- Count occurrences of "= 0"
            local count = 0
            for _ in str:gmatch("= 0") do count = count + 1 end
            assert(count == 3, "Should have 3 pure virtual functions")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 5: = default syntax (C++11)
print("\nTest 5: Defaulted functions (= default)")
local code5 = [[
class MyClass {
public:
    MyClass() = default;
    ~MyClass() = default;
    MyClass(const MyClass&) = default;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code5:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- Default constructor
            assert(decl.type[1][1].constructor == true, "First should be constructor")
            assert(decl.type[1][1].pure == "default", "Constructor should be defaulted")

            -- Default destructor
            assert(decl.type[2][1].destructor == true, "Second should be destructor")
            assert(decl.type[2][1].pure == "default", "Destructor should be defaulted")

            -- Defaulted copy constructor
            assert(decl.type[3][1].constructor == true, "Third should be copy constructor")
            assert(decl.type[3][1].pure == "default", "Copy constructor should be defaulted")

            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            -- Count occurrences of "= default"
            local count = 0
            for _ in str:gmatch("= default") do count = count + 1 end
            assert(count == 3, "Should have 3 defaulted functions")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 6: = delete syntax (C++11)
print("\nTest 6: Deleted functions (= delete)")
local code6 = [[
class NonCopyable {
public:
    NonCopyable() = default;
    NonCopyable(const NonCopyable&) = delete;
    ~NonCopyable() = delete;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code6:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            -- Default constructor
            assert(decl.type[1][1].constructor == true, "First should be constructor")
            assert(decl.type[1][1].pure == "default", "Constructor should be defaulted")

            -- Deleted copy constructor
            assert(decl.type[2][1].constructor == true, "Second should be copy constructor")
            assert(decl.type[2][1].pure == "delete", "Copy constructor should be deleted")

            -- Deleted destructor
            assert(decl.type[3][1].destructor == true, "Third should be destructor")
            assert(decl.type[3][1].pure == "delete", "Destructor should be deleted")

            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            assert(str:find("= default"), "Should show = default")
            -- Count occurrences of "= delete"
            local count = 0
            for _ in str:gmatch("= delete") do count = count + 1 end
            assert(count == 2, "Should have 2 deleted functions")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

-- Test 7: Pure virtual with parameters
print("\nTest 7: Pure virtual method with parameters")
local code7 = [[
class Calculator {
public:
    virtual int calculate(int a, int b) = 0;
    virtual double compute(double x, double y, double z) = 0;
};
]]

success, err = pcall(function()
    local di = cparser.declarationIterator({"-std=c++11"}, code7:gmatch("[^\n]+"), "test.cpp")
    for decl in di do
        if decl.type and decl.type.tag == 'Struct' then
            assert(#decl.type == 2, "Should have 2 methods")

            -- calculate(int, int)
            local calcType = decl.type[1][1]
            assert(calcType.pure == "0", "calculate should be pure virtual")
            local calcFunc = cparser.unqualified(calcType)
            assert(#calcFunc == 2, "calculate should have 2 parameters")

            -- compute(double, double, double)
            local compType = decl.type[2][1]
            assert(compType.pure == "0", "compute should be pure virtual")
            local compFunc = cparser.unqualified(compType)
            assert(#compFunc == 3, "compute should have 3 parameters")

            local str = cparser.typeToString(decl.type)
            print("  Type string:", str)
            assert(str:find("calculate%(int") and str:find("%) = 0"), "Should show calculate with params")
            assert(str:find("compute%(double") and str:find("%) = 0"), "Should show compute with params")
        end
    end
end)
print(success and "  ✓ Pass" or "  ✗ Fail: " .. err)

print("\n=== All Tests Complete ===")
