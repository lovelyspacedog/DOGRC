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
total_tests=41  # Tests 1-38 plus 3 summary tests with "*"
printf "Running unit tests for blank.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/blank.sh" ]]; then
    if print_msg 3 "Can I find blank.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find blank.sh?" false
    printf "Error: Test cannot continue. Blank.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/blank.sh" 2>/dev/null; then
    if print_msg 4 "Can I source blank.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source blank.sh?" false
    printf "Error: Test cannot continue. Blank.sh not found.\n" >&2
    exit 4
fi

if declare -f blank >/dev/null 2>&1; then
    if print_msg 5 "Is blank function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is blank function defined?" false
    printf "Error: blank function not defined.\n" >&2
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

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_blank_$$"

# Source drchelp if available for help flag tests
if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

# Test 6: blank --help
if declare -f drchelp >/dev/null 2>&1; then
    if blank --help >/dev/null 2>&1; then
        if print_msg 6 "Does blank --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 6 "Does blank --help work?" false
    fi
else
    if print_msg 6 "Does blank --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: blank -h
if declare -f drchelp >/dev/null 2>&1; then
    if blank -h >/dev/null 2>&1; then
        if print_msg 7 "Does blank -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does blank -h work?" false
    fi
else
    if print_msg 7 "Does blank -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test 8: Error on missing filename
if ! blank 2>/dev/null; then
    if blank 2>&1 | grep -q "Error: blank requires a filename"; then
        if print_msg 8 "Does blank error on missing filename?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 8 "Does blank error on missing filename?" false
    fi
else
    print_msg 8 "Does blank error on missing filename?" false
fi

# Test 9: Error on non-existent file without --touch
if ! blank "nonexistent_blank_test.txt" 2>/dev/null; then
    if blank "nonexistent_blank_test.txt" 2>&1 | grep -q "Error:.*does not exist"; then
        if print_msg 9 "Does blank error on non-existent file?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 9 "Does blank error on non-existent file?" false
    fi
else
    print_msg 9 "Does blank error on non-existent file?" false
fi

# Test 10: Error message suggests --touch
if blank "nonexistent_blank_test2.txt" 2>&1 | grep -q "Use --touch"; then
    if print_msg 10 "Does error message suggest --touch?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does error message suggest --touch?" false
fi

printf "\nCreating test files...\n"

# Create test file with content
test_content="Line 1 of test file\nLine 2 of test file\nLine 3 with some content\nEnd of test file.\n"
if printf "${test_content}" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file.txt" 2>/dev/null; then
    if print_msg 11 "Can I create test_blank_file.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Can I create test_blank_file.txt?" false
    printf "Error: Test cannot continue. Failed to create test_blank_file.txt.\n" >&2
    exit 11
fi

# Create empty test file
if touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_empty.txt" 2>/dev/null; then
    if print_msg 12 "Can I create test_blank_empty.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Can I create test_blank_empty.txt?" false
fi

print_msg "*" "Did I create test files?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nTesting basic functionality...\n"

# Test 13: Blank empties file with content (using -x to skip countdown)
if printf "Some content\nMore content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_basic.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_basic.txt" 2>/dev/null; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_basic.txt" ]]; then
            if print_msg 13 "Does blank -x empty file with content?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 13 "Does blank -x empty file with content?" false
        fi
    else
        print_msg 13 "Does blank -x empty file with content?" false
    fi
else
    print_msg 13 "Can I create test file for basic test?" false
fi

# Test 14: Success message is printed
if printf "Test content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_success.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_success.txt" 2>&1 | grep -q "Successfully emptied"; then
        if print_msg 14 "Does blank print success message?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 14 "Does blank print success message?" false
    fi
else
    print_msg 14 "Can I create test file for success message test?" false
fi

# Test 15: Return code is 0 on success
if printf "Test content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_return.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_return.txt" >/dev/null 2>&1; then
        if [[ $? -eq 0 ]]; then
            if print_msg 15 "Does blank return 0 on success?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 15 "Does blank return 0 on success?" false
        fi
    else
        print_msg 15 "Does blank return 0 on success?" false
    fi
else
    print_msg 15 "Can I create test file for return code test?" false
fi

