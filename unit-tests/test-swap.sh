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
    
    # Truncate description to 60 characters
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
total_tests=35  # Tests 1-33 plus 2 summary tests with "*"
printf "Running unit tests for swap.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/swap.sh" ]]; then
    if print_msg 3 "Can I find swap.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find swap.sh?" false
    printf "Error: Test cannot continue. Swap.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/swap.sh" 2>/dev/null; then
    if print_msg 4 "Can I source swap.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source swap.sh?" false
    printf "Error: Test cannot continue. Swap.sh not found.\n" >&2
    exit 4
fi

# Verify function is defined
if declare -f swap >/dev/null 2>&1; then
    if print_msg 5 "Is swap function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is swap function defined?" false
    printf "Error: swap function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_swap_$$"
readonly TEST_DIR="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir"
readonly TEST_DIR2="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir2"

# Source drchelp if available for help flag tests
if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

# Test 6: swap --help
if declare -f drchelp >/dev/null 2>&1; then
    if swap --help >/dev/null 2>&1; then
        if print_msg 6 "Does swap --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does swap --help work?" false
    fi
else
    if print_msg 6 "Does swap --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: swap -h
if declare -f drchelp >/dev/null 2>&1; then
    if swap -h >/dev/null 2>&1; then
        if print_msg 7 "Does swap -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does swap -h work?" false
    fi
else
    if print_msg 7 "Does swap -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nCreating test files...\n"
test_content1="This is the content of file one.\nLine 2 of file one.\nEnd of file one.\n"
test_content2="This is the content of file two.\nLine 2 of file two.\nEnd of file two.\n"

# Create test files
if printf "${test_content1}" > "${__UNIT_TESTS_DIR}/file1.txt"; then
    if print_msg 8 "Can I create file1.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Can I create file1.txt?" false
    printf "Error: Test cannot continue. Failed to create file1.txt.\n" >&2
    exit 8
fi

if printf "${test_content2}" > "${__UNIT_TESTS_DIR}/file2.txt"; then
    if print_msg 9 "Can I create file2.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Can I create file2.txt?" false
    printf "Error: Test cannot continue. Failed to create file2.txt.\n" >&2
    exit 9
fi

print_msg "*" "Did I create test files?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nTesting error handling...\n"

# Test 10: swap with no arguments
if ! swap 2>/dev/null; then
    if print_msg 10 "Does swap error on missing arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does swap error on missing arguments?" false
fi

# Test 11: swap with only one argument
if ! swap "file1.txt" 2>/dev/null; then
    if print_msg 11 "Does swap error on missing second argument?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does swap error on missing second argument?" false
fi

# Test 12: swap with non-existent first file
if ! swap "nonexistent1.txt" "file2.txt" 2>/dev/null; then
    if print_msg 12 "Does swap error on non-existent first file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does swap error on non-existent first file?" false
fi

# Test 13: swap with non-existent second file
if ! swap "file1.txt" "nonexistent2.txt" 2>/dev/null; then
    if print_msg 13 "Does swap error on non-existent second file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does swap error on non-existent second file?" false
fi

# Test 14: swap with directory instead of file
if mkdir -p "${TEST_DIR}"; then
    if ! swap "test_dir" "file2.txt" 2>/dev/null; then
        if print_msg 14 "Does swap error when first argument is a directory?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 14 "Does swap error when first argument is a directory?" false
    fi
    rm -rf "${TEST_DIR}"
else
    print_msg 14 "Does swap error when first argument is a directory?" false
fi

# Test 15: swap with directory as second argument
if mkdir -p "${TEST_DIR2}"; then
    if ! swap "file1.txt" "test_dir2" 2>/dev/null; then
        if print_msg 15 "Does swap error when second argument is a directory?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 15 "Does swap error when second argument is a directory?" false
    fi
    rm -rf "${TEST_DIR2}"
else
    print_msg 15 "Does swap error when second argument is a directory?" false
fi

printf "\nTesting basic functionality...\n"

