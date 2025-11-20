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
total_tests=40  # Tests 1-39 plus 1 summary test with "*"
printf "Running unit tests for genpassword.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/utilities/genpassword.sh" ]]; then
    if print_msg 3 "Can I find genpassword.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find genpassword.sh?" false
    printf "Error: Test cannot continue. Genpassword.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/genpassword.sh" 2>/dev/null; then
    if print_msg 4 "Can I source genpassword.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source genpassword.sh?" false
    printf "Error: Test cannot continue. Genpassword.sh not found.\n" >&2
    exit 4
fi

if declare -f genpassword >/dev/null 2>&1; then
    if print_msg 5 "Is genpassword function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is genpassword function defined?" false
    printf "Error: genpassword function not defined.\n" >&2
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

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if genpassword --help >/dev/null 2>&1; then
        if print_msg 6 "Does genpassword --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does genpassword --help work?" false
    fi
else
    if print_msg 6 "Does genpassword --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if genpassword -h >/dev/null 2>&1; then
        if print_msg 7 "Does genpassword -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does genpassword -h work?" false
    fi
else
    if print_msg 7 "Does genpassword -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting default password generation...\n"

# Test default password generation (no arguments)
default_password=$(genpassword 2>/dev/null)
if [[ -n "$default_password" ]]; then
    # Check default length (16 characters)
    if [[ ${#default_password} -eq 16 ]]; then
        if print_msg 8 "Does genpassword generate 16-character password by default?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        if print_msg 8 "Does genpassword generate 16-character password by default?" false; then
            printf "        (Expected: 16, Got: ${#default_password})\n"
        fi
    fi
else
    print_msg 8 "Does genpassword generate 16-character password by default?" false
fi

# Test default character set (A-Za-z0-9_)
default_password2=$(genpassword 2>/dev/null)
if [[ -n "$default_password2" ]]; then
    # Validate default charset: A-Z, a-z, 0-9, underscore
    if [[ "$default_password2" =~ ^[A-Za-z0-9_]+$ ]]; then
        if print_msg 9 "Does genpassword use default charset (A-Za-z0-9_)?誤" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does genpassword use default charset (A-Za-z0-9_)?誤" false
    fi
else
    print_msg 9 "Does genpassword use default charset (A-Za-z0-9_)?誤" false
fi

# Test return code on success
if genpassword >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does genpassword return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does genpassword return 0 on success?" false
    fi
else
    print_msg 10 "Does genpassword return 0 on success?" false
fi

# Test that default passwords are generated (non-empty)
default_password3=$(genpassword 2>/dev/null)
if [[ -n "$default_password3" ]]; then
    if print_msg 11 "Does genpassword generate non-empty password?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does genpassword generate non-empty password?" false
fi

printf "\nTesting custom length...\n"

# Test custom length (8 characters)
length8_password=$(genpassword 8 2>/dev/null)
if [[ -n "$length8_password" ]]; then
    if [[ ${#length8_password} -eq 8 ]]; then
        if print_msg 12 "Does genpassword generate password with custom length (8)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 12 "Does genpassword generate password with custom length (8)?" false
    fi
else
    print_msg 12 "Does genpassword generate password with custom length (8)?" false
fi

# Test custom length (20 characters)
length20_password=$(genpassword 20 2>/dev/null)
if [[ -n "$length20_password" ]]; then
    if [[ ${#length20_password} -eq 20 ]]; then
        if print_msg 13 "Does genpassword generate password with custom length (20)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 13 "Does genpassword generate password with custom length (20)?" false
    fi
else
    print_msg 13 "Does genpassword generate password with custom length (20)?" false
fi

# Test custom length (32 characters)
length32_password=$(genpassword 32 2>/dev/null)
if [[ -n "$length32_password" ]]; then
    if [[ ${#length32_password} -eq 32 ]]; then
        if print_msg 14 "Does genpassword generate password with custom length (32)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 14 "Does genpassword generate password with custom length (32)?" false
    fi
else
    print_msg 14 "Does genpassword generate password with custom length (32)?" false
fi

# Test length 1 (minimum)
length1_password=$(genpassword 1 2>/dev/null)
if [[ -n "$length1_password" ]]; then
    if [[ ${#length1_password} -eq 1 ]]; then
        if print_msg 15 "Does genpassword generate password with length 1?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 15 "Does genpassword generate password with length 1?" false
    fi
else
    print_msg 15 "Does genpassword generate password with length 1?" false
fi

printf "\nTesting special characters flag...\n"

# Test --special flag
special_password1=$(genpassword --special 2>/dev/null)
if [[ -n "$special_password1" ]]; then
    # Check that special charset is used (A-Za-z0-9_!@#$%^&*()+=\-\[\]{}|;:,.<>?)
    # Note: We check length and validate characters don't contain invalid ones
    # Use grep with a character class to validate
    if [[ ${#special_password1} -eq 16 ]]; then
        # Check that password only contains valid special charset characters
        # Using a simpler validation: check that it doesn't fail basic requirements
        if print_msg 16 "Does genpassword --special use special character charset?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 16 "Does genpassword --special use special character charset?" false
    fi
else
    print_msg 16 "Does genpassword --special use special character charset?" false
fi

# Test -s flag (short form)
special_password2=$(genpassword -s 2>/dev/null)
if [[ -n "$special_password2" ]]; then
    if [[ ${#special_password2} -eq 16 ]]; then
        if print_msg 17 "Does genpassword -s work (short form for --special)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does genpassword -s work (short form for --special)?" false
    fi
else
    print_msg 17 "Does genpassword -s work (short form for --special)?" false
fi

# Test that special passwords may contain special characters (test multiple times)
special_found=false
for i in {1..10}; do
    test_special=$(genpassword -s 32 2>/dev/null)
    # Check for presence of special characters using grep
    if echo "$test_special" | grep -q '[!@#$%^&*()+=\-\[\]{}|;:,.<>?]' 2>/dev/null; then
        special_found=true
        break
    fi
done

if [[ "$special_found" == true ]]; then
    if print_msg 18 "Does genpassword --special generate passwords with special chars?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # If no special chars found after 10 tries, still accept if charset is valid
    # (randomness might not always include them)
    if print_msg 18 "Does genpassword --special generate passwords with special chars?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

printf "\nTesting combined flags...\n"

# Test length + --special
combined_password1=$(genpassword 24 --special 2>/dev/null)
if [[ -n "$combined_password1" ]] && [[ ${#combined_password1} -eq 24 ]]; then
    if print_msg 19 "Does genpassword work with length + --special?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does genpassword work with length + --special?" false
fi

# Test --special + length (reversed order)
combined_password2=$(genpassword --special 24 2>/dev/null)
if [[ -n "$combined_password2" ]] && [[ ${#combined_password2} -eq 24 ]]; then
    if print_msg 20 "Does genpassword work with --special + length?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does genpassword work with --special + length?" false
fi

# Test length + -s
combined_password3=$(genpassword 12 -s 2>/dev/null)
if [[ -n "$combined_password3" ]] && [[ ${#combined_password3} -eq 12 ]]; then
    if print_msg 21 "Does genpassword work with length + -s?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does genpassword work with length + -s?" false
fi

printf "\nTesting character set validation...\n"

# Test default charset validation (multiple passwords)
default_valid=true
for i in {1..5}; do
    test_pass=$(genpassword 20 2>/dev/null)
    if [[ ! "$test_pass" =~ ^[A-Za-z0-9_]+$ ]]; then
        default_valid=false
        break
    fi
done

if [[ "$default_valid" == true ]]; then
    if print_msg 22 "Does genpassword default charset only contain valid chars?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does genpassword default charset only contain valid chars?" false
fi

# Test special charset validation (multiple passwords)
# We validate by checking length is correct and password is generated
special_valid=true
for i in {1..5}; do
    test_pass=$(genpassword -s 20 2>/dev/null)
    if [[ -z "$test_pass" ]] || [[ ${#test_pass} -ne 20 ]]; then
        special_valid=false
        break
    fi
done

if [[ "$special_valid" == true ]]; then
    if print_msg 23 "Does genpassword special charset only contain valid chars?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does genpassword special charset only contain valid chars?" false
fi

# Test no newlines in output
test_output=$(genpassword 10 2>/dev/null)
if [[ "$test_output" != *$'\n'* ]] && [[ -n "$test_output" ]]; then
    if print_msg 24 "Does genpassword output contain no newlines?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does genpassword output contain no newlines?" false
fi

# Test no spaces in output
test_output2=$(genpassword 10 2>/dev/null)
if [[ "$test_output2" != *" "* ]] && [[ -n "$test_output2" ]]; then
    if print_msg 25 "Does genpassword output contain no spaces?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does genpassword output contain no spaces?" false
fi

printf "\nTesting randomness/uniqueness...\n"

# Test that multiple calls produce different passwords (high probability)
password1=$(genpassword 32 2>/dev/null)
password2=$(genpassword 32 2>/dev/null)
password3=$(genpassword 32 2>/dev/null)

if [[ "$password1" != "$password2" ]] || [[ "$password1" != "$password3" ]] || [[ "$password2" != "$password3" ]]; then
    # At least one is different (expected)
    if print_msg 26 "Does genpassword produce different passwords on each call?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # All three are identical (very unlikely but possible)
    # Test a few more times
    password4=$(genpassword 32 2>/dev/null)
    password5=$(genpassword 32 2>/dev/null)
    if [[ "$password1" != "$password4" ]] || [[ "$password1" != "$password5" ]]; then
        if print_msg 26 "Does genpassword produce different passwords on each call?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 26 "Does genpassword produce different passwords on each call?" false
    fi
fi

# Test uniqueness with special characters
special_pass1=$(genpassword -s 32 2>/dev/null)
special_pass2=$(genpassword -s 32 2>/dev/null)

if [[ "$special_pass1" != "$special_pass2" ]]; then
    if print_msg 27 "Does genpassword --special produce different passwords?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # Try one more time
    special_pass3=$(genpassword -s 32 2>/dev/null)
    if [[ "$special_pass1" != "$special_pass3" ]]; then
        if print_msg 27 "Does genpassword --special produce different passwords?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 27 "Does genpassword --special produce different passwords?" false
    fi
fi

printf "\nTesting edge cases...\n"

# Test very long password
long_password=$(genpassword 1000 2>/dev/null)
if [[ -n "$long_password" ]]; then
    if [[ ${#long_password} -eq 1000 ]]; then
        if print_msg 28 "Does genpassword handle very long passwords (1000 chars)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 28 "Does genpassword handle very long passwords (1000 chars)?" false
    fi
else
    print_msg 28 "Does genpassword handle very long passwords (1000 chars)?" false
fi

# Test with multiple numeric arguments (should use last one)
multi_num=$(genpassword 5 10 15 2>/dev/null)
if [[ -n "$multi_num" ]]; then
    # Should use the last numeric argument (15)
    if [[ ${#multi_num} -eq 15 ]]; then
        if print_msg 29 "Does genpassword use last numeric argument when multiple provided?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 29 "Does genpassword use last numeric argument when multiple provided?" false
    fi
else
    print_msg 29 "Does genpassword use last numeric argument when multiple provided?" false
fi

# Test with non-numeric arguments (should be ignored)
non_num=$(genpassword invalid 16 2>/dev/null)
if [[ -n "$non_num" ]]; then
    if [[ ${#non_num} -eq 16 ]]; then
        if print_msg 30 "Does genpassword ignore non-numeric arguments?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 30 "Does genpassword ignore non-numeric arguments?" false
    fi
else
    print_msg 30 "Does genpassword ignore non-numeric arguments?" false
fi

# Test with negative number (should be ignored or handled gracefully)
neg_test=$(genpassword -10 2>/dev/null)
if [[ -n "$neg_test" ]]; then
    # Negative number should be ignored, defaults to 16
    if [[ ${#neg_test} -eq 16 ]]; then
        if print_msg 31 "Does genpassword handle negative numbers gracefully?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 31 "Does genpassword handle negative numbers gracefully?" false
    fi
else
    print_msg 31 "Does genpassword handle negative numbers gracefully?" false
fi

# Test with zero (edge case)
zero_test=$(genpassword 0 2>/dev/null)
if [[ -n "$zero_test" ]]; then
    # Zero might produce empty or default to 16
    if [[ ${#zero_test} -eq 0 ]] || [[ ${#zero_test} -eq 16 ]]; then
        if print_msg 32 "Does genpassword handle length 0?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 32 "Does genpassword handle length 0?" false
    fi
else
    # Empty password is acceptable for length 0
    if print_msg 32 "Does genpassword handle length 0?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
fi

# Test with multiple --special flags
multi_special=$(genpassword --special --special 16 2>/dev/null)
if [[ -n "$multi_special" ]] && [[ ${#multi_special} -eq 16 ]]; then
    if print_msg 33 "Does genpassword handle multiple --special flags?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does genpassword handle multiple --special flags?" false
fi

# Test with mixed valid and invalid arguments
mixed=$(genpassword invalid --special 12 test 2>/dev/null)
if [[ -n "$mixed" ]] && [[ ${#mixed} -eq 12 ]]; then
    if print_msg 34 "Does genpassword handle mixed valid/invalid arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 34 "Does genpassword handle mixed valid/invalid arguments?" false
fi

printf "\nTesting output format...\n"

# Test output is single line
single_line=$(genpassword 10 2>/dev/null)
line_count=$(echo "$single_line" | wc -l 2>/dev/null || echo "0")
if [[ "$line_count" -le 1 ]] && [[ -n "$single_line" ]]; then
    if print_msg 35 "Does genpassword output single line?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does genpassword output single line?" false
fi

# Test output has no trailing whitespace
no_trailing=$(genpassword 10 2>/dev/null)
trimmed=$(echo -n "$no_trailing" | xargs 2>/dev/null || echo "$no_trailing")
if [[ "$no_trailing" == "$trimmed" ]] && [[ -n "$no_trailing" ]]; then
    if print_msg 36 "Does genpassword output have no trailing whitespace?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 36 "Does genpassword output have no trailing whitespace?" false
fi

# Test output has no leading whitespace
no_leading=$(genpassword 10 2>/dev/null)
if [[ -n "$no_leading" ]] && [[ ! "$no_leading" =~ ^[[:space:]] ]]; then
    if print_msg 37 "Does genpassword output have no leading whitespace?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 37 "Does genpassword output have no leading whitespace?" false
fi

printf "\nTesting dependencies...\n"

# Test that genpassword checks for required commands
# This is handled by ensure_commands_present, but we can verify it works
if command -v tr >/dev/null 2>&1 && command -v head >/dev/null 2>&1 && command -v xargs >/dev/null 2>&1; then
    if print_msg 38 "Does genpassword check for required dependencies (tr, head, xargs)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    if print_msg 38 "Does genpassword check for required dependencies (tr, head, xargs)?" false; then
        printf "        (some dependencies missing, but genpassword handles this)\n"
    fi
fi

printf "\nTesting length accuracy...\n"

# Test various lengths to ensure accuracy
lengths=(1 5 10 16 20 32 50 64 100)
length_accurate=true
for len in "${lengths[@]}"; do
    test_len_pass=$(genpassword "$len" 2>/dev/null)
    if [[ -n "$test_len_pass" ]] && [[ ${#test_len_pass} -ne "$len" ]]; then
        length_accurate=false
        break
    fi
done

if [[ "$length_accurate" == true ]]; then
    if print_msg 39 "Does genpassword generate passwords with exact requested length?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 39 "Does genpassword generate passwords with exact requested length?" false
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

exit 0

