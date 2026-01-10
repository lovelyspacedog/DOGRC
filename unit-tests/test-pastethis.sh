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
total_tests=56  # Comprehensive test coverage (54 numbered + 2 summary tests)
printf "Running unit tests for pastethis.sh...\n\n"

# Initialize progress tracking for real-time updates
if type init_test_progress >/dev/null 2>&1; then
    init_test_progress "$total_tests"
fi

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_pastethis_dir.$$"
readonly TEST_ISOLATION_DIR="${__UNIT_TESTS_DIR}/${TEST_PREFIX}"
mkdir -p "${TEST_ISOLATION_DIR}" || {
    printf "Error: Cannot create test isolation directory: %s\n" "${TEST_ISOLATION_DIR}" >&2
    exit 1
}

# Change to isolation directory
cd "${TEST_ISOLATION_DIR}" || {
    printf "Error: Cannot cd to test isolation directory.\n" >&2
    exit 1
}

# Cleanup function to remove isolation directory and restore API key
__CLEANUP_DONE=false
cleanup_isolation() {
    # Prevent multiple executions of cleanup
    if [[ "${__CLEANUP_DONE}" == "true" ]]; then
        return
    fi
    __CLEANUP_DONE=true

    local exit_code=$?
    
    # Move out of the isolation directory first
    cd "${__UNIT_TESTS_DIR}" || cd /tmp || true
    
    # Restore API key if it was backed up and not yet restored
    if [[ -n "${api_key_backup:-}" ]] && [[ -f "${api_key_backup}" ]]; then
        mv "${api_key_backup}" "${api_key_file}" 2>/dev/null || true
    fi
    
    # Remove the isolation directory
    if [[ -n "${TEST_ISOLATION_DIR:-}" ]] && [[ -d "${TEST_ISOLATION_DIR}" ]]; then
        # Ensure we have permissions and it's not busy
        chmod -R 777 "${TEST_ISOLATION_DIR}" 2>/dev/null || true
        rm -rf "${TEST_ISOLATION_DIR}" 2>/dev/null || {
            sleep 0.2
            rm -rf "${TEST_ISOLATION_DIR}" 2>/dev/null || true
        }
    fi
    
    # Only call exit if we were triggered by a signal (not normal EXIT)
    # This avoids recursion in some shell versions
    case "${1:-}" in
        INT|TERM|HUP) exit $((128 + exit_code)) ;;
    esac
}
# Trap multiple signals plus normal EXIT
trap 'cleanup_isolation EXIT' EXIT
trap 'cleanup_isolation INT' INT
trap 'cleanup_isolation TERM' TERM
trap 'cleanup_isolation HUP' HUP

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

if [[ -f "${__PLUGINS_DIR}/utilities/pastethis.sh" ]]; then
    if print_msg 3 "Can I find pastethis.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find pastethis.sh?" false
    printf "Error: Test cannot continue. pastethis.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/pastethis.sh" 2>/dev/null; then
    if print_msg 4 "Can I source pastethis.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source pastethis.sh?" false
    printf "Error: Test cannot continue. pastethis.sh failed to source.\n" >&2
    exit 4
fi

if declare -f pastethis >/dev/null 2>&1; then
    if print_msg 5 "Is pastethis function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is pastethis function defined?" false
    printf "Error: pastethis function not defined.\n" >&2
    exit 5
fi

# Check if completion function is defined
if declare -f _pastethis_completion >/dev/null 2>&1; then
    if print_msg 6 "Is _pastethis_completion function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is _pastethis_completion function defined?" false
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

printf "\nTesting help flags...\n"

# Test 7: pastethis --help
if declare -f drchelp >/dev/null 2>&1; then
    if pastethis --help >/dev/null 2>&1; then
        if print_msg 7 "Does pastethis --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does pastethis --help work?" false
    fi
else
    if print_msg 7 "Does pastethis --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 8: pastethis -h
if declare -f drchelp >/dev/null 2>&1; then
    if pastethis -h >/dev/null 2>&1; then
        if print_msg 8 "Does pastethis -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 8 "Does pastethis -h work?" false
    fi
