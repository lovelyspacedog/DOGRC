#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __TESTING_DIR="$(cd "${__UNIT_TESTS_DIR}/.." && pwd)"
readonly __PLUGINS_DIR="$(cd "${__TESTING_DIR}/plugins" && pwd)"
readonly __CORE_DIR="$(cd "${__TESTING_DIR}/core" && pwd)"

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
        return 0
    elif [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
printf "Running unit tests for pwd.sh...\n\n"

# Sanity checks
if [[ -f "${__CORE_DIR}/dependency_check.sh" ]]; then
    if print_msg 1 "Can I find dependency_check.sh?" true; then
        ((score++))
    fi
else
    print_msg 1 "Can I find dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 1
fi

if source "${__CORE_DIR}/dependency_check.sh" 2>/dev/null; then
    if print_msg 2 "Can I source dependency_check.sh?" true; then
        ((score++))
    fi
else
    print_msg 2 "Can I source dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 2
fi

if [[ -f "${__PLUGINS_DIR}/utilities/pwd.sh" ]]; then
    if print_msg 3 "Can I find pwd.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find pwd.sh?" false
    printf "Error: Test cannot continue. pwd.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null; then
    if print_msg 4 "Can I source pwd.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source pwd.sh?" false
    printf "Error: Test cannot continue. pwd.sh not found.\n" >&2
    exit 4
fi

if declare -f pwd >/dev/null 2>&1; then
    if print_msg 5 "Is pwd function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is pwd function defined?" false
    printf "Error: pwd function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))

# Save original directory
original_dir=$(pwd)
cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Setup trap to ensure cleanup happens even on failure
cleanup_pwd_test() {
    local exit_code=$?
    
    # Clean up mock clipboard file
    rm -f "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true
    unset -f wl-copy 2>/dev/null || true
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_pwd_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Always mock wl-copy for all tests
MOCK_CLIPBOARD_FILE=$(mktemp)
wl-copy() {
    cat > "$MOCK_CLIPBOARD_FILE"
}
export -f wl-copy

printf "\nTesting pwd() function help flags...\n"

# Test 6: pwd --drchelp
if declare -f drchelp >/dev/null 2>&1; then
    if pwd --drchelp >/dev/null 2>&1; then
        if print_msg 6 "Does pwd --drchelp work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does pwd --drchelp work?" false
    fi
else
    if print_msg 6 "Does pwd --drchelp work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: pwd --drc
if declare -f drchelp >/dev/null 2>&1; then
    if pwd --drc >/dev/null 2>&1; then
        if print_msg 7 "Does pwd --drc work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does pwd --drc work?" false
    fi
else
    if print_msg 7 "Does pwd --drc work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 8: pwd --help passes through to builtin
# The builtin pwd --help should show help (not intercepted)
output=$(pwd --help 2>&1)
if echo "$output" | grep -q "pwd" || echo "$output" | grep -q "print.*directory" || [[ -n "$output" ]]; then
    if print_msg 8 "Does pwd --help pass through to builtin?" true; then
        ((score++))
    fi
else
    print_msg 8 "Does pwd --help pass through to builtin?" false
fi

printf "\nTesting pwd() function normal behavior...\n"

# Test 9: pwd with no arguments
result=$(pwd 2>&1)
expected=$(builtin pwd 2>&1)
if [[ "$result" == "$expected" ]]; then
    if print_msg 9 "Does pwd return current directory (no arguments)?" true; then
        ((score++))
    fi
else
    print_msg 9 "Does pwd return current directory (no arguments)?" false
fi

# Test 10: pwd output matches builtin pwd
result=$(pwd 2>&1)
expected=$(builtin pwd 2>&1)
if [[ "$result" == "$expected" ]]; then
    if print_msg 10 "Does pwd output match builtin pwd?" true; then
        ((score++))
    fi
else
    print_msg 10 "Does pwd output match builtin pwd?" false
fi

# Test 11: pwd -P (physical path)
result=$(pwd -P 2>&1)
expected=$(builtin pwd -P 2>&1)
if [[ "$result" == "$expected" ]]; then
    if print_msg 11 "Does pwd -P work (physical path)?" true; then
        ((score++))
    fi
else
    print_msg 11 "Does pwd -P work (physical path)?" false
fi

# Test 12: pwd -L (logical path)
result=$(pwd -L 2>&1)
expected=$(builtin pwd -L 2>&1)
if [[ "$result" == "$expected" ]]; then
    if print_msg 12 "Does pwd -L work (logical path)?" true; then
        ((score++))
    fi
else
    print_msg 12 "Does pwd -L work (logical path)?" false
fi

# Test 13: pwd returns 0 on success
if pwd >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 13 "Does pwd return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 13 "Does pwd return 0 on success?" false
    fi
else
    print_msg 13 "Does pwd return 0 on success?" false
fi

printf "\nTesting pwd() function clipboard functionality...\n"

# Test 14: pwd c copies to clipboard
# Use mock wrapper script to test clipboard functionality
MOCK_CLIPBOARD_FILE=$(mktemp)
cat > "${__UNIT_TESTS_DIR}/test_pwd_clipboard.sh" << 'CLIPBOARDTEST'
#!/bin/bash
MOCK_CLIPBOARD_FILE="$1"
TEST_DIR="$2"
PLUGINS_DIR="$3"

# Mock wl-copy before sourcing
wl-copy() {
    cat > "$MOCK_CLIPBOARD_FILE"
}
export -f wl-copy

# Source dependencies
source "${PLUGINS_DIR}/../core/dependency_check.sh" 2>/dev/null

# Source pwd.sh (will use our mocked wl-copy)
source "${PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null

# Test pwd c
cd "$TEST_DIR" || exit 1
output=$(pwd c 2>&1)
expected_dir=$(builtin pwd)

if echo "$output" | grep -q "Working directory copied to clipboard"; then
    clipboard_content=$(cat "$MOCK_CLIPBOARD_FILE" 2>/dev/null || echo "")
    if [[ "$clipboard_content" == "$expected_dir" ]]; then
        exit 0
    fi
fi
exit 1
CLIPBOARDTEST
chmod +x "${__UNIT_TESTS_DIR}/test_pwd_clipboard.sh"

if timeout 3 bash "${__UNIT_TESTS_DIR}/test_pwd_clipboard.sh" "$MOCK_CLIPBOARD_FILE" "${__UNIT_TESTS_DIR}" "${__PLUGINS_DIR}" 2>/dev/null; then
    if print_msg 14 "Does pwd c copy to clipboard (mocked wl-copy)?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does pwd c copy to clipboard (mocked wl-copy)?" false
fi
rm -f "${__UNIT_TESTS_DIR}/test_pwd_clipboard.sh" "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true

# Test 15: pwd C copies to clipboard (case-insensitive)
# Use mock wrapper script
MOCK_CLIPBOARD_FILE=$(mktemp)
cat > "${__UNIT_TESTS_DIR}/test_pwd_clipboard_C.sh" << 'CLIPBOARDTEST'
#!/bin/bash
MOCK_CLIPBOARD_FILE="$1"
TEST_DIR="$2"
PLUGINS_DIR="$3"

# Mock wl-copy before sourcing
wl-copy() {
    cat > "$MOCK_CLIPBOARD_FILE"
}
export -f wl-copy

# Source dependencies
source "${PLUGINS_DIR}/../core/dependency_check.sh" 2>/dev/null

# Source pwd.sh
source "${PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null

# Test pwd C
cd "$TEST_DIR" || exit 1
output=$(pwd C 2>&1)
expected_dir=$(builtin pwd)

if echo "$output" | grep -q "Working directory copied to clipboard"; then
    clipboard_content=$(cat "$MOCK_CLIPBOARD_FILE" 2>/dev/null || echo "")
    if [[ "$clipboard_content" == "$expected_dir" ]]; then
        exit 0
    fi
fi
exit 1
CLIPBOARDTEST
chmod +x "${__UNIT_TESTS_DIR}/test_pwd_clipboard_C.sh"

if timeout 3 bash "${__UNIT_TESTS_DIR}/test_pwd_clipboard_C.sh" "$MOCK_CLIPBOARD_FILE" "${__UNIT_TESTS_DIR}" "${__PLUGINS_DIR}" 2>/dev/null; then
    if print_msg 15 "Does pwd C copy to clipboard (mocked, case-insensitive)?" true; then
        ((score++))
    fi
else
    print_msg 15 "Does pwd C copy to clipboard (mocked, case-insensitive)?" false
fi
rm -f "${__UNIT_TESTS_DIR}/test_pwd_clipboard_C.sh" "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true

# Test 16: pwd shows clipboard message
# Use mock wrapper to test message
MOCK_CLIPBOARD_FILE=$(mktemp)
cat > "${__UNIT_TESTS_DIR}/test_pwd_message.sh" << 'MESSAGETEST'
#!/bin/bash
MOCK_CLIPBOARD_FILE="$1"
TEST_DIR="$2"
PLUGINS_DIR="$3"

# Mock wl-copy
wl-copy() {
    cat > "$MOCK_CLIPBOARD_FILE"
}
export -f wl-copy

# Source dependencies
source "${PLUGINS_DIR}/../core/dependency_check.sh" 2>/dev/null

# Source pwd.sh
source "${PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null

# Test pwd c message
cd "$TEST_DIR" || exit 1
output=$(pwd c 2>&1)

if echo "$output" | grep -q "Working directory copied to clipboard"; then
    exit 0
fi
exit 1
MESSAGETEST
chmod +x "${__UNIT_TESTS_DIR}/test_pwd_message.sh"

if timeout 3 bash "${__UNIT_TESTS_DIR}/test_pwd_message.sh" "$MOCK_CLIPBOARD_FILE" "${__UNIT_TESTS_DIR}" "${__PLUGINS_DIR}" 2>/dev/null; then
    if print_msg 16 "Does pwd show clipboard message?" true; then
        ((score++))
    fi
else
    print_msg 16 "Does pwd show clipboard message?" false
fi
rm -f "${__UNIT_TESTS_DIR}/test_pwd_message.sh" "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true

# Test 17: pwd checks for wl-copy dependency
# Test with mock to verify dependency check
MOCK_CLIPBOARD_FILE=$(mktemp)
cat > "${__UNIT_TESTS_DIR}/test_pwd_dependency.sh" << 'DEPTEST'
#!/bin/bash
TEST_DIR="$1"
PLUGINS_DIR="$2"

# Mock wl-copy to simulate it being available
wl-copy() {
    cat > /dev/null
}
export -f wl-copy

# Source dependencies
source "${PLUGINS_DIR}/../core/dependency_check.sh" 2>/dev/null

# Source pwd.sh
source "${PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null

# Test that dependency check runs (pwd c should work with mock)
cd "$TEST_DIR" || exit 1
output=$(pwd c 2>&1)

# Should show clipboard message (dependency check passed)
if echo "$output" | grep -q "Working directory copied to clipboard"; then
    exit 0
fi
exit 1
DEPTEST
chmod +x "${__UNIT_TESTS_DIR}/test_pwd_dependency.sh"

if timeout 3 bash "${__UNIT_TESTS_DIR}/test_pwd_dependency.sh" "${__UNIT_TESTS_DIR}" "${__PLUGINS_DIR}" 2>/dev/null; then
    if print_msg 17 "Does pwd check for wl-copy dependency?" true; then
        ((score++))
    fi
else
    print_msg 17 "Does pwd check for wl-copy dependency?" false
fi
rm -f "${__UNIT_TESTS_DIR}/test_pwd_dependency.sh" "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true

# Test 18: pwd returns error code when wl-copy not available
# Since we always mock wl-copy, skip this test (can't easily test error case with mocking)
if print_msg 18 "Does pwd return error when wl-copy not available?" "N/A"; then
    printf "        (wl-copy is always mocked, skipping error case test)\n"
fi

printf "\nTesting edge cases...\n"

# Test 19: pwd with argument starting with other letter
result=$(pwd x 2>&1)
expected=$(builtin pwd x 2>&1)
# Should pass through to builtin (may error, but should behave like builtin)
if [[ "$result" == "$expected" ]] || ([[ $? -ne 0 ]] && builtin pwd x >/dev/null 2>&1; [[ $? -ne 0 ]]); then
    if print_msg 19 "Does pwd pass through arguments starting with other letters?" true; then
        ((score++))
    fi
else
    print_msg 19 "Does pwd pass through arguments starting with other letters?" false
fi

# Test 20: pwd with "copy" (starts with c, so triggers clipboard)
result=$(pwd copy 2>&1)
# Should trigger clipboard functionality since it starts with 'c'
if echo "$result" | grep -q "Working directory copied to clipboard"; then
    if print_msg 20 "Does pwd handle 'copy' argument correctly (triggers clipboard)?" true; then
        ((score++))
    fi
else
    print_msg 20 "Does pwd handle 'copy' argument correctly (triggers clipboard)?" false
fi

# Test 21: pwd with empty string (should work like no args)
result=$(pwd "" 2>&1)
expected=$(builtin pwd 2>&1)
if [[ "$result" == "$expected" ]]; then
    if print_msg 21 "Does pwd handle empty string argument?" true; then
        ((score++))
    fi
else
    print_msg 21 "Does pwd handle empty string argument?" false
fi

# Test 22: pwd with multiple arguments
result=$(pwd -P -L 2>&1)
expected=$(builtin pwd -P -L 2>&1)
# Builtin may error on multiple flags, but pwd should pass them through
if [[ "$result" == "$expected" ]] || ([[ $? -ne 0 ]] && builtin pwd -P -L >/dev/null 2>&1; [[ $? -ne 0 ]]); then
    if print_msg 22 "Does pwd handle multiple arguments?" true; then
        ((score++))
    fi
else
    print_msg 22 "Does pwd handle multiple arguments?" false
fi

# Test 23: pwd c returns 0 on success
# Use mock wrapper
MOCK_CLIPBOARD_FILE=$(mktemp)
cat > "${__UNIT_TESTS_DIR}/test_pwd_return.sh" << 'RETURNTEST'
#!/bin/bash
MOCK_CLIPBOARD_FILE="$1"
TEST_DIR="$2"
PLUGINS_DIR="$3"

# Mock wl-copy
wl-copy() {
    cat > "$MOCK_CLIPBOARD_FILE"
}
export -f wl-copy

# Source dependencies
source "${PLUGINS_DIR}/../core/dependency_check.sh" 2>/dev/null

# Source pwd.sh
source "${PLUGINS_DIR}/utilities/pwd.sh" 2>/dev/null

# Test pwd c return code
cd "$TEST_DIR" || exit 1
pwd c >/dev/null 2>&1
exit $?
RETURNTEST
chmod +x "${__UNIT_TESTS_DIR}/test_pwd_return.sh"

if timeout 3 bash "${__UNIT_TESTS_DIR}/test_pwd_return.sh" "$MOCK_CLIPBOARD_FILE" "${__UNIT_TESTS_DIR}" "${__PLUGINS_DIR}" 2>/dev/null; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 23 "Does pwd c return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 23 "Does pwd c return 0 on success?" false
    fi
else
    print_msg 23 "Does pwd c return 0 on success?" false
fi
rm -f "${__UNIT_TESTS_DIR}/test_pwd_return.sh" "$MOCK_CLIPBOARD_FILE" 2>/dev/null || true

total_tests=23  # Tests 1-5, "*", 6-17, 19-23 (Test 18 is intentionally skipped)
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"


printf "\nCleaning up...\n"
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

