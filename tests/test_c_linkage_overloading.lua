#!/usr/bin/env lua

-- Test that C linkage properly prevents function overloading

local cparser = require('cparser')

print("=== Testing C Linkage Prevents Overloading ===\n")

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

-- Test 1: Two extern "C" functions with same name should conflict
print("Test 1: extern \"C\" functions cannot be overloaded")
local code1 = [[
extern "C" void foo(int x);
extern "C" void foo(double y);
]]
local ok1, err1 = pcall(parseCode, code1, {"-std=c++11"})
if not ok1 and (err1:match("conflict") or err1:match("aborted")) then
   print("  ✓ Correctly rejected extern \"C\" function overloading")
else
   print("  ✗ Should have rejected extern \"C\" function overloading")
end

-- Test 2: Mixing C linkage and C++ linkage should conflict
print("\nTest 2: Cannot mix C linkage and C++ linkage for same name")
local code2 = [[
extern "C" void bar(int x);
void bar(double y);
]]
local ok2, err2 = pcall(parseCode, code2, {"-std=c++11"})
if not ok2 and (err2:match("conflict") or err2:match("aborted")) then
   print("  ✓ Correctly rejected mixing C and C++ linkage")
else
   print("  ✗ Should have rejected mixing C and C++ linkage")
end

-- Test 3: Reverse order - C++ then C linkage
print("\nTest 3: C++ function then extern \"C\" should conflict")
local code3 = [[
void baz(int x);
extern "C" void baz(double y);
]]
local ok3, err3 = pcall(parseCode, code3, {"-std=c++11"})
if not ok3 and (err3:match("conflict") or err3:match("aborted")) then
   print("  ✓ Correctly rejected C++ then C linkage conflict")
else
   print("  ✗ Should have rejected C++ then C linkage conflict")
end

-- Test 4: Functions in extern "C" block cannot overload
print("\nTest 4: Functions in extern \"C\" block cannot overload")
local code4 = [[
extern "C" {
   void func(int x);
   void func(double y);
}
]]
local ok4, err4 = pcall(parseCode, code4, {"-std=c++11"})
if not ok4 and (err4:match("conflict") or err4:match("aborted")) then
   print("  ✓ Correctly rejected overloading in extern \"C\" block")
else
   print("  ✗ Should have rejected overloading in extern \"C\" block")
end

-- Test 5: Regular C++ functions CAN overload (sanity check)
print("\nTest 5: Regular C++ functions can still overload")
local code5 = [[
void test(int x);
void test(double y);
]]
local decls5 = parseCode(code5, {"-std=c++11"})
if #decls5 == 2 then
   print("  ✓ C++ functions can still overload")
else
   print("  ✗ Expected 2 overloads, got " .. #decls5)
end

-- Test 6: extern "C" same signature is OK (declaration + definition)
print("\nTest 6: extern \"C\" same signature (declaration + definition)")
local code6 = [[
extern "C" void same(int x);
extern "C" void same(int x) {}
]]
local decls6 = parseCode(code6, {"-std=c++11"})
if #decls6 == 2 and decls6[1].tag == "Declaration" and decls6[2].tag == "Definition" then
   print("  ✓ Same signature allowed for declaration + definition")
else
   print("  ✗ Should allow declaration + definition with same signature")
end

-- Test 7: Multiple extern "C" blocks with same function name conflict
print("\nTest 7: extern \"C\" across multiple blocks")
local code7 = [[
extern "C" {
   void multi(int x);
}
extern "C" {
   void multi(double y);
}
]]
local ok7, err7 = pcall(parseCode, code7, {"-std=c++11"})
if not ok7 and (err7:match("conflict") or err7:match("aborted")) then
   print("  ✓ Correctly rejected across extern \"C\" blocks")
else
   print("  ✗ Should have rejected overloading across blocks")
end

print("\n=== Tests Complete ===")
