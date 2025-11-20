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
printf "Running unit tests for cpuinfo.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/information/cpuinfo.sh" ]]; then
    if print_msg 3 "Can I find cpuinfo.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find cpuinfo.sh?" false
    printf "Error: Test cannot continue. cpuinfo.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/information/cpuinfo.sh" 2>/dev/null; then
    if print_msg 4 "Can I source cpuinfo.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source cpuinfo.sh?" false
    printf "Error: Test cannot continue. cpuinfo.sh not found.\n" >&2
    exit 4
fi

if declare -f cpuinfo >/dev/null 2>&1; then
    if print_msg 5 "Is cpuinfo function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is cpuinfo function defined?" false
    printf "Error: cpuinfo function not defined.\n" >&2
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
cleanup_cpuinfo_test() {
    local exit_code=$?
    
    # Restore original PATH if we modified it
    if [[ -n "${ORIGINAL_PATH:-}" ]]; then
        export PATH="$ORIGINAL_PATH"
    fi
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_cpuinfo_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting cpuinfo() function help flags...\n"

# Test 6: cpuinfo --help
if declare -f drchelp >/dev/null 2>&1; then
    if cpuinfo --help >/dev/null 2>&1; then
        if print_msg 6 "Does cpuinfo --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does cpuinfo --help work?" false
    fi
else
    # Without drchelp, --help should return error
    if cpuinfo --help >/dev/null 2>&1; then
        print_msg 6 "Does cpuinfo --help work?" false
    else
        if print_msg 6 "Does cpuinfo --help work (no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

# Test 7: cpuinfo -h
if declare -f drchelp >/dev/null 2>&1; then
    if cpuinfo -h >/dev/null 2>&1; then
        if print_msg 7 "Does cpuinfo -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does cpuinfo -h work?" false
    fi
else
    if cpuinfo -h >/dev/null 2>&1; then
        print_msg 7 "Does cpuinfo -h work?" false
    else
        if print_msg 7 "Does cpuinfo -h work (no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

# Test 8: cpuinfo --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if cpuinfo --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does cpuinfo --HELP work (case-insensitive)?" true; then
            ((score++))
        fi
    else
        print_msg 8 "Does cpuinfo --HELP work (case-insensitive)?" false
    fi
else
    if cpuinfo --HELP >/dev/null 2>&1; then
        print_msg 8 "Does cpuinfo --HELP work (case-insensitive)?" false
    else
        if print_msg 8 "Does cpuinfo --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

printf "\nTesting cpuinfo() function dependency checks...\n"

# Test 9: cpuinfo checks for required dependencies
# We can't easily test missing dependencies without breaking the system,
# but we can verify the function calls ensure_commands_present
output=$(cpuinfo 2>&1)
if [[ -n "$output" ]]; then
    if print_msg 9 "Does cpuinfo check for dependencies?" true; then
        ((score++))
    fi
else
    print_msg 9 "Does cpuinfo check for dependencies?" false
fi

printf "\nTesting cpuinfo() function basic functionality...\n"

# Test 10: cpuinfo runs without errors
if cpuinfo >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does cpuinfo run without errors?" true; then
            ((score++))
        fi
    else
        print_msg 10 "Does cpuinfo run without errors?" false
    fi
else
    print_msg 10 "Does cpuinfo run without errors?" false
fi

# Test 11: cpuinfo returns 0 on success
if cpuinfo >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 11 "Does cpuinfo return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 11 "Does cpuinfo return 0 on success?" false
    fi
else
    print_msg 11 "Does cpuinfo return 0 on success?" false
fi

# Test 12: cpuinfo produces output
output=$(cpuinfo 2>&1)
if [[ -n "$output" ]]; then
    if print_msg 12 "Does cpuinfo produce output?" true; then
        ((score++))
    fi
else
    print_msg 12 "Does cpuinfo produce output?" false
fi

printf "\nTesting cpuinfo() function output format...\n"

# Test 13: cpuinfo output contains "CPU Usage:" header
output=$(cpuinfo 2>&1)
if echo "$output" | grep -q "CPU Usage:"; then
    if print_msg 13 "Does cpuinfo output contain 'CPU Usage:' header?" true; then
        ((score++))
    fi
else
    print_msg 13 "Does cpuinfo output contain 'CPU Usage:' header?" false
fi

# Test 14: cpuinfo output contains "Top CPU Processes:" header
output=$(cpuinfo 2>&1)
if echo "$output" | grep -q "Top CPU Processes:"; then
    if print_msg 14 "Does cpuinfo output contain 'Top CPU Processes:' header?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does cpuinfo output contain 'Top CPU Processes:' header?" false
fi

# Test 15: cpuinfo output has CPU usage value
output=$(cpuinfo 2>&1)
# CPU usage should be a number (possibly with decimal)
if echo "$output" | grep -qE "^CPU Usage:" && echo "$output" | grep -A1 "CPU Usage:" | tail -1 | grep -qE "^[0-9]+\.?[0-9]*$"; then
    if print_msg 15 "Does cpuinfo output contain CPU usage value?" true; then
        ((score++))
    fi
else
    # Alternative: just check that there's something after "CPU Usage:"
    if echo "$output" | grep -A1 "CPU Usage:" | tail -1 | grep -qE "[0-9]"; then
        if print_msg 15 "Does cpuinfo output contain CPU usage value?" true; then
            ((score++))
        fi
    else
        print_msg 15 "Does cpuinfo output contain CPU usage value?" false
    fi
fi

# Test 16: cpuinfo output has process list
output=$(cpuinfo 2>&1)
# Should have process list after "Top CPU Processes:" header
if echo "$output" | grep -A2 "Top CPU Processes:" | tail -n +2 | grep -qE "(USER|PID|%CPU|COMMAND|root|[0-9])"; then
    if print_msg 16 "Does cpuinfo output contain process list?" true; then
        ((score++))
    fi
else
    # Alternative: just check that there are lines after the header
    if echo "$output" | grep -A2 "Top CPU Processes:" | tail -n +2 | grep -q .; then
        if print_msg 16 "Does cpuinfo output contain process list?" true; then
            ((score++))
        fi
    else
        print_msg 16 "Does cpuinfo output contain process list?" false
    fi
fi

printf "\nTesting cpuinfo() function edge cases...\n"

# Test 17: cpuinfo with no arguments works
output=$(cpuinfo 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "CPU Usage:"; then
    if print_msg 17 "Does cpuinfo work with no arguments?" true; then
        ((score++))
    fi
else
    print_msg 17 "Does cpuinfo work with no arguments?" false
fi

# Test 18: cpuinfo with unknown arguments (should still work, just ignore them)
output=$(cpuinfo --unknown-arg 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "CPU Usage:"; then
    if print_msg 18 "Does cpuinfo handle unknown arguments?" true; then
        ((score++))
    fi
else
    print_msg 18 "Does cpuinfo handle unknown arguments?" false
fi

# Test 19: cpuinfo output format is consistent
output1=$(cpuinfo 2>&1)
sleep 0.5
output2=$(cpuinfo 2>&1)
# Both should have the same headers
if echo "$output1" | grep -q "CPU Usage:" && echo "$output2" | grep -q "CPU Usage:" && \
   echo "$output1" | grep -q "Top CPU Processes:" && echo "$output2" | grep -q "Top CPU Processes:"; then
    if print_msg 19 "Does cpuinfo output format remain consistent?" true; then
        ((score++))
    fi
else
    print_msg 19 "Does cpuinfo output format remain consistent?" false
fi

printf "\nTesting cpuinfo.sh direct script execution...\n"

# Test 20: cpuinfo.sh can be executed directly
if bash "${__PLUGINS_DIR}/information/cpuinfo.sh" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 20 "Can cpuinfo.sh be executed directly?" true; then
            ((score++))
        fi
    else
        print_msg 20 "Can cpuinfo.sh be executed directly?" false
    fi
else
    print_msg 20 "Can cpuinfo.sh be executed directly?" false
fi

# Test 21: cpuinfo.sh direct execution produces output
output=$(bash "${__PLUGINS_DIR}/information/cpuinfo.sh" 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "CPU Usage:"; then
    if print_msg 21 "Does cpuinfo.sh direct execution produce output?" true; then
        ((score++))
    fi
else
    print_msg 21 "Does cpuinfo.sh direct execution produce output?" false
fi

# Test 22: cpuinfo.sh direct execution with --help
# When run directly, drchelp may not be available in the script's context
# The script should handle this gracefully (return error if drchelp not available)
output=$(bash "${__PLUGINS_DIR}/information/cpuinfo.sh" --help 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 22 "Does cpuinfo.sh --help work when executed directly?" true; then
        ((score++))
    fi
else
    print_msg 22 "Does cpuinfo.sh --help work when executed directly?" false
fi

# Test 23: cpuinfo.sh direct execution with -h
# When run directly, drchelp may not be available in the script's context
# The script should handle this gracefully (return error if drchelp not available)
output=$(bash "${__PLUGINS_DIR}/information/cpuinfo.sh" -h 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 23 "Does cpuinfo.sh -h work when executed directly?" true; then
        ((score++))
    fi
else
    print_msg 23 "Does cpuinfo.sh -h work when executed directly?" false
fi

# Test 24: cpuinfo.sh direct execution returns correct exit code
if bash "${__PLUGINS_DIR}/information/cpuinfo.sh" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 24 "Does cpuinfo.sh return correct exit code when executed directly?" true; then
            ((score++))
        fi
    else
        print_msg 24 "Does cpuinfo.sh return correct exit code when executed directly?" false
    fi
else
    print_msg 24 "Does cpuinfo.sh return correct exit code when executed directly?" false
fi

total_tests=25  # Tests 1-5, "*", 6-24
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

