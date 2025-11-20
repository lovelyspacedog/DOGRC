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
total_tests=38  # Tests 1-5, "*", 6-37
printf "Running unit tests for drchelp.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    if print_msg 3 "Can I find drchelp.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find drchelp.sh?" false
    printf "Error: Test cannot continue. drchelp.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null; then
    if print_msg 4 "Can I source drchelp.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source drchelp.sh?" false
    printf "Error: Test cannot continue. drchelp.sh not found.\n" >&2
    exit 4
fi

if declare -f drchelp >/dev/null 2>&1; then
    if print_msg 5 "Is drchelp function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is drchelp function defined?" false
    printf "Error: drchelp function not defined.\n" >&2
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

# Setup trap to ensure cleanup happens even on failure
cleanup_drchelp_test() {
    local exit_code=$?
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_drchelp_test EXIT INT TERM

printf "\nTesting drchelp() function basic functionality...\n"

# Test 6: drchelp runs without errors
if drchelp >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 6 "Does drchelp run without errors?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does drchelp run without errors?" false
    fi
else
    print_msg 6 "Does drchelp run without errors?" false
fi

# Test 7: drchelp returns 0 on success
if drchelp >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 7 "Does drchelp return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does drchelp return 0 on success?" false
    fi
else
    print_msg 7 "Does drchelp return 0 on success?" false
fi

# Test 8: drchelp produces output
output=$(drchelp 2>&1)
if [[ -n "$output" ]]; then
    if print_msg 8 "Does drchelp produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Does drchelp produce output?" false
fi

# Test 9: drchelp default help shows usage
output=$(drchelp 2>&1)
if echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 9 "Does drchelp default help show usage?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does drchelp default help show usage?" false
fi

# Test 10: drchelp default help shows available functions section
output=$(drchelp 2>&1)
if echo "$output" | grep -qi "available functions"; then
    if print_msg 10 "Does drchelp default help show available functions section?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does drchelp default help show available functions section?" false
fi

printf "\nTesting drchelp() function with specific function names...\n"

# Test 11: drchelp shows help for known function (backup)
output=$(drchelp backup 2>&1)
if echo "$output" | grep -q "backup" && echo "$output" | grep -q "Usage:"; then
    if print_msg 11 "Does drchelp show help for known function (backup)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does drchelp show help for known function (backup)?" false
fi

# Test 12: drchelp shows help for known function (calc)
output=$(drchelp calc 2>&1)
if echo "$output" | grep -q "calc" && echo "$output" | grep -q "Usage:"; then
    if print_msg 12 "Does drchelp show help for known function (calc)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does drchelp show help for known function (calc)?" false
fi

# Test 13: drchelp shows help for known function (cpx)
output=$(drchelp cpx 2>&1)
if echo "$output" | grep -q "cpx" && echo "$output" | grep -q "Usage:"; then
    if print_msg 13 "Does drchelp show help for known function (cpx)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does drchelp show help for known function (cpx)?" false
fi

# Test 14: drchelp shows help for known function (motd)
output=$(drchelp motd 2>&1)
if echo "$output" | grep -q "motd" && echo "$output" | grep -q "Usage:"; then
    if print_msg 14 "Does drchelp show help for known function (motd)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does drchelp show help for known function (motd)?" false
fi

# Test 15: drchelp shows help for known function (drcfortune)
output=$(drchelp drcfortune 2>&1)
if echo "$output" | grep -q "drcfortune" && echo "$output" | grep -q "Usage:"; then
    if print_msg 15 "Does drchelp show help for known function (drcfortune)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does drchelp show help for known function (drcfortune)?" false
fi

# Test 16: drchelp shows help for known function (pokefetch)
output=$(drchelp pokefetch 2>&1)
if echo "$output" | grep -q "pokefetch" && echo "$output" | grep -q "Usage:"; then
    if print_msg 16 "Does drchelp show help for known function (pokefetch)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does drchelp show help for known function (pokefetch)?" false
fi

printf "\nTesting drchelp() function error handling...\n"

# Test 17: drchelp returns 1 for unknown function
if drchelp nonexistent_function >/dev/null 2>&1; then
    print_msg 17 "Does drchelp return 1 for unknown function?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 17 "Does drchelp return 1 for unknown function?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does drchelp return 1 for unknown function?" false
    fi
fi

# Test 18: drchelp shows error message for unknown function
output=$(drchelp nonexistent_function 2>&1)
if echo "$output" | grep -q "No manual entry found for: nonexistent_function"; then
    if print_msg 18 "Does drchelp show error message for unknown function?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does drchelp show error message for unknown function?" false
fi

# Test 19: drchelp suggests running without arguments for unknown function
output=$(drchelp unknown_function 2>&1)
if echo "$output" | grep -q "Run 'drchelp' without arguments"; then
    if print_msg 19 "Does drchelp suggest running without arguments for unknown function?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does drchelp suggest running without arguments for unknown function?" false
fi

printf "\nTesting drchelp() function help flags...\n"

# Test 20: drchelp --help shows default help
output=$(drchelp --help 2>&1)
if echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 20 "Does drchelp --help show default help?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does drchelp --help show default help?" false
fi

# Test 21: drchelp -h shows default help
output=$(drchelp -h 2>&1)
if echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 21 "Does drchelp -h show default help?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does drchelp -h show default help?" false
fi

# Test 22: drchelp help shows default help
output=$(drchelp help 2>&1)
if echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 22 "Does drchelp help show default help?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does drchelp help show default help?" false
fi

# Test 23: drchelp drchelp shows default help
output=$(drchelp drchelp 2>&1)
if echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 23 "Does drchelp drchelp show default help?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does drchelp drchelp show default help?" false
fi

printf "\nTesting drchelp() function case sensitivity...\n"

# Test 24: drchelp handles case variations (BACKUP)
output=$(drchelp BACKUP 2>&1)
# Should either show help or error, but not crash
if [[ ${#output} -gt 0 ]]; then
    if print_msg 24 "Does drchelp handle case variations (BACKUP)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does drchelp handle case variations (BACKUP)?" false
fi

# Test 25: drchelp handles case variations (CALC)
output=$(drchelp CALC 2>&1)
# Should either show help or error, but not crash
if [[ ${#output} -gt 0 ]]; then
    if print_msg 25 "Does drchelp handle case variations (CALC)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does drchelp handle case variations (CALC)?" false
fi

printf "\nTesting drchelp() function default help structure...\n"

# Test 26: drchelp default help contains categories
output=$(drchelp 2>&1)
# Check for at least one category (without checking exact names)
if echo "$output" | grep -qE "^[A-Z][a-z]+:"; then
    if print_msg 26 "Does drchelp default help contain categories?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does drchelp default help contain categories?" false
fi

# Test 27: drchelp default help contains function examples
output=$(drchelp 2>&1)
# Check for "Examples:" section (without checking exact content)
if echo "$output" | grep -q "Examples:"; then
    if print_msg 27 "Does drchelp default help contain examples section?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does drchelp default help contain examples section?" false
fi

# Test 28: drchelp default help is non-empty and substantial
output=$(drchelp 2>&1)
# Check that output is substantial (more than 100 characters)
if [[ ${#output} -gt 100 ]]; then
    if print_msg 28 "Does drchelp default help contain substantial content?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does drchelp default help contain substantial content?" false
fi

printf "\nTesting drchelp() function with aliases...\n"

# Test 29: drchelp handles function aliases (cd/cdd/zd)
output=$(drchelp cd 2>&1)
if echo "$output" | grep -q "cd" && echo "$output" | grep -q "Usage:"; then
    if print_msg 29 "Does drchelp handle function aliases (cd)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does drchelp handle function aliases (cd)?" false
fi

# Test 30: drchelp handles slashback functions
output=$(drchelp slashback 2>&1)
if echo "$output" | grep -q "slashback" && echo "$output" | grep -q "Usage:"; then
    if print_msg 30 "Does drchelp handle slashback functions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does drchelp handle slashback functions?" false
fi

printf "\nTesting drchelp.sh direct script execution...\n"

# Test 31: drchelp.sh can be executed directly
if bash "${__PLUGINS_DIR}/drchelp.sh" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 31 "Can drchelp.sh be executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 31 "Can drchelp.sh be executed directly?" false
    fi
else
    print_msg 31 "Can drchelp.sh be executed directly?" false
fi

# Test 32: drchelp.sh direct execution produces output
output=$(bash "${__PLUGINS_DIR}/drchelp.sh" 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "Usage: drchelp"; then
    if print_msg 32 "Does drchelp.sh direct execution produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does drchelp.sh direct execution produce output?" false
fi

# Test 33: drchelp.sh direct execution with function name
output=$(bash "${__PLUGINS_DIR}/drchelp.sh" backup 2>&1)
if echo "$output" | grep -q "backup" && echo "$output" | grep -q "Usage:"; then
    if print_msg 33 "Does drchelp.sh direct execution work with function name?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does drchelp.sh direct execution work with function name?" false
fi

# Test 34: drchelp.sh direct execution with unknown function
if bash "${__PLUGINS_DIR}/drchelp.sh" unknown_function >/dev/null 2>&1; then
    print_msg 34 "Does drchelp.sh return 1 for unknown function?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 34 "Does drchelp.sh return 1 for unknown function?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 34 "Does drchelp.sh return 1 for unknown function?" false
    fi
fi

printf "\nTesting drchelp() function bash completion...\n"

# Test 35: drchelp bash completion function exists
if declare -f _drchelp_completion >/dev/null 2>&1; then
    if print_msg 35 "Does drchelp bash completion function exist?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does drchelp bash completion function exist?" false
fi

# Test 36: drchelp bash completion returns function names
if declare -f _drchelp_completion >/dev/null 2>&1; then
    COMP_WORDS=(drchelp "")
    COMP_CWORD=1
    COMPREPLY=()
    _drchelp_completion 2>/dev/null
    if [[ ${#COMPREPLY[@]} -gt 0 ]]; then
        if print_msg 36 "Does drchelp bash completion return function names?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 36 "Does drchelp bash completion return function names?" false
    fi
else
    print_msg 36 "Does drchelp bash completion return function names?" "N/A"
fi

# Test 37: drchelp bash completion includes known functions
if declare -f _drchelp_completion >/dev/null 2>&1; then
    COMP_WORDS=(drchelp "")
    COMP_CWORD=1
    COMPREPLY=()
    _drchelp_completion 2>/dev/null
    # Check if at least one known function is in completions (without checking exact list)
    if printf '%s\n' "${COMPREPLY[@]}" | grep -qE "^(backup|calc|cpx|motd)$"; then
        if print_msg 37 "Does drchelp bash completion include known functions?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 37 "Does drchelp bash completion include known functions?" false
    fi
else
    print_msg 37 "Does drchelp bash completion include known functions?" "N/A"
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

printf "\nNote: These tests are designed to be future-proof. They test the\n"
printf "      mechanism and structure of drchelp, not the exact list of\n"
printf "      functions. New functions can be added without breaking tests.\n"

printf "\nCleaning up...\n"
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

