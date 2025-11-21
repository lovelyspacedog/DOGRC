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
total_tests=36  # Tests 1-34 plus 2 summary tests with "*"
printf "Running unit tests for archive.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/archive.sh" ]]; then
    if print_msg 3 "Can I find archive.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find archive.sh?" false
    printf "Error: Test cannot continue. Archive.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/archive.sh" 2>/dev/null; then
    if print_msg 4 "Can I source archive.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source archive.sh?" false
    printf "Error: Test cannot continue. Archive.sh not found.\n" >&2
    exit 4
fi

if declare -f extract >/dev/null 2>&1; then
    if print_msg 5 "Is extract function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is extract function defined?" false
    printf "Error: extract function not defined.\n" >&2
    exit 5
fi

if declare -f compress >/dev/null 2>&1; then
    if print_msg 6 "Is compress function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is compress function defined?" false
    printf "Error: compress function not defined.\n" >&2
    exit 6
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
readonly TEST_PREFIX="test_archive_$$"
readonly TEST_DIR="${TEST_PREFIX}_dir"

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if extract --help >/dev/null 2>&1; then
        if print_msg 7 "Does extract --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does extract --help work?" false
    fi
else
    if print_msg 7 "Does extract --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if extract -h >/dev/null 2>&1; then
        if print_msg 8 "Does extract -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does extract -h work?" false
    fi
else
    if print_msg 8 "Does extract -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if compress --help >/dev/null 2>&1; then
        if print_msg 9 "Does compress --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does compress --help work?" false
    fi
else
    if print_msg 9 "Does compress --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if compress -h >/dev/null 2>&1; then
        if print_msg 10 "Does compress -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does compress -h work?" false
    fi
else
    if print_msg 10 "Does compress -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nCreating test files...\n"
test_content="This is a test file for archiving.\nLine 2 of test file.\nEnd of test file.\n"

if printf "${test_content}" > "${__UNIT_TESTS_DIR}/test_file.txt"; then
    if print_msg 11 "Can I create test_file.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Can I create test_file.txt?" false
    printf "Error: Test cannot continue. Failed to create test_file.txt.\n" >&2
    exit 11
fi

print_msg "*" "Did I create test files?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nTesting extract error handling...\n"

if ! extract 2>/dev/null; then
    if print_msg 12 "Does extract error on missing arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does extract error on missing arguments?" false
fi

if ! extract "nonexistent.tar.gz" 2>/dev/null; then
    if print_msg 13 "Does extract error on non-existent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does extract error on non-existent file?" false
fi

printf "test" > "unsupported.txt"
if ! extract "unsupported.txt" 2>/dev/null; then
    if print_msg 14 "Does extract error on unsupported format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does extract error on unsupported format?" false
fi
rm -f "unsupported.txt"

printf "\nTesting compress error handling...\n"

if ! compress 2>/dev/null; then
    if print_msg 15 "Does compress error on missing arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does compress error on missing arguments?" false
fi

if ! compress "nonexistent.txt" 2>/dev/null; then
    if print_msg 16 "Does compress error on non-existent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does compress error on non-existent file?" false
fi

if ! compress "test_file.txt" "unsupported" 2>/dev/null; then
    if print_msg 17 "Does compress error on unsupported format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does compress error on unsupported format?" false
fi

printf "\nTesting compress functionality (if gzip available)...\n"

if command -v gzip >/dev/null 2>&1; then
    if compress "test_file.txt" >/dev/null 2>&1; then
        if [[ -f "test_file.txt.gz" ]]; then
            if print_msg 18 "Does compress create .gz file by default?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 18 "Does compress create .gz file by default?" false
            fi
        else
            print_msg 18 "Does compress create .gz file by default?" false
        fi
    else
        print_msg 18 "Does compress create .gz file by default?" false
    fi
else
    if print_msg 18 "Does compress create .gz file by default?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
fi

if command -v gzip >/dev/null 2>&1; then
    printf "${test_content}" > "test_file2.txt"
    if compress "test_file2.txt" "gz" >/dev/null 2>&1; then
        if [[ -f "test_file2.txt.gz" ]]; then
            if print_msg 19 "Does compress create .gz file with explicit format?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 19 "Does compress create .gz file with explicit format?" false
            fi
        else
            print_msg 19 "Does compress create .gz file with explicit format?" false
        fi
    else
        print_msg 19 "Does compress create .gz file with explicit format?" false
    fi
    rm -f "test_file2.txt" 2>/dev/null || true
else
    if print_msg 19 "Does compress create .gz file with explicit format?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
fi

printf "\nTesting extract functionality (if gunzip available)...\n"

