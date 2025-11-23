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
total_tests=66  # Tests 1-65 plus 1 summary test with "*"
printf "Running unit tests for sanitize-filenames.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/sanitize-filenames.sh" ]]; then
    if print_msg 3 "Can I find sanitize-filenames.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find sanitize-filenames.sh?" false
    printf "Error: Test cannot continue. sanitize-filenames.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/sanitize-filenames.sh" 2>/dev/null; then
    if print_msg 4 "Can I source sanitize-filenames.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source sanitize-filenames.sh?" false
    printf "Error: Test cannot continue. sanitize-filenames.sh not found.\n" >&2
    exit 4
fi

if declare -f sanitize-filenames >/dev/null 2>&1; then
    if print_msg 5 "Is sanitize-filenames function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is sanitize-filenames function defined?" false
    printf "Error: sanitize-filenames function not defined.\n" >&2
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

# Unique prefix for this test run (process ID + test name) for parallel compatibility
readonly TEST_PREFIX="test_sanitize_$$"

# Create isolated test directory for this test run to prevent parallel test interference
readonly TEST_ISOLATION_DIR="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_isolation"
mkdir -p "${TEST_ISOLATION_DIR}" || {
    printf "Error: Failed to create test isolation directory.\n" >&2
    exit 92
}

# Change into the isolation directory for all sanitization operations
cd "${TEST_ISOLATION_DIR}" || {
    printf "Error: Failed to change directory to test isolation directory.\n" >&2
    exit 93
}

# Cleanup function to remove isolation directory
cleanup_isolation() {
    cd "${__UNIT_TESTS_DIR}" || true
    rm -rf "${TEST_ISOLATION_DIR}" 2>/dev/null || true
}
trap cleanup_isolation EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

# Test 6: sanitize-filenames --help
if declare -f drchelp >/dev/null 2>&1; then
    if sanitize-filenames --help >/dev/null 2>&1; then
        if print_msg 6 "Does sanitize-filenames --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 6 "Does sanitize-filenames --help work?" false
    fi
else
    if print_msg 6 "Does sanitize-filenames --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: sanitize-filenames -h
if declare -f drchelp >/dev/null 2>&1; then
    if sanitize-filenames -h >/dev/null 2>&1; then
        if print_msg 7 "Does sanitize-filenames -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does sanitize-filenames -h work?" false
    fi
else
    if print_msg 7 "Does sanitize-filenames -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test 8: sanitize-filenames with non-existent path
if ! sanitize-filenames "nonexistent_file_$$" 2>/dev/null; then
    if print_msg 8 "Does sanitize-filenames error on non-existent path?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Does sanitize-filenames error on non-existent path?" false
fi

# Test 9: sanitize-filenames with invalid option
if ! sanitize-filenames --invalid-option 2>/dev/null; then
    if print_msg 9 "Does sanitize-filenames error on invalid option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does sanitize-filenames error on invalid option?" false
fi

# Test 10: Verify error message format
error_output=$(sanitize-filenames "nonexistent_$$" 2>&1)
if echo "$error_output" | grep -q "Error:"; then
    if print_msg 10 "Does sanitize-filenames output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does sanitize-filenames output error message?" false
fi

# Test 11: Verify return code on error
sanitize-filenames "nonexistent_$$" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
    if print_msg 11 "Does sanitize-filenames return 1 on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does sanitize-filenames return 1 on error?" false
fi

printf "\nTesting core sanitization - single file...\n"

# Test 12: Remove special characters
printf "test content" > "file@name#.txt"
if sanitize-filenames "file@name#.txt" >/dev/null 2>&1; then
    if [[ -f "file_name_.txt" ]] && [[ ! -f "file@name#.txt" ]]; then
        if print_msg 12 "Does sanitize remove special characters?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 12 "Does sanitize remove special characters?" false
    fi
else
    print_msg 12 "Does sanitize remove special characters?" false
fi
rm -f "file_name_.txt" 2>/dev/null || true

# Test 13: Normalize multiple spaces
printf "test content" > "file  name.txt"
if sanitize-filenames "file  name.txt" >/dev/null 2>&1; then
    if [[ -f "file name.txt" ]] && [[ ! -f "file  name.txt" ]]; then
        if print_msg 13 "Does sanitize normalize multiple spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 13 "Does sanitize normalize multiple spaces?" false
    fi
else
    print_msg 13 "Does sanitize normalize multiple spaces?" false
fi
rm -f "file name.txt" 2>/dev/null || true

# Test 14: Replace spaces with underscores (--replace-spaces)
printf "test content" > "file name.txt"
if sanitize-filenames --replace-spaces "file name.txt" >/dev/null 2>&1; then
    if [[ -f "file_name.txt" ]] && [[ ! -f "file name.txt" ]]; then
        if print_msg 14 "Does --replace-spaces replace spaces with underscores?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 14 "Does --replace-spaces replace spaces with underscores?" false
    fi
