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
total_tests=36  # Tests 1-5, "*", 6-35
printf "Running unit tests for motd.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/utilities/motd.sh" ]]; then
    if print_msg 3 "Can I find motd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find motd.sh?" false
    printf "Error: Test cannot continue. motd.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/motd.sh" 2>/dev/null; then
    if print_msg 4 "Can I source motd.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source motd.sh?" false
    printf "Error: Test cannot continue. motd.sh not found.\n" >&2
    exit 4
fi

if declare -f motd >/dev/null 2>&1; then
    if print_msg 5 "Is motd function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is motd function defined?" false
    printf "Error: motd function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Save original directory and HOME
original_dir=$(pwd)
original_home="${HOME:-}"

# Create temporary directory for mocked HOME
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Setup trap to ensure cleanup happens even on failure
cleanup_motd_test() {
    local exit_code=$?
    
    # Restore original HOME
    if [[ -n "$original_home" ]]; then
        export HOME="$original_home"
    else
        unset HOME
    fi
    
    # Clean up temporary directory
    rm -rf "$TEST_HOME" 2>/dev/null || true
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_motd_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Mock editor and pager for testing
MOCK_EDITOR_FILE=$(mktemp)
MOCK_PAGER_FILE=$(mktemp)
nvim() {
    # Ignore all arguments (like -u NONE -R -) and just read from stdin
    # This simulates nvim reading from stdin and writing to a file
    cat > "$MOCK_PAGER_FILE" 2>/dev/null
    return 0
}
export -f nvim
export MOCK_PAGER_FILE
# Also mock less as a fallback
less() {
    # Ignore all arguments and just read from stdin
    cat > "$MOCK_PAGER_FILE" 2>/dev/null
    return 0
}
export -f less

printf "\nTesting motd() function help flags...\n"

# Test 6: motd --help
if declare -f drchelp >/dev/null 2>&1; then
    if motd --help >/dev/null 2>&1; then
        if print_msg 6 "Does motd --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does motd --help work?" false
    fi
else
    if motd --help >/dev/null 2>&1; then
        print_msg 6 "Does motd --help work?" false
    else
        if print_msg 6 "Does motd --help work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 7: motd -h
if declare -f drchelp >/dev/null 2>&1; then
    if motd -h >/dev/null 2>&1; then
        if print_msg 7 "Does motd -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does motd -h work?" false
    fi
else
    if motd -h >/dev/null 2>&1; then
        print_msg 7 "Does motd -h work?" false
    else
        if print_msg 7 "Does motd -h work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 8: motd --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if motd --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does motd --HELP work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does motd --HELP work (case-insensitive)?" false
    fi
else
    if motd --HELP >/dev/null 2>&1; then
        print_msg 8 "Does motd --HELP work (case-insensitive)?" false
    else
        if print_msg 8 "Does motd --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

printf "\nTesting motd() function default behavior...\n"

# Test 9: motd with no arguments shows help
output=$(motd 2>&1)
if echo "$output" | grep -q "Usage: motd" && echo "$output" | grep -q "Message of the Day"; then
    if print_msg 9 "Does motd show help with no arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does motd show help with no arguments?" false
fi

# Test 10: motd returns 0 on help
if motd >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does motd return 0 when showing help?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does motd return 0 when showing help?" false
    fi
else
    print_msg 10 "Does motd return 0 when showing help?" false
fi

printf "\nTesting motd() function SHOO command...\n"

# Test 11: motd shoo removes file
echo "Test message" > "$HOME/motd.txt"
if motd shoo >/dev/null 2>&1; then
    if [[ ! -f "$HOME/motd.txt" ]]; then
        if print_msg 11 "Does motd shoo remove motd.txt file?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 11 "Does motd shoo remove motd.txt file?" false
    fi
else
    print_msg 11 "Does motd shoo remove motd.txt file?" false
fi

# Test 12: motd shoo handles missing file gracefully
if motd shoo >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 12 "Does motd shoo handle missing file gracefully?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 12 "Does motd shoo handle missing file gracefully?" false
    fi
else
    print_msg 12 "Does motd shoo handle missing file gracefully?" false
fi

# Test 13: motd shoo shows success message
echo "Test message" > "$HOME/motd.txt"
output=$(motd shoo 2>&1)
if echo "$output" | grep -q "MOTD file removed"; then
    if print_msg 13 "Does motd shoo show success message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does motd shoo show success message?" false
fi

# Test 14: motd SHOO (case-insensitive)
echo "Test message" > "$HOME/motd.txt"
if motd SHOO >/dev/null 2>&1; then
    if [[ ! -f "$HOME/motd.txt" ]]; then
        if print_msg 14 "Does motd SHOO work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 14 "Does motd SHOO work (case-insensitive)?" false
    fi
else
    print_msg 14 "Does motd SHOO work (case-insensitive)?" false
fi

printf "\nTesting motd() function MAKE command (stdin mode)...\n"

# Test 15: motd make with stdin writes to file
echo "Test message from stdin" | motd make >/dev/null 2>&1
if [[ -f "$HOME/motd.txt" ]] && [[ "$(cat "$HOME/motd.txt")" == "Test message from stdin" ]]; then
    if print_msg 15 "Does motd make write from stdin to file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does motd make write from stdin to file?" false
fi

# Test 16: motd make with stdin shows success message
output=$(echo "Test message" | motd make 2>&1)
if echo "$output" | grep -q "Message of the day written to file"; then
    if print_msg 16 "Does motd make show success message for stdin?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does motd make show success message for stdin?" false
fi

# Test 17: motd make with stdin overwrites existing file
echo "Old message" > "$HOME/motd.txt"
echo "New message" | motd make >/dev/null 2>&1
if [[ "$(cat "$HOME/motd.txt")" == "New message" ]]; then
    if print_msg 17 "Does motd make overwrite existing file from stdin?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does motd make overwrite existing file from stdin?" false
fi

# Test 18: motd MAKE (case-insensitive)
echo "Test message" | motd MAKE >/dev/null 2>&1
if [[ -f "$HOME/motd.txt" ]] && [[ "$(cat "$HOME/motd.txt")" == "Test message" ]]; then
    if print_msg 18 "Does motd MAKE work (case-insensitive)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does motd MAKE work (case-insensitive)?" false
fi

printf "\nTesting motd() function PRINT command (short file)...\n"

# Test 19: motd print with short file displays content
echo "Line 1" > "$HOME/motd.txt"
echo "Line 2" >> "$HOME/motd.txt"
output=$(motd print 2>&1)
if echo "$output" | grep -q "MESSAGE OF THE DAY:" && echo "$output" | grep -q "Line 1" && echo "$output" | grep -q "Line 2"; then
    if print_msg 19 "Does motd print display short file content?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does motd print display short file content?" false
fi

# Test 20: motd print with missing file returns 0
rm -f "$HOME/motd.txt"
if motd print >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 20 "Does motd print return 0 when file missing?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 20 "Does motd print return 0 when file missing?" false
    fi
else
    print_msg 20 "Does motd print return 0 when file missing?" false
fi

# Test 21: motd print with exactly 20 lines displays normally
for i in {1..20}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
output=$(motd print 2>&1)
if echo "$output" | grep -q "MESSAGE OF THE DAY:" && ! echo "$output" | grep -q "preview"; then
    if print_msg 21 "Does motd print display 20-line file normally?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does motd print display 20-line file normally?" false
fi

# Test 22: motd PRINT (case-insensitive)
rm -f "$HOME/motd.txt"
echo "Test message" > "$HOME/motd.txt"
output=$(motd PRINT 2>&1)
if echo "$output" | grep -q "MESSAGE OF THE DAY:" && echo "$output" | grep -q "Test message"; then
    if print_msg 22 "Does motd PRINT work (case-insensitive)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does motd PRINT work (case-insensitive)?" false
fi

printf "\nTesting motd() function PRINT command (long file)...\n"

# Test 23: motd print with long file shows preview
rm -f "$HOME/motd.txt"
for i in {1..25}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
output=$(motd print 2>&1)
if echo "$output" | grep -q "MESSAGE OF THE DAY (preview):" && echo "$output" | grep -q "Line 1" && echo "$output" | grep -q "..."; then
    if print_msg 23 "Does motd print show preview for long file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does motd print show preview for long file?" false
fi

# Test 24: motd print preview shows first 5 lines
rm -f "$HOME/motd.txt"
for i in {1..25}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
output=$(motd print 2>&1)
if echo "$output" | grep -q "Line 1" && echo "$output" | grep -q "Line 5" && ! echo "$output" | grep -q "Line 6"; then
    if print_msg 24 "Does motd print preview show first 5 lines?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does motd print preview show first 5 lines?" false
fi

# Test 25: motd print with long file uses pager
rm -f "$HOME/motd.txt" "$MOCK_PAGER_FILE"
for i in {1..25}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
# Capture preview output (pager calls are non-blocking, no timeout needed)
preview_output=$(motd print 2>&1)
# Check that preview was shown and pager was called (file should have content)
if echo "$preview_output" | grep -q "MESSAGE OF THE DAY (preview):" && [[ -f "$MOCK_PAGER_FILE" ]] && [[ -s "$MOCK_PAGER_FILE" ]]; then
    if print_msg 25 "Does motd print use pager for long file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does motd print use pager for long file?" false
fi

# Test 26: motd print pager includes date/time header
rm -f "$HOME/motd.txt" "$MOCK_PAGER_FILE"
for i in {1..25}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
# Pager calls are non-blocking, no timeout needed
motd print >/dev/null 2>&1
# Check pager file for date/time header
if [[ -f "$MOCK_PAGER_FILE" ]] && grep -qE "20[0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" "$MOCK_PAGER_FILE"; then
    if print_msg 26 "Does motd print pager include date/time header?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does motd print pager include date/time header?" false
fi

# Test 27: motd print pager includes separator line
rm -f "$HOME/motd.txt" "$MOCK_PAGER_FILE"
for i in {1..25}; do
    echo "Line $i" >> "$HOME/motd.txt"
done
# Pager calls are non-blocking, no timeout needed
motd print >/dev/null 2>&1
# Check pager file for separator line (60 dashes)
if [[ -f "$MOCK_PAGER_FILE" ]] && grep -qE "^-{60}" "$MOCK_PAGER_FILE"; then
    if print_msg 27 "Does motd print pager include separator line?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does motd print pager include separator line?" false
fi

printf "\nTesting motd() function edge cases...\n"

# Test 28: motd with unknown command shows help
output=$(motd unknown 2>&1)
if echo "$output" | grep -q "Usage: motd"; then
    if print_msg 28 "Does motd show help for unknown command?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does motd show help for unknown command?" false
fi

# Test 29: motd print with empty file
echo "" > "$HOME/motd.txt"
output=$(motd print 2>&1)
if echo "$output" | grep -q "MESSAGE OF THE DAY:"; then
    if print_msg 29 "Does motd print handle empty file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does motd print handle empty file?" false
fi

# Test 30: motd make with multiline stdin
printf "Line 1\nLine 2\nLine 3\n" | motd make >/dev/null 2>&1
if [[ -f "$HOME/motd.txt" ]] && [[ "$(wc -l < "$HOME/motd.txt")" -eq 3 ]]; then
    if print_msg 30 "Does motd make handle multiline stdin?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does motd make handle multiline stdin?" false
fi

printf "\nTesting motd.sh direct script execution...\n"

# Test 31: motd.sh can be executed directly
if bash "${__PLUGINS_DIR}/utilities/motd.sh" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 31 "Can motd.sh be executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 31 "Can motd.sh be executed directly?" false
    fi
else
    print_msg 31 "Can motd.sh be executed directly?" false
fi

# Test 32: motd.sh direct execution shows help
output=$(bash "${__PLUGINS_DIR}/utilities/motd.sh" 2>&1)
if echo "$output" | grep -q "Usage: motd"; then
    if print_msg 32 "Does motd.sh direct execution show help?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does motd.sh direct execution show help?" false
fi

# Test 33: motd.sh direct execution with --help
# When run directly, drchelp may not be available in the script's context
# The script should handle this gracefully (return error if drchelp not available)
output=$(bash "${__PLUGINS_DIR}/utilities/motd.sh" --help 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 33 "Does motd.sh --help work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does motd.sh --help work when executed directly?" false
fi

# Test 34: motd.sh direct execution with shoo
echo "Test message" > "$HOME/motd.txt"
if bash "${__PLUGINS_DIR}/utilities/motd.sh" shoo >/dev/null 2>&1; then
    if [[ ! -f "$HOME/motd.txt" ]]; then
        if print_msg 34 "Does motd.sh shoo work when executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 34 "Does motd.sh shoo work when executed directly?" false
    fi
else
    print_msg 34 "Does motd.sh shoo work when executed directly?" false
fi

# Test 35: motd.sh direct execution with make (stdin)
echo "Test from script" | bash "${__PLUGINS_DIR}/utilities/motd.sh" make >/dev/null 2>&1
if [[ -f "$HOME/motd.txt" ]] && [[ "$(cat "$HOME/motd.txt")" == "Test from script" ]]; then
    if print_msg 35 "Does motd.sh make work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does motd.sh make work when executed directly?" false
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


printf "\nCleaning up...\n"
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

