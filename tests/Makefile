# Makefile for CParser test suite
# Runs all Lua tests, lcpp tests, and lcdecl tests, then tallies results

SHELL := /bin/bash
LUA := lua
LCPP := ../lcpp
LCDECL := ../lcdecl

# Find all test files
LUA_TESTS := $(wildcard test_*.lua)
LCPP_INPUTS := $(wildcard lcpp/*.c)
LCDECL_INPUTS := $(wildcard lcdecl/*.cpp lcdecl/*.h)

# Color output (optional, works in most terminals)
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m# No Color

.PHONY: all test lua-tests lcpp-tests lcdecl-tests clean clean-outputs

all: test

test: lua-tests lcpp-tests lcdecl-tests
	@echo ""
	@echo "========================================="
	@echo "          TEST SUITE SUMMARY"
	@echo "========================================="
	@$(MAKE) --no-print-directory tally

lua-tests:
	@echo "========================================="
	@echo "Running Lua Test Suite ($(words $(LUA_TESTS)) tests)"
	@echo "========================================="
	@passed=0; failed=0; \
	for test in $(LUA_TESTS); do \
		echo -n "$$test ... "; \
		if (cd .. && $(LUA) tests/$$test > /dev/null 2>&1); then \
			echo -e "$(GREEN)PASS$(NC)"; \
			passed=$$((passed + 1)); \
		else \
			echo -e "$(RED)FAIL$(NC)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo "Lua tests: $$passed passed, $$failed failed" > .lua-results

lcpp-tests:
	@echo ""
	@echo "========================================="
	@echo "Running lcpp Tests ($(words $(LCPP_INPUTS)) tests)"
	@echo "========================================="
	@passed=0; failed=0; \
	for input in $(LCPP_INPUTS); do \
		base=$$(basename $$input); \
		name=$${base%.c}; \
		expected="lcpp/expected/$${name}.out"; \
		echo -n "$$base ... "; \
		if [ ! -f "$$expected" ]; then \
			echo -e "$(YELLOW)SKIP (no expected output)$(NC)"; \
			continue; \
		fi; \
		$(LCPP) $$input > /tmp/lcpp-output.tmp 2>&1; \
		if diff -q $$expected /tmp/lcpp-output.tmp > /dev/null 2>&1; then \
			echo -e "$(GREEN)PASS$(NC)"; \
			passed=$$((passed + 1)); \
		else \
			echo -e "$(RED)FAIL$(NC)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	rm -f /tmp/lcpp-output.tmp; \
	echo "lcpp tests: $$passed passed, $$failed failed" > .lcpp-results

lcdecl-tests:
	@echo ""
	@echo "========================================="
	@echo "Running lcdecl Tests ($(words $(LCDECL_INPUTS)) tests)"
	@echo "========================================="
	@passed=0; failed=0; skipped=0; \
	for input in $(LCDECL_INPUTS); do \
		base=$$(basename $$input); \
		expected="lcdecl/expected/$${base}.out"; \
		echo -n "$$base ... "; \
		if [ ! -f "$$expected" ]; then \
			echo -e "$(YELLOW)SKIP (no expected output)$(NC)"; \
			skipped=$$((skipped + 1)); \
			continue; \
		fi; \
		$(LCDECL) $$input > /tmp/lcdecl-output.tmp 2>&1; \
		if diff -q $$expected /tmp/lcdecl-output.tmp > /dev/null 2>&1; then \
			echo -e "$(GREEN)PASS$(NC)"; \
			passed=$$((passed + 1)); \
		else \
			echo -e "$(RED)FAIL$(NC)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	rm -f /tmp/lcdecl-output.tmp; \
	echo "lcdecl tests: $$passed passed, $$failed failed" > .lcdecl-results

tally:
	@lua_results=$$(cat .lua-results 2>/dev/null || echo "Lua tests: 0 passed, 0 failed"); \
	lcpp_results=$$(cat .lcpp-results 2>/dev/null || echo "lcpp tests: 0 passed, 0 failed"); \
	lcdecl_results=$$(cat .lcdecl-results 2>/dev/null || echo "lcdecl tests: 0 passed, 0 failed"); \
	echo "$$lua_results"; \
	echo "$$lcpp_results"; \
	echo "$$lcdecl_results"; \
	echo ""; \
	lua_passed=$$(echo $$lua_results | grep -o '[0-9]* passed' | awk '{print $$1}'); \
	lua_failed=$$(echo $$lua_results | grep -o '[0-9]* failed' | awk '{print $$1}'); \
	lcpp_passed=$$(echo $$lcpp_results | grep -o '[0-9]* passed' | awk '{print $$1}'); \
	lcpp_failed=$$(echo $$lcpp_results | grep -o '[0-9]* failed' | awk '{print $$1}'); \
	lcdecl_passed=$$(echo $$lcdecl_results | grep -o '[0-9]* passed' | awk '{print $$1}'); \
	lcdecl_failed=$$(echo $$lcdecl_results | grep -o '[0-9]* failed' | awk '{print $$1}'); \
	total_passed=$$((lua_passed + lcpp_passed + lcdecl_passed)); \
	total_failed=$$((lua_failed + lcpp_failed + lcdecl_failed)); \
	total_tests=$$((total_passed + total_failed)); \
	echo -e "$(BLUE)TOTAL: $$total_passed/$$total_tests tests passed$(NC)"; \
	if [ $$total_failed -eq 0 ]; then \
		echo -e "$(GREEN)All tests passed!$(NC)"; \
		exit 0; \
	else \
		echo -e "$(RED)$$total_failed test(s) failed$(NC)"; \
		exit 1; \
	fi

# Update expected outputs (use when outputs are known to be correct)
update-expected: update-lcpp-expected update-lcdecl-expected

update-lcpp-expected:
	@echo "Updating lcpp expected outputs..."
	@mkdir -p lcpp/expected
	@for input in $(LCPP_INPUTS); do \
		base=$$(basename $$input); \
		name=$${base%.c}; \
		$(LCPP) $$input > lcpp/expected/$${name}.out 2>&1; \
	done
	@echo "lcpp expected outputs updated."

update-lcdecl-expected:
	@echo "Updating lcdecl expected outputs..."
	@mkdir -p lcdecl/expected
	@for input in $(LCDECL_INPUTS); do \
		base=$$(basename $$input); \
		$(LCDECL) $$input > lcdecl/expected/$${base}.out 2>&1; \
	done
	@echo "lcdecl expected outputs updated."

clean:
	rm -f .lua-results .lcpp-results .lcdecl-results

clean-outputs:
	rm -rf lcpp/expected/*.out lcdecl/expected/*.out

help:
	@echo "CParser Test Suite Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make test                   - Run all tests and show summary"
	@echo "  make lua-tests              - Run only Lua tests"
	@echo "  make lcpp-tests             - Run only lcpp tests"
	@echo "  make lcdecl-tests           - Run only lcdecl tests"
	@echo "  make update-expected        - Update all expected outputs"
	@echo "  make update-lcpp-expected   - Update only lcpp expected outputs"
	@echo "  make update-lcdecl-expected - Update only lcdecl expected outputs"
	@echo "  make clean                  - Remove test result files"
	@echo "  make clean-outputs          - Remove all expected output files"
	@echo "  make help                   - Show this help message"