if command -v gunzip >/dev/null 2>&1 && [[ -f "test_file.txt.gz" ]]; then
    rm -f "test_file.txt" 2>/dev/null || true
    if extract "test_file.txt.gz" >/dev/null 2>&1; then
        if [[ -f "test_file.txt" ]] && [[ ! -f "test_file.txt.gz" ]]; then
            if print_msg 20 "Does extract .gz file work correctly?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 20 "Does extract .gz file work correctly?" false
            fi
        else
            print_msg 20 "Does extract .gz file work correctly?" false
        fi
    else
        print_msg 20 "Does extract .gz file work correctly?" false
    fi
    printf "${test_content}" > "test_file.txt"
else
    if print_msg 20 "Does extract .gz file work correctly?" false; then
        printf "        (gunzip not available or no .gz file, skipping)\n"
    fi
fi

printf "\nTesting tar.gz compression (if tar available)...\n"

if command -v tar >/dev/null 2>&1; then
    mkdir -p "${TEST_DIR}"
    printf "content1" > "${TEST_DIR}/file1.txt"
    printf "content2" > "${TEST_DIR}/file2.txt"
    if compress "${TEST_DIR}" >/dev/null 2>&1; then
        if [[ -f "${TEST_DIR}.tar.gz" ]]; then
            if print_msg 21 "Does compress create .tar.gz for directory?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 21 "Does compress create .tar.gz for directory?" false
            fi
        else
            print_msg 21 "Does compress create .tar.gz for directory?" false
        fi
    else
        print_msg 21 "Does compress create .tar.gz for directory?" false
    fi
    rm -rf "${TEST_DIR}" 2>/dev/null || true
else
    if print_msg 21 "Does compress create .tar.gz for directory?" false; then
        printf "        (tar not available, skipping)\n"
    fi
fi

if command -v tar >/dev/null 2>&1 && [[ -f "${TEST_DIR}.tar.gz" ]]; then
    if extract "${TEST_DIR}.tar.gz" >/dev/null 2>&1; then
        if [[ -d "${TEST_DIR}" ]] && [[ -f "${TEST_DIR}/file1.txt" ]]; then
            if print_msg 22 "Does extract .tar.gz file work correctly?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 22 "Does extract .tar.gz file work correctly?" false
            fi
        else
            print_msg 22 "Does extract .tar.gz file work correctly?" false
        fi
    else
        print_msg 22 "Does extract .tar.gz file work correctly?" false
    fi
    rm -rf "${TEST_DIR}" "${TEST_DIR}.tar.gz" 2>/dev/null || true
else
    if print_msg 22 "Does extract .tar.gz file work correctly?" false; then
        printf "        (tar not available or no .tar.gz file, skipping)\n"
    fi
fi

printf "\nTesting return codes...\n"

if command -v gzip >/dev/null 2>&1; then
    printf "${test_content}" > "test_success.txt"
    if compress "test_success.txt" >/dev/null 2>&1; then
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            if print_msg 23 "Does compress return 0 on success?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 23 "Does compress return 0 on success?" false
        fi
    else
        print_msg 23 "Does compress return 0 on success?" false
    fi
    rm -f "test_success.txt" "test_success.txt.gz" 2>/dev/null || true
else
    if print_msg 23 "Does compress return 0 on success?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
fi

if command -v gunzip >/dev/null 2>&1 && command -v gzip >/dev/null 2>&1; then
    # Create a new .gz file for this test since test 20 removed it
    printf "${test_content}" > "test_file24.txt"
    if compress "test_file24.txt" >/dev/null 2>&1 && [[ -f "test_file24.txt.gz" ]]; then
        rm -f "test_file24.txt" 2>/dev/null || true
        if extract "test_file24.txt.gz" >/dev/null 2>&1; then
            exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                if print_msg 24 "Does extract return 0 on success?" true; then
                    ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
                fi
            else
                print_msg 24 "Does extract return 0 on success?" false
            fi
        else
            print_msg 24 "Does extract return 0 on success?" false
        fi
        rm -f "test_file24.txt" "test_file24.txt.gz" 2>/dev/null || true
    else
        print_msg 24 "Does extract return 0 on success?" false
        rm -f "test_file24.txt" "test_file24.txt.gz" 2>/dev/null || true
    fi
else
    if print_msg 24 "Does extract return 0 on success?" false; then
        printf "        (gunzip/gzip not available, skipping)\n"
    fi
fi

compress "nonexistent.txt" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 25 "Does compress return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does compress return non-zero on error?" false
fi

extract "nonexistent.tar.gz" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 26 "Does extract return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does extract return non-zero on error?" false
fi

printf "\nTesting bash completion (if available)...\n"