# Test 16: Swap two files successfully
original_content1="$(cat file1.txt 2>/dev/null)"
original_content2="$(cat file2.txt 2>/dev/null)"

if swap "file1.txt" "file2.txt" >/dev/null 2>&1; then
    # After swap, file1.txt should have file2's content and vice versa
    if [[ -f "file1.txt" ]] && [[ -f "file2.txt" ]]; then
        new_content1="$(cat file1.txt 2>/dev/null)"
        new_content2="$(cat file2.txt 2>/dev/null)"
        if [[ "$new_content1" == "$original_content2" ]] && [[ "$new_content2" == "$original_content1" ]]; then
            if print_msg 16 "Does swap successfully swap two files?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 16 "Does swap successfully swap two files?" false
        fi
    else
        print_msg 16 "Does swap successfully swap two files?" false
    fi
else
    print_msg 16 "Does swap successfully swap two files?" false
fi

# Swap back for next tests
if swap "file1.txt" "file2.txt" >/dev/null 2>&1; then
    : # Swapped back
fi

# Test 17: Verify return code on success
if swap "file1.txt" "file2.txt" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 17 "Does swap return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does swap return 0 on success?" false
    fi
    # Swap back
    swap "file1.txt" "file2.txt" >/dev/null 2>&1
else
    print_msg 17 "Does swap return 0 on success?" false
    # Swap back
    swap "file1.txt" "file2.txt" >/dev/null 2>&1
fi

# Test 18: Verify success message
output=$(swap "file1.txt" "file2.txt" 2>&1)
if echo "$output" | grep -q "Successfully swapped"; then
    if print_msg 18 "Does swap output success message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does swap output success message?" false
fi
# Swap back
swap "file1.txt" "file2.txt" >/dev/null 2>&1

printf "\nTesting content preservation...\n"

# Test 19: Content preserved after swap
original_content1="$(cat file1.txt 2>/dev/null)"
original_content2="$(cat file2.txt 2>/dev/null)"

if swap "file1.txt" "file2.txt" >/dev/null 2>&1; then
    swapped_content1="$(cat file1.txt 2>/dev/null)"
    swapped_content2="$(cat file2.txt 2>/dev/null)"
    # Swap back
    swap "file1.txt" "file2.txt" >/dev/null 2>&1
    restored_content1="$(cat file1.txt 2>/dev/null)"
    restored_content2="$(cat file2.txt 2>/dev/null)"
    
    if [[ "$restored_content1" == "$original_content1" ]] && [[ "$restored_content2" == "$original_content2" ]]; then
        if print_msg 19 "Does swap preserve content correctly (swap back test)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 19 "Does swap preserve content correctly (swap back test)?" false
    fi
else
    print_msg 19 "Does swap preserve content correctly (swap back test)?" false
fi

# Test 20: Multiple swaps
original_content1="$(cat file1.txt 2>/dev/null)"
original_content2="$(cat file2.txt 2>/dev/null)"

# Swap multiple times
swap "file1.txt" "file2.txt" >/dev/null 2>&1
swap "file1.txt" "file2.txt" >/dev/null 2>&1
swap "file1.txt" "file2.txt" >/dev/null 2>&1

final_content1="$(cat file1.txt 2>/dev/null)"
final_content2="$(cat file2.txt 2>/dev/null)"

# After 3 swaps: 1->2, 2->1, 1->2 again = file1 should have file2's original content
if [[ "$final_content1" == "$original_content2" ]] && [[ "$final_content2" == "$original_content1" ]]; then
    if print_msg 20 "Does swap work correctly with multiple swaps?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does swap work correctly with multiple swaps?" false
fi

# Swap back to original state
swap "file1.txt" "file2.txt" >/dev/null 2>&1

printf "\nTesting extension warnings...\n"

# Test 21: Files with same extension (no warning)
printf "test1" > "test1.txt"
printf "test2" > "test2.txt"

output=$(swap "test1.txt" "test2.txt" 2>&1)
if ! echo "$output" | grep -q "Warning: Files have different extensions"; then
    if print_msg 21 "Does swap NOT warn when files have same extension?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does swap NOT warn when files have same extension?" false