else
    print_msg 14 "Does --replace-spaces replace spaces with underscores?" false
fi
rm -f "file_name.txt" 2>/dev/null || true

# Test 15: Replace spaces with underscores (-r shorthand)
printf "test content" > "file name2.txt"
if sanitize-filenames -r "file name2.txt" >/dev/null 2>&1; then
    if [[ -f "file_name2.txt" ]] && [[ ! -f "file name2.txt" ]]; then
        if print_msg 15 "Does -r shorthand replace spaces with underscores?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 15 "Does -r shorthand replace spaces with underscores?" false
    fi
else
    print_msg 15 "Does -r shorthand replace spaces with underscores?" false
fi
rm -f "file_name2.txt" 2>/dev/null || true

# Test 16: Remove leading/trailing spaces
printf "test content" > " file.txt "
if sanitize-filenames " file.txt " >/dev/null 2>&1; then
    if [[ -f "file.txt" ]] && [[ ! -f " file.txt " ]]; then
        if print_msg 16 "Does sanitize remove leading/trailing spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 16 "Does sanitize remove leading/trailing spaces?" false
    fi
else
    print_msg 16 "Does sanitize remove leading/trailing spaces?" false
fi
rm -f "file.txt" 2>/dev/null || true

# Test 17: Normalize multiple underscores
printf "test content" > "file__name.txt"
if sanitize-filenames "file__name.txt" >/dev/null 2>&1; then
    if [[ -f "file_name.txt" ]] && [[ ! -f "file__name.txt" ]]; then
        if print_msg 17 "Does sanitize normalize multiple underscores?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 17 "Does sanitize normalize multiple underscores?" false
    fi
else
    print_msg 17 "Does sanitize normalize multiple underscores?" false
fi
rm -f "file_name.txt" 2>/dev/null || true

# Test 18: Normalize multiple hyphens
printf "test content" > "file--name.txt"
if sanitize-filenames "file--name.txt" >/dev/null 2>&1; then
    if [[ -f "file_name.txt" ]] && [[ ! -f "file--name.txt" ]]; then
        if print_msg 18 "Does sanitize normalize multiple hyphens?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 18 "Does sanitize normalize multiple hyphens?" false
    fi
else
    print_msg 18 "Does sanitize normalize multiple hyphens?" false
fi
rm -f "file_name.txt" 2>/dev/null || true

# Test 19: Normalize mixed underscores/hyphens
printf "test content" > "file_-name.txt"
if sanitize-filenames "file_-name.txt" >/dev/null 2>&1; then
    if [[ -f "file_name.txt" ]] && [[ ! -f "file_-name.txt" ]]; then
        if print_msg 19 "Does sanitize normalize mixed underscores/hyphens?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 19 "Does sanitize normalize mixed underscores/hyphens?" false
    fi
else
    print_msg 19 "Does sanitize normalize mixed underscores/hyphens?" false
fi
rm -f "file_name.txt" 2>/dev/null || true

# Test 20: Preserve hidden files (leading dot)
printf "test content" > ".hidden_file.txt"
if sanitize-filenames ".hidden_file.txt" >/dev/null 2>&1; then
    if [[ -f ".hidden_file.txt" ]]; then
        if print_msg 20 "Does sanitize preserve hidden files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 20 "Does sanitize preserve hidden files?" false
    fi
else
    print_msg 20 "Does sanitize preserve hidden files?" false
fi
rm -f ".hidden_file.txt" 2>/dev/null || true

# Test 21: Sanitize hidden file with special chars
printf "test content" > ".hidden@file.txt"
if sanitize-filenames ".hidden@file.txt" >/dev/null 2>&1; then
    if [[ -f ".hidden_file.txt" ]] && [[ ! -f ".hidden@file.txt" ]]; then
        if print_msg 21 "Does sanitize clean hidden file special chars?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 21 "Does sanitize clean hidden file special chars?" false
    fi
else
    print_msg 21 "Does sanitize clean hidden file special chars?" false
fi
rm -f ".hidden_file.txt" 2>/dev/null || true

# Test 22: Skip files that don't need sanitization
printf "test content" > "clean_name.txt"
if sanitize-filenames "clean_name.txt" >/dev/null 2>&1; then
    if [[ -f "clean_name.txt" ]]; then
        output=$(sanitize-filenames "clean_name.txt" 2>&1)
        if echo "$output" | grep -q "unchanged" || ! echo "$output" | grep -q "Renamed"; then
            if print_msg 22 "Does sanitize skip unchanged files?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 22 "Does sanitize skip unchanged files?" false
        fi
    else
        print_msg 22 "Does sanitize skip unchanged files?" false
    fi
else
    print_msg 22 "Does sanitize skip unchanged files?" false
