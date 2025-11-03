#!/usr/bin/env lua

-- Test typeToString for C++ classes

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing typeToString for C++ Classes ===\n")

-- Test 1: Simple class with members
print("Test 1: Simple class")
local code1 = [[
class Point {
private:
    int x, y;
public:
    void setX(int newX);
    int getX();
};
]]

local di = cparser.declarationIterator({"-std=c++11"}, code1:gmatch("[^\n]+"), "test.cpp")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' then
        print("Declaration:", decl.tag)
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

-- Test 2: Class with constructor/destructor
print("Test 2: Class with constructor/destructor")
local code2 = [[
class Widget {
public:
    Widget();
    Widget(int size);
    ~Widget();
    void foo();
};
]]

di = cparser.declarationIterator({"-std=c++11"}, code2:gmatch("[^\n]+"), "test.cpp")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' then
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

-- Test 3: Class with inheritance
print("Test 3: Class with inheritance")
local code3 = [[
class Base {};
class Derived : public Base {
    int x;
};
]]

di = cparser.declarationIterator({"-std=c++11"}, code3:gmatch("[^\n]+"), "test.cpp")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'Derived' then
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

-- Test 4: Multiple inheritance
print("Test 4: Multiple inheritance")
local code4 = [[
class A {};
class B {};
class C : public A, private B {
public:
    void method();
};
]]

di = cparser.declarationIterator({"-std=c++11"}, code4:gmatch("[^\n]+"), "test.cpp")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'C' then
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

-- Test 5: Virtual inheritance
print("Test 5: Virtual inheritance")
local code5 = [[
class Base {};
class Derived : public virtual Base {};
]]

di = cparser.declarationIterator({"-std=c++11"}, code5:gmatch("[^\n]+"), "test.cpp")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' and decl.type.n == 'Derived' then
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

-- Test 6: Plain C struct (should still work)
print("Test 6: Plain C struct")
local code6 = [[
struct Data {
    int x;
    int y;
};
]]

di = cparser.declarationIterator({"-std=c99"}, code6:gmatch("[^\n]+"), "test.c")
for decl in di do
    if decl.type and decl.type.tag == 'Struct' then
        print("Type string:", cparser.typeToString(decl.type))
        print()
    end
end

print("=== Tests Complete ===")
