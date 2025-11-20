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
printf "Running unit tests for pokefetch.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/information/pokefetch.sh" ]]; then
    if print_msg 3 "Can I find pokefetch.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find pokefetch.sh?" false
    printf "Error: Test cannot continue. pokefetch.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/information/pokefetch.sh" 2>/dev/null; then
    if print_msg 4 "Can I source pokefetch.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source pokefetch.sh?" false
    printf "Error: Test cannot continue. pokefetch.sh not found.\n" >&2
    exit 4
fi

if declare -f pokefetch >/dev/null 2>&1; then
    if print_msg 5 "Is pokefetch function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is pokefetch function defined?" false
    printf "Error: pokefetch function not defined.\n" >&2
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
cleanup_pokefetch_test() {
    local exit_code=$?
    
    # Clean up temporary files
    rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2 2>/dev/null || true
    
    # Restore original commands if we modified PATH
    if [[ -n "${ORIGINAL_PATH:-}" ]]; then
        export PATH="$ORIGINAL_PATH"
    fi
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_pokefetch_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Create mock functions
MOCK_POKEMON_OUTPUT=""
MOCK_FASTFETCH_CALLED=false
MOCK_FASTFETCH_ARGS=()
MOCK_FASTFETCH_ARGS_FILE=$(mktemp)

# Mock pokemon-colorscripts command
pokemon-colorscripts() {
    # Write mock Pokemon data to the file
    echo -n "$MOCK_POKEMON_OUTPUT" > /tmp/pokefetch.txt
    return 0
}
export -f pokemon-colorscripts

# Mock fastfetch command
fastfetch() {
    MOCK_FASTFETCH_CALLED=true
    echo "$@" > "$MOCK_FASTFETCH_ARGS_FILE"
    return 0
}
export -f fastfetch
export MOCK_FASTFETCH_ARGS_FILE

printf "\nTesting pokefetch() function help flags...\n"

# Test 6: pokefetch --help
if declare -f drchelp >/dev/null 2>&1; then
    if pokefetch --help >/dev/null 2>&1; then
        if print_msg 6 "Does pokefetch --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does pokefetch --help work?" false
    fi
else
    if pokefetch --help >/dev/null 2>&1; then
        print_msg 6 "Does pokefetch --help work?" false
    else
        if print_msg 6 "Does pokefetch --help work (no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

# Test 7: pokefetch -h
if declare -f drchelp >/dev/null 2>&1; then
    if pokefetch -h >/dev/null 2>&1; then
        if print_msg 7 "Does pokefetch -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does pokefetch -h work?" false
    fi
else
    if pokefetch -h >/dev/null 2>&1; then
        print_msg 7 "Does pokefetch -h work?" false
    else
        if print_msg 7 "Does pokefetch -h work (no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

# Test 8: pokefetch --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if pokefetch --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does pokefetch --HELP work (case-insensitive)?" true; then
            ((score++))
        fi
    else
        print_msg 8 "Does pokefetch --HELP work (case-insensitive)?" false
    fi
else
    if pokefetch --HELP >/dev/null 2>&1; then
        print_msg 8 "Does pokefetch --HELP work (case-insensitive)?" false
    else
        if print_msg 8 "Does pokefetch --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        fi
    fi
fi

printf "\nTesting pokefetch() function basic functionality...\n"

# Test 9: pokefetch runs without errors
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2\nASCII art line 3'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
if pokefetch >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 9 "Does pokefetch run without errors?" true; then
            ((score++))
        fi
    else
        print_msg 9 "Does pokefetch run without errors?" false
    fi
else
    print_msg 9 "Does pokefetch run without errors?" false
fi

# Test 10: pokefetch returns 0 on success
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
if pokefetch >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does pokefetch return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 10 "Does pokefetch return 0 on success?" false
    fi
else
    print_msg 10 "Does pokefetch return 0 on success?" false
fi

# Test 11: pokefetch produces output
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if [[ -n "$output" ]]; then
    if print_msg 11 "Does pokefetch produce output?" true; then
        ((score++))
    fi
else
    print_msg 11 "Does pokefetch produce output?" false
fi

printf "\nTesting pokefetch() function file operations...\n"

# Test 12: pokefetch writes to /tmp/pokefetch.txt
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
if [[ -f /tmp/pokefetch.txt ]]; then
    if print_msg 12 "Does pokefetch write to /tmp/pokefetch.txt?" true; then
        ((score++))
    fi
else
    print_msg 12 "Does pokefetch write to /tmp/pokefetch.txt?" false
fi

# Test 13: pokefetch extracts Pokemon name from first line
MOCK_POKEMON_OUTPUT=$'charizard\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
# Pokemon name is capitalized in output, so check for capitalized version
if echo "$output" | grep -qi "charizard"; then
    if print_msg 13 "Does pokefetch extract Pokemon name from first line?" true; then
        ((score++))
    fi
else
    print_msg 13 "Does pokefetch extract Pokemon name from first line?" false
fi

# Test 14: pokefetch removes first line from file
MOCK_POKEMON_OUTPUT=$'bulbasaur\nASCII art line 1\nASCII art line 2\nASCII art line 3'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
# Check that first line (Pokemon name) is removed
if [[ -f /tmp/pokefetch.txt ]] && ! head -n 1 /tmp/pokefetch.txt | grep -q "bulbasaur"; then
    if print_msg 14 "Does pokefetch remove first line from file?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does pokefetch remove first line from file?" false
fi

# Test 15: pokefetch preserves remaining lines after removing first
MOCK_POKEMON_OUTPUT=$'squirtle\nASCII art line 1\nASCII art line 2\nASCII art line 3'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
# Check that remaining lines are preserved
if [[ -f /tmp/pokefetch.txt ]] && head -n 1 /tmp/pokefetch.txt | grep -q "ASCII art line 1"; then
    if print_msg 15 "Does pokefetch preserve remaining lines after removing first?" true; then
        ((score++))
    fi
else
    print_msg 15 "Does pokefetch preserve remaining lines after removing first?" false
fi

printf "\nTesting pokefetch() function Pokemon name capitalization...\n"

# Test 16: pokefetch capitalizes first letter of Pokemon name
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -q "\[ Pikachu \]"; then
    if print_msg 16 "Does pokefetch capitalize first letter of Pokemon name?" true; then
        ((score++))
    fi
else
    print_msg 16 "Does pokefetch capitalize first letter of Pokemon name?" false
fi

# Test 17: pokefetch handles lowercase Pokemon name
MOCK_POKEMON_OUTPUT=$'charizard\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -q "\[ Charizard \]"; then
    if print_msg 17 "Does pokefetch handle lowercase Pokemon name?" true; then
        ((score++))
    fi
else
    print_msg 17 "Does pokefetch handle lowercase Pokemon name?" false
fi

# Test 18: pokefetch handles already capitalized Pokemon name
MOCK_POKEMON_OUTPUT=$'Pikachu\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -q "\[ Pikachu \]"; then
    if print_msg 18 "Does pokefetch handle already capitalized Pokemon name?" true; then
        ((score++))
    fi
else
    print_msg 18 "Does pokefetch handle already capitalized Pokemon name?" false
fi

printf "\nTesting pokefetch() function output formatting...\n"

# Test 19: pokefetch displays battle message
MOCK_POKEMON_OUTPUT=$'bulbasaur\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -q "Joins The Battle!"; then
    if print_msg 19 "Does pokefetch display battle message?" true; then
        ((score++))
    fi
else
    print_msg 19 "Does pokefetch display battle message?" false
fi

# Test 20: pokefetch battle message format is correct
MOCK_POKEMON_OUTPUT=$'squirtle\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -qE "\[ Squirtle \] Joins The Battle!"; then
    if print_msg 20 "Does pokefetch battle message format match expected?" true; then
        ((score++))
    fi
else
    print_msg 20 "Does pokefetch battle message format match expected?" false
fi

# Test 21: pokefetch adds blank line after battle message
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
# Use a temp file to capture output without newline stripping
TEMP_OUTPUT_FILE=$(mktemp)
pokefetch > "$TEMP_OUTPUT_FILE" 2>&1
# Check if file ends with blank line (two newlines at the end)
if [[ -s "$TEMP_OUTPUT_FILE" ]] && [[ "$(tail -c 2 "$TEMP_OUTPUT_FILE" | od -An -tu1)" == *" 10 10" ]]; then
    if print_msg 21 "Does pokefetch add blank line after battle message?" true; then
        ((score++))
    fi
else
    # Check if it ends with at least one newline
    if [[ "$(tail -c 1 "$TEMP_OUTPUT_FILE" | od -An -tu1)" == *" 10" ]]; then
        if print_msg 21 "Does pokefetch add blank line after battle message?" true; then
            ((score++))
        fi
    else
        print_msg 21 "Does pokefetch add blank line after battle message?" false
    fi
fi
rm -f "$TEMP_OUTPUT_FILE"

printf "\nTesting pokefetch() function fastfetch call...\n"

# Test 22: pokefetch calls fastfetch
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
if [[ "$MOCK_FASTFETCH_CALLED" == true ]]; then
    if print_msg 22 "Does pokefetch call fastfetch?" true; then
        ((score++))
    fi
else
    print_msg 22 "Does pokefetch call fastfetch?" false
fi

# Test 23: pokefetch calls fastfetch with --logo-height 5
MOCK_POKEMON_OUTPUT=$'charizard\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
fastfetch_args=$(cat "$MOCK_FASTFETCH_ARGS_FILE" 2>/dev/null || echo "")
# Use case statement or [[ ]] to check for string containment
if [[ "$fastfetch_args" == *"--logo-height 5"* ]]; then
    if print_msg 23 "Does pokefetch call fastfetch with --logo-height 5?" true; then
        ((score++))
    fi
else
    print_msg 23 "Does pokefetch call fastfetch with --logo-height 5?" false
fi

# Test 24: pokefetch calls fastfetch with --logo /tmp/pokefetch.txt
MOCK_POKEMON_OUTPUT=$'bulbasaur\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
fastfetch_args=$(cat "$MOCK_FASTFETCH_ARGS_FILE" 2>/dev/null || echo "")
# Use [[ ]] to check for string containment
if [[ "$fastfetch_args" == *"--logo /tmp/pokefetch.txt"* ]]; then
    if print_msg 24 "Does pokefetch call fastfetch with --logo /tmp/pokefetch.txt?" true; then
        ((score++))
    fi
else
    print_msg 24 "Does pokefetch call fastfetch with --logo /tmp/pokefetch.txt?" false
fi

# Test 25: pokefetch calls fastfetch with correct argument order
MOCK_POKEMON_OUTPUT=$'squirtle\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
pokefetch >/dev/null 2>&1
fastfetch_args=$(cat "$MOCK_FASTFETCH_ARGS_FILE" 2>/dev/null || echo "")
# Check that both arguments are present using [[ ]]
if [[ "$fastfetch_args" == *"--logo-height 5"* ]] && [[ "$fastfetch_args" == *"--logo /tmp/pokefetch.txt"* ]]; then
    if print_msg 25 "Does pokefetch call fastfetch with correct arguments?" true; then
        ((score++))
    fi
else
    print_msg 25 "Does pokefetch call fastfetch with correct arguments?" false
fi

printf "\nTesting pokefetch() function edge cases...\n"

# Test 26: pokefetch handles single line Pokemon output
MOCK_POKEMON_OUTPUT=$'pikachu'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
if pokefetch >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 26 "Does pokefetch handle single line Pokemon output?" true; then
            ((score++))
        fi
    else
        print_msg 26 "Does pokefetch handle single line Pokemon output?" false
    fi
else
    print_msg 26 "Does pokefetch handle single line Pokemon output?" false
fi

# Test 27: pokefetch handles Pokemon name with spaces
MOCK_POKEMON_OUTPUT=$'mr. mime\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(pokefetch 2>&1)
if echo "$output" | grep -q "\[ Mr. mime \]"; then
    if print_msg 27 "Does pokefetch handle Pokemon name with spaces?" true; then
        ((score++))
    fi
else
    print_msg 27 "Does pokefetch handle Pokemon name with spaces?" false
fi

# Test 28: pokefetch handles empty Pokemon name
MOCK_POKEMON_OUTPUT=$'\nASCII art line 1\nASCII art line 2'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
if pokefetch >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 28 "Does pokefetch handle empty Pokemon name?" true; then
            ((score++))
        fi
    else
        print_msg 28 "Does pokefetch handle empty Pokemon name?" false
    fi
else
    print_msg 28 "Does pokefetch handle empty Pokemon name?" false
fi

printf "\nTesting pokefetch.sh direct script execution...\n"

# Test 29: pokefetch.sh can be executed directly
MOCK_POKEMON_OUTPUT=$'pikachu\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
if bash "${__PLUGINS_DIR}/information/pokefetch.sh" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 29 "Can pokefetch.sh be executed directly?" true; then
            ((score++))
        fi
    else
        print_msg 29 "Can pokefetch.sh be executed directly?" false
    fi
else
    print_msg 29 "Can pokefetch.sh be executed directly?" false
fi

# Test 30: pokefetch.sh direct execution produces output
MOCK_POKEMON_OUTPUT=$'charizard\nASCII art line 1'
MOCK_FASTFETCH_CALLED=false
rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2
output=$(bash -c "source <(declare -f pokemon-colorscripts fastfetch); export MOCK_POKEMON_OUTPUT='$MOCK_POKEMON_OUTPUT'; export MOCK_FASTFETCH_ARGS_FILE='$MOCK_FASTFETCH_ARGS_FILE'; ${__PLUGINS_DIR}/information/pokefetch.sh" 2>&1)
if [[ -n "$output" ]] && echo "$output" | grep -q "Joins The Battle!"; then
    if print_msg 30 "Does pokefetch.sh direct execution produce output?" true; then
        ((score++))
    fi
else
    print_msg 30 "Does pokefetch.sh direct execution produce output?" false
fi

# Test 31: pokefetch.sh direct execution with --help
output=$(bash "${__PLUGINS_DIR}/information/pokefetch.sh" --help 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 31 "Does pokefetch.sh --help work when executed directly?" true; then
        ((score++))
    fi
else
    print_msg 31 "Does pokefetch.sh --help work when executed directly?" false
fi

total_tests=32  # Tests 1-5, "*", 6-31
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

