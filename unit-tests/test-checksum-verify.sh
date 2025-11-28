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
total_tests=40  # Tests 1-38 plus 2 summary tests with "*"
printf "Running unit tests for checksum-verify.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/checksum-verify.sh" ]]; then
    if print_msg 3 "Can I find checksum-verify.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find checksum-verify.sh?" false
    printf "Error: Test cannot continue. Checksum-verify.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/checksum-verify.sh" 2>/dev/null; then
    if print_msg 4 "Can I source checksum-verify.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source checksum-verify.sh?" false
    printf "Error: Test cannot continue. Checksum-verify.sh not found.\n" >&2
    exit 4
fi

if declare -f checksum-verify >/dev/null 2>&1; then
    if print_msg 5 "Is checksum-verify function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is checksum-verify function defined?" false
    printf "Error: checksum-verify function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Source drchelp if available for help flag tests
if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_checksum_verify_$$"
readonly TEST_DIR="/tmp/${TEST_PREFIX}"

# Create test directory
mkdir -p "$TEST_DIR" || {
    printf "Error: Failed to create test directory.\n" >&2
    exit 92
}

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

printf "\nTesting help flags...\n"

# Test 6: checksum-verify --help
if declare -f drchelp >/dev/null 2>&1; then
    if checksum-verify --help >/dev/null 2>&1; then
        if print_msg 6 "Does checksum-verify --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 6 "Does checksum-verify --help work?" false
    fi
else
    if print_msg 6 "Does checksum-verify --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: checksum-verify -h
if declare -f drchelp >/dev/null 2>&1; then
    if checksum-verify -h >/dev/null 2>&1; then
        if print_msg 7 "Does checksum-verify -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does checksum-verify -h work?" false
    fi
else
    if print_msg 7 "Does checksum-verify -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test 8: Error on missing file
if ! checksum-verify 2>/dev/null; then
    if print_msg 8 "Does checksum-verify error on missing file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Does checksum-verify error on missing file?" false
fi

# Test 9: Error message for missing file
if checksum-verify 2>&1 | grep -q "Error: File is required"; then
    if print_msg 9 "Does checksum-verify show error message for missing file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does checksum-verify show error message for missing file?" false
fi

# Test 10: Error on nonexistent file
if ! checksum-verify "/nonexistent/file.txt" "abc123" 2>/dev/null; then
    if print_msg 10 "Does checksum-verify error on nonexistent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does checksum-verify error on nonexistent file?" false
fi

# Test 11: Error on missing checksum in verify mode
echo "test content" > "${TEST_DIR}/test.txt"
if ! checksum-verify "${TEST_DIR}/test.txt" 2>/dev/null; then
    if print_msg 11 "Does checksum-verify error on missing checksum?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does checksum-verify error on missing checksum?" false
fi

# Test 12: Error on unknown algorithm
if ! checksum-verify "${TEST_DIR}/test.txt" "abc123" --algorithm invalid 2>/dev/null; then
    if print_msg 12 "Does checksum-verify error on unknown algorithm?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does checksum-verify error on unknown algorithm?" false
fi

# Test 13: Error on unknown option
if ! checksum-verify --unknown-flag 2>/dev/null; then
    if print_msg 13 "Does checksum-verify error on unknown option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does checksum-verify error on unknown option?" false
fi

# Test 14: Error on --algorithm without argument
if ! checksum-verify "${TEST_DIR}/test.txt" "abc123" --algorithm 2>/dev/null; then
    if print_msg 14 "Does checksum-verify error on --algorithm without argument?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does checksum-verify error on --algorithm without argument?" false
fi

printf "\nTesting generate mode...\n"

# Test 15: Generate SHA256 checksum (default)
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 64 ]] && [[ "$result" =~ ^[0-9a-f]{64}$ ]]; then
        if print_msg 15 "Does checksum-verify generate SHA256 checksum (default)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 15 "Does checksum-verify generate SHA256 checksum (default)?" false
    fi
