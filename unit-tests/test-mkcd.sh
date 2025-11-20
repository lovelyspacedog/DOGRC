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
total_tests=22  # Tests 1-21 plus 1 summary test with "*"
printf "Running unit tests for mkcd.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/mkcd.sh" ]]; then
    if print_msg 3 "Can I find mkcd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find mkcd.sh?" false
    printf "Error: Test cannot continue. Mkcd.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/mkcd.sh" 2>/dev/null; then
    if print_msg 4 "Can I source mkcd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source mkcd.sh?" false
    printf "Error: Test cannot continue. Mkcd.sh not found.\n" >&2
    exit 4
fi

if declare -f mkcd >/dev/null 2>&1; then
    if print_msg 5 "Is mkcd function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is mkcd function defined?" false
    printf "Error: mkcd function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

original_dir=$(pwd)
cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if mkcd --help >/dev/null 2>&1; then
        if print_msg 6 "Does mkcd --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does mkcd --help work?" false
    fi
else
    if print_msg 6 "Does mkcd --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if mkcd -h >/dev/null 2>&1; then
        if print_msg 7 "Does mkcd -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does mkcd -h work?" false
    fi
else
    if print_msg 7 "Does mkcd -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting basic functionality...\n"

# Test 8: Create new directory
test_dir="test_mkcd_new"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    # After mkcd, we're inside the directory, so check absolute path
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${test_dir}" ]] && [[ -d "${__UNIT_TESTS_DIR}/${test_dir}" ]]; then
        if print_msg 8 "Does mkcd create new directory and change into it?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does mkcd create new directory and change into it?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 8 "Does mkcd create new directory and change into it?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

# Test 9: Create nested directory
test_dir="test_mkcd_nested/subdir/another"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    # After mkcd, we're inside the directory, so check absolute path
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${test_dir}" ]] && [[ -d "${__UNIT_TESTS_DIR}/${test_dir}" ]]; then
        if print_msg 9 "Does mkcd create nested directories?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does mkcd create nested directories?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf test_mkcd_nested 2>/dev/null || true
else
    print_msg 9 "Does mkcd create nested directories?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf test_mkcd_nested 2>/dev/null || true
fi

# Test 10: Change into existing directory
test_dir="test_mkcd_existing"
mkdir -p "$test_dir"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${test_dir}" ]]; then
        if print_msg 10 "Does mkcd change into existing directory?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does mkcd change into existing directory?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 10 "Does mkcd change into existing directory?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

# Test 11: Return code on success
test_dir="test_mkcd_return"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 11 "Does mkcd return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 11 "Does mkcd return 0 on success?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 11 "Does mkcd return 0 on success?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

printf "\nTesting output messages...\n"

# Test 12: Output message contains pwd
test_dir="test_mkcd_output"
cd "${__UNIT_TESTS_DIR}" || exit 91
output=$(mkcd "$test_dir" 2>&1)
if echo "$output" | grep -q "$test_dir"; then
    if print_msg 12 "Does mkcd output directory path?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does mkcd output directory path?" false
fi
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -rf "$test_dir" 2>/dev/null || true

# Test 13: Output includes listing
test_dir="test_mkcd_listing"
cd "${__UNIT_TESTS_DIR}" || exit 91
output=$(mkcd "$test_dir" 2>&1)
if echo "$output" | grep -q "test_mkcd_listing" && [[ ${#output} -gt 10 ]]; then
    if print_msg 13 "Does mkcd output directory listing?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does mkcd output directory listing?" false
fi
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -rf "$test_dir" 2>/dev/null || true

printf "\nTesting error handling...\n"

# Test 14: Error on missing argument
cd "${__UNIT_TESTS_DIR}" || exit 91
if ! mkcd 2>/dev/null; then
    if print_msg 14 "Does mkcd error on missing argument?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does mkcd error on missing argument?" false
fi

# Test 15: Error on permission denied (if possible)
if [[ -d "/root" ]] && [[ ! -r "/root" ]] 2>/dev/null; then
    cd "${__UNIT_TESTS_DIR}" || exit 91
    if ! mkcd "/root/test_mkcd_no_permission" 2>/dev/null; then
        if print_msg 15 "Does mkcd error on permission denied?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 15 "Does mkcd error on permission denied?" false
    fi
else
    if print_msg 15 "Does mkcd error on permission denied?" false; then
        printf "        (Cannot test permission denied, skipping)\n"
    fi
fi

# Test 16: Return code on error
cd "${__UNIT_TESTS_DIR}" || exit 91
mkcd 2>/dev/null
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 16 "Does mkcd return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does mkcd return non-zero on error?" false
fi

# Test 17: Error message format
cd "${__UNIT_TESTS_DIR}" || exit 91
error_output=$(mkcd 2>&1)
if echo "$error_output" | grep -q "ERR:" || [[ -n "$error_output" ]]; then
    if print_msg 17 "Does mkcd output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does mkcd output error message?" false
fi

printf "\nTesting edge cases...\n"

# Test 18: Directory with spaces
test_dir="test mkcd with spaces"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    # After mkcd, we're inside the directory, so check absolute path
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${test_dir}" ]] && [[ -d "${__UNIT_TESTS_DIR}/${test_dir}" ]]; then
        if print_msg 18 "Does mkcd work with directory names containing spaces?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 18 "Does mkcd work with directory names containing spaces?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 18 "Does mkcd work with directory names containing spaces?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

# Test 19: Absolute path
test_dir="${__UNIT_TESTS_DIR}/test_mkcd_absolute"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "$test_dir" >/dev/null 2>&1; then
    if [[ -d "$test_dir" ]] && [[ "$(pwd)" == "$test_dir" ]]; then
        if print_msg 19 "Does mkcd work with absolute paths?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 19 "Does mkcd work with absolute paths?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 19 "Does mkcd work with absolute paths?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

# Test 20: Relative path
test_dir="test_mkcd_relative"
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "./$test_dir" >/dev/null 2>&1; then
    # After mkcd, we're inside the directory, so check absolute path
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${test_dir}" ]] && [[ -d "${__UNIT_TESTS_DIR}/${test_dir}" ]]; then
        if print_msg 20 "Does mkcd work with relative paths?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 20 "Does mkcd work with relative paths?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
else
    print_msg 20 "Does mkcd work with relative paths?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf "$test_dir" 2>/dev/null || true
fi

# Test 21: Multiple mkcd calls
cd "${__UNIT_TESTS_DIR}" || exit 91
if mkcd "test_mkcd_multi1" >/dev/null 2>&1 && mkcd "../test_mkcd_multi2" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/test_mkcd_multi2" ]]; then
        if print_msg 21 "Does mkcd work correctly with multiple calls?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 21 "Does mkcd work correctly with multiple calls?" false
    fi
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf test_mkcd_multi1 test_mkcd_multi2 2>/dev/null || true
else
    print_msg 21 "Does mkcd work correctly with multiple calls?" false
    cd "${__UNIT_TESTS_DIR}" || exit 91
    rm -rf test_mkcd_multi1 test_mkcd_multi2 2>/dev/null || true
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

printf "\nCleaning up test files...\n"
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -rf test_mkcd_* 2>/dev/null || true
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0
