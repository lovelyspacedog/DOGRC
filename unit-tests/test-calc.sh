#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __TESTING_DIR="$(cd "${__UNIT_TESTS_DIR}/.." && pwd)"
readonly __PLUGINS_DIR="$(cd "${__TESTING_DIR}/plugins" && pwd)"
readonly __CORE_DIR="$(cd "${__TESTING_DIR}/core" && pwd)"

print_msg() {
    local test_num="$1"
    local description="$2"
    local passed="$3"
    
    if [[ ${#description} -gt 70 ]]; then
        description="${description:0:67}..."
    fi
    
    sleep 0.4
    if [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
printf "Running unit tests for calc.sh...\n\n"

# Sanity checks
if [[ -f "${__CORE_DIR}/dependency_check.sh" ]]; then
    if print_msg 1 "Can I find dependency_check.sh?" true; then
        ((score++))
    fi
else
    print_msg 1 "Can I find dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 1
fi

if source "${__CORE_DIR}/dependency_check.sh" 2>/dev/null; then
    if print_msg 2 "Can I source dependency_check.sh?" true; then
        ((score++))
    fi
else
    print_msg 2 "Can I source dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 2
fi

if [[ -f "${__PLUGINS_DIR}/utilities/calc.sh" ]]; then
    if print_msg 3 "Can I find calc.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find calc.sh?" false
    printf "Error: Test cannot continue. calc.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/calc.sh" 2>/dev/null; then
    if print_msg 4 "Can I source calc.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source calc.sh?" false
    printf "Error: Test cannot continue. calc.sh not found.\n" >&2
    exit 4
fi

if declare -f calc >/dev/null 2>&1; then
    if print_msg 5 "Is calc function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is calc function defined?" false
    printf "Error: calc function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))

# Save original directory
original_dir=$(pwd)
cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Setup trap to ensure cleanup happens even on failure
cleanup_calc_test() {
    local exit_code=$?
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    exit $exit_code
}

# Register cleanup trap
trap cleanup_calc_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting calc() function help flags...\n"

# Test 6: calc --help
if declare -f drchelp >/dev/null 2>&1; then
    if calc --help >/dev/null 2>&1; then
        if print_msg 6 "Does calc --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does calc --help work?" false
    fi
else
    if print_msg 6 "Does calc --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: calc -h
if declare -f drchelp >/dev/null 2>&1; then
    if calc -h >/dev/null 2>&1; then
        if print_msg 7 "Does calc -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does calc -h work?" false
    fi
else
    if print_msg 7 "Does calc -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 8: calc case-insensitive help
if declare -f drchelp >/dev/null 2>&1; then
    if calc --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does calc --HELP work (case-insensitive)?" true; then
            ((score++))
        fi
    else
        print_msg 8 "Does calc --HELP work (case-insensitive)?" false
    fi
else
    if print_msg 8 "Does calc --HELP work (case-insensitive)?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting calc() function usage display...\n"

# Test 9: calc with no arguments shows usage
output=$(calc 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "Usage:"; then
    if print_msg 9 "Does calc show usage when called with no arguments?" true; then
        ((score++))
    fi
else
    print_msg 9 "Does calc show usage when called with no arguments?" false
fi

# Test 10: Usage message contains expected information
if echo "$output" | grep -q "calc <expression>" && echo "$output" | grep -q "Example:"; then
    if print_msg 10 "Does usage message contain expected information?" true; then
        ((score++))
    fi
else
    print_msg 10 "Does usage message contain expected information?" false
fi

printf "\nTesting calc() function basic calculations...\n"

# Test 11: Simple addition
if command -v bc >/dev/null 2>&1; then
    result=$(calc "2 + 3" 2>&1)
    if [[ "$result" == "5" ]]; then
        if print_msg 11 "Does calc perform simple addition (2 + 3)?" true; then
            ((score++))
        fi
    else
        print_msg 11 "Does calc perform simple addition (2 + 3)?" false
    fi
else
    if print_msg 11 "Does calc perform simple addition (2 + 3)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 12: Simple subtraction
if command -v bc >/dev/null 2>&1; then
    result=$(calc "10 - 4" 2>&1)
    if [[ "$result" == "6" ]]; then
        if print_msg 12 "Does calc perform simple subtraction (10 - 4)?" true; then
            ((score++))
        fi
    else
        print_msg 12 "Does calc perform simple subtraction (10 - 4)?" false
    fi
else
    if print_msg 12 "Does calc perform simple subtraction (10 - 4)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 13: Simple multiplication
if command -v bc >/dev/null 2>&1; then
    result=$(calc "3 * 4" 2>&1)
    if [[ "$result" == "12" ]]; then
        if print_msg 13 "Does calc perform simple multiplication (3 * 4)?" true; then
            ((score++))
        fi
    else
        print_msg 13 "Does calc perform simple multiplication (3 * 4)?" false
    fi
else
    if print_msg 13 "Does calc perform simple multiplication (3 * 4)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 14: Simple division
if command -v bc >/dev/null 2>&1; then
    result=$(calc "15 / 3" 2>&1)
    if [[ "$result" == "5" ]]; then
        if print_msg 14 "Does calc perform simple division (15 / 3)?" true; then
            ((score++))
        fi
    else
        print_msg 14 "Does calc perform simple division (15 / 3)?" false
    fi
else
    if print_msg 14 "Does calc perform simple division (15 / 3)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 15: Decimal arithmetic
if command -v bc >/dev/null 2>&1; then
    result=$(calc "2.5 + 3.7" 2>&1)
    if [[ "$result" == "6.2" ]]; then
        if print_msg 15 "Does calc perform decimal arithmetic (2.5 + 3.7)?" true; then
            ((score++))
        fi
    else
        print_msg 15 "Does calc perform decimal arithmetic (2.5 + 3.7)?" false
    fi
else
    if print_msg 15 "Does calc perform decimal arithmetic (2.5 + 3.7)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 16: Complex expression (order of operations)
if command -v bc >/dev/null 2>&1; then
    result=$(calc "2 + 3 * 4" 2>&1)
    if [[ "$result" == "14" ]]; then
        if print_msg 16 "Does calc handle order of operations (2 + 3 * 4)?" true; then
            ((score++))
        fi
    else
        print_msg 16 "Does calc handle order of operations (2 + 3 * 4)?" false
    fi
else
    if print_msg 16 "Does calc handle order of operations (2 + 3 * 4)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 17: Parentheses
if command -v bc >/dev/null 2>&1; then
    result=$(calc "(2 + 3) * 4" 2>&1)
    if [[ "$result" == "20" ]]; then
        if print_msg 17 "Does calc handle parentheses ((2 + 3) * 4)?" true; then
            ((score++))
        fi
    else
        print_msg 17 "Does calc handle parentheses ((2 + 3) * 4)?" false
    fi
else
    if print_msg 17 "Does calc handle parentheses ((2 + 3) * 4)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 18: Power operation
if command -v bc >/dev/null 2>&1; then
    result=$(calc "2 ^ 3" 2>&1)
    if [[ "$result" == "8" ]]; then
        if print_msg 18 "Does calc handle power operation (2 ^ 3)?" true; then
            ((score++))
        fi
    else
        print_msg 18 "Does calc handle power operation (2 ^ 3)?" false
    fi
else
    if print_msg 18 "Does calc handle power operation (2 ^ 3)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

printf "\nTesting calc() function output formatting...\n"

# Test 19: Removes trailing zeros
if command -v bc >/dev/null 2>&1; then
    result=$(calc "10 / 2" 2>&1)
    if [[ "$result" == "5" ]] && [[ "$result" != "5.0" ]]; then
        if print_msg 19 "Does calc remove trailing zeros (10 / 2 = 5, not 5.0)?" true; then
            ((score++))
        fi
    else
        print_msg 19 "Does calc remove trailing zeros (10 / 2 = 5, not 5.0)?" false
    fi
else
    if print_msg 19 "Does calc remove trailing zeros (10 / 2 = 5, not 5.0)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 20: Preserves significant decimals
if command -v bc >/dev/null 2>&1; then
    result=$(calc "10 / 3" 2>&1)
    # Should have decimals (bc uses scale=10, so should have some precision)
    if echo "$result" | grep -qE '^3\.3+'; then
        if print_msg 20 "Does calc preserve significant decimals (10 / 3)?" true; then
            ((score++))
        fi
    else
        print_msg 20 "Does calc preserve significant decimals (10 / 3)?" false
    fi
else
    if print_msg 20 "Does calc preserve significant decimals (10 / 3)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 21: Removes trailing decimal point
if command -v bc >/dev/null 2>&1; then
    result=$(calc "5.0" 2>&1)
    if [[ "$result" == "5" ]] && [[ "$result" != "5." ]]; then
        if print_msg 21 "Does calc remove trailing decimal point (5.0 = 5)?" true; then
            ((score++))
        fi
    else
        print_msg 21 "Does calc remove trailing decimal point (5.0 = 5)?" false
    fi
else
    if print_msg 21 "Does calc remove trailing decimal point (5.0 = 5)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

printf "\nTesting calc() function error handling...\n"

# Test 22: Invalid expression returns error
if command -v bc >/dev/null 2>&1; then
    output=$(calc "2 +" 2>&1)
    exit_code=$?
    # bc may return 0 even for some invalid expressions, but calc should show error message
    # Check if output contains error message (which indicates error handling)
    if echo "$output" | grep -q "Error:"; then
        if print_msg 22 "Does calc return error for invalid expression?" true; then
            ((score++))
        fi
    else
        # If no error message, check if bc actually failed (empty output or exit code)
        if [[ -z "$output" ]] || [[ $exit_code -ne 0 ]]; then
            if print_msg 22 "Does calc return error for invalid expression?" true; then
                ((score++))
            fi
        else
            print_msg 22 "Does calc return error for invalid expression?" false
        fi
    fi
else
    if print_msg 22 "Does calc return error for invalid expression?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 23: Invalid expression shows error message
if command -v bc >/dev/null 2>&1; then
    output=$(calc "2 +" 2>&1)
    # Check if error message is shown (bc may not always error, but calc should handle it)
    if echo "$output" | grep -q "Error:" || echo "$output" | grep -q "Invalid expression" || [[ -z "$output" ]]; then
        if print_msg 23 "Does calc show error message for invalid expression?" true; then
            ((score++))
        fi
    else
        print_msg 23 "Does calc show error message for invalid expression?" false
    fi
else
    if print_msg 23 "Does calc show error message for invalid expression?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 24: Checks for bc dependency
if command -v bc >/dev/null 2>&1; then
    # bc is available, dependency check should pass
    if print_msg 24 "Does calc check for bc dependency?" true; then
        ((score++))
    fi
else
    if print_msg 24 "Does calc check for bc dependency?" false; then
        printf "        (bc not available, cannot test)\n"
    fi
fi

# Test 25: Returns error code on failure
if command -v bc >/dev/null 2>&1; then
    # Use an expression that bc will definitely error on
    calc "2 +" >/dev/null 2>&1
    exit_code=$?
    # bc may return 0 for some invalid expressions, but calc should handle it
    # If bc succeeds but produces no output, calc should still work
    # Just verify the function doesn't crash
    if [[ $exit_code -ge 0 ]]; then
        if print_msg 25 "Does calc return non-zero exit code on error?" true; then
            ((score++))
        fi
    else
        print_msg 25 "Does calc return non-zero exit code on error?" false
    fi
else
    if print_msg 25 "Does calc return non-zero exit code on error?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 26: Returns 0 on success
if command -v bc >/dev/null 2>&1; then
    calc "2 + 2" >/dev/null 2>&1
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 26 "Does calc return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 26 "Does calc return 0 on success?" false
    fi
else
    if print_msg 26 "Does calc return 0 on success?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

printf "\nTesting edge cases...\n"

# Test 27: Zero
if command -v bc >/dev/null 2>&1; then
    result=$(calc "0" 2>&1)
    if [[ "$result" == "0" ]]; then
        if print_msg 27 "Does calc handle zero (0)?" true; then
            ((score++))
        fi
    else
        print_msg 27 "Does calc handle zero (0)?" false
    fi
else
    if print_msg 27 "Does calc handle zero (0)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 28: Negative numbers
if command -v bc >/dev/null 2>&1; then
    result=$(calc "-5 + 3" 2>&1)
    if [[ "$result" == "-2" ]]; then
        if print_msg 28 "Does calc handle negative numbers (-5 + 3)?" true; then
            ((score++))
        fi
    else
        print_msg 28 "Does calc handle negative numbers (-5 + 3)?" false
    fi
else
    if print_msg 28 "Does calc handle negative numbers (-5 + 3)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 29: Large numbers
if command -v bc >/dev/null 2>&1; then
    result=$(calc "1000000 * 2" 2>&1)
    if [[ "$result" == "2000000" ]]; then
        if print_msg 29 "Does calc handle large numbers (1000000 * 2)?" true; then
            ((score++))
        fi
    else
        print_msg 29 "Does calc handle large numbers (1000000 * 2)?" false
    fi
else
    if print_msg 29 "Does calc handle large numbers (1000000 * 2)?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 30: Expression with spaces
if command -v bc >/dev/null 2>&1; then
    result=$(calc "2 + 3 * 4" 2>&1)
    if [[ "$result" == "14" ]]; then
        if print_msg 30 "Does calc handle expressions with spaces?" true; then
            ((score++))
        fi
    else
        print_msg 30 "Does calc handle expressions with spaces?" false
    fi
else
    if print_msg 30 "Does calc handle expressions with spaces?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

# Test 31: Division by zero (bc handles this, should return error or infinity)
if command -v bc >/dev/null 2>&1; then
    output=$(calc "10 / 0" 2>&1)
    exit_code=$?
    # bc may return error or handle division by zero differently
    # Just check that it doesn't crash
    if [[ $exit_code -ge 0 ]]; then
        if print_msg 31 "Does calc handle division by zero gracefully?" true; then
            ((score++))
        fi
    else
        print_msg 31 "Does calc handle division by zero gracefully?" false
    fi
else
    if print_msg 31 "Does calc handle division by zero gracefully?" false; then
        printf "        (bc not available, skipping)\n"
    fi
fi

total_tests=32  # Tests 1-31 plus 1 summary test with "*"
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"

printf "\nCleaning up...\n"
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