else
    if print_msg 15 "Does checksum-verify generate SHA256 checksum (default)?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 16: Generate MD5 checksum
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm md5 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 32 ]] && [[ "$result" =~ ^[0-9a-f]{32}$ ]]; then
        if print_msg 16 "Does checksum-verify generate MD5 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 16 "Does checksum-verify generate MD5 checksum?" false
    fi
else
    if print_msg 16 "Does checksum-verify generate MD5 checksum?" false; then
        printf "        (md5sum/md5 not available)\n"
    fi
fi

# Test 17: Generate SHA1 checksum
if command -v sha1sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm sha1 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 40 ]] && [[ "$result" =~ ^[0-9a-f]{40}$ ]]; then
        if print_msg 17 "Does checksum-verify generate SHA1 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 17 "Does checksum-verify generate SHA1 checksum?" false
    fi
else
    if print_msg 17 "Does checksum-verify generate SHA1 checksum?" false; then
        printf "        (sha1sum/shasum not available)\n"
    fi
fi

# Test 18: Generate SHA512 checksum
if command -v sha512sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm sha512 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 128 ]] && [[ "$result" =~ ^[0-9a-f]{128}$ ]]; then
        if print_msg 18 "Does checksum-verify generate SHA512 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 18 "Does checksum-verify generate SHA512 checksum?" false
    fi
else
    if print_msg 18 "Does checksum-verify generate SHA512 checksum?" false; then
        printf "        (sha512sum/shasum not available)\n"
    fi
fi

# Test 19: Generate with -g flag
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    result=$(checksum-verify -g "${TEST_DIR}/test.txt" 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 64 ]] && [[ "$result" =~ ^[0-9a-f]{64}$ ]]; then
        if print_msg 19 "Does -g flag work for generate mode?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 19 "Does -g flag work for generate mode?" false
    fi
else
    if print_msg 19 "Does -g flag work for generate mode?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 20: Generate with -a flag
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" -a md5 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 32 ]] && [[ "$result" =~ ^[0-9a-f]{32}$ ]]; then
        if print_msg 20 "Does -a flag work for algorithm selection?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 20 "Does -a flag work for algorithm selection?" false
    fi
else
    if print_msg 20 "Does -a flag work for algorithm selection?" false; then
        printf "        (md5sum/md5 not available)\n"
    fi
fi

printf "\nTesting verify mode...\n"

# Test 21: Verify correct SHA256 checksum
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    if checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 21 "Does checksum-verify verify correct SHA256 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 21 "Does checksum-verify verify correct SHA256 checksum?" false
    fi
else
    if print_msg 21 "Does checksum-verify verify correct SHA256 checksum?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 22: Verify incorrect checksum
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    if checksum-verify "${TEST_DIR}/test.txt" "wrongchecksum123456789012345678901234567890123456789012345678901234567890" 2>&1 | grep -q "✗ Checksums do NOT match"; then
        if print_msg 22 "Does checksum-verify detect incorrect checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 22 "Does checksum-verify detect incorrect checksum?" false
    fi
else
    if print_msg 22 "Does checksum-verify detect incorrect checksum?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 23: Verify correct MD5 checksum
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm md5 2>&1)
    if checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" --algorithm md5 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 23 "Does checksum-verify verify correct MD5 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 23 "Does checksum-verify verify correct MD5 checksum?" false
    fi
else
    if print_msg 23 "Does checksum-verify verify correct MD5 checksum?" false; then
        printf "        (md5sum/md5 not available)\n"
    fi
fi

# Test 24: Verify correct SHA1 checksum
if command -v sha1sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm sha1 2>&1)
    if checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" --algorithm sha1 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 24 "Does checksum-verify verify correct SHA1 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 24 "Does checksum-verify verify correct SHA1 checksum?" false
    fi