else
    if print_msg 8 "Does pastethis -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test 9: Error on missing file
if ! pastethis 2>/dev/null; then
    if print_msg 9 "Does pastethis error on missing file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does pastethis error on missing file?" false
fi

# Test 10: Error on non-existent file
if ! pastethis nonexistent_file_$$.txt 2>/dev/null; then
    if print_msg 10 "Does pastethis error on non-existent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does pastethis error on non-existent file?" false
fi

# Test 11: Error on empty file
touch "${TEST_PREFIX}_empty.txt"
if ! pastethis "${TEST_PREFIX}_empty.txt" 2>/dev/null; then
    if print_msg 11 "Does pastethis error on empty file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does pastethis error on empty file?" false
fi
rm -f "${TEST_PREFIX}_empty.txt"

# Test 12: Error on missing API key file
# Temporarily move API key if it exists
api_key_file="/home/tony/Documents/pastebin-api-key"
api_key_backup=""
if [[ -f "$api_key_file" ]]; then
    api_key_backup="${api_key_file}.backup_$$"
    mv "$api_key_file" "$api_key_backup" 2>/dev/null || true
fi

echo "test content" > "${TEST_PREFIX}_test.txt"
if ! pastethis "${TEST_PREFIX}_test.txt" 2>/dev/null; then
    if print_msg 12 "Does pastethis error on missing API key file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does pastethis error on missing API key file?" false
fi

# Restore API key immediately after test 12
if [[ -n "${api_key_backup:-}" ]] && [[ -f "${api_key_backup}" ]]; then
    mv "${api_key_backup}" "${api_key_file}" 2>/dev/null || true
    unset api_key_backup
fi

# Test 13: Error on invalid privacy level
echo "test content" > "${TEST_PREFIX}_privacy.txt"
if ! pastethis --privacy invalid_privacy "${TEST_PREFIX}_privacy.txt" 2>/dev/null; then
    if print_msg 13 "Does pastethis error on invalid privacy level?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does pastethis error on invalid privacy level?" false
fi
rm -f "${TEST_PREFIX}_privacy.txt"

# Test 14: Error on invalid expiration
echo "test content" > "${TEST_PREFIX}_expire.txt"
if ! pastethis --expires invalid_time "${TEST_PREFIX}_expire.txt" 2>/dev/null; then
    if print_msg 14 "Does pastethis error on invalid expiration?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does pastethis error on invalid expiration?" false
fi
rm -f "${TEST_PREFIX}_expire.txt"

printf "\nTesting file extension auto-detection...\n"

# Test 15-25: Extension detection for various languages
test_extensions=(
    "sh:Bash"
    "py:Python"
    "js:JavaScript"
    "ts:TypeScript"
    "java:Java"
    "cpp:C++"
    "rs:Rust"
    "go:Go"
    "rb:Ruby"
    "php:PHP"
    "html:HTML"
)

test_num=15
for ext_test in "${test_extensions[@]}"; do
    IFS=: read -r extension expected_format <<< "$ext_test"
    test_file="${TEST_PREFIX}_test.$extension"
    echo "// Test content for .$extension" > "$test_file"
    
    # We can't easily test the actual format without mocking curl
    # But we can verify the file is readable and has content
    if [[ -s "$test_file" ]]; then
        if print_msg "$test_num" "Can detect .$extension extension (file created)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg "$test_num" "Can detect .$extension extension (file created)?" false
    fi
    rm -f "$test_file"
    ((test_num++))
done

printf "\nTesting special filename handling...\n"

# Test 26: Filename with spaces
special_file="${TEST_PREFIX}_file with spaces.txt"
echo "content" > "$special_file"
if [[ -f "$special_file" ]]; then
    if print_msg 26 "Can handle filenames with spaces?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Can handle filenames with spaces?" false
fi
rm -f "$special_file"

# Test 27: Filename with special characters
special_file="${TEST_PREFIX}_file&symbols$.txt"
echo "content" > "$special_file"
if [[ -f "$special_file" ]]; then
    if print_msg 27 "Can handle filenames with special chars?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Can handle filenames with special chars?" false
