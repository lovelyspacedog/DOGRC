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
total_tests=46  # Tests 1-6 (sanity), 7-45 (functional), plus 1 summary (*)
printf "Running unit tests for sort-downloads.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/sort-downloads.sh" ]]; then
    if print_msg 3 "Can I find sort-downloads.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find sort-downloads.sh?" false
    printf "Error: Test cannot continue. Sort-downloads.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/sort-downloads.sh" 2>/dev/null; then
    if print_msg 4 "Can I source sort-downloads.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source sort-downloads.sh?" false
    printf "Error: Test cannot continue. Sort-downloads.sh not found.\n" >&2
    exit 4
fi

if declare -f sort-downloads >/dev/null 2>&1; then
    if print_msg 5 "Is sort-downloads function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is sort-downloads function defined?" false
    printf "Error: sort-downloads function not defined.\n" >&2
    exit 5
fi

if declare -f sortdl >/dev/null 2>&1; then
    if print_msg 6 "Is sortdl function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is sortdl function defined?" false
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

# Unique prefix for this test run (timestamp + process ID + test name)
# Using timestamp + PID ensures uniqueness in parallel execution
readonly TEST_PREFIX="test_sort_downloads_$(date +%s)_$$"
readonly TEST_DIR="${__UNIT_TESTS_DIR}/${TEST_PREFIX}"

# Create isolated test directory (parallel-safe)
mkdir -p "$TEST_DIR" || {
    printf "Error: Failed to create test directory.\n" >&2
    exit 99
}

# Cleanup function (parallel-safe)
cleanup() {
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
}

# Register cleanup function
trap cleanup EXIT INT TERM

# Source drchelp for help flag tests
if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

# Test 7: Test --help flag
if declare -f drchelp >/dev/null 2>&1; then
    if sort-downloads --help 2>&1 | grep -q "sort-downloads"; then
        if print_msg 7 "Does sort-downloads --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does sort-downloads --help work?" false
    fi
else
    print_msg 7 "Does sort-downloads --help work?" false
    printf "        (drchelp not available, skipping)\n"
fi

# Test 8: Test -h flag
if declare -f drchelp >/dev/null 2>&1; then
    if sort-downloads -h 2>&1 | grep -q "sort-downloads"; then
        if print_msg 8 "Does sort-downloads -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 8 "Does sort-downloads -h work?" false
    fi
else
    print_msg 8 "Does sort-downloads -h work?" false
fi

# Test 9: Test drchelp integration
if declare -f drchelp >/dev/null 2>&1; then
    if drchelp sort-downloads 2>&1 | grep -q "sort-downloads"; then
        if print_msg 9 "Is sort-downloads documented in drchelp?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 9 "Is sort-downloads documented in drchelp?" false
    fi
else
    print_msg 9 "Is sort-downloads documented in drchelp?" false
fi

printf "\nTesting error handling...\n"

# Test 10: Error when directory doesn't exist
if ! sort-downloads "/nonexistent/path/$$" 2>&1 | grep -qi "does not exist"; then
    if print_msg 10 "Does sort-downloads error when directory doesn't exist?" false; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    if print_msg 10 "Does sort-downloads error when directory doesn't exist?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

# Test 11: Error when --directory has no argument
if ! sort-downloads --directory 2>&1 | grep -qi "requires a path"; then
    if print_msg 11 "Does sort-downloads error when --directory has no argument?" false; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    if print_msg 11 "Does sort-downloads error when --directory has no argument?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

# Test 12: Error on unknown flags
if ! sort-downloads --unknown-flag 2>&1 | grep -qi "Unknown option"; then
    if print_msg 12 "Does sort-downloads error on unknown flags?" false; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    if print_msg 12 "Does sort-downloads error on unknown flags?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

printf "\nTesting empty directory handling...\n"

# Test 13: Handle empty directory
TEST_EMPTY_DIR="${TEST_DIR}/empty_test"
mkdir -p "$TEST_EMPTY_DIR" 2>/dev/null || true

