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
    if [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
total_tests=28  # Tests 1-27 plus 1 summary test with "*"
printf "Running unit tests for slashback.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/navigation/slashback.sh" ]]; then
    if print_msg 3 "Can I find slashback.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find slashback.sh?" false
    printf "Error: Test cannot continue. slashback.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/navigation/slashback.sh" 2>/dev/null; then
    if print_msg 4 "Can I source slashback.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source slashback.sh?" false
    printf "Error: Test cannot continue. slashback.sh not found.\n" >&2
    exit 4
fi

if declare -f __slashback >/dev/null 2>&1; then
    if print_msg 5 "Is __slashback function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is __slashback function defined?" false
fi

if declare -f "/" >/dev/null 2>&1; then
    if print_msg 6 "Is / function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is / function defined?" false
fi

if declare -f "//" >/dev/null 2>&1; then
    if print_msg 7 "Is // function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 7 "Is // function defined?" false
fi

if declare -f "///" >/dev/null 2>&1; then
    if print_msg 8 "Is /// function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Is /// function defined?" false
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

# Create test directory structure
TEST_SLASHBACK_DIR=$(mktemp -d "${__UNIT_TESTS_DIR}/test_slashback.XXXXXX" 2>/dev/null || echo "${__UNIT_TESTS_DIR}/test_slashback.$$")
mkdir -p "${TEST_SLASHBACK_DIR}/level1/level2/level3/level4/level5/level6/level7" || {
    printf "Error: Failed to create test directories.\n" >&2
    exit 92
}

# Setup trap to ensure cleanup happens even on failure
cleanup_slashback_test() {
    local exit_code=$?
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    # Remove test directory and all contents
    if [[ -d "$TEST_SLASHBACK_DIR" ]]; then
        rm -rf "$TEST_SLASHBACK_DIR" 2>/dev/null || true
    fi
    
    # Remove any leftover test directories
    rm -rf "${__UNIT_TESTS_DIR}"/test_slashback.* 2>/dev/null || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_slashback_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting slashback functions help flags...\n"

# Test 9: / --help
if declare -f drchelp >/dev/null 2>&1; then
    if "/" --help >/dev/null 2>&1; then
        if print_msg 9 "Does / --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does / --help work?" false
    fi
else
    if print_msg 9 "Does / --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 10: / -h
if declare -f drchelp >/dev/null 2>&1; then
    if "/" -h >/dev/null 2>&1; then
        if print_msg 10 "Does / -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does / -h work?" false
    fi
else
    if print_msg 10 "Does / -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 11: // --help
if declare -f drchelp >/dev/null 2>&1; then
    if "//" --help >/dev/null 2>&1; then
        if print_msg 11 "Does // --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 11 "Does // --help work?" false
    fi
else
    if print_msg 11 "Does // --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting slashback functions directory navigation...\n"

# Test 12: / goes up 1 level
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2" || exit 91
"/" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 12 "Does / go up 1 directory level?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does / go up 1 directory level?" false
fi

# Test 13: // goes up 2 levels
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3" || exit 91
"//" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 13 "Does // go up 2 directory levels?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does // go up 2 directory levels?" false
fi

# Test 14: /// goes up 3 levels
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3/level4" || exit 91
"///" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 14 "Does /// go up 3 directory levels?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does /// go up 3 directory levels?" false
fi

# Test 15: //// goes up 4 levels
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3/level4/level5" || exit 91
"////" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 15 "Does //// go up 4 directory levels?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does //// go up 4 directory levels?" false
fi

# Test 16: ///// goes up 5 levels
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3/level4/level5/level6" || exit 91
"/////" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 16 "Does ///// go up 5 directory levels?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does ///// go up 5 directory levels?" false
fi

# Test 17: ////// goes up 6 levels
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3/level4/level5/level6/level7" || exit 91
"//////" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 17 "Does ////// go up 6 directory levels?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does ////// go up 6 directory levels?" false
fi

# Test 18: / from level1 goes to test root
builtin cd "${TEST_SLASHBACK_DIR}/level1" || exit 91
"/" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}" ]]; then
    if print_msg 18 "Does / go from level1 to test root?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does / go from level1 to test root?" false
fi

# Test 19: // from level2 goes to test root
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2" || exit 91
"//" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}" ]]; then
    if print_msg 19 "Does // go from level2 to test root?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does // go from level2 to test root?" false
fi

printf "\nTesting edge cases...\n"

# Test 20: / from test root (should stay at root or handle gracefully)
builtin cd "${TEST_SLASHBACK_DIR}" || exit 91
original_pwd=$(pwd)
"/" >/dev/null 2>&1
# Should either stay at root or go to parent (both are acceptable)
if [[ "$(pwd)" == "$original_pwd" ]] || [[ "$(pwd)" == "$(dirname "$original_pwd")" ]]; then
    if print_msg 20 "Does / handle being at root directory gracefully?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does / handle being at root directory gracefully?" false
fi

# Test 21: Multiple / calls in sequence
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3" || exit 91
"/" >/dev/null 2>&1
"/" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}/level1" ]]; then
    if print_msg 21 "Do multiple / calls work in sequence?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Do multiple / calls work in sequence?" false
fi

# Test 22: // followed by /
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3" || exit 91
"//" >/dev/null 2>&1
"/" >/dev/null 2>&1
if [[ "$(pwd)" == "${TEST_SLASHBACK_DIR}" ]]; then
    if print_msg 22 "Does // followed by / work correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does // followed by / work correctly?" false
fi

# Test 23: Return code on success
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2" || exit 91
if "/" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 23 "Does / return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 23 "Does / return 0 on success?" false
    fi
else
    print_msg 23 "Does / return 0 on success?" false
fi

printf "\nTesting direct script execution...\n"

# Test 24: Script shows usage when run with no arguments
output=$(bash "${__PLUGINS_DIR}/navigation/slashback.sh" 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "Usage:"; then
    if print_msg 24 "Does script show usage when run with no arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does script show usage when run with no arguments?" false
fi

# Test 25: Script executes function when given function name
# Script runs in subshell, so we can't verify directory change directly
# Instead, verify the script runs without error
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2" || exit 91
if bash "${__PLUGINS_DIR}/navigation/slashback.sh" "/" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 25 "Does script execute function when given function name?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 25 "Does script execute function when given function name?" false
    fi
else
    print_msg 25 "Does script execute function when given function name?" false
fi

# Test 26: Script shows error for unknown function name
output=$(bash "${__PLUGINS_DIR}/navigation/slashback.sh" "unknown" 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "Error:" && echo "$output" | grep -q "Unknown function"; then
    if print_msg 26 "Does script show error for unknown function name?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does script show error for unknown function name?" false
fi

# Test 27: Script executes // function
# Script runs in subshell, so we can't verify directory change directly
# Instead, verify the script runs without error
builtin cd "${TEST_SLASHBACK_DIR}/level1/level2/level3" || exit 91
if bash "${__PLUGINS_DIR}/navigation/slashback.sh" "//" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 27 "Does script execute // function correctly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 27 "Does script execute // function correctly?" false
    fi
else
    print_msg 27 "Does script execute // function correctly?" false
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
# Cleanup will be handled by trap
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