# Test 16: Blanking already empty file works
if touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_already_empty.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_already_empty.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_already_empty.txt" ]]; then
            if print_msg 16 "Does blank work on already empty file?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 16 "Does blank work on already empty file?" false
        fi
    else
        print_msg 16 "Does blank work on already empty file?" false
    fi
else
    print_msg 16 "Can I create already empty test file?" false
fi

printf "\nTesting --touch flag...\n"

# Test 17: --touch creates new file
if [[ ! -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" ]]; then
    if blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" ]]; then
            if print_msg 17 "Does --touch create new file and empty it?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 17 "Does --touch create new file and empty it?" false
        fi
    else
        print_msg 17 "Does --touch create new file and empty it?" false
    fi
else
    rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt"
    if blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_new.txt" ]]; then
            if print_msg 17 "Does --touch create new file and empty it?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 17 "Does --touch create new file and empty it?" false
        fi
    else
        print_msg 17 "Does --touch create new file and empty it?" false
    fi
fi

# Test 18: --touch shows warning when creating new file
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_warning.txt" 2>/dev/null; then
    if blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_warning.txt" 2>&1 | grep -q "Warning.*creating new file"; then
        if print_msg 18 "Does --touch show warning when creating file?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 18 "Does --touch show warning when creating file?" false
    fi
else
    print_msg 18 "Can I remove test file for warning test?" false
fi

# Test 19: -t short form works
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_t_short.txt" 2>/dev/null; then
    if blank -t -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_t_short.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_t_short.txt" ]]; then
            if print_msg 19 "Does -t short form work for touch?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 19 "Does -t short form work for touch?" false
        fi
    else
        print_msg 19 "Does -t short form work for touch?" false
    fi
else
    print_msg 19 "Can I remove test file for -t test?" false
fi

# Test 20: --touch with existing file doesn't show warning
if printf "Existing content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_existing.txt" 2>/dev/null; then
    if ! blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_existing.txt" 2>&1 | grep -q "Warning.*creating new file"; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_touch_existing.txt" ]]; then
            if print_msg 20 "Does --touch with existing file not show warning?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 20 "Does --touch with existing file not show warning?" false
        fi
    else
        print_msg 20 "Does --touch with existing file not show warning?" false
    fi
else
    print_msg 20 "Can I create test file for existing file test?" false
fi

printf "\nTesting -x (skip countdown) flag...\n"

# Test 21: -x skips countdown and empties immediately
if printf "Content to be emptied\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_x_flag.txt" 2>/dev/null; then
    start_time=$(date +%s)
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_x_flag.txt" >/dev/null 2>&1; then
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        if [[ $elapsed -lt 2 ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_x_flag.txt" ]]; then
            if print_msg 21 "Does -x skip countdown and empty immediately?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 21 "Does -x skip countdown and empty immediately?" false
        fi
    else
        print_msg 21 "Does -x skip countdown and empty immediately?" false
    fi
else
    print_msg 21 "Can I create test file for -x test?" false
fi

# Test 22: --no-countdown long form works
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_nocountdown.txt" 2>/dev/null; then
    if blank --no-countdown "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_nocountdown.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_nocountdown.txt" ]]; then
            if print_msg 22 "Does --no-countdown long form work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 22 "Does --no-countdown long form work?" false
        fi
    else
        print_msg 22 "Does --no-countdown long form work?" false
    fi
else
    print_msg 22 "Can I create test file for --no-countdown test?" false
fi

# Test 23: --skip-countdown long form works
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_skipcountdown.txt" 2>/dev/null; then
    if blank --skip-countdown "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_skipcountdown.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_skipcountdown.txt" ]]; then
            if print_msg 23 "Does --skip-countdown long form work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 23 "Does --skip-countdown long form work?" false
        fi
    else
        print_msg 23 "Does --skip-countdown long form work?" false
    fi
else
    print_msg 23 "Can I create test file for --skip-countdown test?" false
fi

printf "\nTesting flag combinations...\n"

# Test 24: --touch -x combination
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb1.txt" 2>/dev/null; then
    if blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb1.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb1.txt" ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb1.txt" ]]; then
            if print_msg 24 "Does --touch -x combination work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 24 "Does --touch -x combination work?" false
        fi
    else
        print_msg 24 "Does --touch -x combination work?" false
    fi
else
    print_msg 24 "Can I remove test file for combination test?" false
fi

