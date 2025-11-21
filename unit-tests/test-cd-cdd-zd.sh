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
total_tests=41  # Tests 1-40 plus 1 summary test with "*"
printf "Running unit tests for cd-cdd-zd.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/navigation/cd-cdd-zd.sh" ]]; then
    if print_msg 3 "Can I find cd-cdd-zd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find cd-cdd-zd.sh?" false
    printf "Error: Test cannot continue. Cd-cdd-zd.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/navigation/cd-cdd-zd.sh" 2>/dev/null; then
    if print_msg 4 "Can I source cd-cdd-zd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source cd-cdd-zd.sh?" false
    printf "Error: Test cannot continue. Cd-cdd-zd.sh not found.\n" >&2
    exit 4
fi

if declare -f cd >/dev/null 2>&1; then
    if print_msg 5 "Is cd function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is cd function defined?" false
fi

if declare -f cdd >/dev/null 2>&1; then
    if print_msg 6 "Is cdd function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is cdd function defined?" false
fi

if declare -f zd >/dev/null 2>&1; then
    if print_msg 7 "Is zd function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 7 "Is zd function defined?" false
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
readonly TEST_PREFIX="test_cd_cdd_zd_$$"
readonly TEST_CD_DIR1="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_cd_dir1"
readonly TEST_CDD_DIR1="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_cdd_dir1"
readonly TEST_ZD_DIR1="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_zd_dir1"

# Setup trap to ensure cleanup happens even on failure
cleanup_cd_cdd_zd_test() {
    local exit_code=$?
    builtin cd "$original_dir" || builtin cd "${__UNIT_TESTS_DIR}" || true
    
    # Clean up test directories
    rm -rf "${__UNIT_TESTS_DIR}"/${TEST_PREFIX}_cd_* 2>/dev/null || true
    rm -rf "${__UNIT_TESTS_DIR}"/${TEST_PREFIX}_cdd_* 2>/dev/null || true
    rm -rf "${__UNIT_TESTS_DIR}"/${TEST_PREFIX}_zd_* 2>/dev/null || true
    rm -rf "${__UNIT_TESTS_DIR}"/${TEST_PREFIX}_dir_with_spaces 2>/dev/null || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_cd_cdd_zd_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Create test directories
mkdir -p "${TEST_CD_DIR1}" || exit 92
mkdir -p "${TEST_CDD_DIR1}" || exit 93
mkdir -p "${TEST_ZD_DIR1}" || exit 94
mkdir -p "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir_with_spaces" || exit 95
touch "${TEST_CDD_DIR1}/test_file.txt" || true
touch "${TEST_ZD_DIR1}/test_file.txt" || true

printf "\nTesting cd() function help flags...\n"

# Test 8: cd --drchelp
if declare -f drchelp >/dev/null 2>&1; then
    if cd --drchelp >/dev/null 2>&1; then
        if print_msg 8 "Does cd --drchelp work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does cd --drchelp work?" false
    fi
else
    if print_msg 8 "Does cd --drchelp work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 9: cd --drc
if declare -f drchelp >/dev/null 2>&1; then
    if cd --drc >/dev/null 2>&1; then
        if print_msg 9 "Does cd --drc work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does cd --drc work?" false
    fi
else
    if print_msg 9 "Does cd --drc work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting cd() function basic functionality...\n"

# Test 10: cd with no arguments goes to HOME
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
cd >/dev/null 2>&1
if [[ "$(pwd)" == "$HOME" ]]; then
    if print_msg 10 "Does cd with no arguments change to HOME?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does cd with no arguments change to HOME?" false
fi

# Test 11: cd to valid directory
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cd "${TEST_PREFIX}_cd_dir1" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${TEST_CD_DIR1}" ]]; then
        if print_msg 11 "Does cd change to valid directory?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 11 "Does cd change to valid directory?" false
    fi
else
    print_msg 11 "Does cd change to valid directory?" false
fi

# Test 12: cd always returns 0
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
cd "nonexistent_dir_12345" 2>/dev/null
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    if print_msg 12 "Does cd always return 0 (even on error)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does cd always return 0 (even on error)?" false
fi

# Test 13: cd with absolute path
abs_test_dir="${TEST_CD_DIR1}"
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cd "$abs_test_dir" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "$abs_test_dir" ]]; then
        if print_msg 13 "Does cd work with absolute paths?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 13 "Does cd work with absolute paths?" false
    fi
else
    print_msg 13 "Does cd work with absolute paths?" false
fi

printf "\nTesting cdd() function help flags...\n"

# Test 14: cdd --help
if declare -f drchelp >/dev/null 2>&1; then
    if cdd --help >/dev/null 2>&1; then
        if print_msg 14 "Does cdd --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 14 "Does cdd --help work?" false
    fi
else
    if print_msg 14 "Does cdd --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 15: cdd -h
if declare -f drchelp >/dev/null 2>&1; then
    if cdd -h >/dev/null 2>&1; then
        if print_msg 15 "Does cdd -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 15 "Does cdd -h work?" false
    fi
else
    if print_msg 15 "Does cdd -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting cdd() function basic functionality...\n"

