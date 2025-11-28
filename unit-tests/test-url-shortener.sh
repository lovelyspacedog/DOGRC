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
total_tests=35  # Tests 1-33 plus 2 summary tests with "*"
printf "Running unit tests for url-shortener.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/utilities/url-shortener.sh" ]]; then
    if print_msg 3 "Can I find url-shortener.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find url-shortener.sh?" false
    printf "Error: Test cannot continue. Url-shortener.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/url-shortener.sh" 2>/dev/null; then
    if print_msg 4 "Can I source url-shortener.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source url-shortener.sh?" false
    printf "Error: Test cannot continue. Url-shortener.sh not found.\n" >&2
    exit 4
fi

if declare -f url-shortener >/dev/null 2>&1; then
    if print_msg 5 "Is url-shortener function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is url-shortener function defined?" false
    printf "Error: url-shortener function not defined.\n" >&2
    exit 5
fi

if declare -f shorturl >/dev/null 2>&1; then
    if print_msg 6 "Is shorturl function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is shorturl function defined?" false
    printf "Error: shorturl function not defined.\n" >&2
    exit 6
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

# Test 7: url-shortener --help
if declare -f drchelp >/dev/null 2>&1; then
    if url-shortener --help >/dev/null 2>&1; then
        if print_msg 7 "Does url-shortener --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 7 "Does url-shortener --help work?" false
    fi
else
    if print_msg 7 "Does url-shortener --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 8: url-shortener -h
if declare -f drchelp >/dev/null 2>&1; then
    if url-shortener -h >/dev/null 2>&1; then
        if print_msg 8 "Does url-shortener -h work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 8 "Does url-shortener -h work?" false
    fi
else
    if print_msg 8 "Does url-shortener -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 9: shorturl --help
if declare -f drchelp >/dev/null 2>&1; then
    if shorturl --help >/dev/null 2>&1; then
        if print_msg 9 "Does shorturl --help work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        print_msg 9 "Does shorturl --help work?" false
    fi
else
    if print_msg 9 "Does shorturl --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test 10: Error on missing URL
if ! url-shortener 2>/dev/null; then
    if print_msg 10 "Does url-shortener error on missing URL?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does url-shortener error on missing URL?" false
fi

# Test 11: Error message for missing URL
if url-shortener 2>&1 | grep -q "Error: URL is required"; then
    if print_msg 11 "Does url-shortener show error message for missing URL?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does url-shortener show error message for missing URL?" false
fi

# Test 12: Error on invalid URL format
if ! url-shortener "not-a-url" 2>/dev/null; then
    if print_msg 12 "Does url-shortener error on invalid URL format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does url-shortener error on invalid URL format?" false
fi

# Test 13: Error message for invalid URL
if url-shortener "not-a-url" 2>&1 | grep -q "Error: URL must start with http:// or https://"; then
    if print_msg 13 "Does url-shortener show error for invalid URL format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does url-shortener show error for invalid URL format?" false
fi

# Test 14: Error on unknown service
if ! url-shortener "https://example.com" --service invalid 2>/dev/null; then
    if print_msg 14 "Does url-shortener error on unknown service?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does url-shortener error on unknown service?" false
fi

# Test 15: Error on unknown option
if ! url-shortener --unknown-flag 2>/dev/null; then
    if print_msg 15 "Does url-shortener error on unknown option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does url-shortener error on unknown option?" false
fi

# Test 16: Error on --service without argument
if ! url-shortener "https://example.com" --service 2>/dev/null; then
    if print_msg 16 "Does url-shortener error on --service without argument?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does url-shortener error on --service without argument?" false
fi

# Test 17: Error on multiple URLs
if ! url-shortener "https://example.com" "https://example2.com" 2>/dev/null; then
    if print_msg 17 "Does url-shortener error on multiple URLs?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does url-shortener error on multiple URLs?" false
fi

printf "\nTesting basic functionality...\n"

# Test 18: Shorten URL with default service (is.gd)
# Note: This requires internet connection and may fail if service is down
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" 2>&1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/"; then
        if print_msg 18 "Does url-shortener shorten URL with default service?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        # Check if it's a network error (acceptable)
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 18 "Does url-shortener shorten URL with default service?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 18 "Does url-shortener shorten URL with default service?" false
        fi
    fi
else
    if print_msg 18 "Does url-shortener shorten URL with default service?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 19: Shorten URL with is.gd service explicitly
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --service is.gd 2>&1)
    if echo "$result" | grep -qE "^https://is\.gd/"; then
        if print_msg 19 "Does url-shortener work with is.gd service?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 19 "Does url-shortener work with is.gd service?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 19 "Does url-shortener work with is.gd service?" false
        fi
    fi
else
    if print_msg 19 "Does url-shortener work with is.gd service?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 20: Shorten URL with tinyurl service
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --service tinyurl 2>&1)
    if echo "$result" | grep -qE "^https://tinyurl\.com/"; then
        if print_msg 20 "Does url-shortener work with tinyurl service?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 20 "Does url-shortener work with tinyurl service?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 20 "Does url-shortener work with tinyurl service?" false
        fi
    fi
else
    if print_msg 20 "Does url-shortener work with tinyurl service?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 21: Shorten URL with -s flag
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" -s tinyurl 2>&1)
    if echo "$result" | grep -qE "^https://tinyurl\.com/"; then
        if print_msg 21 "Does -s flag work for service selection?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 21 "Does -s flag work for service selection?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 21 "Does -s flag work for service selection?" false
        fi
    fi