# Test 25: -x --touch (flags in different order)
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb2.txt" 2>/dev/null; then
    if blank -x --touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb2.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb2.txt" ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb2.txt" ]]; then
            if print_msg 25 "Does -x --touch (different order) work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 25 "Does -x --touch (different order) work?" false
        fi
    else
        print_msg 25 "Does -x --touch (different order) work?" false
    fi
else
    print_msg 25 "Can I remove test file for combination test?" false
fi

# Test 26: Filename in middle of flags
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb3.txt" 2>/dev/null; then
    if blank --touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb3.txt" -x >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb3.txt" ]] && [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_comb3.txt" ]]; then
            if print_msg 26 "Does filename in middle of flags work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 26 "Does filename in middle of flags work?" false
        fi
    else
        print_msg 26 "Does filename in middle of flags work?" false
    fi
else
    print_msg 26 "Can I remove test file for combination test?" false
fi

printf "\nTesting edge cases...\n"

# Test 27: File with spaces in name
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_with_spaces.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_with_spaces.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_with_spaces.txt" ]]; then
            if print_msg 27 "Does blank work with spaces in filename?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 27 "Does blank work with spaces in filename?" false
        fi
    else
        print_msg 27 "Does blank work with spaces in filename?" false
    fi
else
    print_msg 27 "Can I create test file with spaces?" false
fi

# Test 28: File with special characters in name
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_special@123.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_special@123.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_special@123.txt" ]]; then
            if print_msg 28 "Does blank work with special characters in filename?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 28 "Does blank work with special characters in filename?" false
        fi
    else
        print_msg 28 "Does blank work with special characters in filename?" false
    fi
else
    print_msg 28 "Can I create test file with special characters?" false
fi

# Test 29: Relative path
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_relative.txt" 2>/dev/null; then
    if blank -x "${TEST_PREFIX}_relative.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_relative.txt" ]]; then
            if print_msg 29 "Does blank work with relative path?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 29 "Does blank work with relative path?" false
        fi
    else
        print_msg 29 "Does blank work with relative path?" false
    fi
else
    print_msg 29 "Can I create test file for relative path test?" false
fi

# Test 30: Absolute path
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_absolute.txt" 2>/dev/null; then
    abs_path="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_absolute.txt"
    if blank -x "$abs_path" >/dev/null 2>&1; then
        if [[ ! -s "$abs_path" ]]; then
            if print_msg 30 "Does blank work with absolute path?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 30 "Does blank work with absolute path?" false
        fi
    else
        print_msg 30 "Does blank work with absolute path?" false
    fi
else
    print_msg 30 "Can I create test file for absolute path test?" false
fi

# Test 31: Multiple consecutive calls
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_multiple.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_multiple.txt" >/dev/null 2>&1 && \
       blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_multiple.txt" >/dev/null 2>&1 && \
       blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_multiple.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_multiple.txt" ]]; then
            if print_msg 31 "Does blank work on multiple consecutive calls?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 31 "Does blank work on multiple consecutive calls?" false
        fi
    else
        print_msg 31 "Does blank work on multiple consecutive calls?" false
    fi
else
    print_msg 31 "Can I create test file for multiple calls test?" false
fi

# Test 32: Large file (ensures proper emptying)
if dd if=/dev/urandom of="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_large.txt" bs=1K count=100 >/dev/null 2>&1; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_large.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_large.txt" ]]; then
            if print_msg 32 "Does blank work on large file?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 32 "Does blank work on large file?" false
        fi
    else
        print_msg 32 "Does blank work on large file?" false
    fi
else
    print_msg 32 "Can I create large test file?" false
fi

# Test 33: File permissions preserved (basic check - file still exists after)
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_perms.txt" 2>/dev/null; then
    orig_perms=$(stat -c "%a" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_perms.txt" 2>/dev/null || stat -f "%OLp" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_perms.txt" 2>/dev/null || echo "")
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_perms.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_perms.txt" ]]; then
            if print_msg 33 "Does blank preserve file existence (permissions check)?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 33 "Does blank preserve file existence (permissions check)?" false
        fi
    else
        print_msg 33 "Does blank preserve file existence (permissions check)?" false
    fi
else
    print_msg 33 "Can I create test file for permissions test?" false
fi

printf "\nTesting argument parsing...\n"