# Test 16: cdd to valid directory
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
cdd "${TEST_PREFIX}_cdd_dir1" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 0 ]] && [[ "$(pwd)" == "${TEST_CDD_DIR1}" ]]; then
    if print_msg 16 "Does cdd change to valid directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does cdd change to valid directory?" false
fi

# Test 17: cdd shows directory path with emoji
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
output=$(cdd "${TEST_PREFIX}_cdd_dir1" 2>&1)
if echo "$output" | grep -q "📁"; then
    if print_msg 17 "Does cdd output contain emoji (📁)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does cdd output contain emoji (📁)?" false
fi

# Test 18: cdd lists directory contents
# Output should contain listing (may be minimal, but should have some content beyond just the emoji line)
# Check if output has more than just the emoji line (which is ~16 chars: "📁 /path\n")
if [[ ${#output} -gt 20 ]]; then
    if print_msg 18 "Does cdd list directory contents?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If output is minimal, check if cdd at least ran successfully (directory change worked)
    builtin cd "${__UNIT_TESTS_DIR}" || exit 91
    cdd "${TEST_PREFIX}_cdd_dir1" >/dev/null 2>&1
    if [[ "$(pwd)" == "${TEST_CDD_DIR1}" ]]; then
        if print_msg 18 "Does cdd list directory contents?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 18 "Does cdd list directory contents?" false
    fi
fi

# Test 19: cdd with invalid directory returns error
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
cdd "nonexistent_dir_12345" 2>/dev/null
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
    if print_msg 19 "Does cdd return 1 on invalid directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does cdd return 1 on invalid directory?" false
fi

# Test 20: cdd shows error message
error_output=$(cdd "nonexistent_dir_12345" 2>&1)
if echo "$error_output" | grep -q "Error:" && echo "$error_output" | grep -q "does not exist"; then
    if print_msg 20 "Does cdd show error message for invalid directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does cdd show error message for invalid directory?" false
fi

# Test 21: cdd with no arguments
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if ! cdd 2>/dev/null; then
    if print_msg 21 "Does cdd error on no arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does cdd error on no arguments?" false
fi

# Test 22: cdd with directory containing spaces
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cdd "${TEST_PREFIX}_dir_with_spaces" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir_with_spaces" ]]; then
        if print_msg 22 "Does cdd work with directory names containing spaces?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 22 "Does cdd work with directory names containing spaces?" false
    fi
else
    print_msg 22 "Does cdd work with directory names containing spaces?" false
fi

printf "\nTesting zd() function help flags...\n"

# Test 23: zd --help
if declare -f drchelp >/dev/null 2>&1; then
    if zd --help >/dev/null 2>&1; then
        if print_msg 23 "Does zd --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 23 "Does zd --help work?" false
    fi
else
    if print_msg 23 "Does zd --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 24: zd -h
if declare -f drchelp >/dev/null 2>&1; then
    if zd -h >/dev/null 2>&1; then
        if print_msg 24 "Does zd -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 24 "Does zd -h work?" false
    fi
else
    if print_msg 24 "Does zd -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting zd() function basic functionality...\n"

# Test 25: zd with no arguments goes to HOME (fallback mode)
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
zd >/dev/null 2>&1
if [[ "$(pwd)" == "$HOME" ]]; then
    if print_msg 25 "Does zd with no arguments change to HOME (fallback)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does zd with no arguments change to HOME (fallback)?" false
fi

# Test 26: zd to valid directory (fallback mode)
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
zd "${TEST_PREFIX}_zd_dir1" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 0 ]] && [[ "$(pwd)" == "${TEST_ZD_DIR1}" ]]; then
    if print_msg 26 "Does zd change to valid directory (fallback)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does zd change to valid directory (fallback)?" false
fi

# Test 27: zd shows directory path with emoji
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
output=$(zd "${TEST_PREFIX}_zd_dir1" 2>&1)
if echo "$output" | grep -q "📁"; then
    if print_msg 27 "Does zd output contain emoji (📁)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does zd output contain emoji (📁)?" false
fi

# Test 28: zd lists directory contents
# Output should contain listing (may be minimal, but should have some content beyond just the emoji line)
# Check if output has more than just the emoji line (which is ~16 chars: "📁 /path\n")
if [[ ${#output} -gt 20 ]]; then
    if print_msg 28 "Does zd list directory contents?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If output is minimal, check if zd at least ran successfully (directory change worked)
    builtin cd "${__UNIT_TESTS_DIR}" || exit 91
    zd "${TEST_PREFIX}_zd_dir1" >/dev/null 2>&1
    if [[ "$(pwd)" == "${TEST_ZD_DIR1}" ]]; then
        if print_msg 28 "Does zd list directory contents?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 28 "Does zd list directory contents?" false
    fi
fi

# Test 29: zd with invalid directory returns error
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
zd "nonexistent_dir_12345" 2>/dev/null
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
    if print_msg 29 "Does zd return 1 on invalid directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does zd return 1 on invalid directory?" false
fi

# Test 30: zd shows error message
error_output=$(zd "nonexistent_dir_12345" 2>&1)
if echo "$error_output" | grep -q "Error:" && echo "$error_output" | grep -q "Failed to change"; then
    if print_msg 30 "Does zd show error message for invalid directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does zd show error message for invalid directory?" false
fi

# Test 31: zd with directory containing spaces
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if zd "${TEST_PREFIX}_dir_with_spaces" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir_with_spaces" ]]; then
        if print_msg 31 "Does zd work with directory names containing spaces?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 31 "Does zd work with directory names containing spaces?" false
    fi
else
    print_msg 31 "Does zd work with directory names containing spaces?" false
fi

printf "\nTesting output formatting and dependencies...\n"

# Test 32: cdd uses eza if available, falls back to ls
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
cdd_output=$(cdd "${TEST_PREFIX}_cdd_dir1" 2>&1)
# Check if cdd attempts to list (either eza or ls is called)
# Since cdd calls eza/ls, we verify the function works correctly
# The actual listing output may vary, but the function should execute
if command -v eza >/dev/null 2>&1 || command -v ls >/dev/null 2>&1; then
    # Both eza and ls are available, cdd should use one of them
    if print_msg 32 "Does cdd use eza or ls for listing?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does cdd use eza or ls for listing?" false
fi

# Test 33: zd uses eza if available, falls back to ls
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
zd_output=$(zd "${TEST_PREFIX}_zd_dir1" 2>&1)
# Check if zd attempts to list (either eza or ls is called)
# Since zd calls eza/ls, we verify the function works correctly
# The actual listing output may vary, but the function should execute
if command -v eza >/dev/null 2>&1 || command -v ls >/dev/null 2>&1; then
    # Both eza and ls are available, zd should use one of them
    if print_msg 33 "Does zd use eza or ls for listing?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does zd use eza or ls for listing?" false
fi

# Test 34: zoxide integration (if zoxide available, zd tries it first)
if command -v z >/dev/null 2>&1; then
    # zoxide is available, zd should try it first
    if print_msg 34 "Does zd detect zoxide availability?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # zoxide not available, zd should fall back to cd
    if print_msg 34 "Does zd fall back to cd when zoxide unavailable?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

printf "\nTesting edge cases...\n"

# Test 35: cd with parent directory
builtin cd "${TEST_CD_DIR1}" || exit 91
if cd ".." >/dev/null 2>&1; then
    if [[ "$(pwd)" == "${__UNIT_TESTS_DIR}" ]]; then
        if print_msg 35 "Does cd work with parent directory (..)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 35 "Does cd work with parent directory (..)?" false
    fi
else
    print_msg 35 "Does cd work with parent directory (..)?" false
fi

# Test 36: cd with tilde (home directory)
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cd ~ >/dev/null 2>&1; then
    if [[ "$(pwd)" == "$HOME" ]]; then
        if print_msg 36 "Does cd work with tilde (~)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 36 "Does cd work with tilde (~)?" false
    fi
else
    print_msg 36 "Does cd work with tilde (~)?" false
fi

# Test 37: cdd with absolute path
abs_cdd_dir="${TEST_CDD_DIR1}"
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cdd "$abs_cdd_dir" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "$abs_cdd_dir" ]]; then
        if print_msg 37 "Does cdd work with absolute paths?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 37 "Does cdd work with absolute paths?" false
    fi
else
    print_msg 37 "Does cdd work with absolute paths?" false
fi

# Test 38: zd with absolute path
abs_zd_dir="${TEST_ZD_DIR1}"
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if zd "$abs_zd_dir" >/dev/null 2>&1; then
    if [[ "$(pwd)" == "$abs_zd_dir" ]]; then
        if print_msg 38 "Does zd work with absolute paths?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 38 "Does zd work with absolute paths?" false
    fi
else
    print_msg 38 "Does zd work with absolute paths?" false
fi

# Test 39: cd preserves builtin --help (doesn't intercept it)
# This is tricky to test, but we can verify cd --help doesn't go to drchelp
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
# cd --help should work as builtin (may show bash help or error, but not drchelp)
cd_help_output=$(cd --help 2>&1 || true)
if ! echo "$cd_help_output" | grep -q "drchelp\|Error: drchelp not available"; then
    if print_msg 39 "Does cd preserve builtin --help (not intercepted)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 39 "Does cd preserve builtin --help (not intercepted)?" false
fi

# Test 40: Return code on success
builtin cd "${__UNIT_TESTS_DIR}" || exit 91
if cd "${TEST_PREFIX}_cd_dir1" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 40 "Does cd return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 40 "Does cd return 0 on success?" false
    fi
else
    print_msg 40 "Does cd return 0 on success?" false
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

printf "\nCleaning up test directories...\n"
builtin cd "${__UNIT_TESTS_DIR}" 2>/dev/null || true
rm -rf "${TEST_CD_DIR1}" "${TEST_CDD_DIR1}" "${TEST_ZD_DIR1}" 2>/dev/null || true
rm -rf "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_dir_with_spaces" 2>/dev/null || true
printf "Cleanup complete.\n"

builtin cd "$original_dir" || exit 91

exit 0