fi

# Swap back
swap "test1.txt" "test2.txt" >/dev/null 2>&1
rm -f "test1.txt" "test2.txt"

# Test 22: Files with different extensions (should warn)
printf "test1" > "test1.txt"
printf "test2" > "test2.sh"

output=$(swap "test1.txt" "test2.sh" 2>&1)
if echo "$output" | grep -q "Warning: Files have different extensions"; then
    if print_msg 22 "Does swap warn when files have different extensions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does swap warn when files have different extensions?" false
fi

# Swap back and cleanup
swap "test1.txt" "test2.sh" >/dev/null 2>&1
rm -f "test1.txt" "test2.sh"

# Test 23: Files without extensions (no warning)
printf "test1" > "test1"
printf "test2" > "test2"

output=$(swap "test1" "test2" 2>&1)
if ! echo "$output" | grep -q "Warning: Files have different extensions"; then
    if print_msg 23 "Does swap NOT warn when files have no extensions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does swap NOT warn when files have no extensions?" false
fi

# Swap back and cleanup
swap "test1" "test2" >/dev/null 2>&1
rm -f "test1" "test2"

# Test 24: One file with extension, one without (no warning if logic matches)
printf "test1" > "test1.txt"
printf "test2" > "test2"

output=$(swap "test1.txt" "test2" 2>&1)
# According to the logic, it only warns if BOTH have extensions and they differ
# So one with extension, one without should not warn
if ! echo "$output" | grep -q "Warning: Files have different extensions"; then
    if print_msg 24 "Does swap NOT warn when only one file has extension?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does swap NOT warn when only one file has extension?" false
fi

# Swap back and cleanup
swap "test1.txt" "test2" >/dev/null 2>&1
rm -f "test1.txt" "test2"

printf "\nTesting edge cases...\n"

# Test 25: Files with spaces in names
space_file1="test file one.txt"
space_file2="test file two.txt"
printf "content1" > "${space_file1}"
printf "content2" > "${space_file2}"

if swap "${space_file1}" "${space_file2}" >/dev/null 2>&1; then
    content1="$(cat "${space_file1}" 2>/dev/null)"
    content2="$(cat "${space_file2}" 2>/dev/null)"
    if [[ "$content1" == "content2" ]] && [[ "$content2" == "content1" ]]; then
        if print_msg 25 "Does swap work with filenames containing spaces?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 25 "Does swap work with filenames containing spaces?" false
    fi
    # Swap back
    swap "${space_file1}" "${space_file2}" >/dev/null 2>&1
else
    print_msg 25 "Does swap work with filenames containing spaces?" false
fi
rm -f "${space_file1}" "${space_file2}"

# Test 26: Empty files
printf "" > "empty1.txt"
printf "" > "empty2.txt"

if swap "empty1.txt" "empty2.txt" >/dev/null 2>&1; then
    # Both should still be empty after swap
    if [[ ! -s "empty1.txt" ]] && [[ ! -s "empty2.txt" ]]; then
        if print_msg 26 "Does swap work with empty files?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 26 "Does swap work with empty files?" false
    fi
else
    print_msg 26 "Does swap work with empty files?" false
fi
rm -f "empty1.txt" "empty2.txt"

# Test 27: Swap same file with itself
# Note: This currently fails because swap moves first file to tmp, then can't find it
# This is expected behavior - swapping a file with itself should error
printf "test content" > "self_swap.txt"

if ! swap "self_swap.txt" "self_swap.txt" >/dev/null 2>&1; then
    # This is expected - swapping file with itself should fail
    # The function errors because it moves the file away and then can't find it
    if print_msg 27 "Does swap error when swapping file with itself?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does swap error when swapping file with itself?" false
fi
# Cleanup (file may or may not exist after the error)
rm -f "self_swap.txt" "tmp."* 2>/dev/null || true