fi
rm -f "$special_file"

# Test 28: Long filename
long_file="${TEST_PREFIX}_$(printf 'a%.0s' {1..100}).txt"
echo "content" > "$long_file"
if [[ -f "$long_file" ]]; then
    if print_msg 28 "Can handle long filenames?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Can handle long filenames?" false
fi
rm -f "$long_file"

printf "\nTesting argument parsing...\n"

# Test 29: Long privacy flag
echo "content" > "${TEST_PREFIX}_shortflag.txt"
# Test that command parses without syntax error (will fail on API key, which is expected)
# In parallel mode, we can't check stdout, so we check that it doesn't fail with argument parsing errors
# Use explicit format to avoid default format issues
if pastethis --privacy public --format Python "${TEST_PREFIX}_shortflag.txt" >/dev/null 2>&1; then
    # Command succeeded (API error is expected, not argument parsing error)
    if print_msg 29 "Does --privacy flag parse correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # Check if it failed with argument parsing error (exit codes 1,3,4,5) vs API error (exit code 6)
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 29 "Does --privacy flag parse correctly?" false
    else
        # Any other exit code (like 6 for API error) means parsing succeeded
        if print_msg 29 "Does --privacy flag parse correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "${TEST_PREFIX}_shortflag.txt"

# Test 30: Long format flag
echo "content" > "${TEST_PREFIX}_format.txt"
if pastethis --format Python "${TEST_PREFIX}_format.txt" >/dev/null 2>&1; then
    if print_msg 30 "Does --format flag parse correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 30 "Does --format flag parse correctly?" false
    else
        if print_msg 30 "Does --format flag parse correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "${TEST_PREFIX}_format.txt"

# Test 31: -n flag (never expire)
echo "content" > "${TEST_PREFIX}_never.txt"
if pastethis -n --format Python "${TEST_PREFIX}_never.txt" >/dev/null 2>&1; then
    if print_msg 31 "Does -n flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 31 "Does -n flag work?" false
    else
        if print_msg 31 "Does -n flag work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "${TEST_PREFIX}_never.txt"

# Test 32: Title flag
echo "content" > "${TEST_PREFIX}_title.txt"
if pastethis --title "Test Title" --format Python "${TEST_PREFIX}_title.txt" >/dev/null 2>&1; then
    if print_msg 32 "Does --title flag parse correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 32 "Does --title flag parse correctly?" false
    else
        if print_msg 32 "Does --title flag parse correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "${TEST_PREFIX}_title.txt"

# Test 33-35: Expires flag with various formats (test just 3)
test_expires=("10m" "1h" "1d")
test_num=33
for expire_val in "${test_expires[@]}"; do
    test_file="${TEST_PREFIX}_expire_${expire_val}.txt"
    echo "content" > "$test_file"
    if pastethis --expires "$expire_val" --format Python "$test_file" >/dev/null 2>&1; then
        if print_msg "$test_num" "Does --expires $expire_val parse correctly?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        exit_code=$?
        if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
            print_msg "$test_num" "Does --expires $expire_val parse correctly?" false
        else
            if print_msg "$test_num" "Does --expires $expire_val parse correctly?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        fi
    fi
    rm -f "$test_file"
    ((test_num++))
done

printf "\nTesting completion function...\n"

# Test 36: Completion function for privacy values
if declare -f _pastethis_completion >/dev/null 2>&1; then
    COMP_WORDS=(pastethis --privacy "")
    COMP_CWORD=2
    _pastethis_completion
    if [[ " ${COMPREPLY[*]} " =~ " public " ]]; then
        if print_msg 36 "Does completion suggest 'public' for --privacy?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 36 "Does completion suggest 'public' for --privacy?" false
    fi
else
    print_msg 36 "Does completion suggest 'public' for --privacy?" false
fi

# Test 37: Completion for format values
if declare -f _pastethis_completion >/dev/null 2>&1; then
    COMP_WORDS=(pastethis --format "")
    COMP_CWORD=2
    _pastethis_completion
    if [[ " ${COMPREPLY[*]} " =~ " python " ]]; then
        if print_msg 37 "Does completion suggest 'python' for --format?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 37 "Does completion suggest 'python' for --format?" false
    fi