else
    if print_msg 21 "Does -s flag work for service selection?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 22: --show-service flag
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --show-service 2>&1)
    if echo "$result" | grep -qE "\(is\.gd\)"; then
        if print_msg 22 "Does --show-service flag display service name?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 22 "Does --show-service flag display service name?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 22 "Does --show-service flag display service name?" false
        fi
    fi
else
    if print_msg 22 "Does --show-service flag display service name?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 23: Return code 0 on success
if command -v curl >/dev/null 2>&1; then
    if url-shortener "https://www.example.com/test" >/dev/null 2>&1; then
        if print_msg 23 "Does url-shortener return 0 on success?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        # Check if it's a network error (acceptable)
        result=$(url-shortener "https://www.example.com/test" 2>&1)
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 23 "Does url-shortener return 0 on success?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 23 "Does url-shortener return 0 on success?" false
        fi
    fi
else
    if print_msg 23 "Does url-shortener return 0 on success?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 24: shorturl alias works
if command -v curl >/dev/null 2>&1; then
    result=$(shorturl "https://www.example.com/test" 2>&1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/"; then
        if print_msg 24 "Does shorturl alias work?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 24 "Does shorturl alias work?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 24 "Does shorturl alias work?" false
        fi
    fi
else
    if print_msg 24 "Does shorturl alias work?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 25: shorturl with options
if command -v curl >/dev/null 2>&1; then
    result=$(shorturl "https://www.example.com/test" -s tinyurl 2>&1)
    if echo "$result" | grep -qE "^https://tinyurl\.com/"; then
        if print_msg 25 "Does shorturl work with options?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 25 "Does shorturl work with options?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 25 "Does shorturl work with options?" false
        fi
    fi
else
    if print_msg 25 "Does shorturl work with options?" false; then
        printf "        (curl not available)\n"
    fi
fi

printf "\nTesting edge cases...\n"

# Test 26: URL with query parameters
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/path?query=test&param=value" 2>&1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/"; then
        if print_msg 26 "Does url-shortener handle URLs with query parameters?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 26 "Does url-shortener handle URLs with query parameters?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 26 "Does url-shortener handle URLs with query parameters?" false
        fi
    fi
else
    if print_msg 26 "Does url-shortener handle URLs with query parameters?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 27: URL with fragments
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/path#fragment" 2>&1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/"; then
        if print_msg 27 "Does url-shortener handle URLs with fragments?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 27 "Does url-shortener handle URLs with fragments?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 27 "Does url-shortener handle URLs with fragments?" false
        fi
    fi
else
    if print_msg 27 "Does url-shortener handle URLs with fragments?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 28: Service name case insensitivity
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --service IS.GD 2>&1)
    if echo "$result" | grep -qE "^https://is\.gd/"; then
        if print_msg 28 "Does url-shortener handle case-insensitive service names?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 28 "Does url-shortener handle case-insensitive service names?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 28 "Does url-shortener handle case-insensitive service names?" false
        fi
    fi
else
    if print_msg 28 "Does url-shortener handle case-insensitive service names?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 29: Service aliases (isgd, tiny)
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --service isgd 2>&1)
    if echo "$result" | grep -qE "^https://is\.gd/"; then
        if print_msg 29 "Does url-shortener accept service aliases (isgd)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 29 "Does url-shortener accept service aliases (isgd)?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 29 "Does url-shortener accept service aliases (isgd)?" false
        fi
    fi
else
    if print_msg 29 "Does url-shortener accept service aliases (isgd)?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 30: Service aliases (tiny)
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" --service tiny 2>&1)
    if echo "$result" | grep -qE "^https://tinyurl\.com/"; then
        if print_msg 30 "Does url-shortener accept service aliases (tiny)?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 30 "Does url-shortener accept service aliases (tiny)?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 30 "Does url-shortener accept service aliases (tiny)?" false
        fi
    fi
else
    if print_msg 30 "Does url-shortener accept service aliases (tiny)?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 31: -- separator
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener -- "https://www.example.com/test" 2>&1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/"; then
        if print_msg 31 "Does url-shortener handle -- separator?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 31 "Does url-shortener handle -- separator?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 31 "Does url-shortener handle -- separator?" false
        fi
    fi
else
    if print_msg 31 "Does url-shortener handle -- separator?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 32: URL starting with http:// (not https://)
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "http://www.example.com/test" 2>&1)
    if echo "$result" | grep -qE "^https?://(is\.gd|tinyurl\.com)/"; then
        if print_msg 32 "Does url-shortener handle http:// URLs?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 32 "Does url-shortener handle http:// URLs?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 32 "Does url-shortener handle http:// URLs?" false
        fi
    fi
else
    if print_msg 32 "Does url-shortener handle http:// URLs?" false; then
        printf "        (curl not available)\n"
    fi
fi

# Test 33: Output format (should be a valid URL)
if command -v curl >/dev/null 2>&1; then
    result=$(url-shortener "https://www.example.com/test" 2>&1 | head -1)
    if echo "$result" | grep -qE "^https://(is\.gd|tinyurl\.com)/[a-zA-Z0-9]+"; then
        if print_msg 33 "Does url-shortener output valid shortened URL format?" true; then
            ((score++))
            if type update_progress_from_score >/dev/null 2>&1; then
                update_progress_from_score
            fi
        fi
    else
        if echo "$result" | grep -qE "(Error|Failed|curl|network|connection)"; then
            if print_msg 33 "Does url-shortener output valid shortened URL format?" false; then
                printf "        (Network error or service unavailable - acceptable)\n"
            fi
        else
            print_msg 33 "Does url-shortener output valid shortened URL format?" false
        fi
    fi
else
    if print_msg 33 "Does url-shortener output valid shortened URL format?" false; then
        printf "        (curl not available)\n"
    fi
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