if sort-downloads "$TEST_EMPTY_DIR" 2>&1 | grep -q "No files found"; then
    if print_msg 13 "Does sort-downloads handle empty directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does sort-downloads handle empty directory?" false
fi

# Test 14: Handle directory with only subdirectories (no files)
TEST_SUBDIR_ONLY="${TEST_DIR}/subdir_only"
mkdir -p "${TEST_SUBDIR_ONLY}/subdir" 2>/dev/null || true
echo "test" > "${TEST_SUBDIR_ONLY}/subdir/file.txt" 2>/dev/null || true

if sort-downloads "$TEST_SUBDIR_ONLY" 2>&1 | grep -q "No files found"; then
    if print_msg 14 "Does sort-downloads handle directory with only subdirectories?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does sort-downloads handle directory with only subdirectories?" false
fi

printf "\nTesting extension-based organization...\n"

# Test 15: Organize by extension (default)
TEST_EXT_DIR="${TEST_DIR}/ext_test"
mkdir -p "$TEST_EXT_DIR" 2>/dev/null || true
echo "test" > "${TEST_EXT_DIR}/file1.txt" 2>/dev/null || true
echo "test" > "${TEST_EXT_DIR}/file2.pdf" 2>/dev/null || true
echo "test" > "${TEST_EXT_DIR}/file3.jpg" 2>/dev/null || true

if sort-downloads "$TEST_EXT_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_EXT_DIR}/txt/file1.txt" ]] && \
       [[ -f "${TEST_EXT_DIR}/pdf/file2.pdf" ]] && \
       [[ -f "${TEST_EXT_DIR}/jpg/file3.jpg" ]]; then
        if print_msg 15 "Does sort-downloads organize files by extension?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 15 "Does sort-downloads organize files by extension?" false
    fi
else
    print_msg 15 "Does sort-downloads organize files by extension?" false
fi

# Test 16: Extension directories are lowercase
TEST_EXT2_DIR="${TEST_DIR}/ext2_test"
mkdir -p "$TEST_EXT2_DIR" 2>/dev/null || true
echo "test" > "${TEST_EXT2_DIR}/file.PDF" 2>/dev/null || true

if sort-downloads "$TEST_EXT2_DIR" >/dev/null 2>&1; then
    if [[ -d "${TEST_EXT2_DIR}/pdf" ]] && [[ -f "${TEST_EXT2_DIR}/pdf/file.PDF" ]]; then
        if print_msg 16 "Does sort-downloads convert extensions to lowercase?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 16 "Does sort-downloads convert extensions to lowercase?" false
    fi
else
    print_msg 16 "Does sort-downloads convert extensions to lowercase?" false
fi

# Test 17: Files without extensions go to no-extension
TEST_NOEXT_DIR="${TEST_DIR}/noext_test"
mkdir -p "$TEST_NOEXT_DIR" 2>/dev/null || true
echo "test" > "${TEST_NOEXT_DIR}/file_noext" 2>/dev/null || true

if sort-downloads "$TEST_NOEXT_DIR" >/dev/null 2>&1; then
    if [[ -d "${TEST_NOEXT_DIR}/no-extension" ]] && \
       [[ -f "${TEST_NOEXT_DIR}/no-extension/file_noext" ]]; then
        if print_msg 17 "Does sort-downloads handle files without extensions?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 17 "Does sort-downloads handle files without extensions?" false
    fi
else
    print_msg 17 "Does sort-downloads handle files without extensions?" false
fi

# Test 18: Does not process files in subdirectories
TEST_SUBDIR2="${TEST_DIR}/subdir2_test"
mkdir -p "${TEST_SUBDIR2}/subdir" 2>/dev/null || true
echo "test" > "${TEST_SUBDIR2}/top_level.txt" 2>/dev/null || true
echo "test" > "${TEST_SUBDIR2}/subdir/should_not_move.txt" 2>/dev/null || true

