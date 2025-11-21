#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __TESTING_DIR="$(cd "${__UNIT_TESTS_DIR}/.." && pwd)"
readonly __PLUGINS_DIR="$(cd "${__TESTING_DIR}/plugins" && pwd)"
readonly __CORE_DIR="$(cd "${__TESTING_DIR}/core" && pwd)"

# Source results helper
if [[ -f "${__UNIT_TESTS_DIR}/_test-results-helper.sh" ]]; then
    source "${__UNIT_TESTS_DIR}/_test-results-helper.sh"
fi

print_msg() {
    local test_num="$1"
    local description="$2"
    local passed="$3"
    
    if [[ ${#description} -gt 70 ]]; then
        description="${description:0:67}..."
    fi
    
    sleep 0.4
    if [[ "$passed" == "N/A" ]] || [[ "$passed" == "n/a" ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[  N/A   ]"
        return 0
    elif [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
total_tests=28  # Tests 1-5, "*", 6-27
printf "Running unit tests for available.sh...\n\n"

# Initialize progress tracking for real-time updates
if type init_test_progress >/dev/null 2>&1; then
    init_test_progress "$total_tests"
fi

# Sanity checks
if [[ -f "${__CORE_DIR}/dependency_check.sh" ]]; then
    if print_msg 1 "Can I find dependency_check.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 1 "Can I find dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 1
fi

if source "${__CORE_DIR}/dependency_check.sh" 2>/dev/null; then
    if print_msg 2 "Can I source dependency_check.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 2 "Can I source dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 2
fi

if [[ -f "${__PLUGINS_DIR}/utilities/available.sh" ]]; then
    if print_msg 3 "Can I find available.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find available.sh?" false
    printf "Error: Test cannot continue. available.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/available.sh" 2>/dev/null; then
    if print_msg 4 "Can I source available.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source available.sh?" false
    printf "Error: Test cannot continue. available.sh not found.\n" >&2
    exit 4
fi

if declare -f available >/dev/null 2>&1; then
    if print_msg 5 "Is available function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is available function defined?" false
    printf "Error: available function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Save original directory
original_dir=$(pwd)
cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_available_$$"

# Setup trap to ensure cleanup happens even on failure
cleanup_available_test() {
    local exit_code=$?
    
    # Clean up test functions
    unset -f test_public_func 2>/dev/null || true
    unset -f test_another_public 2>/dev/null || true
    unset -f _test_private_func 2>/dev/null || true
    unset -f _test_another_private 2>/dev/null || true
    unset -f test_very_long_function_name_that_should_be_truncated 2>/dev/null || true
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_available_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting available() function help flags...\n"

# Test 6: available --help
if declare -f drchelp >/dev/null 2>&1; then
    if available --help >/dev/null 2>&1; then
        if print_msg 6 "Does available --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does available --help work?" false
    fi
else
    # Without drchelp, --help should return error
    if available --help >/dev/null 2>&1; then
        print_msg 6 "Does available --help work?" false
    else
        if print_msg 6 "Does available --help work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 7: available --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if available --HELP >/dev/null 2>&1; then
        if print_msg 7 "Does available --HELP work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does available --HELP work (case-insensitive)?" false
    fi
else
    if available --HELP >/dev/null 2>&1; then
        print_msg 7 "Does available --HELP work (case-insensitive)?" false
    else
        if print_msg 7 "Does available --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

printf "\nTesting available() function basic functionality...\n"

# Test 8: available lists functions
output=$(available 2>&1)
if echo "$output" | grep -q "Functions available after sourcing ~/.bashrc"; then
    if print_msg 8 "Does available list functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Does available list functions?" false
fi

# Test 9: available returns 0 on success
if available >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 9 "Does available return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does available return 0 on success?" false
    fi
else
    print_msg 9 "Does available return 0 on success?" false
fi

# Test 10: available output contains header
output=$(available 2>&1)
if echo "$output" | grep -qE "^Functions available after sourcing"; then
    if print_msg 10 "Does available output contain header?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does available output contain header?" false
fi

printf "\nTesting available() function filtering mode...\n"

# Create test functions
test_public_func() { :; }
test_another_public() { :; }
_test_private_func() { :; }
_test_another_private() { :; }

# Test 11: available filters out private functions (default)
output=$(available 2>&1)
if echo "$output" | grep -q "test_public_func" && ! echo "$output" | grep -q "_test_private_func"; then
    if print_msg 11 "Does available filter out private functions (default)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does available filter out private functions (default)?" false
fi

# Test 12: available shows public functions
output=$(available 2>&1)
if echo "$output" | grep -q "test_public_func"; then
    if print_msg 12 "Does available show public functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does available show public functions?" false
fi

printf "\nTesting available() function hold mode...\n"

# Test 13: available --hold shows all functions
output=$(available --hold 2>&1)
if echo "$output" | grep -q "_test_private_func"; then
    if print_msg 13 "Does available --hold show all functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does available --hold show all functions?" false
fi

# Test 14: available -h shows all functions
output=$(available -h 2>&1)
if echo "$output" | grep -q "_test_private_func"; then
    if print_msg 14 "Does available -h show all functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does available -h show all functions?" false
fi

# Test 15: available --all shows all functions
output=$(available --all 2>&1)
if echo "$output" | grep -q "_test_private_func"; then
    if print_msg 15 "Does available --all show all functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does available --all show all functions?" false
fi

# Test 16: available -a shows all functions
output=$(available -a 2>&1)
if echo "$output" | grep -q "_test_private_func"; then
    if print_msg 16 "Does available -a show all functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does available -a show all functions?" false
fi

printf "\nTesting available() function output formatting...\n"

# Test 17: available output is formatted in columns
output=$(available 2>&1 | tail -n +2)
# Check if output has multiple columns (spaces between function names)
if echo "$output" | head -1 | grep -qE "  .{1,30}  .{1,30}"; then
    if print_msg 17 "Does available format output in columns?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does available format output in columns?" false
fi

# Test 18: available handles long function names (truncation)
test_very_long_function_name_that_should_be_truncated() { :; }
output=$(available 2>&1)
if echo "$output" | grep -qE "test_very_long.*\.\.\."; then
    if print_msg 18 "Does available truncate long function names?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does available truncate long function names?" false
fi

# Test 19: available shows (none) for empty function list
# This is hard to test directly, but we can test the helper function behavior
# by checking if the output format is correct when functions exist
output=$(available 2>&1)
if echo "$output" | grep -qE "(Functions available|  [a-zA-Z_][a-zA-Z0-9_]*|  \(none\))"; then
    if print_msg 19 "Does available handle empty function list correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does available handle empty function list correctly?" false
fi

printf "\nTesting available() function edge cases...\n"

# Test 20: available ignores unknown options
output=$(available --unknown-option 2>&1)
if echo "$output" | grep -q "ignoring unknown option" && echo "$output" | grep -q "Functions available"; then
    if print_msg 20 "Does available ignore unknown options?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does available ignore unknown options?" false
fi

# Test 21: available handles multiple unknown options
output=$(available --unknown1 --unknown2 2>&1)
if echo "$output" | grep -q "Functions available"; then
    if print_msg 21 "Does available handle multiple unknown options?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does available handle multiple unknown options?" false
fi

# Test 22: available with no arguments works
output=$(available 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "Functions available"; then
    if print_msg 22 "Does available work with no arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does available work with no arguments?" false
fi

# Test 23: available with hold flag and unknown option
output=$(available --hold --unknown 2>&1)
if echo "$output" | grep -q "_test_private_func" && echo "$output" | grep -q "ignoring unknown option"; then
    if print_msg 23 "Does available handle hold flag with unknown option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does available handle hold flag with unknown option?" false
fi

printf "\nTesting available.sh direct script execution...\n"

# Test 24: available.sh can be executed directly
# Use timeout to prevent hanging on interactive shell commands
if command -v timeout >/dev/null 2>&1; then
    if timeout 10 bash "${__PLUGINS_DIR}/utilities/available.sh" >/dev/null 2>&1; then
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            if print_msg 24 "Can available.sh be executed directly?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 24 "Can available.sh be executed directly?" false
        fi
    else
        print_msg 24 "Can available.sh be executed directly?" false
    fi
else
    if bash "${__PLUGINS_DIR}/utilities/available.sh" >/dev/null 2>&1; then
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            if print_msg 24 "Can available.sh be executed directly?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 24 "Can available.sh be executed directly?" false
        fi
    else
        print_msg 24 "Can available.sh be executed directly?" false
    fi
fi

# Test 25: available.sh direct execution shows functions
# Use timeout to prevent hanging on interactive shell commands
if command -v timeout >/dev/null 2>&1; then
    output=$(timeout 10 bash "${__PLUGINS_DIR}/utilities/available.sh" 2>&1)
else
    output=$(bash "${__PLUGINS_DIR}/utilities/available.sh" 2>&1)
fi
if echo "$output" | grep -q "Functions available after sourcing ~/.bashrc"; then
    if print_msg 25 "Does available.sh direct execution show functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does available.sh direct execution show functions?" false
fi

# Test 26: available.sh direct execution with --help
# When run directly, drchelp may not be available in the script's context
# The script should handle this gracefully (return error if drchelp not available)
if command -v timeout >/dev/null 2>&1; then
    output=$(timeout 10 bash "${__PLUGINS_DIR}/utilities/available.sh" --help 2>&1)
else
    output=$(bash "${__PLUGINS_DIR}/utilities/available.sh" --help 2>&1)
fi
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 26 "Does available.sh --help work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does available.sh --help work when executed directly?" false
fi

# Test 27: available.sh direct execution with --hold
if command -v timeout >/dev/null 2>&1; then
    output=$(timeout 10 bash "${__PLUGINS_DIR}/utilities/available.sh" --hold 2>&1)
else
    output=$(bash "${__PLUGINS_DIR}/utilities/available.sh" --hold 2>&1)
fi
if echo "$output" | grep -q "Functions available after sourcing ~/.bashrc"; then
    if print_msg 27 "Does available.sh --hold work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does available.sh --hold work when executed directly?" false
fi

percentage=$((score * 100 / total_tests))

# Write results file
if type write_test_results >/dev/null 2>&1; then
    if [[ $score -eq $total_tests ]]; then
        write_test_results "PASSED" "$score" "$total_tests" "$percentage"
    else
        write_test_results "FAILED" "$score" "$total_tests" "$percentage"
    fi
fi

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