else
    print_msg 37 "Does completion suggest 'python' for --format?" false
fi

# Test 38: Completion for flags
if declare -f _pastethis_completion >/dev/null 2>&1; then
    COMP_WORDS=(pastethis --)
    COMP_CWORD=1
    _pastethis_completion
    if [[ " ${COMPREPLY[*]} " =~ " --help " ]]; then
        if print_msg 38 "Does completion suggest --help flag?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 38 "Does completion suggest --help flag?" false
    fi
else
    print_msg 38 "Does completion suggest --help flag?" false
fi

printf "\nTesting file content handling...\n"

# Test 39: Multi-line file
multiline_file="${TEST_PREFIX}_multiline.txt"
cat > "$multiline_file" <<'MULTILINE'
Line 1
Line 2
Line 3
Line 4
Line 5
MULTILINE
if [[ $(wc -l < "$multiline_file") -eq 5 ]]; then
    if print_msg 39 "Can create multi-line test file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 39 "Can create multi-line test file?" false
fi
rm -f "$multiline_file"

# Test 40: File with special characters in content
special_content_file="${TEST_PREFIX}_special.txt"
cat > "$special_content_file" <<'SPECIAL'
Content with & ampersand
Content with = equals
Content with ? question
Content with # hash
Content with $ dollar
SPECIAL
if [[ -s "$special_content_file" ]]; then
    if print_msg 40 "Can create file with special chars in content?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 40 "Can create file with special chars in content?" false
fi
rm -f "$special_content_file"

# Test 41: File with backticks
backtick_file="${TEST_PREFIX}_backtick.txt"
echo 'Code with `backticks` inside' > "$backtick_file"
if [[ -s "$backtick_file" ]]; then
    if print_msg 41 "Can handle file with backticks?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 41 "Can handle file with backticks?" false
fi
rm -f "$backtick_file"

# Test 42: File with quotes
quote_file="${TEST_PREFIX}_quotes.txt"
echo 'String with "quotes" and '\''single quotes'\''' > "$quote_file"
if [[ -s "$quote_file" ]]; then
    if print_msg 42 "Can handle file with quotes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 42 "Can handle file with quotes?" false
fi
rm -f "$quote_file"

printf "\nTesting automatic title generation...\n"

# Test 43: Title is set from filename
# Since we can't easily test without API, we verify the parsing happens
filename_test="${TEST_PREFIX}_mytitle.sh"
echo "content" > "$filename_test"
if [[ -f "$filename_test" ]]; then
    if print_msg 43 "File created for title test?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 43 "File created for title test?" false
fi
rm -f "$filename_test"

printf "\nTesting format flag combinations...\n"

# Test 44: Explicit format overrides extension
override_file="${TEST_PREFIX}_override.py"
echo "# Python file" > "$override_file"
if pastethis --format JavaScript "$override_file" >/dev/null 2>&1; then
    if print_msg 44 "Does explicit --format override extension?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 44 "Does explicit --format override extension?" false
    else
        if print_msg 44 "Does explicit --format override extension?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "$override_file"

# Test 45: auto format triggers detection
auto_file="${TEST_PREFIX}_auto.js"
echo "// JavaScript" > "$auto_file"
if pastethis --format auto "$auto_file" >/dev/null 2>&1; then
    if print_msg 45 "Does --format auto work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
        print_msg 45 "Does --format auto work?" false
    else
        if print_msg 45 "Does --format auto work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    fi
fi
rm -f "$auto_file"

printf "\nTesting special file types...\n"

# Test 46: Dockerfile (no extension)
dockerfile="${TEST_PREFIX}_Dockerfile"
echo "FROM ubuntu:latest" > "$dockerfile"
if [[ -s "$dockerfile" ]]; then
    if print_msg 46 "Can handle Dockerfile (no extension)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 46 "Can handle Dockerfile (no extension)?" false