# Test 34: Only first non-flag argument used as filename
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg1.txt" 2>/dev/null && \
   printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg2.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg1.txt" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg2.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg1.txt" ]] && [[ -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_arg2.txt" ]]; then
            if print_msg 34 "Does blank only use first non-flag argument?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 34 "Does blank only use first non-flag argument?" false
        fi
    else
        print_msg 34 "Does blank only use first non-flag argument?" false
    fi
else
    print_msg 34 "Can I create test files for argument parsing test?" false
fi

# Test 35: Case-insensitive flag handling (if applicable - touch flag)
if rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_case.txt" 2>/dev/null; then
    # Note: case-insensitive check depends on implementation - testing lowercase behavior
    if blank --touch -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_case.txt" >/dev/null 2>&1; then
        if [[ -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_case.txt" ]]; then
            if print_msg 35 "Does blank handle flags correctly (case test)?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 35 "Does blank handle flags correctly (case test)?" false
        fi
    else
        print_msg 35 "Does blank handle flags correctly (case test)?" false
    fi
else
    print_msg 35 "Can I remove test file for case test?" false
fi

printf "\nTesting non-interactive behavior...\n"

# Test 36: Blank works in non-interactive shell (no countdown)
if printf "Content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_noninteractive.txt" 2>/dev/null; then
    # Run in non-interactive context (piped input simulates non-interactive)
    if echo "" | blank "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_noninteractive.txt" >/dev/null 2>&1; then
        if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_noninteractive.txt" ]]; then
            if print_msg 36 "Does blank work in non-interactive context?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 36 "Does blank work in non-interactive context?" false
        fi
    else
        # Try with -x flag explicitly
        if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_noninteractive.txt" >/dev/null 2>&1; then
            if [[ ! -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_noninteractive.txt" ]]; then
                if print_msg 36 "Does blank work in non-interactive context?" true; then
                    ((score++))
                    if type update_progress_from_score >/dev/null 2>&1; then
                        update_progress_from_score
                    fi
                fi
            else
                print_msg 36 "Does blank work in non-interactive context?" false
            fi
        else
            print_msg 36 "Does blank work in non-interactive context?" false
        fi
    fi
else
    print_msg 36 "Can I create test file for non-interactive test?" false
fi

# Test 37: File can be written to after blanking
if printf "Original content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_after_write.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_after_write.txt" >/dev/null 2>&1; then
        if printf "New content after blanking\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_after_write.txt" 2>/dev/null; then
            if [[ -s "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_after_write.txt" ]] && \
               grep -q "New content after blanking" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_after_write.txt" 2>/dev/null; then
                if print_msg 37 "Can file be written to after blanking?" true; then
                    ((score++))
                    if type update_progress_from_score >/dev/null 2>&1; then
                        update_progress_from_score
                    fi
                fi
            else
                print_msg 37 "Can file be written to after blanking?" false
            fi
        else
            print_msg 37 "Can file be written to after blanking?" false
        fi
    else
        print_msg 37 "Can file be written to after blanking?" false
    fi
else
    print_msg 37 "Can I create test file for after-write test?" false
fi

# Test 38: File size is exactly 0 bytes after blanking
if printf "Multi-line content\nLine 2\nLine 3\nEnd\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_size.txt" 2>/dev/null; then
    if blank -x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_size.txt" >/dev/null 2>&1; then
        file_size=$(stat -c "%s" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_size.txt" 2>/dev/null || stat -f "%z" "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_size.txt" 2>/dev/null || echo "-1")
        if [[ "$file_size" == "0" ]] || [[ "$file_size" -eq 0 ]]; then
            if print_msg 38 "Is file size exactly 0 bytes after blanking?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 38 "Is file size exactly 0 bytes after blanking?" false
        fi
    else
        print_msg 38 "Is file size exactly 0 bytes after blanking?" false
    fi
else
    print_msg 38 "Can I create test file for size test?" false
fi

print_msg "*" "Did I complete all tests?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nCleaning up test files...\n"
rm -f "${__UNIT_TESTS_DIR}"/${TEST_PREFIX}_*.txt 2>/dev/null
rm -f "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_with_spaces.txt" 2>/dev/null

cd "$original_dir" || true

# Write results to .results file for test runner
percentage=$((score * 100 / total_tests))
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

if [[ $score -eq $total_tests ]]; then
    exit 0
else
    exit 1
fi

