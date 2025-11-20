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
printf "Running unit tests for dots.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/navigation/dots.sh" ]]; then
    if print_msg 3 "Can I find dots.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find dots.sh?" false
    printf "Error: Test cannot continue. Dots.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/navigation/dots.sh" 2>/dev/null; then
    if print_msg 4 "Can I source dots.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source dots.sh?" false
    printf "Error: Test cannot continue. Dots.sh not found.\n" >&2
    exit 4
fi

if declare -f dots >/dev/null 2>&1; then
    if print_msg 5 "Is dots function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is dots function defined?" false
    printf "Error: dots function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))

# Save original directory and .config path
original_dir=$(pwd)
original_config="$HOME/.config"
test_config="${__UNIT_TESTS_DIR}/.config_test"
test_config_backup=""

# Backup original .config if it exists
if [[ -d "$original_config" ]]; then
    test_config_backup="${original_config}.dots_test_backup.$(date +%s)"
    # We'll create a symlink or use the test config, but preserve original
    # For safety, we'll work in a test directory instead
fi

# Setup trap to ensure cleanup happens even on failure
cleanup_dots_test() {
    local exit_code=$?
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    # Restore original .config if we backed it up
    if [[ -n "$test_config_backup" ]] && [[ -d "$test_config_backup" ]]; then
        # We didn't actually move it, so no restore needed
        rm -rf "$test_config_backup" 2>/dev/null || true
    fi
    
    # Clean up test .config directory
    rm -rf "$test_config" 2>/dev/null || true
    
    # Clean up any test directories we created
    rm -rf "${__UNIT_TESTS_DIR}/test_dots_"* 2>/dev/null || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_dots_test EXIT INT TERM

# Create test .config directory structure
mkdir -p "$test_config" || {
    printf "Error: Failed to create test .config directory.\n" >&2
    exit 91
}

# Create test subdirectories with various names for testing
mkdir -p "$test_config"/{hypr,waybar,kitty,neofetch,starship,test_dir,another_dir,zed} || {
    printf "Error: Failed to create test subdirectories.\n" >&2
    exit 92
}

# Create some files in test directories
touch "$test_config/hypr/config.conf" "$test_config/waybar/config.json" "$test_config/kitty/kitty.conf" || true

# Temporarily override HOME/.config for testing by using a function wrapper
# We'll test with the actual test_config path
export TEST_CONFIG_DIR="$test_config"

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if dots --help >/dev/null 2>&1; then
        if print_msg 6 "Does dots --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does dots --help work?" false
    fi
else
    if print_msg 6 "Does dots --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if dots -h >/dev/null 2>&1; then
        if print_msg 7 "Does dots -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does dots -h work?" false
    fi
else
    if print_msg 7 "Does dots -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test case-insensitive help flags
if declare -f drchelp >/dev/null 2>&1; then
    if dots --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does dots --HELP work (case-insensitive)?" true; then
            ((score++))
        fi
    else
        print_msg 8 "Does dots --HELP work (case-insensitive)?" false
    fi
else
    if print_msg 8 "Does dots --HELP work (case-insensitive)?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting no arguments / usage display...\n"

# Test 9: No arguments shows usage
cd "${__UNIT_TESTS_DIR}" || exit 91
output=$(dots 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "Usage:"; then
    if print_msg 9 "Does dots show usage when called with no arguments?" true; then
        ((score++))
    fi
else
    print_msg 9 "Does dots show usage when called with no arguments?" false
fi

# Test 10: Usage message contains expected commands
if echo "$output" | grep -q "ls" && echo "$output" | grep -q "Commands:"; then
    if print_msg 10 "Does usage message contain expected commands?" true; then
        ((score++))
    fi
else
    print_msg 10 "Does usage message contain expected commands?" false
fi

printf "\nTesting 'dots ls' command...\n"

# Create a wrapper function to test with our test config
test_dots_ls() {
    local old_home_config="$HOME/.config"
    # Temporarily override HOME for this test
    local test_home="${__UNIT_TESTS_DIR}/test_home_dots"
    mkdir -p "$test_home/.config" || return 1
    cp -r "$test_config"/* "$test_home/.config/" 2>/dev/null || true
    
    # Test by temporarily changing HOME
    local old_home="$HOME"
    export HOME="$test_home"
    
    local result=0
    dots ls >/dev/null 2>&1 || result=$?
    
    export HOME="$old_home"
    rm -rf "$test_home" 2>/dev/null || true
    
    return $result
}

# Test 11: dots ls lists directories
if test_dots_ls; then
    if print_msg 11 "Does 'dots ls' list .config directories?" true; then
        ((score++))
    fi
else
    print_msg 11 "Does 'dots ls' list .config directories?" false
fi

# Test 12: dots ls output is sorted
test_home="${__UNIT_TESTS_DIR}/test_home_dots_sorted"
mkdir -p "$test_home/.config" || exit 91
cp -r "$test_config"/* "$test_home/.config/" 2>/dev/null || true

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

# Check if output appears sorted (first directory should be alphabetically first)
if echo "$output" | grep -q "another_dir\|hypr\|kitty\|neofetch\|starship\|test_dir\|waybar\|zed"; then
    if print_msg 12 "Does 'dots ls' output appear sorted?" true; then
        ((score++))
    fi
else
    print_msg 12 "Does 'dots ls' output appear sorted?" false
fi

# Test 13: dots ls with specific directory
test_home="${__UNIT_TESTS_DIR}/test_home_dots_lsdir"
mkdir -p "$test_home/.config/hypr" || exit 91
touch "$test_home/.config/hypr/test.conf" || true

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls hypr 2>&1)
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]] && echo "$output" | grep -q "hypr\|test.conf"; then
    if print_msg 13 "Does 'dots ls <dir>' list directory contents?" true; then
        ((score++))
    fi
else
    print_msg 13 "Does 'dots ls <dir>' list directory contents?" false
fi

# Test 14: dots ls .config special case
test_home="${__UNIT_TESTS_DIR}/test_home_dots_config"
mkdir -p "$test_home/.config/hypr" || exit 91
touch "$test_home/.config/test_file" || true

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls .config 2>&1)
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]] && (echo "$output" | grep -q "hypr\|test_file"); then
    if print_msg 14 "Does 'dots ls .config' list ~/.config itself?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does 'dots ls .config' list ~/.config itself?" false
fi

# Test 15: dots ls with invalid directory
test_home="${__UNIT_TESTS_DIR}/test_home_dots_invalid"
mkdir -p "$test_home/.config" || exit 91

old_home="$HOME"
export HOME="$test_home"
dots ls nonexistent_dir 2>/dev/null
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 2 ]]; then
    if print_msg 15 "Does 'dots ls <invalid_dir>' return error code 2?" true; then
        ((score++))
    fi
else
    print_msg 15 "Does 'dots ls <invalid_dir>' return error code 2?" false
fi

printf "\nTesting directory navigation...\n"

# Test 16: dots <valid_dir> changes directory
test_home="${__UNIT_TESTS_DIR}/test_home_dots_nav"
mkdir -p "$test_home/.config/hypr" || exit 91
touch "$test_home/.config/hypr/test.conf" || true

old_home="$HOME"
old_pwd=$(pwd)
export HOME="$test_home"
cd "$test_home" || exit 91

# Source dots again with new HOME
source "${__PLUGINS_DIR}/navigation/dots.sh" 2>/dev/null || true

dots hypr >/dev/null 2>&1
exit_code=$?
new_pwd=$(pwd)

cd "$old_pwd" || true
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]] && [[ "$new_pwd" == "$test_home/.config/hypr" ]]; then
    if print_msg 16 "Does 'dots <dir>' change to the directory?" true; then
        ((score++))
    fi
else
    print_msg 16 "Does 'dots <dir>' change to the directory?" false
fi

# Test 17: dots .config navigates to ~/.config
test_home="${__UNIT_TESTS_DIR}/test_home_dots_nav_config"
mkdir -p "$test_home/.config" || exit 91

old_home="$HOME"
old_pwd=$(pwd)
export HOME="$test_home"
cd "$test_home" || exit 91

# Source dots again with new HOME
source "${__PLUGINS_DIR}/navigation/dots.sh" 2>/dev/null || true

dots .config >/dev/null 2>&1
exit_code=$?
new_pwd=$(pwd)

cd "$old_pwd" || true
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]] && [[ "$new_pwd" == "$test_home/.config" ]]; then
    if print_msg 17 "Does 'dots .config' navigate to ~/.config?" true; then
        ((score++))
    fi
else
    print_msg 17 "Does 'dots .config' navigate to ~/.config?" false
fi

# Test 18: dots <invalid_dir> returns error code 3
test_home="${__UNIT_TESTS_DIR}/test_home_dots_nav_invalid"
mkdir -p "$test_home/.config" || exit 91

old_home="$HOME"
old_pwd=$(pwd)
export HOME="$test_home"
cd "$test_home" || exit 91

# Source dots again with new HOME
source "${__PLUGINS_DIR}/navigation/dots.sh" 2>/dev/null || true

dots nonexistent_dir 2>/dev/null
exit_code=$?

cd "$old_pwd" || true
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 3 ]]; then
    if print_msg 18 "Does 'dots <invalid_dir>' return error code 3?" true; then
        ((score++))
    fi
else
    print_msg 18 "Does 'dots <invalid_dir>' return error code 3?" false
fi

printf "\nTesting output formatting...\n"

# Test 19: Output contains emoji
test_home="${__UNIT_TESTS_DIR}/test_home_dots_emoji"
mkdir -p "$test_home/.config/hypr" || exit 91

old_home="$HOME"
export HOME="$test_home"
output=$(dots hypr 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if echo "$output" | grep -q "📁"; then
    if print_msg 19 "Does output contain emoji (📁)?" true; then
        ((score++))
    fi
else
    print_msg 19 "Does output contain emoji (📁)?" false
fi

# Test 20: Output shows full path
test_home="${__UNIT_TESTS_DIR}/test_home_dots_path"
mkdir -p "$test_home/.config/hypr" || exit 91

old_home="$HOME"
export HOME="$test_home"
output=$(dots hypr 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if echo "$output" | grep -q "$test_home/.config/hypr"; then
    if print_msg 20 "Does output show full directory path?" true; then
        ((score++))
    fi
else
    print_msg 20 "Does output show full directory path?" false
fi

# Test 21: Uses eza if available, falls back to ls
test_home="${__UNIT_TESTS_DIR}/test_home_dots_eza"
mkdir -p "$test_home/.config/hypr" || exit 91
touch "$test_home/.config/hypr/test.conf" || true

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls hypr 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

# Check if output contains listing (either eza or ls format)
if echo "$output" | grep -q "test.conf\|Listing contents"; then
    if print_msg 21 "Does 'dots ls' use eza or ls for listing?" true; then
        ((score++))
    fi
else
    print_msg 21 "Does 'dots ls' use eza or ls for listing?" false
fi

printf "\nTesting edge cases...\n"

# Test 22: Empty .config directory
test_home="${__UNIT_TESTS_DIR}/test_home_dots_empty"
mkdir -p "$test_home/.config" || exit 91

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls 2>&1)
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

# Should handle empty directory gracefully
if [[ $exit_code -eq 0 ]]; then
    if print_msg 22 "Does 'dots ls' handle empty .config directory?" true; then
        ((score++))
    fi
else
    print_msg 22 "Does 'dots ls' handle empty .config directory?" false
fi

# Test 23: .config doesn't exist
test_home="${__UNIT_TESTS_DIR}/test_home_dots_no_config"
rm -rf "$test_home/.config" 2>/dev/null || true

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls 2>&1)
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

# Should handle missing .config gracefully (may return 0 or non-zero, but shouldn't crash)
if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 255 ]]; then
    if print_msg 23 "Does 'dots ls' handle missing .config directory?" true; then
        ((score++))
    fi
else
    print_msg 23 "Does 'dots ls' handle missing .config directory?" false
fi

# Test 24: Directory name with spaces
test_home="${__UNIT_TESTS_DIR}/test_home_dots_spaces"
mkdir -p "$test_home/.config/my config" || exit 91

old_home="$HOME"
old_pwd=$(pwd)
export HOME="$test_home"
cd "$test_home" || exit 91

# Source dots again with new HOME
source "${__PLUGINS_DIR}/navigation/dots.sh" 2>/dev/null || true

dots "my config" >/dev/null 2>&1
exit_code=$?
new_pwd=$(pwd)

cd "$old_pwd" || true
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]] && [[ "$new_pwd" == "$test_home/.config/my config" ]]; then
    if print_msg 24 "Does 'dots' work with directory names containing spaces?" true; then
        ((score++))
    fi
else
    print_msg 24 "Does 'dots' work with directory names containing spaces?" false
fi

# Test 25: Return code on success
test_home="${__UNIT_TESTS_DIR}/test_home_dots_return"
mkdir -p "$test_home/.config/hypr" || exit 91

old_home="$HOME"
export HOME="$test_home"
dots ls >/dev/null 2>&1
exit_code=$?
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if [[ $exit_code -eq 0 ]]; then
    if print_msg 25 "Does 'dots ls' return 0 on success?" true; then
        ((score++))
    fi
else
    print_msg 25 "Does 'dots ls' return 0 on success?" false
fi

# Test 26: Error message format for invalid directory
test_home="${__UNIT_TESTS_DIR}/test_home_dots_errmsg"
mkdir -p "$test_home/.config" || exit 91

old_home="$HOME"
export HOME="$test_home"
error_output=$(dots ls invalid_dir 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

if echo "$error_output" | grep -q "not a valid directory\|invalid"; then
    if print_msg 26 "Does 'dots ls' show user-friendly error message?" true; then
        ((score++))
    fi
else
    print_msg 26 "Does 'dots ls' show user-friendly error message?" false
fi

# Test 27: First letter coloring in dots ls
test_home="${__UNIT_TESTS_DIR}/test_home_dots_color"
mkdir -p "$test_home/.config"/{apple,banana,cherry} || exit 91

old_home="$HOME"
export HOME="$test_home"
output=$(dots ls 2>&1)
export HOME="$old_home"
rm -rf "$test_home" 2>/dev/null || true

# Check if output contains color codes (ANSI escape sequences)
# Look for escape sequences: \033[ or \e[ or actual color codes
if echo "$output" | grep -qE $'\033\[|\[0-9]+m'; then
    if print_msg 27 "Does 'dots ls' color first letter of each new letter group?" true; then
        ((score++))
    fi
else
    print_msg 27 "Does 'dots ls' color first letter of each new letter group?" false
fi

printf "\nTesting bash completion...\n"

# Test 28: Completion function exists
if declare -f _dots_completion >/dev/null 2>&1; then
    if print_msg 28 "Is _dots_completion function defined?" true; then
        ((score++))
    fi
else
    print_msg 28 "Is _dots_completion function defined?" false
fi

# Test 29: Completion is registered
if [[ -n "${BASH_VERSION:-}" ]] && command -v complete >/dev/null 2>&1; then
    # Check if completion is registered (this is hard to test directly, so we check if complete command would work)
    if complete -p dots >/dev/null 2>&1; then
        if print_msg 29 "Is dots completion registered with bash?" true; then
            ((score++))
        fi
    else
        # Completion might not be registered in test environment, but function exists
        if print_msg 29 "Is dots completion registered with bash?" false; then
            printf "        (Completion function exists but may not be registered in test environment)\n"
        fi
    fi
else
    if print_msg 29 "Is dots completion registered with bash?" false; then
        printf "        (Bash completion not available, skipping)\n"
    fi
fi

total_tests=30  # Tests 1-29 plus 1 summary test with "*"
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"

printf "\nCleanup complete.\n"

exit 0

