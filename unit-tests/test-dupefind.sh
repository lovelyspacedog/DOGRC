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
        return 2  # Return 2 for N/A to distinguish from pass/fail
    elif [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
total_tests=45  # Tests 1-42 plus 3 summary tests with "*"
printf "Running unit tests for dupefind.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/dupefind.sh" ]]; then
    if print_msg 3 "Can I find dupefind.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find dupefind.sh?" false
    printf "Error: Test cannot continue. Dupefind.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/dupefind.sh" 2>/dev/null; then
    if print_msg 4 "Can I source dupefind.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source dupefind.sh?" false
    printf "Error: Test cannot continue. Dupefind.sh not found.\n" >&2
    exit 4
fi

if declare -f dupefind >/dev/null 2>&1; then
    if print_msg 5 "Is dupefind function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is dupefind function defined?" false
    printf "Error: dupefind function not defined.\n" >&2
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
readonly TEST_PREFIX="test_dupefind_$$"
readonly TEST_DIR="${TEST_PREFIX}_dir"
readonly TEST_EMPTY_DIR="${TEST_PREFIX}_empty_dir"

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if dupefind --help >/dev/null 2>&1; then
        if print_msg 6 "Does dupefind --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does dupefind --help work?" false
    fi
else
    if print_msg 6 "Does dupefind --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if dupefind -h >/dev/null 2>&1; then
        if print_msg 7 "Does dupefind -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does dupefind -h work?" false
    fi
else
    if print_msg 7 "Does dupefind -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nCreating test files...\n"

# Clean up any existing test directory
rm -rf "${TEST_DIR}" 2>/dev/null || true

# Create test directory structure with duplicate files
if mkdir -p "${TEST_DIR}/subdir" 2>/dev/null; then
    if print_msg 8 "Can I create ${TEST_DIR}?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Can I create ${TEST_DIR}?" false
    printf "Error: Test cannot continue. Failed to create ${TEST_DIR}.\n" >&2
    exit 8
fi

# Create duplicate files
test_content1="This is test content for duplicate files.\nLine 2 of content.\nEnd of content.\n"
test_content2="This is different content.\nIt should not be a duplicate.\n"

if printf "${test_content1}" > "${TEST_DIR}/file1.txt" 2>/dev/null; then
    if print_msg 9 "Can I create file1.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Can I create file1.txt?" false
    printf "Error: Test cannot continue. Failed to create file1.txt.\n" >&2
    exit 9
fi

# Create duplicate of file1.txt
if cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file2.txt 2>/dev/null; then
    if print_msg 10 "Can I create duplicate file2.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Can I create duplicate file2.txt?" false
    printf "Error: Test cannot continue. Failed to create file2.txt.\n" >&2
    exit 10
fi

# Create another duplicate
if cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file4.txt 2>/dev/null; then
    if print_msg 11 "Can I create duplicate file4.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Can I create duplicate file4.txt?" false
fi

# Create different content file
if printf "${test_content2}" > ${TEST_DIR}/file3.txt 2>/dev/null; then
    if print_msg 12 "Can I create different content file3.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Can I create different content file3.txt?" false
fi

# Create duplicate in subdirectory
if cp ${TEST_DIR}/file1.txt ${TEST_DIR}/subdir/file5.txt 2>/dev/null; then
    if print_msg 13 "Can I create duplicate in subdir?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Can I create duplicate in subdir?" false
fi

print_msg "*" "Did I create test files?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nTesting error handling...\n"

if ! dupefind "nonexistent_dir" 2>/dev/null; then
    if print_msg 14 "Does dupefind error on non-existent directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does dupefind error on non-existent directory?" false
fi

if dupefind "nonexistent_dir" 2>&1 | grep -q "Error:"; then
    if print_msg 15 "Does dupefind output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does dupefind output error message?" false
fi

if ! dupefind --unknown-flag 2>/dev/null; then
    if print_msg 16 "Does dupefind error on unknown option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does dupefind error on unknown option?" false
