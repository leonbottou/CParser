#!/usr/bin/env lua

-- Test C++ extern "C" linkage specification

local cparser = require('cparser')

print("=== Testing extern \"C\" Linkage ===\n")

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

-- Helper to check if type has C linkage
local function hasLinkage(ty, linkage)
   if not ty then return false end
   if ty.tag == "Qualified" and ty.linkage == linkage then
      return true
   end
   return false
end

-- Test 1: Single extern "C" declaration
print("Test 1: Single extern \"C\" declaration")
local code1 = [[
extern "C" void c_function(int x);
]]
local decls1 = parseCode(code1, {"-std=c++11"})
if #decls1 == 1 and hasLinkage(decls1[1].type, "C") then
   print("  ✓ Single extern \"C\" declaration parsed with C linkage")
else
   print("  ✗ Failed to parse single extern \"C\" declaration")
   if #decls1 > 0 and decls1[1].type then
      print("     Type tag: " .. (decls1[1].type.tag or "none"))
      print("     Linkage: " .. tostring(decls1[1].type.linkage or "none"))
   end
end

-- Test 2: extern "C" block
print("\nTest 2: extern \"C\" block with multiple declarations")
local code2 = [[
extern "C" {
   void func1();
   void func2(int x);
   int global_var;
}
]]
local decls2 = parseCode(code2, {"-std=c++11"})
if #decls2 == 3 then
   local allC = true
   for i = 1, #decls2 do
      if not hasLinkage(decls2[i].type, "C") then
         allC = false
         break
      end
   end
   if allC then
      print("  ✓ All declarations in extern \"C\" block have C linkage")
   else
      print("  ✗ Not all declarations have C linkage")
   end
else
   print("  ✗ Expected 3 declarations, got " .. #decls2)
end

-- Test 3: Nested extern "C" blocks
print("\nTest 3: Multiple extern \"C\" blocks")
local code3 = [[
extern "C" {
   void c_func1();
}
void cpp_func();
extern "C" {
   void c_func2();
}
]]
local decls3 = parseCode(code3, {"-std=c++11"})
if #decls3 == 3 then
   if hasLinkage(decls3[1].type, "C") and
      not hasLinkage(decls3[2].type, "C") and
      hasLinkage(decls3[3].type, "C") then
      print("  ✓ Linkage correctly applies only to extern \"C\" functions")
   else
      print("  ✗ Linkage not applied correctly")
   end
else
   print("  ✗ Expected 3 declarations, got " .. #decls3)
end

-- Test 4: extern "C" with function definition
print("\nTest 4: extern \"C\" with function definition")
local code4 = [[
extern "C" void c_function(int x) {
   // body
}
]]
local decls4 = parseCode(code4, {"-std=c++11"})
if #decls4 == 1 and decls4[1].tag == "Definition" and hasLinkage(decls4[1].type, "C") then
   print("  ✓ extern \"C\" function definition parsed")
else
   print("  ✗ Failed to parse extern \"C\" function definition")
end

-- Test 5: static within extern "C" should not have linkage
print("\nTest 5: static within extern \"C\" block")
local code5 = [[
extern "C" {
   static int static_var;
}
]]
local decls5 = parseCode(code5, {"-std=c++11"})
if #decls5 == 1 then
   -- static should not get C linkage
   if not hasLinkage(decls5[1].type, "C") then
      print("  ✓ static correctly does not get C linkage")
   else
      print("  ✗ static should not have C linkage")
   end
else
   print("  ✗ Expected 1 declaration, got " .. #decls5)
end

-- Test 6: extern "C" in C mode
print("\nTest 6: C mode should not support extern \"C\" syntax")
local code6 = [[
extern "C" void func();
]]
local ok6, err6 = pcall(parseCode, code6, {"-std=c99"})
if not ok6 and (err6:match("syntax") or err6:match("aborted") or err6:match("unexpected")) then
   print("  ✓ C mode correctly rejects extern \"C\" syntax")
else
   print("  ✗ C mode should not support extern \"C\" syntax")
   if ok6 then print("     Unexpectedly succeeded") end
end

-- Test 7: Mixed C++ and C linkage
print("\nTest 7: Mixed C++ and extern \"C\" functions")
local code7 = [[
void cpp_func1();
extern "C" void c_func();
void cpp_func2();
]]
local decls7 = parseCode(code7, {"-std=c++11"})
if #decls7 == 3 then
   if not hasLinkage(decls7[1].type, "C") and
      hasLinkage(decls7[2].type, "C") and
      not hasLinkage(decls7[3].type, "C") then
      print("  ✓ Mixed C++/C linkage correctly distinguished")
   else
      print("  ✗ Linkage not correctly applied")
   end
else
   print("  ✗ Expected 3 declarations, got " .. #decls7)
end

-- Test 8: extern "C" block with struct
print("\nTest 8: extern \"C\" block with struct definition")
local code8 = [[
extern "C" {
   struct Point {
      int x;
      int y;
   };
   void process_point(struct Point* p);
}
]]
local decls8 = parseCode(code8, {"-std=c++11"})
if #decls8 == 2 then
   -- The function should have C linkage
   if hasLinkage(decls8[2].type, "C") then
      print("  ✓ extern \"C\" block with struct parsed correctly")
   else
      print("  ✗ Function should have C linkage")
   end
else
   print("  ✗ Expected 2 declarations, got " .. #decls8)
end

print("\n=== Tests Complete ===")