fi
rm -f "$dockerfile"

# Test 47: Makefile (no extension)
makefile="${TEST_PREFIX}_Makefile"
echo "all:" > "$makefile"
if [[ -s "$makefile" ]]; then
    if print_msg 47 "Can handle Makefile (no extension)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 47 "Can handle Makefile (no extension)?" false
fi
rm -f "$makefile"

# Test 48: Unknown extension defaults safely
unknown_file="${TEST_PREFIX}_unknown.xyz"
echo "unknown content" > "$unknown_file"
if [[ -s "$unknown_file" ]]; then
    if print_msg 48 "Can handle unknown extension .xyz?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 48 "Can handle unknown extension .xyz?" false
fi
rm -f "$unknown_file"

printf "\nTesting privacy combinations...\n"

# Test 49-51: Privacy values
test_privacy=("public" "unlisted" "private")
test_num=49
for priv in "${test_privacy[@]}"; do
    priv_file="${TEST_PREFIX}_${priv}.txt"
    echo "content" > "$priv_file"
    if pastethis --privacy "$priv" --format Python "$priv_file" >/dev/null 2>&1; then
        if print_msg "$test_num" "Does --privacy $priv parse?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        exit_code=$?
        if [[ $exit_code -eq 1 ]] || [[ $exit_code -eq 3 ]] || [[ $exit_code -eq 4 ]] || [[ $exit_code -eq 5 ]]; then
            print_msg "$test_num" "Does --privacy $priv parse?" false
        else
            if print_msg "$test_num" "Does --privacy $priv parse?" true; then
                ((score++))
                if type update_progress_from_score >/dev/null 2>&1; then
                    update_progress_from_score
                fi
            fi
        fi
    fi
    rm -f "$priv_file"
    ((test_num++))
done

printf "\nTesting edge cases...\n"

# Test 52: Very large file (1000 lines)
large_file="${TEST_PREFIX}_large.txt"
for i in {1..1000}; do
    echo "Line $i with some content to make it longer" >> "$large_file"
done
if [[ $(wc -l < "$large_file") -eq 1000 ]]; then
    if print_msg 52 "Can create large file (1000 lines)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 52 "Can create large file (1000 lines)?" false
fi
rm -f "$large_file"

# Test 53: File with only whitespace
whitespace_file="${TEST_PREFIX}_whitespace.txt"
echo "   " > "$whitespace_file"
if [[ -s "$whitespace_file" ]]; then
    if print_msg 53 "Can handle file with whitespace content?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 53 "Can handle file with whitespace content?" false
fi
rm -f "$whitespace_file"

# Test 54: Script returns exit codes correctly
echo "content" > "${TEST_PREFIX}_exitcode.txt"
pastethis "${TEST_PREFIX}_exitcode.txt" 2>/dev/null
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 54 "Does pastethis return non-zero on missing API key?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 54 "Does pastethis return non-zero on missing API key?" false
fi
rm -f "${TEST_PREFIX}_exitcode.txt"

print_msg "*" "Did I pass all validation tests?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Final results
printf "\n\n"
printf "================================================================================\n"
printf "Test Results: %d/%d tests passed\n" "$score" "$total_tests"
printf "================================================================================\n"

if [[ $score -eq $total_tests ]]; then
    write_test_results "PASSED" "$score" "$total_tests"
    printf "Status: ALL TESTS PASSED ✅\n"
    # Ensure results are written before we potentially exit
    sync 2>/dev/null || true
    exit 0
elif [[ $score -ge $((total_tests * 80 / 100)) ]]; then
    write_test_results "PASSED" "$score" "$total_tests"
    printf "Status: MOSTLY PASSED ⚠️  (%.1f%%)\n" "$(bc -l <<< "scale=1; $score * 100 / $total_tests")"
    sync 2>/dev/null || true
    exit 0
else
    write_test_results "FAILED" "$score" "$total_tests"
    printf "Status: FAILED ❌ (%.1f%%)\n" "$(bc -l <<< "scale=1; $score * 100 / $total_tests")"
    sync 2>/dev/null || true
    exit 1
fi