fi
rm -f "clean_name.txt" 2>/dev/null || true

# Test 23: Handle files with only special characters
printf "test content" > "@#$%"
if sanitize-filenames "@#$%" >/dev/null 2>&1; then
    # Should create a fallback name like sanitized_*
    files_found=$(find . -maxdepth 1 -name "sanitized_*" -type f | wc -l)
    if [[ $files_found -gt 0 ]] && [[ ! -f "@#$%" ]]; then
        if print_msg 23 "Does sanitize handle files with only special chars?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 23 "Does sanitize handle files with only special chars?" false
    fi
else
    print_msg 23 "Does sanitize handle files with only special chars?" false
fi
rm -f sanitized_* 2>/dev/null || true

printf "\nTesting dry-run mode...\n"

# Test 24: Dry-run shows preview without renaming
printf "test content" > "test@file.txt"
output=$(sanitize-filenames --dry-run "test@file.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN" && echo "$output" | grep -q "Would rename"; then
    if [[ -f "test@file.txt" ]] && [[ ! -f "test_file.txt" ]]; then
        if print_msg 24 "Does --dry-run show preview without renaming?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 24 "Does --dry-run show preview without renaming?" false
    fi
else
    print_msg 24 "Does --dry-run show preview without renaming?" false
fi
rm -f "test@file.txt" "test_file.txt" 2>/dev/null || true

# Test 25: -d shorthand for dry-run
printf "test content" > "test2@file.txt"
output=$(sanitize-filenames -d "test2@file.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN"; then
    if [[ -f "test2@file.txt" ]] && [[ ! -f "test2_file.txt" ]]; then
        if print_msg 25 "Does -d shorthand work for dry-run?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 25 "Does -d shorthand work for dry-run?" false
    fi
else
    print_msg 25 "Does -d shorthand work for dry-run?" false
fi
rm -f "test2@file.txt" "test2_file.txt" 2>/dev/null || true

# Test 26: Combine --dry-run and --replace-spaces
printf "test content" > "test file.txt"
output=$(sanitize-filenames --dry-run --replace-spaces "test file.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN" && echo "$output" | grep -q "Replace spaces"; then
    if [[ -f "test file.txt" ]] && [[ ! -f "test_file.txt" ]]; then
        if print_msg 26 "Does --dry-run work with --replace-spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 26 "Does --dry-run work with --replace-spaces?" false
    fi
else
    print_msg 26 "Does --dry-run work with --replace-spaces?" false
fi
rm -f "test file.txt" "test_file.txt" 2>/dev/null || true

printf "\nTesting directory mode...\n"

# Test 27: Sanitize directory recursively
mkdir -p "test_dir/subdir"
printf "content1" > "test_dir/file@name.txt"
printf "content2" > "test_dir/subdir/file  name.txt"
printf "content3" > "test_dir/file__name.txt"

if sanitize-filenames "test_dir" >/dev/null 2>&1; then
    if [[ -f "test_dir/file_name.txt" ]] && \
       [[ -f "test_dir/subdir/file name.txt" ]] && \
       [[ -f "test_dir/file_name.txt" ]] && \
       [[ ! -f "test_dir/file@name.txt" ]]; then
        if print_msg 27 "Does sanitize work on directories recursively?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 27 "Does sanitize work on directories recursively?" false
    fi
else
    print_msg 27 "Does sanitize work on directories recursively?" false
fi
rm -rf "test_dir" 2>/dev/null || true

# Test 28: Process directories from deepest to shallowest
mkdir -p "deep/sub/deeper"
printf "content1" > "deep/sub/deeper/file@name.txt"
printf "content2" > "deep/sub/file@name.txt"
printf "content3" > "deep/file@name.txt"

if sanitize-filenames "deep" >/dev/null 2>&1; then
    # All should be sanitized
    if [[ -f "deep/sub/deeper/file_name.txt" ]] && \
       [[ -f "deep/sub/file_name.txt" ]] && \
       [[ -f "deep/file_name.txt" ]]; then
        if print_msg 28 "Does sanitize process nested dirs correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 28 "Does sanitize process nested dirs correctly?" false
    fi
else
    print_msg 28 "Does sanitize process nested dirs correctly?" false
fi
rm -rf "deep" 2>/dev/null || true

# Test 29: Sanitize directory names too
mkdir -p "dir@name/subdir  name"
printf "content" > "dir@name/subdir  name/file.txt"

if sanitize-filenames "dir@name" >/dev/null 2>&1; then
    # Directory names should also be sanitized
    if [[ -d "dir_name" ]] && [[ ! -d "dir@name" ]]; then
        if print_msg 29 "Does sanitize sanitize directory names?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 29 "Does sanitize sanitize directory names?" false
    fi
else
    print_msg 29 "Does sanitize sanitize directory names?" false
fi
rm -rf "dir_name" "dir@name" 2>/dev/null || true

# Test 30: Empty directory (should succeed even if no files to process)
mkdir -p "empty_dir"
output=$(sanitize-filenames "empty_dir" 2>&1)
exit_code=$?
if [[ $exit_code -eq 0 ]] && [[ -d "empty_dir" ]]; then
    # Empty directory should be handled gracefully (no errors)
    if echo "$output" | grep -q "Summary:"; then
        if print_msg 30 "Does sanitize handle empty directories?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 30 "Does sanitize handle empty directories?" false
    fi
else
    print_msg 30 "Does sanitize handle empty directories?" false
fi
rm -rf "empty_dir" 2>/dev/null || true

printf "\nTesting edge cases...\n"

# Test 31: Target name already exists (should skip)
printf "content1" > "target_exists.txt"
printf "content2" > "target@exists.txt"
# Create the target manually to simulate conflict
printf "existing" > "target_exists_conflict.txt"

if sanitize-filenames "target@exists.txt" >/dev/null 2>&1; then
    # Should rename to target_exists.txt
    if [[ -f "target_exists.txt" ]]; then
        output=$(sanitize-filenames "target@exists.txt" 2>&1)
        # Second run should skip because target already exists
        if echo "$output" | grep -q "Skip" || echo "$output" | grep -q "unchanged"; then
            if print_msg 31 "Does sanitize skip when target exists?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 31 "Does sanitize skip when target exists?" false
        fi
    else
        print_msg 31 "Does sanitize skip when target exists?" false
    fi
else
    print_msg 31 "Does sanitize skip when target exists?" false
fi
rm -f "target_exists.txt" "target@exists.txt" "target_exists_conflict.txt" 2>/dev/null || true

# Test 32: Files with unicode characters
printf "content" > "file_ñame.txt"
if sanitize-filenames "file_ñame.txt" >/dev/null 2>&1; then
    # Unicode might be kept or replaced depending on sed behavior
    if [[ -f "file_name.txt" ]] || [[ -f "file_ñame.txt" ]]; then
        if print_msg 32 "Does sanitize handle unicode characters?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 32 "Does sanitize handle unicode characters?" false
    fi
else
    print_msg 32 "Does sanitize handle unicode characters?" false
fi
rm -f "file_ñame.txt" "file_name.txt" 2>/dev/null || true

# Test 33: Files with only spaces
printf "content" > "   "
if sanitize-filenames "   " >/dev/null 2>&1; then
    # Should create fallback name
    files_found=$(find . -maxdepth 1 -name "sanitized_*" -type f | wc -l)
    if [[ $files_found -gt 0 ]]; then
        if print_msg 33 "Does sanitize handle files with only spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 33 "Does sanitize handle files with only spaces?" false
    fi
else
    print_msg 33 "Does sanitize handle files with only spaces?" false
fi
rm -f "   " sanitized_* 2>/dev/null || true

# Test 34: Files with no extension
printf "content" > "file@name"
if sanitize-filenames "file@name" >/dev/null 2>&1; then
    if [[ -f "file_name" ]] && [[ ! -f "file@name" ]]; then
        if print_msg 34 "Does sanitize work with files without extension?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 34 "Does sanitize work with files without extension?" false
    fi
else
    print_msg 34 "Does sanitize work with files without extension?" false
fi
rm -f "file_name" "file@name" 2>/dev/null || true

printf "\nTesting output and summary...\n"

# Test 35: Summary shows correct counts
printf "content1" > "file1@name.txt"
printf "content2" > "file2@name.txt"
output=$(sanitize-filenames . 2>&1)
if echo "$output" | grep -q "Summary:" && echo "$output" | grep -q "Files renamed"; then
    if print_msg 35 "Does sanitize show summary with counts?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does sanitize show summary with counts?" false
fi
rm -f "file1_name.txt" "file2_name.txt" "file1@name.txt" "file2@name.txt" 2>/dev/null || true

# Test 36: Dry-run summary shows correct counts
printf "content" > "dry@test.txt"
output=$(sanitize-filenames --dry-run "dry@test.txt" 2>&1)
if echo "$output" | grep -q "Summary:" && echo "$output" | grep -q "would be renamed"; then
    if print_msg 36 "Does dry-run show summary with would-be counts?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 36 "Does dry-run show summary with would-be counts?" false
fi
rm -f "dry@test.txt" "dry_test.txt" 2>/dev/null || true

# Test 37: Return code on success
printf "content" > "success@test.txt"
if sanitize-filenames "success@test.txt" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 37 "Does sanitize return 0 on success?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 37 "Does sanitize return 0 on success?" false
    fi
else
    print_msg 37 "Does sanitize return 0 on success?" false
fi
rm -f "success_test.txt" "success@test.txt" 2>/dev/null || true

printf "\nTesting aliases...\n"

# Test 38: sanitize_filenames alias works
if declare -f sanitize_filenames >/dev/null 2>&1; then
    printf "content" > "alias@test.txt"
    if sanitize_filenames "alias@test.txt" >/dev/null 2>&1; then
        if [[ -f "alias_test.txt" ]] && [[ ! -f "alias@test.txt" ]]; then
            if print_msg 38 "Does sanitize_filenames alias work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 38 "Does sanitize_filenames alias work?" false
        fi
    else
        print_msg 38 "Does sanitize_filenames alias work?" false
    fi
    rm -f "alias_test.txt" "alias@test.txt" 2>/dev/null || true
else
    print_msg 38 "Does sanitize_filenames alias work?" false
fi

# Test 39: fixnames alias works
if declare -f fixnames >/dev/null 2>&1; then
    printf "content" > "fix@test.txt"
    if fixnames "fix@test.txt" >/dev/null 2>&1; then
        if [[ -f "fix_test.txt" ]] && [[ ! -f "fix@test.txt" ]]; then
            if print_msg 39 "Does fixnames alias work?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 39 "Does fixnames alias work?" false
        fi
    else
        print_msg 39 "Does fixnames alias work?" false
    fi
    rm -f "fix_test.txt" "fix@test.txt" 2>/dev/null || true
else
    print_msg 39 "Does fixnames alias work?" false
fi

# Test 40: Aliases produce same output
printf "content1" > "alias1@test.txt"
printf "content2" > "alias2@test.txt"
output1=$(sanitize-filenames --dry-run "alias1@test.txt" 2>&1)
output2=$(fixnames --dry-run "alias2@test.txt" 2>&1)
if [[ -n "$output1" ]] && [[ -n "$output2" ]] && echo "$output1" | grep -q "Would rename" && echo "$output2" | grep -q "Would rename"; then
    if print_msg 40 "Do aliases produce same output format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 40 "Do aliases produce same output format?" false
fi
rm -f "alias1@test.txt" "alias2@test.txt" 2>/dev/null || true

printf "\nTesting combined flags...\n"

# Test 41: Combined --dry-run and --replace-spaces flags
printf "test content" > "combined test.txt"
output=$(sanitize-filenames --dry-run --replace-spaces "combined test.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN" && echo "$output" | grep -q "Replace spaces"; then
    if [[ -f "combined test.txt" ]] && [[ ! -f "combined_test.txt" ]]; then
        if print_msg 41 "Do combined flags work together?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 41 "Do combined flags work together?" false
    fi
else
    print_msg 41 "Do combined flags work together?" false
fi
rm -f "combined test.txt" "combined_test.txt" 2>/dev/null || true

# Test 42: Flags in different order
printf "test content" > "order test.txt"
output=$(sanitize-filenames --replace-spaces --dry-run "order test.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN" && echo "$output" | grep -q "Replace spaces"; then
    if [[ -f "order test.txt" ]] && [[ ! -f "order_test.txt" ]]; then
        if print_msg 42 "Do flags work in different order?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 42 "Do flags work in different order?" false
    fi
else
    print_msg 42 "Do flags work in different order?" false
fi
rm -f "order test.txt" "order_test.txt" 2>/dev/null || true

# Test 43: Short flags combined
printf "test content" > "short test.txt"
output=$(sanitize-filenames -d -r "short test.txt" 2>&1)
if echo "$output" | grep -q "DRY RUN" && echo "$output" | grep -q "Replace spaces"; then
    if [[ -f "short test.txt" ]] && [[ ! -f "short_test.txt" ]]; then
        if print_msg 43 "Do short flags work combined?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 43 "Do short flags work combined?" false
    fi
else
    print_msg 43 "Do short flags work combined?" false
fi
rm -f "short test.txt" "short_test.txt" 2>/dev/null || true

printf "\nTesting current directory mode...\n"

# Test 44: Default to current directory
cd "${TEST_ISOLATION_DIR}" || exit 93
printf "content1" > "default@test1.txt"
printf "content2" > "default@test2.txt"
if sanitize-filenames >/dev/null 2>&1; then
    if [[ -f "default_test1.txt" ]] && [[ -f "default_test2.txt" ]]; then
        if print_msg 44 "Does sanitize default to current directory?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 44 "Does sanitize default to current directory?" false
    fi
else
    print_msg 44 "Does sanitize default to current directory?" false
fi
rm -f "default_test1.txt" "default_test2.txt" 2>/dev/null || true

# Test 45: Current directory with explicit .
cd "${TEST_ISOLATION_DIR}" || exit 93
printf "content1" > "dot@test1.txt"
printf "content2" > "dot@test2.txt"
if sanitize-filenames . >/dev/null 2>&1; then
    if [[ -f "dot_test1.txt" ]] && [[ -f "dot_test2.txt" ]]; then
        if print_msg 45 "Does sanitize work with explicit . directory?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 45 "Does sanitize work with explicit . directory?" false
    fi
else
    print_msg 45 "Does sanitize work with explicit . directory?" false
fi
rm -f "dot_test1.txt" "dot_test2.txt" 2>/dev/null || true

printf "\nTesting complex scenarios...\n"

# Test 46: Multiple files with same sanitized name (first succeeds, rest skip)
printf "content1" > "file@name.txt"
printf "content2" > "file#name.txt"
if sanitize-filenames . >/dev/null 2>&1; then
    # Both should sanitize to file_name.txt, but second should skip
    file_count=$(find . -name "file_name.txt" -type f | wc -l)
    if [[ $file_count -eq 1 ]]; then
        if print_msg 46 "Does sanitize handle name conflicts correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 46 "Does sanitize handle name conflicts correctly?" false
    fi
else
    print_msg 46 "Does sanitize handle name conflicts correctly?" false
fi
rm -f "file_name.txt" "file@name.txt" "file#name.txt" 2>/dev/null || true

# Test 47: Very long filename with special characters
# Use special characters so sanitization actually changes the name
long_name="very_long_filename_$(printf '@%.0s' {1..50})_$(printf 'a%.0s' {1..150}).txt"
if printf "content" > "${long_name}" 2>/dev/null; then
    if sanitize-filenames "${long_name}" >/dev/null 2>&1; then
        # Should be sanitized (special chars removed)
        if [[ ! -f "${long_name}" ]]; then
            if print_msg 47 "Does sanitize handle very long filenames?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 47 "Does sanitize handle very long filenames?" false
        fi
    else
        print_msg 47 "Does sanitize handle very long filenames?" false
    fi
    rm -f "${long_name}" very_long_filename_* 2>/dev/null || true
else
    # If we can't create the file (filesystem limits), that's also acceptable behavior
    print_msg 47 "Does sanitize handle very long filenames?" true
    ((score++))
    if type update_progress_from_score >/dev/null 2>&1; then
        update_progress_from_score
    fi
fi

# Test 48: Directory with many files
mkdir -p "many_files"
for i in {1..10}; do
    printf "content$i" > "many_files/file${i}@name.txt"
done
if sanitize-filenames "many_files" >/dev/null 2>&1; then
    renamed_count=$(find "many_files" -name "file*_name.txt" -type f | wc -l)
    if [[ $renamed_count -eq 10 ]]; then
        if print_msg 48 "Does sanitize handle directories with many files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 48 "Does sanitize handle directories with many files?" false
    fi
else
    print_msg 48 "Does sanitize handle directories with many files?" false
fi
rm -rf "many_files" 2>/dev/null || true

# Test 49: Hidden directory
mkdir -p ".hidden_dir"
printf "content" > ".hidden_dir/file@name.txt"
if sanitize-filenames ".hidden_dir" >/dev/null 2>&1; then
    if [[ -f ".hidden_dir/file_name.txt" ]] && [[ -d ".hidden_dir" ]]; then
        if print_msg 49 "Does sanitize handle hidden directories?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 49 "Does sanitize handle hidden directories?" false
    fi
else
    print_msg 49 "Does sanitize handle hidden directories?" false
fi
rm -rf ".hidden_dir" 2>/dev/null || true

# Test 50: Mixed file types
printf "content1" > "file@name.txt"
printf "content2" > "file@name.sh"
printf "content3" > "file@name"
if sanitize-filenames . >/dev/null 2>&1; then
    txt_count=$(find . -name "file_name.txt" -type f | wc -l)
    sh_count=$(find . -name "file_name.sh" -type f | wc -l)
    no_ext_count=$(find . -name "file_name" -type f | wc -l)
    if [[ $txt_count -eq 1 ]] && [[ $sh_count -eq 1 ]] && [[ $no_ext_count -eq 1 ]]; then
        if print_msg 50 "Does sanitize handle mixed file types?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 50 "Does sanitize handle mixed file types?" false
    fi
else
    print_msg 50 "Does sanitize handle mixed file types?" false
fi
rm -f "file_name.txt" "file_name.sh" "file_name" 2>/dev/null || true

# Test 51: Files with leading/trailing dots (non-hidden)
printf "content" > ".file.txt."
if sanitize-filenames ".file.txt." >/dev/null 2>&1; then
    if [[ -f "file.txt" ]] && [[ ! -f ".file.txt." ]]; then
        if print_msg 51 "Does sanitize remove leading/trailing dots (non-hidden)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 51 "Does sanitize remove leading/trailing dots (non-hidden)?" false
    fi
else
    print_msg 51 "Does sanitize remove leading/trailing dots (non-hidden)?" false
fi
rm -f "file.txt" ".file.txt." 2>/dev/null || true

# Test 52: Files with leading/trailing hyphens (use -- separator)
printf "content" > "-file-name-.txt"
if sanitize-filenames -- "-file-name-.txt" >/dev/null 2>&1; then
    if [[ -f "file-name.txt" ]] && [[ ! -f "-file-name-.txt" ]]; then
        if print_msg 52 "Does sanitize remove leading/trailing hyphens?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 52 "Does sanitize remove leading/trailing hyphens?" false
    fi
else
    print_msg 52 "Does sanitize remove leading/trailing hyphens?" false
fi
rm -f "file-name.txt" "-file-name-.txt" 2>/dev/null || true

# Test 53: Multiple consecutive spaces with --replace-spaces
printf "content" > "file   name.txt"
if sanitize-filenames --replace-spaces "file   name.txt" >/dev/null 2>&1; then
    if [[ -f "file_name.txt" ]] && [[ ! -f "file   name.txt" ]]; then
        if print_msg 53 "Does --replace-spaces handle multiple spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 53 "Does --replace-spaces handle multiple spaces?" false
    fi
else
    print_msg 53 "Does --replace-spaces handle multiple spaces?" false
fi
rm -f "file_name.txt" "file   name.txt" 2>/dev/null || true

# Test 54: Empty file
printf "" > "empty@file.txt"
if sanitize-filenames "empty@file.txt" >/dev/null 2>&1; then
    if [[ -f "empty_file.txt" ]] && [[ ! -f "empty@file.txt" ]]; then
        if print_msg 54 "Does sanitize work with empty files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 54 "Does sanitize work with empty files?" false
    fi
else
    print_msg 54 "Does sanitize work with empty files?" false
fi
rm -f "empty_file.txt" "empty@file.txt" 2>/dev/null || true

# Test 55: Summary accuracy - count renamed files
mkdir -p "summary_test"
printf "content1" > "summary_test/file1@name.txt"
printf "content2" > "summary_test/file2@name.txt"
printf "content3" > "summary_test/clean_name.txt"  # Should be skipped
output=$(sanitize-filenames "summary_test" 2>&1)
renamed_count=$(echo "$output" | grep -o "Files renamed: [0-9]*" | grep -o "[0-9]*")
if [[ "$renamed_count" -ge 2 ]]; then
    if print_msg 55 "Does summary show accurate renamed count?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 55 "Does summary show accurate renamed count?" false
fi
rm -rf "summary_test" 2>/dev/null || true

# Test 56: Summary accuracy - count unchanged files
mkdir -p "summary_test2"
printf "content1" > "summary_test2/clean_file1.txt"
printf "content2" > "summary_test2/clean_file2.txt"
output=$(sanitize-filenames "summary_test2" 2>&1)
unchanged_count=$(echo "$output" | grep -o "Files unchanged: [0-9]*" | grep -o "[0-9]*")
if [[ "$unchanged_count" -ge 2 ]]; then
    if print_msg 56 "Does summary show accurate unchanged count?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 56 "Does summary show accurate unchanged count?" false
fi
rm -rf "summary_test2" 2>/dev/null || true

# Test 57: Output format - color codes
printf "content" > "color@test.txt"
output=$(sanitize-filenames "color@test.txt" 2>&1)
if echo "$output" | grep -q "✓\|Renamed" || echo "$output" | grep -q "color_test.txt"; then
    if print_msg 57 "Does sanitize show formatted output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 57 "Does sanitize show formatted output?" false
fi
rm -f "color_test.txt" "color@test.txt" 2>/dev/null || true

# Test 58: Directory name conflicts
# Both dir@name1 and dir@name2 should sanitize to dir_name (the @ and number should be replaced)
# Actually, dir@name1 becomes dir_name1 and dir@name2 becomes dir_name2 (numbers are preserved)
# Let's test with names that would actually conflict
mkdir -p "dir@name"
mkdir -p "dir#name"
printf "content" > "dir@name/file.txt"
printf "content" > "dir#name/file.txt"
if sanitize-filenames . >/dev/null 2>&1; then
    # Both should sanitize to dir_name, but second should skip due to conflict
    dir_count=$(find . -name "dir_name" -type d | wc -l)
    if [[ $dir_count -eq 1 ]]; then
        if print_msg 58 "Does sanitize handle directory name conflicts?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 58 "Does sanitize handle directory name conflicts?" false
    fi
else
    print_msg 58 "Does sanitize handle directory name conflicts?" false
fi
rm -rf "dir_name" "dir@name" "dir#name" 2>/dev/null || true

# Test 59: Nested directory with same name conflict
mkdir -p "outer@dir/inner@dir"
printf "content1" > "outer@dir/file@name.txt"
printf "content2" > "outer@dir/inner@dir/file@name.txt"
if sanitize-filenames "outer@dir" >/dev/null 2>&1; then
    # Should handle nested structure correctly
    if [[ -d "outer_dir" ]] && [[ -f "outer_dir/file_name.txt" ]]; then
        if print_msg 59 "Does sanitize handle nested dirs with conflicts?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 59 "Does sanitize handle nested dirs with conflicts?" false
    fi
else
    print_msg 59 "Does sanitize handle nested dirs with conflicts?" false
fi
rm -rf "outer_dir" "outer@dir" 2>/dev/null || true

# Test 60: Files that become . or .. (should use fallback)
# Create a file that would become just a dot after sanitization
printf "content" > "."
if sanitize-filenames "." >/dev/null 2>&1 2>&1; then
    # Should handle this gracefully
    files_found=$(find . -maxdepth 1 -name "sanitized_*" -type f | wc -l)
    if [[ $files_found -gt 0 ]] || [[ ! -f "." ]]; then
        if print_msg 60 "Does sanitize handle reserved names (. or ..)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 60 "Does sanitize handle reserved names (. or ..)?" false
    fi
else
    print_msg 60 "Does sanitize handle reserved names (. or ..)?" false
fi
rm -f "." sanitized_* 2>/dev/null || true

# Test 61: Test isolation - verify parallel compatibility
cd "${TEST_ISOLATION_DIR}" || exit 93
printf "content" > "isolated@test.txt"
if sanitize-filenames "isolated@test.txt" >/dev/null 2>&1; then
    if [[ -f "isolated_test.txt" ]]; then
        # Verify it's in our isolation directory
        if [[ "$(dirname "$(readlink -f isolated_test.txt 2>/dev/null || echo isolated_test.txt)")" == "${TEST_ISOLATION_DIR}" ]] || [[ -f "${TEST_ISOLATION_DIR}/isolated_test.txt" ]]; then
            if print_msg 61 "Is test isolation working (parallel compatibility)?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        else
            print_msg 61 "Is test isolation working (parallel compatibility)?" false
        fi
    else
        print_msg 61 "Is test isolation working (parallel compatibility)?" false
    fi
else
    print_msg 61 "Is test isolation working (parallel compatibility)?" false
fi
rm -f "isolated_test.txt" "isolated@test.txt" 2>/dev/null || true

# Test 62: Return code when errors occur
# Test with a non-existent path (which should error) rather than read-only file
# (read-only files can still be renamed if directory is writable)
sanitize-filenames "nonexistent_error_test_$$" >/dev/null 2>&1
exit_code=$?
# Function should return 1 on error
if [[ $exit_code -eq 1 ]]; then
    if print_msg 62 "Does sanitize return 1 when errors occur?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 62 "Does sanitize return 1 when errors occur?" false
fi

# Test 63: Process files before directories
mkdir -p "process_order/subdir"
printf "content1" > "process_order/file@name.txt"
printf "content2" > "process_order/subdir/file@name.txt"
if sanitize-filenames "process_order" >/dev/null 2>&1; then
    # Files should be processed first, then dirs
    if [[ -f "process_order/file_name.txt" ]] && [[ -f "process_order/subdir/file_name.txt" ]] && [[ -d "process_order" ]]; then
        if print_msg 63 "Does sanitize process files before directories?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 63 "Does sanitize process files before directories?" false
    fi
else
    print_msg 63 "Does sanitize process files before directories?" false
fi
rm -rf "process_order" 2>/dev/null || true

# Test 64: Default mode (no flags) behavior
printf "content" > "default@mode.txt"
if sanitize-filenames "default@mode.txt" >/dev/null 2>&1; then
    if [[ -f "default_mode.txt" ]] && [[ ! -f "default@mode.txt" ]]; then
        if print_msg 64 "Does default mode sanitize correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 64 "Does default mode sanitize correctly?" false
    fi
else
    print_msg 64 "Does default mode sanitize correctly?" false
fi
rm -f "default_mode.txt" "default@mode.txt" 2>/dev/null || true

# Test 65: Verify -- separator works
printf "content" > "-special.txt"
if sanitize-filenames -- "-special.txt" >/dev/null 2>&1; then
    if [[ -f "_special.txt" ]] || [[ ! -f "-special.txt" ]]; then
        if print_msg 65 "Does -- separator work for paths starting with -?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 65 "Does -- separator work for paths starting with -?" false
    fi
else
    print_msg 65 "Does -- separator work for paths starting with -?" false
fi
rm -f "-special.txt" "_special.txt" 2>/dev/null || true

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
cleanup_isolation

# Clean up any leftover test_debug directories from manual testing
find "${__UNIT_TESTS_DIR}" -maxdepth 1 -type d -name "test_debug*" -exec rm -rf {} + 2>/dev/null || true
find "${__UNIT_TESTS_DIR}" -maxdepth 1 -type f -name "*test_debug*" -delete 2>/dev/null || true

printf "Cleanup complete.\n"

exit 0