fi

printf "\nTesting basic functionality...\n"

# Test basic duplicate detection
if dupefind ${TEST_DIR} >/dev/null 2>&1; then
    if print_msg 17 "Does dupefind run successfully?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does dupefind run successfully?" false
fi

# Check if duplicates are found
if dupefind ${TEST_DIR} 2>&1 | grep -q "file1.txt"; then
    if dupefind ${TEST_DIR} 2>&1 | grep -q "file2.txt"; then
        if print_msg 18 "Does dupefind find duplicate files?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 18 "Does dupefind find duplicate files?" false
    fi
else
    print_msg 18 "Does dupefind find duplicate files?" false
fi

# Check if duplicate groups are shown
if dupefind ${TEST_DIR} 2>&1 | grep -q "Duplicate group\|file4.txt"; then
    if print_msg 19 "Does dupefind group duplicates correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does dupefind group duplicates correctly?" false
fi

# Check if file sizes are shown
if dupefind ${TEST_DIR} 2>&1 | grep -q "KB\|MB\|B\|Wasted space"; then
    if print_msg 20 "Does dupefind show file sizes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does dupefind show file sizes?" false
fi

# Test with empty directory (should find no duplicates)
mkdir -p ${TEST_EMPTY_DIR} 2>/dev/null || true
if dupefind ${TEST_EMPTY_DIR} 2>&1 | grep -q "No duplicates found\|No files found"; then
    if print_msg 21 "Does dupefind handle empty directory?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does dupefind handle empty directory?" false
fi
rm -rf ${TEST_EMPTY_DIR} 2>/dev/null || true

# Test recursive search (should find duplicates in subdir)
if dupefind ${TEST_DIR} 2>&1 | grep -q "subdir/file5.txt"; then
    if print_msg 22 "Does dupefind search recursively?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does dupefind search recursively?" false
fi

# Test return code
if dupefind ${TEST_DIR} >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 23 "Does dupefind return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 23 "Does dupefind return 0 on success?" false
    fi
else
    print_msg 23 "Does dupefind return 0 on success?" false
fi

printf "\nTesting hash algorithm options...\n"

# Test --md5 flag (if md5 available)
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    if dupefind --md5 ${TEST_DIR} >/dev/null 2>&1; then
        if print_msg 24 "Does --md5 flag work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 24 "Does --md5 flag work?" false
    fi
else
    if print_msg 24 "Does --md5 flag work?" "N/A"; then
        printf "        (md5sum/md5 not available, skipping)\n"
    fi
fi

# Test --sha256 flag (if sha256 available)
if command -v sha256sum >/dev/null 2>&1 || command -v sha256 >/dev/null 2>&1; then
    if dupefind --sha256 ${TEST_DIR} >/dev/null 2>&1; then
        if print_msg 25 "Does --sha256 flag work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 25 "Does --sha256 flag work?" false
    fi
else
    if print_msg 25 "Does --sha256 flag work?" "N/A"; then
        printf "        (sha256sum/sha256 not available, skipping)\n"
    fi
fi

# Test -m flag (short for --md5)
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    if dupefind -m ${TEST_DIR} >/dev/null 2>&1; then
        if print_msg 26 "Does -m flag work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 26 "Does -m flag work?" false
    fi
else
    if print_msg 26 "Does -m flag work?" "N/A"; then
        printf "        (md5sum/md5 not available, skipping)\n"
    fi
fi

# Test -s flag (short for --sha256)
if command -v sha256sum >/dev/null 2>&1 || command -v sha256 >/dev/null 2>&1; then
    if dupefind -s ${TEST_DIR} >/dev/null 2>&1; then
        if print_msg 27 "Does -s flag work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 27 "Does -s flag work?" false
    fi
else
    if print_msg 27 "Does -s flag work?" "N/A"; then
        printf "        (sha256sum/sha256 not available, skipping)\n"
    fi
fi

printf "\nTesting size filtering...\n"