else
    if print_msg 24 "Does checksum-verify verify correct SHA1 checksum?" false; then
        printf "        (sha1sum/shasum not available)\n"
    fi
fi

# Test 25: Verify correct SHA512 checksum
if command -v sha512sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm sha512 2>&1)
    if checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" --algorithm sha512 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 25 "Does checksum-verify verify correct SHA512 checksum?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 25 "Does checksum-verify verify correct SHA512 checksum?" false
    fi
else
    if print_msg 25 "Does checksum-verify verify correct SHA512 checksum?" false; then
        printf "        (sha512sum/shasum not available)\n"
    fi
fi

# Test 26: Return code 0 on successful verification
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    if checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" >/dev/null 2>&1; then
        if print_msg 26 "Does checksum-verify return 0 on successful verification?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 26 "Does checksum-verify return 0 on successful verification?" false
    fi
else
    if print_msg 26 "Does checksum-verify return 0 on successful verification?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 27: Return code 1 on failed verification
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    if ! checksum-verify "${TEST_DIR}/test.txt" "wrongchecksum123456789012345678901234567890123456789012345678901234567890" >/dev/null 2>&1; then
        if print_msg 27 "Does checksum-verify return 1 on failed verification?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 27 "Does checksum-verify return 1 on failed verification?" false
    fi
else
    if print_msg 27 "Does checksum-verify return 1 on failed verification?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

printf "\nTesting edge cases...\n"

# Test 28: Case-insensitive checksum comparison
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    uppercase_checksum=$(echo "$correct_checksum" | tr '[:lower:]' '[:upper:]')
    if checksum-verify "${TEST_DIR}/test.txt" "$uppercase_checksum" 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 28 "Does checksum-verify handle case-insensitive checksums?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 28 "Does checksum-verify handle case-insensitive checksums?" false
    fi
else
    if print_msg 28 "Does checksum-verify handle case-insensitive checksums?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 29: Checksum with spaces (should be normalized)
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    checksum_with_spaces="  $correct_checksum  "
    if checksum-verify "${TEST_DIR}/test.txt" "$checksum_with_spaces" 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 29 "Does checksum-verify normalize checksums with spaces?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 29 "Does checksum-verify normalize checksums with spaces?" false
    fi
else
    if print_msg 29 "Does checksum-verify normalize checksums with spaces?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 30: Case-insensitive algorithm names
