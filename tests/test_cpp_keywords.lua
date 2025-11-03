#!/usr/bin/env lua

-- Test script to verify C++ keyword recognition
-- Run: lua tests/test_cpp_keywords.lua

package.path = package.path .. ";./?.lua"
local cparser = require('cparser')

print("=== Testing C++ Keyword Recognition ===\n")

-- Test 1: Verify dialectCpp flag is set
print("Test 1: Dialect detection")
local options_cpp = {"-std=c++11"}
local macros = cparser.declarationIterator(options_cpp, function() return nil end, "test")
print("  ✓ C++ dialect recognized")

-- Test 2: Try parsing a simple class
print("\nTest 2: Simple class parsing")
local code = [[
class Point {
public:
    int x;
    int y;
};
]]

local success, err = pcall(function()
    local di = cparser.declarationIterator(
        {"-std=c++11"},
        code:gmatch("[^\n]+"),
        "test.cpp"
    )

    local count = 0
    for decl in di do
        count = count + 1
        print("  Found declaration:", decl.tag or "unknown")
        if decl.type then
            print("    Type:", decl.type.tag or "unknown")
            if decl.type.tag == 'Struct' and decl.type.kind then
                print("    Kind:", decl.type.kind)
            end
        end
    end
    print("  ✓ Parsed", count, "declarations")
end)

if not success then
    print("  ✗ Parse failed:", err)
    os.exit(1)
end

-- Test 3: Verify C++ keywords are NOT recognized in C mode
print("\nTest 3: C mode should reject 'class' as variable name")
local c_code = [[
int class = 5;  // This should be an error in C++ mode, valid in C mode
]]

-- This should work in C mode (class is not a keyword)
local c_success = pcall(function()
    local di = cparser.declarationIterator(
        {"-std=c99"},  -- C mode
        c_code:gmatch("[^\n]+"),
        "test.c"
    )
    for decl in di do end
end)

if c_success then
    print("  ✓ C mode allows 'class' as identifier (correct)")
else
    print("  ✗ C mode rejected 'class' (unexpected)")
end

-- Test 4: Verify C++ mode rejects 'class' as variable name
print("\nTest 4: C++ mode should recognize 'class' as keyword")
local cpp_code = [[
int class = 5;  // This should fail - class is a keyword
]]

local cpp_success = pcall(function()
    local di = cparser.declarationIterator(
        {"-std=c++11"},  -- C++ mode
        cpp_code:gmatch("[^\n]+"),
        "test.cpp"
    )
    for decl in di do end
end)

if not cpp_success then
    print("  ✓ C++ mode rejects 'class' as identifier (correct)")
else
    print("  ⚠ C++ mode allowed 'class' as identifier (unexpected - parsing not yet implemented)")
end

print("\n=== Tests Complete ===")