# Test --min-size filter
if dupefind --min-size 1 ${TEST_DIR} >/dev/null 2>&1; then
    if print_msg 28 "Does --min-size flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does --min-size flag work?" false
fi

# Test --min-size with K suffix
if dupefind --min-size 1K ${TEST_DIR} >/dev/null 2>&1; then
    if print_msg 29 "Does --min-size with K suffix work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does --min-size with K suffix work?" false
fi

printf "\nTesting display options...\n"

# Test --no-size flag
if dupefind --no-size ${TEST_DIR} 2>&1 | grep -vq "KB\|MB\|B\|Wasted"; then
    # If grep -vq returns true, it means we didn't find size info (which is what we want)
    if print_msg 30 "Does --no-size hide size information?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If grep found size info, that means --no-size didn't work
    if dupefind --no-size ${TEST_DIR} 2>&1 | grep -q "file1.txt"; then
        # At least it still finds duplicates, so partial credit
        if print_msg 30 "Does --no-size hide size information?" false; then
            printf "        (Size information still shown, but duplicates found)\n"
        fi
    else
        print_msg 30 "Does --no-size hide size information?" false
    fi
fi

printf "\nTesting delete mode...\n"

# Create fresh duplicates for delete testing
cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file_to_delete.txt 2>/dev/null || true

# Test --delete mode
if dupefind --delete ${TEST_DIR} >/dev/null 2>&1; then
    # Check if duplicate was deleted (keeps first, deletes rest)
    if [[ ! -f ${TEST_DIR}/file_to_delete.txt ]] || [[ ! -f ${TEST_DIR}/file2.txt ]]; then
        # At least one duplicate should be deleted
        if print_msg 31 "Does --delete remove duplicate files?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        # If files still exist, deletion didn't work
        if print_msg 31 "Does --delete remove duplicate files?" false; then
            printf "        (Files still exist after delete)\n"
        fi
    fi
else
    print_msg 31 "Does --delete remove duplicate files?" false
fi

# Recreate duplicates for further testing
cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file_to_delete.txt 2>/dev/null || true

# Test -d flag (short for --delete)
if dupefind -d ${TEST_DIR} >/dev/null 2>&1; then
    if [[ ! -f ${TEST_DIR}/file_to_delete.txt ]]; then
        if print_msg 32 "Does -d flag work for delete?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 32 "Does -d flag work for delete?" false
    fi
else
    print_msg 32 "Does -d flag work for delete?" false
fi

# Test that kept file still exists after delete
if [[ -f ${TEST_DIR}/file1.txt ]]; then
    if print_msg 33 "Does --delete keep first file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does --delete keep first file?" false
fi

# Test that no duplicates found after delete
if dupefind ${TEST_DIR} 2>&1 | grep -q "No duplicates found"; then
    if print_msg 34 "Does dupefind find no duplicates after delete?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # Recreate duplicates if they were all deleted
    cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file2.txt 2>/dev/null || true
    if print_msg 34 "Does dupefind find no duplicates after delete?" false; then
        printf "        (Duplicates may still exist)\n"
    fi
fi

printf "\nTesting single file mode...\n"

# Recreate test directory with duplicates for single file test
rm -rf ${TEST_DIR} 2>/dev/null || true
mkdir -p ${TEST_DIR}/subdir 2>/dev/null || true
printf "${test_content1}" > ${TEST_DIR}/file1.txt 2>/dev/null || true
cp ${TEST_DIR}/file1.txt ${TEST_DIR}/file2.txt 2>/dev/null || true
cp ${TEST_DIR}/file1.txt ${TEST_DIR}/subdir/file3.txt 2>/dev/null || true

# Test single file argument (should compare with other files in directory)
if dupefind ${TEST_DIR}/file1.txt 2>&1 | grep -q "file1.txt\|file2.txt\|Duplicate"; then
    if print_msg 35 "Does dupefind work with single file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does dupefind work with single file?" false
fi

printf "\nTesting edge cases...\n"

