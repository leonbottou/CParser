#!/usr/bin/env lua

-- Test C++ function overloading support

local cparser = require('cparser')

print("=== Testing C++ Function Overloading ===\n")

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

-- Test 1: Simple overload
print("Test 1: Simple function overload")
local code1 = [[
void foo(int x);
void foo(double y);
]]
local decls1 = parseCode(code1, {"-std=c++11"})
if #decls1 == 2 then
   print("  ✓ Both overloads parsed")
else
   print("  ✗ Expected 2 declarations, got " .. #decls1)
end

-- Test 2: Different argument counts
print("\nTest 2: Different argument counts")
local code2 = [[
void bar();
void bar(int x);
void bar(int x, int y);
]]
local decls2 = parseCode(code2, {"-std=c++11"})
if #decls2 == 3 then
   print("  ✓ All three overloads parsed")
else
   print("  ✗ Expected 3 declarations, got " .. #decls2)
end

-- Test 3: Declaration followed by definition
print("\nTest 3: Declaration then definition")
local code3 = [[
void baz(int x);
void baz(int x) {}
]]
local decls3 = parseCode(code3, {"-std=c++11"})
if #decls3 == 2 and decls3[1].tag == "Declaration" and decls3[2].tag == "Definition" then
   print("  ✓ Declaration and definition both present")
else
   print("  ✗ Expected declaration then definition")
end

-- Test 4: Error on duplicate definition
print("\nTest 4: Duplicate definition error")
local code4 = [[
void qux(int x) {}
void qux(int x) {}
]]
local ok, err = pcall(parseCode, code4, {"-std=c++11"})
if not ok and (err:match("redefinition") or err:match("conflicts") or err:match("aborted")) then
   print("  ✓ Correctly rejected duplicate definition")
else
   print("  ✗ Should have errored on duplicate definition")
   if err then print("     Error: " .. err) end
end

-- Test 5: Non-function conflicts with function
print("\nTest 5: Non-function conflicts with function")
local code5 = [[
void func(int x);
int func;
]]
local ok5, err5 = pcall(parseCode, code5, {"-std=c++11"})
if not ok5 and (err5:match("conflict") or err5:match("aborted")) then
   print("  ✓ Correctly rejected function/non-function conflict")
else
   print("  ✗ Should have errored on function/non-function conflict")
   if err5 then print("     Error: " .. err5) end
end

-- Test 6: C mode should not allow overloading
print("\nTest 6: C mode rejects overloading")
local code6 = [[
void test(int x);
void test(double y);
]]
local ok6, err6 = pcall(parseCode, code6, {"-std=c99"})
if not ok6 and (err6:match("conflict") or err6:match("aborted")) then
   print("  ✓ C mode correctly rejects overloading")
else
   print("  ✗ C mode should not allow function overloading")
   if ok6 then print("     Unexpectedly succeeded") end
end

print("\n=== Tests Complete ===")
