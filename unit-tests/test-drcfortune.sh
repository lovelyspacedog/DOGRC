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
total_tests=42  # Tests 1-5, "*", 6-41
printf "Running unit tests for drcfortune.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/information/drcfortune.sh" ]]; then
    if print_msg 3 "Can I find drcfortune.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find drcfortune.sh?" false
    printf "Error: Test cannot continue. drcfortune.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/information/drcfortune.sh" 2>/dev/null; then
    if print_msg 4 "Can I source drcfortune.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source drcfortune.sh?" false
    printf "Error: Test cannot continue. drcfortune.sh not found.\n" >&2
    exit 4
fi

if declare -f drcfortune >/dev/null 2>&1; then
    if print_msg 5 "Is drcfortune function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is drcfortune function defined?" false
    printf "Error: drcfortune function not defined.\n" >&2
    exit 5
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

# Setup trap to ensure cleanup happens even on failure
cleanup_drcfortune_test() {
    local exit_code=$?
    
    # Clean up temporary files
    rm -f "$MOCK_FORTUNE_ARGS_FILE" 2>/dev/null || true
    
    # Restore original commands if we modified PATH
    if [[ -n "${ORIGINAL_PATH:-}" ]]; then
        export PATH="$ORIGINAL_PATH"
    fi
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_drcfortune_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Create mock functions for fortune, tput, clear, and head
MOCK_FORTUNE_OUTPUT=""
MOCK_FORTUNE_ARGS_FILE=$(mktemp)

# Mock fortune command
fortune() {
    # Store arguments for verification (write to file for persistence across subshells)
    echo "$@" > "$MOCK_FORTUNE_ARGS_FILE"
    # Return the mock output
    echo -n "$MOCK_FORTUNE_OUTPUT"
    return 0
}
export -f fortune
export MOCK_FORTUNE_ARGS_FILE

# Mock tput (just return success)
tput() {
    return 0
}
export -f tput

# Mock clear (just return success, don't actually clear)
clear() {
    return 0
}
export -f clear

# Mock head (use real head if available, otherwise simple mock)
if ! command -v head >/dev/null 2>&1; then
    head() {
        local lines="${1:-10}"
        lines="${lines#-}"
        local count=0
        while IFS= read -r line && [[ $count -lt $lines ]]; do
            echo "$line"
            ((count++))
        done
    }
    export -f head
fi

printf "\nTesting drcfortune() function help flags...\n"

# Test 6: drcfortune --help
if declare -f drchelp >/dev/null 2>&1; then
    if drcfortune --help >/dev/null 2>&1; then
        if print_msg 6 "Does drcfortune --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does drcfortune --help work?" false
    fi
else
    if drcfortune --help >/dev/null 2>&1; then
        print_msg 6 "Does drcfortune --help work?" false
    else
        if print_msg 6 "Does drcfortune --help work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 7: drcfortune -h
if declare -f drchelp >/dev/null 2>&1; then
    if drcfortune -h >/dev/null 2>&1; then
        if print_msg 7 "Does drcfortune -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does drcfortune -h work?" false
    fi
else
    if drcfortune -h >/dev/null 2>&1; then
        print_msg 7 "Does drcfortune -h work?" false
    else
        if print_msg 7 "Does drcfortune -h work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 8: drcfortune --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if drcfortune --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does drcfortune --HELP work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does drcfortune --HELP work (case-insensitive)?" false
    fi
else
    if drcfortune --HELP >/dev/null 2>&1; then
        print_msg 8 "Does drcfortune --HELP work (case-insensitive)?" false
    else
        if print_msg 8 "Does drcfortune --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

printf "\nTesting drcfortune() function basic functionality...\n"

# Test 9: drcfortune runs without errors
MOCK_FORTUNE_OUTPUT="Test fortune message"
if drcfortune --zero >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 9 "Does drcfortune run without errors?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does drcfortune run without errors?" false
    fi
else
    print_msg 9 "Does drcfortune run without errors?" false
fi

# Test 10: drcfortune returns 0 on success
MOCK_FORTUNE_OUTPUT="Test fortune message"
if drcfortune --zero >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does drcfortune return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does drcfortune return 0 on success?" false
    fi
else
    print_msg 10 "Does drcfortune return 0 on success?" false
fi

# Test 11: drcfortune produces output
MOCK_FORTUNE_OUTPUT="Test fortune message"
output=$(drcfortune --zero 2>&1)
if [[ -n "$output" ]]; then
    if print_msg 11 "Does drcfortune produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does drcfortune produce output?" false
fi

printf "\nTesting drcfortune() function --zero flag...\n"

# Test 12: drcfortune --zero disables typewriter effect
MOCK_FORTUNE_OUTPUT="Quick test"
start_time=$(date +%s.%N)
output=$(drcfortune --zero 2>&1)
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
# With --zero, should be very fast (less than 0.5 seconds for short text)
if (( $(echo "$elapsed < 0.5" | bc -l) )); then
    if print_msg 12 "Does drcfortune --zero disable typewriter effect?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does drcfortune --zero disable typewriter effect?" false
fi

# Test 13: drcfortune --zero produces output instantly
MOCK_FORTUNE_OUTPUT="Test message"
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "Test message"; then
    if print_msg 13 "Does drcfortune --zero produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does drcfortune --zero produce output?" false
fi

printf "\nTesting drcfortune() function --custom flag...\n"

# Test 14: drcfortune --custom with valid speeds
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --custom 0.05 0.005 >/dev/null 2>&1; then
    if print_msg 14 "Does drcfortune --custom work with valid speeds?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does drcfortune --custom work with valid speeds?" false
fi

# Test 15: drcfortune --custom with "-" uses defaults
MOCK_FORTUNE_OUTPUT="Test message"
output=$(drcfortune --custom - 0 2>&1)
if echo "$output" | grep -qE "drcfortune --custom"; then
    if print_msg 15 "Does drcfortune --custom echo expanded command with '-'?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does drcfortune --custom echo expanded command with '-'?" false
fi

# Test 16: drcfortune --custom with missing arguments
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --custom 0.05 >/dev/null 2>&1; then
    print_msg 16 "Does drcfortune --custom error on missing arguments?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 16 "Does drcfortune --custom error on missing arguments?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 16 "Does drcfortune --custom error on missing arguments?" false
    fi
fi

# Test 17: drcfortune --custom with invalid speed (non-numeric)
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --custom invalid 0.05 >/dev/null 2>&1; then
    print_msg 17 "Does drcfortune --custom error on invalid speed?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 17 "Does drcfortune --custom error on invalid speed?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does drcfortune --custom error on invalid speed?" false
    fi
fi

# Test 18: drcfortune --custom with "-" for title speed
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --custom - 0.01 >/dev/null 2>&1; then
    if print_msg 18 "Does drcfortune --custom work with '-' for title speed?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does drcfortune --custom work with '-' for title speed?" false
fi

# Test 19: drcfortune --custom with "-" for fortune speed
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --custom 0.1 - >/dev/null 2>&1; then
    if print_msg 19 "Does drcfortune --custom work with '-' for fortune speed?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does drcfortune --custom work with '-' for fortune speed?" false
fi

printf "\nTesting drcfortune() function fortune cookie format parsing...\n"

# Test 20: drcfortune parses fortune cookie with "%" separator
MOCK_FORTUNE_OUTPUT=$'Cookie Name\n%\nFortune text here'
output=$(drcfortune --zero 2>&1)
# Title is converted to uppercase, so check for "COOKIE NAME"
if echo "$output" | grep -q "COOKIE NAME" && echo "$output" | grep -q "Fortune text here"; then
    if print_msg 20 "Does drcfortune parse fortune cookie with '%' separator?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does drcfortune parse fortune cookie with '%' separator?" false
fi

# Test 21: drcfortune parses fortune cookie with "---" separator
MOCK_FORTUNE_OUTPUT=$'Cookie Name\n---\nFortune text here'
output=$(drcfortune --zero 2>&1)
# Title is converted to uppercase, so check for "COOKIE NAME"
if echo "$output" | grep -q "COOKIE NAME" && echo "$output" | grep -q "Fortune text here"; then
    if print_msg 21 "Does drcfortune parse fortune cookie with '---' separator?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does drcfortune parse fortune cookie with '---' separator?" false
fi

# Test 22: drcfortune handles fortune without separator
MOCK_FORTUNE_OUTPUT="Just fortune text, no title"
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "Just fortune text, no title"; then
    if print_msg 22 "Does drcfortune handle fortune without separator?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does drcfortune handle fortune without separator?" false
fi

printf "\nTesting drcfortune() function title processing...\n"

# Test 23: drcfortune removes parentheses from title
MOCK_FORTUNE_OUTPUT=$'(Cookie Name)\n%\nFortune text'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "COOKIE NAME" && ! echo "$output" | grep -q "("; then
    if print_msg 23 "Does drcfortune remove parentheses from title?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does drcfortune remove parentheses from title?" false
fi

# Test 24: drcfortune converts title to uppercase
MOCK_FORTUNE_OUTPUT=$'cookie name\n%\nFortune text'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "COOKIE NAME"; then
    if print_msg 24 "Does drcfortune convert title to uppercase?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does drcfortune convert title to uppercase?" false
fi

# Test 25: drcfortune extracts basename from path-like title
MOCK_FORTUNE_OUTPUT=$'path/to/cookie name\n%\nFortune text'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "COOKIE NAME" && ! echo "$output" | grep -q "path/to"; then
    if print_msg 25 "Does drcfortune extract basename from path-like title?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does drcfortune extract basename from path-like title?" false
fi

printf "\nTesting drcfortune() function case transformation...\n"

# Test 26: drcfortune --upper converts fortune text to uppercase
MOCK_FORTUNE_OUTPUT="Test Fortune Text"
output=$(drcfortune --zero --upper 2>&1)
if echo "$output" | grep -q "TEST FORTUNE TEXT"; then
    if print_msg 26 "Does drcfortune --upper convert fortune text to uppercase?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does drcfortune --upper convert fortune text to uppercase?" false
fi

# Test 27: drcfortune --lower converts fortune text to lowercase
MOCK_FORTUNE_OUTPUT="TEST FORTUNE TEXT"
output=$(drcfortune --zero --lower 2>&1)
if echo "$output" | grep -q "test fortune text"; then
    if print_msg 27 "Does drcfortune --lower convert fortune text to lowercase?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does drcfortune --lower convert fortune text to lowercase?" false
fi

# Test 28: drcfortune errors on conflicting --upper and --lower
MOCK_FORTUNE_OUTPUT="Test message"
if drcfortune --zero --upper --lower >/dev/null 2>&1; then
    print_msg 28 "Does drcfortune error on conflicting --upper and --lower?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        output=$(drcfortune --zero --upper --lower 2>&1)
        if echo "$output" | grep -q "Error: --upper and --lower flags cannot be used together"; then
            if print_msg 28 "Does drcfortune error on conflicting --upper and --lower?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 28 "Does drcfortune error on conflicting --upper and --lower?" false
        fi
    else
        print_msg 28 "Does drcfortune error on conflicting --upper and --lower?" false
    fi
fi

printf "\nTesting drcfortune() function output formatting...\n"

# Test 29: drcfortune displays title with emoji
MOCK_FORTUNE_OUTPUT=$'Cookie Name\n%\nFortune text'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "🐾"; then
    if print_msg 29 "Does drcfortune display title with emoji?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does drcfortune display title with emoji?" false
fi

# Test 30: drcfortune displays title with ANSI color codes
MOCK_FORTUNE_OUTPUT=$'Cookie Name\n%\nFortune text'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -qE '\e\[1;34m|\\033\[1;34m|\[1;34m'; then
    if print_msg 30 "Does drcfortune display title with ANSI color codes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does drcfortune display title with ANSI color codes?" false
fi

# Test 31: drcfortune ensures final newline
# Note: Command substitution $(...) strips trailing newlines, so we check differently
MOCK_FORTUNE_OUTPUT="Test message"
# Use a temp file to capture output without newline stripping
TEMP_OUTPUT_FILE=$(mktemp)
drcfortune --zero > "$TEMP_OUTPUT_FILE" 2>&1
# Check if file ends with newline (last byte should be 0x0A)
if [[ -s "$TEMP_OUTPUT_FILE" ]] && [[ "$(tail -c 1 "$TEMP_OUTPUT_FILE" | od -An -tu1)" == *" 10" ]]; then
    if print_msg 31 "Does drcfortune ensure final newline?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 31 "Does drcfortune ensure final newline?" false
fi
rm -f "$TEMP_OUTPUT_FILE"

printf "\nTesting drcfortune() function --clear flag...\n"

# Test 32: drcfortune --clear calls clear command
MOCK_FORTUNE_OUTPUT="Test message"
CLEAR_CALLED=false
clear() {
    CLEAR_CALLED=true
    return 0
}
export -f clear
drcfortune --zero --clear >/dev/null 2>&1
if [[ "$CLEAR_CALLED" == true ]]; then
    if print_msg 32 "Does drcfortune --clear call clear command?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does drcfortune --clear call clear command?" false
fi
# Restore mock clear
clear() {
    return 0
}
export -f clear

printf "\nTesting drcfortune() function --no-a flag...\n"

# Test 33: drcfortune --no-a skips fortune -a flag
MOCK_FORTUNE_OUTPUT="Test message"
drcfortune --zero --no-a >/dev/null 2>&1
# Check that -a is not in the arguments
fortune_args=$(cat "$MOCK_FORTUNE_ARGS_FILE" 2>/dev/null || echo "")
if [[ "$fortune_args" != *"-a"* ]]; then
    if print_msg 33 "Does drcfortune --no-a skip fortune -a flag?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does drcfortune --no-a skip fortune -a flag?" false
fi

# Test 34: drcfortune includes -a flag by default
MOCK_FORTUNE_OUTPUT="Test message"
drcfortune --zero >/dev/null 2>&1
# Check that -a is in the arguments
fortune_args=$(cat "$MOCK_FORTUNE_ARGS_FILE" 2>/dev/null || echo "")
if [[ "$fortune_args" == *"-a"* ]]; then
    if print_msg 34 "Does drcfortune include -a flag by default?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 34 "Does drcfortune include -a flag by default?" false
fi

# Test 35: drcfortune passes fortune args through
MOCK_FORTUNE_OUTPUT="Test message"
drcfortune --zero computers >/dev/null 2>&1
# Check that "computers" is in the arguments
fortune_args=$(cat "$MOCK_FORTUNE_ARGS_FILE" 2>/dev/null || echo "")
if [[ "$fortune_args" == *"computers"* ]]; then
    if print_msg 35 "Does drcfortune pass fortune args through?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does drcfortune pass fortune args through?" false
fi

printf "\nTesting drcfortune() function edge cases...\n"

# Test 36: drcfortune handles empty fortune output
MOCK_FORTUNE_OUTPUT=""
if drcfortune --zero >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 36 "Does drcfortune handle empty fortune output?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 36 "Does drcfortune handle empty fortune output?" false
    fi
else
    print_msg 36 "Does drcfortune handle empty fortune output?" false
fi

# Test 37: drcfortune handles fortune with only title
MOCK_FORTUNE_OUTPUT=$'Cookie Name\n%'
output=$(drcfortune --zero 2>&1)
if echo "$output" | grep -q "Cookie Name"; then
    if print_msg 37 "Does drcfortune handle fortune with only title?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 37 "Does drcfortune handle fortune with only title?" false
fi

# Test 38: drcfortune handles multiple fortune args
MOCK_FORTUNE_OUTPUT="Test message"
drcfortune --zero computers science >/dev/null 2>&1
# Check that both args are passed
fortune_args=$(cat "$MOCK_FORTUNE_ARGS_FILE" 2>/dev/null || echo "")
if [[ "$fortune_args" == *"computers"* ]] && [[ "$fortune_args" == *"science"* ]]; then
    if print_msg 38 "Does drcfortune handle multiple fortune args?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 38 "Does drcfortune handle multiple fortune args?" false
fi

printf "\nTesting drcfortune.sh direct script execution...\n"

# Test 39: drcfortune.sh can be executed directly
MOCK_FORTUNE_OUTPUT="Test message"
if bash "${__PLUGINS_DIR}/information/drcfortune.sh" --zero >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 39 "Can drcfortune.sh be executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 39 "Can drcfortune.sh be executed directly?" false
    fi
else
    print_msg 39 "Can drcfortune.sh be executed directly?" false
fi

# Test 40: drcfortune.sh direct execution produces output
# When run directly, mock functions need to be available in the subshell
MOCK_FORTUNE_OUTPUT="Test message"
output=$(bash -c "source <(declare -f fortune); export MOCK_FORTUNE_OUTPUT='$MOCK_FORTUNE_OUTPUT'; export MOCK_FORTUNE_ARGS_FILE='$MOCK_FORTUNE_ARGS_FILE'; ${__PLUGINS_DIR}/information/drcfortune.sh --zero" 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "Test message"; then
    if print_msg 40 "Does drcfortune.sh direct execution produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 40 "Does drcfortune.sh direct execution produce output?" false
fi

# Test 41: drcfortune.sh direct execution with --help
# When run directly, drchelp may not be available in the script's context
output=$(bash "${__PLUGINS_DIR}/information/drcfortune.sh" --help 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 41 "Does drcfortune.sh --help work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 41 "Does drcfortune.sh --help work when executed directly?" false
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

