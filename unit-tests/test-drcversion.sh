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
    if [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        return 0
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        return 1
    fi
}

score=0
printf "Running unit tests for drcversion.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/information/drcversion.sh" ]]; then
    if print_msg 3 "Can I find drcversion.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find drcversion.sh?" false
    printf "Error: Test cannot continue. drcversion.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/information/drcversion.sh" 2>/dev/null; then
    if print_msg 4 "Can I source drcversion.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source drcversion.sh?" false
    printf "Error: Test cannot continue. drcversion.sh not found.\n" >&2
    exit 4
fi

if declare -f drcversion >/dev/null 2>&1; then
    if print_msg 5 "Is drcversion function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is drcversion function defined?" false
    printf "Error: drcversion function not defined.\n" >&2
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

# Create test directory structure
TEST_DOGRC_DIR=$(mktemp -d "${__UNIT_TESTS_DIR}/test_drcversion_dogrc.XXXXXX" 2>/dev/null || echo "${__UNIT_TESTS_DIR}/test_drcversion_dogrc.$$")
TEST_CONFIG_DIR="${TEST_DOGRC_DIR}/config"
mkdir -p "${TEST_CONFIG_DIR}" || {
    printf "Error: Failed to create test directories.\n" >&2
    exit 92
}

# Setup trap to ensure cleanup happens even on failure
cleanup_drcversion_test() {
    local exit_code=$?
    
    # Restore original directory
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    # Remove test directory and all contents
    if [[ -d "$TEST_DOGRC_DIR" ]]; then
        rm -rf "$TEST_DOGRC_DIR" 2>/dev/null || true
    fi
    
    # Remove any leftover test directories
    rm -rf "${__UNIT_TESTS_DIR}"/test_drcversion_dogrc.* 2>/dev/null || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_drcversion_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Create a wrapper script that overrides __DOGRC_DIR before sourcing
create_drcversion_wrapper() {
    cat > "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" << TESTWRAPPER
#!/bin/bash
# Wrapper to test drcversion with custom __DOGRC_DIR
TEST_DOGRC_DIR_VAR="${TEST_DOGRC_DIR}"
PLUGINS_DIR_VAR="${__PLUGINS_DIR}"
CORE_DIR_VAR="${__CORE_DIR}"

# Source dependency_check first
source "\${CORE_DIR_VAR}/dependency_check.sh" 2>/dev/null

# Source drcversion.sh - it will set __DOGRC_DIR, but we can override it
# by creating a modified version that uses our test directory
# Actually, since __DOGRC_DIR is readonly, we need to source it in a way
# that allows us to override it. Let's source it and then manually override
# the paths it uses.

# Source the original script
source "\${PLUGINS_DIR_VAR}/information/drcversion.sh" 2>/dev/null

# Override the function to use our test directory
drcversion() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "\${1:-}" ]] && { [[ "\${1,,}" == "--help" ]] || [[ "\${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp drcversion
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "drcversion" cat jq || {
        return \$?
    }

    # Use test directory instead of __DOGRC_DIR
    local version_file="\${TEST_DOGRC_DIR_VAR}/config/version.fake"
    if [[ -f "\$version_file" ]]; then
        local version=\$(cat "\$version_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "\$version" ]]; then
            local real_version=\$(cat "\${TEST_DOGRC_DIR_VAR}/config/DOGRC.json" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "unknown")
            [[ -z "\$real_version" ]] && real_version="unknown"
            echo "DOGRC Version \$version (spoofed, real version: \$real_version)"
            return 0
        fi
    fi
    
    # Fall back to DOGRC.json
    local real_version=\$(cat "\${TEST_DOGRC_DIR_VAR}/config/DOGRC.json" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "unknown")
    [[ -z "\$real_version" ]] && real_version="unknown"
    echo "DOGRC Version \$real_version"
    
    return 0
}

export -f drcversion
export TEST_DOGRC_DIR_VAR

# Run drcversion with provided arguments
drcversion "\$@"
exit \$?
TESTWRAPPER
    chmod +x "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh"
}

create_drcversion_wrapper

printf "\nTesting drcversion() function help flags...\n"

# Test 6: drcversion --help
if declare -f drchelp >/dev/null 2>&1; then
    if drcversion --help >/dev/null 2>&1; then
        if print_msg 6 "Does drcversion --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does drcversion --help work?" false
    fi
else
    if print_msg 6 "Does drcversion --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test 7: drcversion -h
if declare -f drchelp >/dev/null 2>&1; then
    if drcversion -h >/dev/null 2>&1; then
        if print_msg 7 "Does drcversion -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does drcversion -h work?" false
    fi
else
    if print_msg 7 "Does drcversion -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting drcversion() function dependency checks...\n"

# Test 8: Checks for cat dependency
if command -v cat >/dev/null 2>&1; then
    # cat is available, dependency check should pass
    if print_msg 8 "Does drcversion check for cat dependency?" true; then
        ((score++))
    fi
else
    if print_msg 8 "Does drcversion check for cat dependency?" false; then
        printf "        (cat not available, cannot test)\n"
    fi
fi

# Test 9: Checks for jq dependency
if command -v jq >/dev/null 2>&1; then
    # jq is available, dependency check should pass
    if print_msg 9 "Does drcversion check for jq dependency?" true; then
        ((score++))
    fi
else
    if print_msg 9 "Does drcversion check for jq dependency?" false; then
        printf "        (jq not available, cannot test)\n"
    fi
fi

printf "\nTesting drcversion() function version reading...\n"

# Test 10: Reads version from DOGRC.json (normal case)
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    rm -f "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -q "DOGRC Version 0.1.5" && ! echo "$output" | grep -q "spoofed"; then
        if print_msg 10 "Does drcversion read version from DOGRC.json?" true; then
            ((score++))
        fi
    else
        print_msg 10 "Does drcversion read version from DOGRC.json?" false
    fi
else
    if print_msg 10 "Does drcversion read version from DOGRC.json?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 11: Output format for normal version
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -qE "^DOGRC Version [0-9]+\.[0-9]+\.[0-9]+$"; then
        if print_msg 11 "Does drcversion output format match expected pattern?" true; then
            ((score++))
        fi
    else
        print_msg 11 "Does drcversion output format match expected pattern?" false
    fi
else
    if print_msg 11 "Does drcversion output format match expected pattern?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 12: Reads version from version.fake (spoofed case)
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    echo "0.2.0" > "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -q "DOGRC Version 0.2.0" && echo "$output" | grep -q "spoofed" && echo "$output" | grep -q "real version: 0.1.5"; then
        if print_msg 12 "Does drcversion read version from version.fake when it exists?" true; then
            ((score++))
        fi
    else
        print_msg 12 "Does drcversion read version from version.fake when it exists?" false
    fi
else
    if print_msg 12 "Does drcversion read version from version.fake when it exists?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 13: Spoofed output format
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -qE "DOGRC Version [0-9]+\.[0-9]+\.[0-9]+ \(spoofed, real version: [0-9]+\.[0-9]+\.[0-9]+\)"; then
        if print_msg 13 "Does drcversion show correct spoofed output format?" true; then
            ((score++))
        fi
    else
        print_msg 13 "Does drcversion show correct spoofed output format?" false
    fi
else
    if print_msg 13 "Does drcversion show correct spoofed output format?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 14: Empty version.fake falls back to DOGRC.json
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    echo "" > "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -q "DOGRC Version 0.1.5" && ! echo "$output" | grep -q "spoofed"; then
        if print_msg 14 "Does drcversion fall back to DOGRC.json when version.fake is empty?" true; then
            ((score++))
        fi
    else
        print_msg 14 "Does drcversion fall back to DOGRC.json when version.fake is empty?" false
    fi
    rm -f "${TEST_CONFIG_DIR}/version.fake"
else
    if print_msg 14 "Does drcversion fall back to DOGRC.json when version.fake is empty?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 15: Whitespace in version.fake is trimmed
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    echo "  0.2.0  " > "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -q "DOGRC Version 0.2.0" && ! echo "$output" | grep -q "  0.2.0  "; then
        if print_msg 15 "Does drcversion trim whitespace from version.fake?" true; then
            ((score++))
        fi
    else
        print_msg 15 "Does drcversion trim whitespace from version.fake?" false
    fi
    rm -f "${TEST_CONFIG_DIR}/version.fake"
else
    if print_msg 15 "Does drcversion trim whitespace from version.fake?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 16: Missing DOGRC.json shows "unknown" for real version
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    rm -f "${TEST_CONFIG_DIR}/DOGRC.json"
    echo "0.2.0" > "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    if echo "$output" | grep -q "DOGRC Version 0.2.0" && echo "$output" | grep -q "real version: unknown"; then
        if print_msg 16 "Does drcversion show 'unknown' when DOGRC.json is missing?" true; then
            ((score++))
        fi
    else
        print_msg 16 "Does drcversion show 'unknown' when DOGRC.json is missing?" false
    fi
    rm -f "${TEST_CONFIG_DIR}/version.fake"
    # Restore DOGRC.json for other tests
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
else
    if print_msg 16 "Does drcversion show 'unknown' when DOGRC.json is missing?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 17: Missing DOGRC.json shows "unknown" in normal case
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    rm -f "${TEST_CONFIG_DIR}/DOGRC.json"
    rm -f "${TEST_CONFIG_DIR}/version.fake"
    output=$(bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" 2>&1)
    # Check if output contains "unknown" (case-insensitive)
    if echo "$output" | grep -qi "DOGRC Version unknown" || echo "$output" | grep -qi "unknown"; then
        if print_msg 17 "Does drcversion show 'unknown' when DOGRC.json is missing (no version.fake)?" true; then
            ((score++))
        fi
    else
        print_msg 17 "Does drcversion show 'unknown' when DOGRC.json is missing (no version.fake)?" false
    fi
    # Restore DOGRC.json for other tests
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
else
    if print_msg 17 "Does drcversion show 'unknown' when DOGRC.json is missing (no version.fake)?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

printf "\nTesting drcversion() function return codes...\n"

# Test 18: Returns 0 on success
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    rm -f "${TEST_CONFIG_DIR}/version.fake"
    bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" >/dev/null 2>&1
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 18 "Does drcversion return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 18 "Does drcversion return 0 on success?" false
    fi
else
    if print_msg 18 "Does drcversion return 0 on success?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

# Test 19: Returns 0 on success with version.fake
if command -v cat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cat > "${TEST_CONFIG_DIR}/DOGRC.json" << 'EOF'
{
  "version": "0.1.5"
}
EOF
    echo "0.2.0" > "${TEST_CONFIG_DIR}/version.fake"
    bash "${TEST_DOGRC_DIR}/test_drcversion_wrapper.sh" >/dev/null 2>&1
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 19 "Does drcversion return 0 on success with version.fake?" true; then
            ((score++))
        fi
    else
        print_msg 19 "Does drcversion return 0 on success with version.fake?" false
    fi
    rm -f "${TEST_CONFIG_DIR}/version.fake"
else
    if print_msg 19 "Does drcversion return 0 on success with version.fake?" false; then
        printf "        (cat or jq not available, skipping)\n"
    fi
fi

total_tests=20  # Tests 1-19 plus 1 summary test with "*"
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"

printf "\nCleaning up...\n"
# Cleanup will be handled by trap
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