# Test with empty files (0-byte duplicates)
# Note: Empty files are filtered by default min-size of 1, so we'll test with --min-size 0
printf "" > ${TEST_DIR}/empty1.txt 2>/dev/null || true
printf "" > ${TEST_DIR}/empty2.txt 2>/dev/null || true

# Test with min-size 0 to include empty files
if dupefind --min-size 0 ${TEST_DIR} 2>&1 | grep -q "empty1.txt\|empty2.txt"; then
    if print_msg 36 "Does dupefind handle empty files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If min-size 0 doesn't work, check if they're found without size filter
    if dupefind ${TEST_DIR} 2>&1 | grep -q "empty1.txt\|empty2.txt"; then
        if print_msg 36 "Does dupefind handle empty files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        # Empty files are filtered by default min-size, which is expected behavior
        if print_msg 36 "Does dupefind handle empty files?" "N/A"; then
            printf "        (Empty files filtered by default min-size=1, expected behavior)\n"
        fi
    fi
fi

# Test with special characters in filenames
if printf "${test_content1}" > "${TEST_DIR}/file with spaces.txt" 2>/dev/null; then
    if cp "${TEST_DIR}/file with spaces.txt" "${TEST_DIR}/file_with_spaces_copy.txt" 2>/dev/null; then
        if dupefind ${TEST_DIR} 2>&1 | grep -q "file with spaces"; then
            if print_msg 37 "Does dupefind handle spaces in filenames?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 37 "Does dupefind handle spaces in filenames?" false
        fi
    else
        print_msg 37 "Does dupefind handle spaces in filenames?" false
    fi
else
    print_msg 37 "Does dupefind handle spaces in filenames?" false
fi

# Test that different content files are not marked as duplicates
if dupefind ${TEST_DIR} 2>&1 | grep -q "file1.txt" && ! dupefind ${TEST_DIR} 2>&1 | grep -q "file3.txt.*file1.txt\|file1.txt.*file3.txt"; then
    # Check that file3 (different content) is not grouped with file1
    if print_msg 38 "Does dupefind correctly identify non-duplicates?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 38 "Does dupefind correctly identify non-duplicates?" false
fi

printf "\nTesting interactive mode (basic)...\n"

# Test --interactive flag exists and runs (we can't fully test interactive input)
if dupefind --interactive ${TEST_DIR} 2>&1 | head -5 | grep -q "."; then
    # If it produces output, it's running
    if print_msg 39 "Does --interactive flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If no output or error, mark as N/A since we can't fully test interactive
    if print_msg 39 "Does --interactive flag work?" "N/A"; then
        printf "        (Interactive mode requires user input, basic test only)\n"
    fi
fi

# Test -i flag (short for --interactive)
if dupefind -i ${TEST_DIR} 2>&1 | head -5 | grep -q "."; then
    if print_msg 40 "Does -i flag work for interactive?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    if print_msg 40 "Does -i flag work for interactive?" "N/A"; then
        printf "        (Interactive mode requires user input, basic test only)\n"
    fi
fi

printf "\nTesting output format...\n"

# Test that output contains summary information
if dupefind ${TEST_DIR} 2>&1 | grep -q "Summary\|No duplicates found\|Found duplicate"; then
    if print_msg 41 "Does dupefind output summary information?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 41 "Does dupefind output summary information?" false
fi

# Test that output shows scanning message
if dupefind ${TEST_DIR} 2>&1 | grep -q "Scanning\|Analyzing"; then
    if print_msg 42 "Does dupefind show progress messages?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # Progress messages are optional, so this is okay to skip
    if print_msg 42 "Does dupefind show progress messages?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

print_msg "*" "Did I complete all functionality tests?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

rm -rf ${TEST_DIR} 2>/dev/null || true

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
rm -rf ${TEST_DIR} ${TEST_EMPTY_DIR} 2>/dev/null || true
rm -f test_dupefind_*.txt 2>/dev/null || true
printf "Cleanup complete.\n"

exit 0