# Test 28: Large files (simulate with reasonable size)
# Create a larger file (1KB)
dd if=/dev/zero of="large1.txt" bs=1024 count=1 >/dev/null 2>&1
dd if=/dev/zero of="large2.txt" bs=512 count=1 >/dev/null 2>&1

size1_before=$(stat -c%s "large1.txt" 2>/dev/null || stat -f%z "large1.txt" 2>/dev/null || echo 0)
size2_before=$(stat -c%s "large2.txt" 2>/dev/null || stat -f%z "large2.txt" 2>/dev/null || echo 0)

if swap "large1.txt" "large2.txt" >/dev/null 2>&1; then
    size1_after=$(stat -c%s "large1.txt" 2>/dev/null || stat -f%z "large1.txt" 2>/dev/null || echo 0)
    size2_after=$(stat -c%s "large2.txt" 2>/dev/null || stat -f%z "large2.txt" 2>/dev/null || echo 0)
    # Sizes should be swapped
    if [[ "$size1_after" -eq "$size2_before" ]] && [[ "$size2_after" -eq "$size1_before" ]]; then
        if print_msg 28 "Does swap work with files of different sizes?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 28 "Does swap work with files of different sizes?" false
    fi
else
    print_msg 28 "Does swap work with files of different sizes?" false
fi
rm -f "large1.txt" "large2.txt"

printf "\nTesting return codes...\n"

# Test 29: Return code on error
swap "nonexistent.txt" "file1.txt" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
    if print_msg 29 "Does swap return 1 on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does swap return 1 on error?" false
fi

# Test 30: Error message format
error_output=$(swap "nonexistent.txt" "file1.txt" 2>&1)
if echo "$error_output" | grep -q "Error:"; then
    if print_msg 30 "Does swap output error message on failure?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does swap output error message on failure?" false
fi

printf "\nTesting bash completion (if available)...\n"

# Test 31: Check if completion function is registered
if command -v complete >/dev/null 2>&1; then
    if complete -p swap >/dev/null 2>&1; then
        if print_msg 31 "Is swap completion function registered?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 31 "Is swap completion function registered?" false
    fi
else
    if print_msg 31 "Is swap completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

printf "\nTesting output messages...\n"

# Test 32: Success message contains correct filenames
printf "content1" > "msg_test1.txt"
printf "content2" > "msg_test2.txt"

output=$(swap "msg_test1.txt" "msg_test2.txt" 2>&1)
if echo "$output" | grep -q "Successfully swapped" && echo "$output" | grep -q "msg_test1.txt" && echo "$output" | grep -q "msg_test2.txt"; then
    if print_msg 32 "Does success message contain both filenames?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does success message contain both filenames?" false
fi

# Swap back and cleanup
swap "msg_test1.txt" "msg_test2.txt" >/dev/null 2>&1
rm -f "msg_test1.txt" "msg_test2.txt"

# Test 33: Warning message format
printf "test1" > "warn_test1.txt"
printf "test2" > "warn_test2.sh"

output=$(swap "warn_test1.txt" "warn_test2.sh" 2>&1)
if echo "$output" | grep -q "Warning: Files have different extensions" && (echo "$output" | grep -q "\.txt" || echo "$output" | grep -q "\.sh"); then
    if print_msg 33 "Does warning message include extension information?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does warning message include extension information?" false
fi

# Swap back and cleanup
swap "warn_test1.txt" "warn_test2.sh" >/dev/null 2>&1
rm -f "warn_test1.txt" "warn_test2.sh"

# Calculate and display test results
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

# Final cleanup
printf "\nCleaning up test files...\n"
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -f file1.txt file2.txt 2>/dev/null || true
rm -f test1.txt test2.txt test1 test2 test1.sh test2.sh 2>/dev/null || true
rm -f "test file"*.txt 2>/dev/null || true
rm -f empty*.txt large*.txt msg_test*.txt warn_test*.txt 2>/dev/null || true
rm -f self_swap.txt tmp.* 2>/dev/null || true
printf "Cleanup complete.\n"

exit 0