if sort-downloads "$TEST_SUBDIR2" >/dev/null 2>&1; then
    if [[ -f "${TEST_SUBDIR2}/subdir/should_not_move.txt" ]] && \
       [[ -f "${TEST_SUBDIR2}/txt/top_level.txt" ]]; then
        if print_msg 18 "Does sort-downloads only process top-level files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 18 "Does sort-downloads only process top-level files?" false
    fi
else
    print_msg 18 "Does sort-downloads only process top-level files?" false
fi

printf "\nTesting date-based organization...\n"

# Test 19: Organize by date
TEST_DATE_DIR="${TEST_DIR}/date_test"
mkdir -p "$TEST_DATE_DIR" 2>/dev/null || true
# Create files with specific dates
touch -t 202401151200 "${TEST_DATE_DIR}/file1.txt" 2>/dev/null || \
    touch -t 20240115 "${TEST_DATE_DIR}/file1.txt" 2>/dev/null || \
    echo "test" > "${TEST_DATE_DIR}/file1.txt" 2>/dev/null || true

if sort-downloads --by-date "$TEST_DATE_DIR" >/dev/null 2>&1; then
    # Check if file was organized (date format may vary)
    if [[ ! -f "${TEST_DATE_DIR}/file1.txt" ]]; then
        # File was moved, check if it's in a date directory
        found=false
        for dir in "${TEST_DATE_DIR}"/*/; do
            if [[ -d "$dir" ]] && [[ -f "${dir}file1.txt" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == true ]]; then
            if print_msg 19 "Does sort-downloads organize files by date?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 19 "Does sort-downloads organize files by date?" false
        fi
    else
        print_msg 19 "Does sort-downloads organize files by date?" false
    fi
else
    print_msg 19 "Does sort-downloads organize files by date?" false
fi

# Test 20: --by-date flag works
TEST_DATE2_DIR="${TEST_DIR}/date2_test"
mkdir -p "$TEST_DATE2_DIR" 2>/dev/null || true
echo "test" > "${TEST_DATE2_DIR}/test.txt" 2>/dev/null || true

if sort-downloads --by-date "$TEST_DATE2_DIR" >/dev/null 2>&1; then
    # Should organize by date, not extension
    if [[ ! -d "${TEST_DATE2_DIR}/txt" ]] && [[ ! -f "${TEST_DATE2_DIR}/test.txt" ]]; then
        if print_msg 20 "Does --by-date flag work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 20 "Does --by-date flag work?" false
    fi
else
    print_msg 20 "Does --by-date flag work?" false
fi

printf "\nTesting dry-run mode...\n"

# Test 21: Dry-run shows what would be moved
TEST_DRY_DIR="${TEST_DIR}/dry_test"
mkdir -p "$TEST_DRY_DIR" 2>/dev/null || true
echo "test" > "${TEST_DRY_DIR}/dry_test.txt" 2>/dev/null || true

DRY_OUTPUT=$(sort-downloads --dry-run "$TEST_DRY_DIR" 2>&1)
if echo "$DRY_OUTPUT" | grep -q "DRY RUN MODE" && \
   echo "$DRY_OUTPUT" | grep -q "Would move" && \
   [[ -f "${TEST_DRY_DIR}/dry_test.txt" ]]; then
    if print_msg 21 "Does --dry-run show what would be moved?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does --dry-run show what would be moved?" false
fi

# Test 22: Dry-run doesn't create directories
TEST_DRY2_DIR="${TEST_DIR}/dry2_test"
mkdir -p "$TEST_DRY2_DIR" 2>/dev/null || true
echo "test" > "${TEST_DRY2_DIR}/test.txt" 2>/dev/null || true

sort-downloads --dry-run "$TEST_DRY2_DIR" >/dev/null 2>&1

if [[ ! -d "${TEST_DRY2_DIR}/txt" ]]; then
    if print_msg 22 "Does --dry-run not create directories?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does --dry-run not create directories?" false
fi

# Test 23: Dry-run doesn't modify files
TEST_DRY3_DIR="${TEST_DIR}/dry3_test"
mkdir -p "$TEST_DRY3_DIR" 2>/dev/null || true
echo "original" > "${TEST_DRY3_DIR}/test.txt" 2>/dev/null || true

sort-downloads --dry-run "$TEST_DRY3_DIR" >/dev/null 2>&1

if [[ -f "${TEST_DRY3_DIR}/test.txt" ]] && \
   [[ "$(cat "${TEST_DRY3_DIR}/test.txt" 2>/dev/null)" == "original" ]]; then
    if print_msg 23 "Does --dry-run not modify files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does --dry-run not modify files?" false
fi

printf "\nTesting custom directory...\n"

# Test 24: --directory flag works
TEST_CUSTOM_DIR="${TEST_DIR}/custom_test"
mkdir -p "$TEST_CUSTOM_DIR" 2>/dev/null || true
echo "test" > "${TEST_CUSTOM_DIR}/test.txt" 2>/dev/null || true

if sort-downloads --directory "$TEST_CUSTOM_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_CUSTOM_DIR}/txt/test.txt" ]]; then
        if print_msg 24 "Does --directory flag work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 24 "Does --directory flag work?" false
    fi
else
    print_msg 24 "Does --directory flag work?" false
fi

# Test 25: --dir short flag works
TEST_DIR2="${TEST_DIR}/dir2_test"
mkdir -p "$TEST_DIR2" 2>/dev/null || true
echo "test" > "${TEST_DIR2}/test.txt" 2>/dev/null || true

if sort-downloads --dir "$TEST_DIR2" >/dev/null 2>&1; then
    if [[ -f "${TEST_DIR2}/txt/test.txt" ]]; then
        if print_msg 25 "Does --dir short flag work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 25 "Does --dir short flag work?" false
    fi
else
    print_msg 25 "Does --dir short flag work?" false
fi

# Test 26: Positional directory argument works
TEST_POS_DIR="${TEST_DIR}/pos_test"
mkdir -p "$TEST_POS_DIR" 2>/dev/null || true
echo "test" > "${TEST_POS_DIR}/test.txt" 2>/dev/null || true

if sort-downloads "$TEST_POS_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_POS_DIR}/txt/test.txt" ]]; then
        if print_msg 26 "Does positional directory argument work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 26 "Does positional directory argument work?" false
    fi
else
    print_msg 26 "Does positional directory argument work?" false
fi

printf "\nTesting duplicate filename handling...\n"

# Test 27: Handles duplicate filenames
TEST_DUP_DIR="${TEST_DIR}/dup_test"
mkdir -p "${TEST_DUP_DIR}/txt" 2>/dev/null || true
echo "existing" > "${TEST_DUP_DIR}/txt/duplicate.txt" 2>/dev/null || true
echo "new" > "${TEST_DUP_DIR}/duplicate.txt" 2>/dev/null || true

if sort-downloads "$TEST_DUP_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_DUP_DIR}/txt/duplicate_1.txt" ]] || \
       [[ -f "${TEST_DUP_DIR}/txt/duplicate_2.txt" ]]; then
        if print_msg 27 "Does sort-downloads handle duplicate filenames?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 27 "Does sort-downloads handle duplicate filenames?" false
    fi
else
    print_msg 27 "Does sort-downloads handle duplicate filenames?" false
fi

# Test 28: Handles multiple duplicates
TEST_DUP2_DIR="${TEST_DIR}/dup2_test"
mkdir -p "${TEST_DUP2_DIR}/txt" 2>/dev/null || true
echo "1" > "${TEST_DUP2_DIR}/txt/file.txt" 2>/dev/null || true
echo "2" > "${TEST_DUP2_DIR}/txt/file_1.txt" 2>/dev/null || true
echo "3" > "${TEST_DUP2_DIR}/file.txt" 2>/dev/null || true

if sort-downloads "$TEST_DUP2_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_DUP2_DIR}/txt/file_2.txt" ]]; then
        if print_msg 28 "Does sort-downloads handle multiple duplicates?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 28 "Does sort-downloads handle multiple duplicates?" false
    fi
else
    print_msg 28 "Does sort-downloads handle multiple duplicates?" false
fi

# Test 29: Handles duplicates for files without extensions
TEST_DUP3_DIR="${TEST_DIR}/dup3_test"
mkdir -p "${TEST_DUP3_DIR}/no-extension" 2>/dev/null || true
echo "1" > "${TEST_DUP3_DIR}/no-extension/file_noext" 2>/dev/null || true
echo "2" > "${TEST_DUP3_DIR}/file_noext" 2>/dev/null || true

if sort-downloads "$TEST_DUP3_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_DUP3_DIR}/no-extension/file_noext_1" ]]; then
        if print_msg 29 "Does sort-downloads handle duplicates for no-extension files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 29 "Does sort-downloads handle duplicates for no-extension files?" false
    fi
else
    print_msg 29 "Does sort-downloads handle duplicates for no-extension files?" false
fi

printf "\nTesting flag combinations...\n"

# Test 30: --dry-run + --by-date
TEST_COMBO_DIR="${TEST_DIR}/combo_test"
mkdir -p "$TEST_COMBO_DIR" 2>/dev/null || true
echo "test" > "${TEST_COMBO_DIR}/test.txt" 2>/dev/null || true

if sort-downloads --dry-run --by-date "$TEST_COMBO_DIR" 2>&1 | grep -q "DRY RUN MODE"; then
    if print_msg 30 "Does --dry-run + --by-date work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does --dry-run + --by-date work?" false
fi

# Test 31: --by-extension flag works
TEST_EXT_FLAG_DIR="${TEST_DIR}/ext_flag_test"
mkdir -p "$TEST_EXT_FLAG_DIR" 2>/dev/null || true
echo "test" > "${TEST_EXT_FLAG_DIR}/test.txt" 2>/dev/null || true

if sort-downloads --by-extension "$TEST_EXT_FLAG_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_EXT_FLAG_DIR}/txt/test.txt" ]]; then
        if print_msg 31 "Does --by-extension flag work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 31 "Does --by-extension flag work?" false
    fi
else
    print_msg 31 "Does --by-extension flag work?" false
fi

# Test 32: Short flags work
TEST_SHORT_DIR="${TEST_DIR}/short_test"
mkdir -p "$TEST_SHORT_DIR" 2>/dev/null || true
echo "test" > "${TEST_SHORT_DIR}/test.txt" 2>/dev/null || true

if sort-downloads -d "$TEST_SHORT_DIR" >/dev/null 2>&1; then
    # -d should be --by-date
    if [[ ! -d "${TEST_SHORT_DIR}/txt" ]] && [[ ! -f "${TEST_SHORT_DIR}/test.txt" ]]; then
        if print_msg 32 "Does short flag -d (--by-date) work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 32 "Does short flag -d (--by-date) work?" false
    fi
else
    print_msg 32 "Does short flag -d (--by-date) work?" false
fi

# Test 33: Short flag -n (--dry-run)
TEST_SHORT2_DIR="${TEST_DIR}/short2_test"
mkdir -p "$TEST_SHORT2_DIR" 2>/dev/null || true
echo "test" > "${TEST_SHORT2_DIR}/test.txt" 2>/dev/null || true

if sort-downloads -n "$TEST_SHORT2_DIR" 2>&1 | grep -q "DRY RUN MODE"; then
    if print_msg 33 "Does short flag -n (--dry-run) work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does short flag -n (--dry-run) work?" false
fi

printf "\nTesting file counting and summary...\n"

# Test 34: Correctly counts files
TEST_COUNT_DIR="${TEST_DIR}/count_test"
mkdir -p "$TEST_COUNT_DIR" 2>/dev/null || true
echo "1" > "${TEST_COUNT_DIR}/file1.txt" 2>/dev/null || true
echo "2" > "${TEST_COUNT_DIR}/file2.txt" 2>/dev/null || true
echo "3" > "${TEST_COUNT_DIR}/file3.txt" 2>/dev/null || true

OUTPUT=$(sort-downloads "$TEST_COUNT_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "Found 3 file"; then
    if print_msg 34 "Does sort-downloads correctly count files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 34 "Does sort-downloads correctly count files?" false
fi

# Test 35: Shows summary after organizing
TEST_SUMMARY_DIR="${TEST_DIR}/summary_test"
mkdir -p "$TEST_SUMMARY_DIR" 2>/dev/null || true
echo "test" > "${TEST_SUMMARY_DIR}/test.txt" 2>/dev/null || true

OUTPUT=$(sort-downloads "$TEST_SUMMARY_DIR" 2>&1)
if echo "$OUTPUT" | grep -qi "Organized.*file"; then
    if print_msg 35 "Does sort-downloads show summary after organizing?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does sort-downloads show summary after organizing?" false
fi

printf "\nTesting sortdl alias...\n"

# Test 36: sortdl passes arguments correctly
TEST_SORTDL_DIR="${TEST_DIR}/sortdl_test"
mkdir -p "$TEST_SORTDL_DIR" 2>/dev/null || true
echo "test" > "${TEST_SORTDL_DIR}/test.txt" 2>/dev/null || true

if sortdl "$TEST_SORTDL_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_SORTDL_DIR}/txt/test.txt" ]]; then
        if print_msg 36 "Does sortdl alias work correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 36 "Does sortdl alias work correctly?" false
    fi
else
    print_msg 36 "Does sortdl alias work correctly?" false
fi

# Test 37: sortdl returns same exit code
TEST_SORTDL2_DIR="${TEST_DIR}/sortdl2_test"
mkdir -p "$TEST_SORTDL2_DIR" 2>/dev/null || true

sortdl "/nonexistent_$$" >/dev/null 2>&1
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    if print_msg 37 "Does sortdl return correct exit codes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 37 "Does sortdl return correct exit codes?" false
fi

printf "\nTesting edge cases...\n"

# Test 38: Handles files with spaces in names
TEST_SPACE_DIR="${TEST_DIR}/space_test"
mkdir -p "$TEST_SPACE_DIR" 2>/dev/null || true
echo "test" > "${TEST_SPACE_DIR}/file with spaces.txt" 2>/dev/null || true

if sort-downloads "$TEST_SPACE_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_SPACE_DIR}/txt/file with spaces.txt" ]]; then
        if print_msg 38 "Does sort-downloads handle filenames with spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 38 "Does sort-downloads handle filenames with spaces?" false
    fi
else
    print_msg 38 "Does sort-downloads handle filenames with spaces?" false
fi

# Test 39: Handles hidden files
TEST_HIDDEN_DIR="${TEST_DIR}/hidden_test"
mkdir -p "$TEST_HIDDEN_DIR" 2>/dev/null || true
echo "test" > "${TEST_HIDDEN_DIR}/.hidden_file.txt" 2>/dev/null || true

if sort-downloads "$TEST_HIDDEN_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_HIDDEN_DIR}/txt/.hidden_file.txt" ]]; then
        if print_msg 39 "Does sort-downloads handle hidden files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 39 "Does sort-downloads handle hidden files?" false
    fi
else
    print_msg 39 "Does sort-downloads handle hidden files?" false
fi

# Test 40: Handles complex extensions
TEST_COMPLEX_DIR="${TEST_DIR}/complex_test"
mkdir -p "$TEST_COMPLEX_DIR" 2>/dev/null || true
echo "test" > "${TEST_COMPLEX_DIR}/file.tar.gz" 2>/dev/null || true

if sort-downloads "$TEST_COMPLEX_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_COMPLEX_DIR}/gz/file.tar.gz" ]]; then
        if print_msg 40 "Does sort-downloads handle complex extensions (tar.gz)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 40 "Does sort-downloads handle complex extensions (tar.gz)?" false
    fi
else
    print_msg 40 "Does sort-downloads handle complex extensions (tar.gz)?" false
fi

# Test 41: Only processes regular files (not directories)
TEST_REGULAR_DIR="${TEST_DIR}/regular_test"
mkdir -p "$TEST_REGULAR_DIR" 2>/dev/null || true
mkdir -p "${TEST_REGULAR_DIR}/subdir" 2>/dev/null || true
echo "test" > "${TEST_REGULAR_DIR}/file.txt" 2>/dev/null || true

if sort-downloads "$TEST_REGULAR_DIR" >/dev/null 2>&1; then
    if [[ -d "${TEST_REGULAR_DIR}/subdir" ]] && \
       [[ -f "${TEST_REGULAR_DIR}/txt/file.txt" ]] && \
       [[ ! -d "${TEST_REGULAR_DIR}/txt/subdir" ]]; then
        if print_msg 41 "Does sort-downloads only process regular files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 41 "Does sort-downloads only process regular files?" false
    fi
else
    print_msg 41 "Does sort-downloads only process regular files?" false
fi

# Test 42: Preserves file content
TEST_CONTENT_DIR="${TEST_DIR}/content_test"
mkdir -p "$TEST_CONTENT_DIR" 2>/dev/null || true
CONTENT="This is test content with special chars: !@#\$%^&*()"
echo "$CONTENT" > "${TEST_CONTENT_DIR}/test.txt" 2>/dev/null || true

if sort-downloads "$TEST_CONTENT_DIR" >/dev/null 2>&1; then
    if [[ -f "${TEST_CONTENT_DIR}/txt/test.txt" ]] && \
       [[ "$(cat "${TEST_CONTENT_DIR}/txt/test.txt" 2>/dev/null)" == "$CONTENT" ]]; then
        if print_msg 42 "Does sort-downloads preserve file content?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 42 "Does sort-downloads preserve file content?" false
    fi
else
    print_msg 42 "Does sort-downloads preserve file content?" false
fi

printf "\nTesting completion function...\n"

# Test 43: Bash completion function exists
if declare -f _sort-downloads_completion >/dev/null 2>&1; then
    if print_msg 43 "Does sort-downloads have bash completion function?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 43 "Does sort-downloads have bash completion function?" false
fi

# Test 44: Multiple files with same extension
TEST_MULTI_DIR="${TEST_DIR}/multi_test"
mkdir -p "$TEST_MULTI_DIR" 2>/dev/null || true
echo "1" > "${TEST_MULTI_DIR}/file1.txt" 2>/dev/null || true
echo "2" > "${TEST_MULTI_DIR}/file2.txt" 2>/dev/null || true
echo "3" > "${TEST_MULTI_DIR}/file3.txt" 2>/dev/null || true

if sort-downloads "$TEST_MULTI_DIR" >/dev/null 2>&1; then
    COUNT=$(find "${TEST_MULTI_DIR}/txt" -type f -name "*.txt" 2>/dev/null | wc -l)
    if [[ $COUNT -eq 3 ]]; then
        if print_msg 44 "Does sort-downloads handle multiple files with same extension?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 44 "Does sort-downloads handle multiple files with same extension?" false
    fi
else
    print_msg 44 "Does sort-downloads handle multiple files with same extension?" false
fi

# Test 45: Exit code on success
TEST_EXIT_DIR="${TEST_DIR}/exit_test"
mkdir -p "$TEST_EXIT_DIR" 2>/dev/null || true
echo "test" > "${TEST_EXIT_DIR}/test.txt" 2>/dev/null || true

if sort-downloads "$TEST_EXIT_DIR" >/dev/null 2>&1; then
    if [[ $? -eq 0 ]]; then
        if print_msg 45 "Does sort-downloads return exit code 0 on success?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 45 "Does sort-downloads return exit code 0 on success?" false
    fi
else
    if [[ $? -eq 0 ]]; then
        if print_msg 45 "Does sort-downloads return exit code 0 on success?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 45 "Does sort-downloads return exit code 0 on success?" false
    fi
fi

# Final summary
printf "\n"
printf "Test Results: %d / %d tests passed.\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$(( score * 100 / total_tests ))"

# Write final results
if type write_test_results >/dev/null 2>&1; then
    final_status="PASSED"
    if [[ $score -lt $total_tests ]]; then
        final_status="FAILED"
    fi
    write_test_results "$final_status" "$score" "$total_tests" "$(( score * 100 / total_tests ))"
fi

exit 0