if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" --algorithm MD5 2>&1)
    if [[ -n "$result" ]] && [[ ${#result} -eq 32 ]] && [[ "$result" =~ ^[0-9a-f]{32}$ ]]; then
        if print_msg 30 "Does checksum-verify handle case-insensitive algorithm names?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 30 "Does checksum-verify handle case-insensitive algorithm names?" false
    fi
else
    if print_msg 30 "Does checksum-verify handle case-insensitive algorithm names?" false; then
        printf "        (md5sum/md5 not available)\n"
    fi
fi

# Test 31: Different file content produces different checksum
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    echo "different content" > "${TEST_DIR}/test2.txt"
    checksum1=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    checksum2=$(checksum-verify --generate "${TEST_DIR}/test2.txt" 2>&1)
    if [[ "$checksum1" != "$checksum2" ]]; then
        if print_msg 31 "Does checksum-verify produce different checksums for different files?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 31 "Does checksum-verify produce different checksums for different files?" false
    fi
else
    if print_msg 31 "Does checksum-verify produce different checksums for different files?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 32: Same file content produces same checksum
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    echo "test content" > "${TEST_DIR}/test3.txt"
    checksum1=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    checksum2=$(checksum-verify --generate "${TEST_DIR}/test3.txt" 2>&1)
    if [[ "$checksum1" == "$checksum2" ]]; then
        if print_msg 32 "Does checksum-verify produce same checksum for same content?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 32 "Does checksum-verify produce same checksum for same content?" false
    fi
else
    if print_msg 32 "Does checksum-verify produce same checksum for same content?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 33: Verify output format (match)
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    output=$(checksum-verify "${TEST_DIR}/test.txt" "$correct_checksum" 2>&1)
    if echo "$output" | grep -q "✓ Checksums match" && \
       echo "$output" | grep -q "File:" && \
       echo "$output" | grep -q "Algorithm:" && \
       echo "$output" | grep -q "Checksum:"; then
        if print_msg 33 "Does checksum-verify output correct format on match?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 33 "Does checksum-verify output correct format on match?" false
    fi
else
    if print_msg 33 "Does checksum-verify output correct format on match?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 34: Verify output format (mismatch)
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    output=$(checksum-verify "${TEST_DIR}/test.txt" "wrongchecksum123456789012345678901234567890123456789012345678901234567890" 2>&1)
    if echo "$output" | grep -q "✗ Checksums do NOT match" && \
       echo "$output" | grep -q "File:" && \
       echo "$output" | grep -q "Algorithm:" && \
       echo "$output" | grep -q "Expected:" && \
       echo "$output" | grep -q "Actual:"; then
        if print_msg 34 "Does checksum-verify output correct format on mismatch?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 34 "Does checksum-verify output correct format on mismatch?" false
    fi
else
    if print_msg 34 "Does checksum-verify output correct format on mismatch?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 35: Generate mode output (just checksum, no extra text)
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    result=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    # Should be just the checksum, no extra text
    if [[ -n "$result" ]] && [[ ${#result} -eq 64 ]] && [[ "$result" =~ ^[0-9a-f]{64}$ ]] && ! echo "$result" | grep -q "Error"; then
        if print_msg 35 "Does generate mode output only checksum (no extra text)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 35 "Does generate mode output only checksum (no extra text)?" false
    fi
else
    if print_msg 35 "Does generate mode output only checksum (no extra text)?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 36: -- separator handling
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    correct_checksum=$(checksum-verify --generate "${TEST_DIR}/test.txt" 2>&1)
    if checksum-verify -- "${TEST_DIR}/test.txt" "$correct_checksum" 2>&1 | grep -q "✓ Checksums match"; then
        if print_msg 36 "Does checksum-verify handle -- separator?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 36 "Does checksum-verify handle -- separator?" false
    fi
else
    if print_msg 36 "Does checksum-verify handle -- separator?" false; then
        printf "        (sha256sum/shasum not available)\n"
    fi
fi

# Test 37: Too many arguments error
if ! checksum-verify "${TEST_DIR}/test.txt" "abc123" "extra" 2>/dev/null; then
    if print_msg 37 "Does checksum-verify error on too many arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 37 "Does checksum-verify error on too many arguments?" false
fi

# Test 38: Generate mode with extra argument (should error on too many args)
if ! checksum-verify --generate "${TEST_DIR}/test.txt" "extra" 2>/dev/null; then
    if print_msg 38 "Does generate mode error on too many arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 38 "Does generate mode error on too many arguments?" false
fi

print_msg "*" "Did I complete all functional tests?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Final summary
printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Total Tests: %d\n" "$total_tests"
printf "Passed: %d\n" "$score"
printf "Failed: %d\n" "$((total_tests - score))"
percentage=$(echo "scale=1; $score * 100 / $total_tests" | bc)
printf "Success Rate: %.1f%%\n" "$percentage"

# Write results file for test runner
if type write_test_results >/dev/null 2>&1; then
    if [[ $score -eq $total_tests ]]; then
        write_test_results "PASSED" "$score" "$total_tests" "$percentage"
    else
        write_test_results "FAILED" "$score" "$total_tests" "$percentage"
    fi
fi

if [[ $score -eq $total_tests ]]; then
    printf "\nAll tests passed! ✓\n"
    exit 0
else
    printf "\nSome tests failed. ✗\n"
    exit 1
fi