if command -v complete >/dev/null 2>&1; then
    if complete -p extract >/dev/null 2>&1; then
        if print_msg 27 "Is extract completion function registered?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 27 "Is extract completion function registered?" false
    fi
else
    if print_msg 27 "Is extract completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

if command -v complete >/dev/null 2>&1; then
    if complete -p compress >/dev/null 2>&1; then
        if print_msg 28 "Is compress completion function registered?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 28 "Is compress completion function registered?" false
    fi
else
    if print_msg 28 "Is compress completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

printf "\nTesting output messages...\n"

if command -v gzip >/dev/null 2>&1; then
    printf "${test_content}" > "test_msg.txt"
    output=$(compress "test_msg.txt" 2>&1)
    if echo "$output" | grep -q "Created:"; then
        if print_msg 29 "Does compress output success message?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 29 "Does compress output success message?" false
    fi
    rm -f "test_msg.txt" "test_msg.txt.gz" 2>/dev/null || true
else
    if print_msg 29 "Does compress output success message?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
fi

error_output=$(compress "nonexistent.txt" 2>&1)
if echo "$error_output" | grep -q "Error:"; then
    if print_msg 30 "Does compress output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does compress output error message?" false
fi

error_output=$(extract "nonexistent.tar.gz" 2>&1)
if echo "$error_output" | grep -q "Error:" || echo "$error_output" | grep -q "cannot be extracted"; then
    if print_msg 31 "Does extract output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 31 "Does extract output error message?" false
fi

printf "\nTesting edge cases...\n"

if command -v gzip >/dev/null 2>&1; then
    printf "${test_content}" > "test_exists.txt"
    printf "${test_content}" > "test_exists.txt.gz"
    if ! compress "test_exists.txt" "gz" >/dev/null 2>&1; then
        if print_msg 32 "Does compress error when output already exists?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 32 "Does compress error when output already exists?" false
    fi
    rm -f "test_exists.txt" "test_exists.txt.gz" 2>/dev/null || true
else
    if print_msg 32 "Does compress error when output already exists?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
fi

if command -v tar >/dev/null 2>&1 && command -v bzip2 >/dev/null 2>&1; then
    mkdir -p "${TEST_PREFIX}_format"
    printf "content" > "${TEST_PREFIX}_format/file.txt"
    if compress "${TEST_PREFIX}_format" "tbz2" >/dev/null 2>&1; then
        if [[ -f "${TEST_PREFIX}_format.tar.bz2" ]]; then
            if print_msg 33 "Does compress handle format alias (tbz2)?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 33 "Does compress handle format alias (tbz2)?" false
            fi
        else
            print_msg 33 "Does compress handle format alias (tbz2)?" false
        fi
    else
        print_msg 33 "Does compress handle format alias (tbz2)?" false
    fi
    rm -rf "${TEST_PREFIX}_format" "${TEST_PREFIX}_format.tar.bz2" 2>/dev/null || true
else
    if print_msg 33 "Does compress handle format alias (tbz2)?" false; then
        printf "        (tar/bzip2 not available, skipping)\n"
    fi
fi

if command -v gzip >/dev/null 2>&1; then
    printf "${test_content}" > "test_preserve.txt"
    original_content="$(cat test_preserve.txt)"
    if compress "test_preserve.txt" >/dev/null 2>&1; then
        preserved_content="$(cat test_preserve.txt 2>/dev/null || echo '')"
        if [[ "$preserved_content" == "$original_content" ]]; then
            if print_msg 34 "Does compress preserve original file?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            else
                print_msg 34 "Does compress preserve original file?" false
            fi
        else
            print_msg 34 "Does compress preserve original file?" false
        fi
    else
        print_msg 34 "Does compress preserve original file?" false
    fi
    rm -f "test_preserve.txt" "test_preserve.txt.gz" 2>/dev/null || true
else
    if print_msg 34 "Does compress preserve original file?" false; then
        printf "        (gzip not available, skipping)\n"
    fi
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
rm -f test_file.txt test_file.txt.gz test_file2.txt test_file2.txt.gz 2>/dev/null || true
rm -f test_success.txt test_success.txt.gz test_msg.txt test_msg.txt.gz 2>/dev/null || true
rm -f test_exists.txt test_exists.txt.gz test_preserve.txt test_preserve.txt.gz 2>/dev/null || true
rm -rf ${TEST_DIR} ${TEST_DIR}.tar.gz ${TEST_PREFIX}_format ${TEST_PREFIX}_format.tar.bz2 2>/dev/null || true
rm -f *.tar.gz *.tar.bz2 *.gz *.bz2 2>/dev/null || true
printf "Cleanup complete.\n"

exit 0
