#!/usr/bin/env lua

-- Test C++ operator overloading support

local cparser = require('cparser')

print("=== Testing C++ Operator Overloading ===\n")

-- Helper function
local function parseCode(code, opts)
   opts = opts or {}
   local results = {}
   local di = cparser.declarationIterator(opts, code:gmatch("[^\n]+"), "<test>")
   for decl in di do
      table.insert(results, decl)
   end
   return results
end

-- Test 1: Basic arithmetic operators
print("Test 1: Arithmetic operators (+, -, *, /)")
local code1 = [[
class Complex {
public:
   Complex operator+(const Complex& other);
   Complex operator-(const Complex& other);
   Complex operator*(const Complex& other);
   Complex operator/(const Complex& other);
};
]]
local decls1 = parseCode(code1, {"-std=c++11"})
if #decls1 == 1 and decls1[1].tag == "TypeDef" then
   print("  ✓ Arithmetic operator overloads parsed")
else
   print("  ✗ Failed to parse arithmetic operators")
end

-- Test 2: Subscript operator
print("\nTest 2: Subscript operator []")
local code2 = [[
class Array {
   int& operator[](int index);
};
]]
local decls2 = parseCode(code2, {"-std=c++11"})
if #decls2 == 1 then
   print("  ✓ Subscript operator parsed")
else
   print("  ✗ Failed to parse subscript operator")
end

-- Test 3: Function call operator
print("\nTest 3: Function call operator ()")
local code3 = [[
class Functor {
   void operator()();
   void operator()(int x);
   void operator()(int x, int y);
};
]]
local decls3 = parseCode(code3, {"-std=c++11"})
if #decls3 == 1 then
   print("  ✓ Function call operator parsed")
else
   print("  ✗ Failed to parse function call operator")
end

-- Test 4: new and delete operators
print("\nTest 4: new and delete operators")
local code4 = [[
class Memory {
   void* operator new(unsigned long size);
   void* operator new[](unsigned long size);
   void operator delete(void* ptr);
   void operator delete[](void* ptr);
};
]]
local decls4 = parseCode(code4, {"-std=c++11"})
if #decls4 == 1 then
   print("  ✓ new/delete operators parsed")
else
   print("  ✗ Failed to parse new/delete operators")
end

-- Test 5: Comparison operators
print("\nTest 5: Comparison operators")
local code5 = [[
class Value {
   bool operator==(const Value& other);
   bool operator!=(const Value& other);
   bool operator<(const Value& other);
   bool operator>(const Value& other);
   bool operator<=(const Value& other);
   bool operator>=(const Value& other);
};
]]
local decls5 = parseCode(code5, {"-std=c++11"})
if #decls5 == 1 then
   print("  ✓ Comparison operators parsed")
else
   print("  ✗ Failed to parse comparison operators")
end

-- Test 6: Assignment operators
print("\nTest 6: Assignment operators")
local code6 = [[
class Assignable {
   Assignable& operator=(const Assignable& other);
   Assignable& operator+=(const Assignable& other);
   Assignable& operator-=(const Assignable& other);
};
]]
local decls6 = parseCode(code6, {"-std=c++11"})
if #decls6 == 1 then
   print("  ✓ Assignment operators parsed")
else
   print("  ✗ Failed to parse assignment operators")
end

-- Test 7: Stream operators
print("\nTest 7: Stream operators (<< and >>)")
local code7 = [[
class Stream {
   Stream& operator<<(int value);
   Stream& operator>>(int& value);
};
]]
local decls7 = parseCode(code7, {"-std=c++11"})
if #decls7 == 1 then
   print("  ✓ Stream operators parsed")
else
   print("  ✗ Failed to parse stream operators")
end

-- Test 8: Increment/Decrement operators
print("\nTest 8: Increment/Decrement operators")
local code8 = [[
class Counter {
   Counter& operator++();    // prefix
   Counter operator++(int);  // postfix
   Counter& operator--();    // prefix
   Counter operator--(int);  // postfix
};
]]
local decls8 = parseCode(code8, {"-std=c++11"})
if #decls8 == 1 then
   print("  ✓ Increment/Decrement operators parsed")
else
   print("  ✗ Failed to parse increment/decrement operators")
end

-- Test 9: Arrow and dereference operators
print("\nTest 9: Arrow and dereference operators")
local code9 = [[
class Pointer {
   int* operator->();
   int& operator*();
};
]]
local decls9 = parseCode(code9, {"-std=c++11"})
if #decls9 == 1 then
   print("  ✓ Arrow and dereference operators parsed")
else
   print("  ✗ Failed to parse arrow/dereference operators")
end

-- Test 10: Global operator overloads
print("\nTest 10: Global operator overloads")
local code10 = [[
class Point;
Point operator+(const Point& a, const Point& b);
Point operator*(const Point& p, double scalar);
]]
local decls10 = parseCode(code10, {"-std=c++11"})
-- Note: forward declaration doesn't yield a declaration, only registers the type
if #decls10 == 2 then
   print("  ✓ Global operator overloads parsed")
else
   print("  ✗ Failed to parse global operator overloads, got " .. #decls10)
end

-- Test 11: C mode should not support operator keyword
print("\nTest 11: C mode rejects operator keyword")
local code11 = [[
int operator+(int a, int b);
]]
local ok11, err11 = pcall(parseCode, code11, {"-std=c99"})
if not ok11 and (err11:match("operator") or err11:match("syntax") or err11:match("aborted")) then
   print("  ✓ C mode correctly rejects operator keyword")
else
   print("  ✗ C mode should not allow operator keyword")
   if ok11 then print("     Unexpectedly succeeded") end
end

print("\n=== Tests Complete ===")
