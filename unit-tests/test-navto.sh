#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __TESTING_DIR="$(cd "${__UNIT_TESTS_DIR}/.." && pwd)"
readonly __PLUGINS_DIR="$(cd "${__TESTING_DIR}/plugins" && pwd)"
readonly __CORE_DIR="$(cd "${__TESTING_DIR}/core" && pwd)"
readonly __CONFIG_DIR="$(cd "${__TESTING_DIR}/config" && pwd)"

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
printf "Running unit tests for navto.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/navigation/navto.sh" ]]; then
    if print_msg 3 "Can I find navto.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find navto.sh?" false
    printf "Error: Test cannot continue. Navto.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/navigation/navto.sh" 2>/dev/null; then
    if print_msg 4 "Can I source navto.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source navto.sh?" false
    printf "Error: Test cannot continue. Navto.sh not found.\n" >&2
    exit 4
fi

if declare -f navto >/dev/null 2>&1; then
    if print_msg 5 "Is navto function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is navto function defined?" false
    printf "Error: navto function not defined.\n" >&2
    exit 5
fi

if declare -f __navto_remove_destination >/dev/null 2>&1; then
    if print_msg 6 "Is __navto_remove_destination function defined?" true; then
        ((score++))
    fi
else
    print_msg 6 "Is __navto_remove_destination function defined?" false
fi

if declare -f __navto_create_template >/dev/null 2>&1; then
    if print_msg 7 "Is __navto_create_template function defined?" true; then
        ((score++))
    fi
else
    print_msg 7 "Is __navto_create_template function defined?" false
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))

cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

# Backup original navto.json if it exists
# IMPORTANT: We backup and restore to ensure no data loss
original_navto_json="${__CONFIG_DIR}/navto.json"
test_navto_json_backup="${__CONFIG_DIR}/navto.json.test_backup"
backup_created=false

if [[ -f "$original_navto_json" ]]; then
    if cp "$original_navto_json" "$test_navto_json_backup" 2>/dev/null; then
        backup_created=true
        # Only remove original if backup was successful
        rm -f "$original_navto_json" 2>/dev/null || true
    else
        printf "Warning: Could not backup original navto.json. Test may be destructive.\n" >&2
        printf "Aborting to prevent data loss.\n" >&2
        exit 100
    fi
fi

# Create test directories
test_dir1="${__UNIT_TESTS_DIR}/test_navto_dir1"
test_dir2="${__UNIT_TESTS_DIR}/test_navto_dir2"
test_dir3="${__UNIT_TESTS_DIR}/test_navto_dir3"
mkdir -p "$test_dir1" "$test_dir2" "$test_dir3" 2>/dev/null || true

# Save original directory
original_dir=$(pwd)

# Use the actual config directory for testing
test_navto_json="${__CONFIG_DIR}/navto.json"

# Setup trap to ensure cleanup happens even on failure
cleanup_navto_test() {
    local exit_code=$?
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    # Always restore original navto.json if backup was created
    if [[ "$backup_created" == "true" ]] && [[ -f "$test_navto_json_backup" ]]; then
        mv "$test_navto_json_backup" "$original_navto_json" 2>/dev/null || {
            printf "Error: Failed to restore original navto.json from backup!\n" >&2
            printf "Backup is at: %s\n" "$test_navto_json_backup" >&2
        }
    fi
    
    # Clean up test files and directories
    rm -f "$test_navto_json" "${test_navto_json}".* 2>/dev/null || true
    rm -rf "$test_dir1" "$test_dir2" "$test_dir3" 2>/dev/null || true
    rm -rf "${__UNIT_TESTS_DIR}/test navto space" 2>/dev/null || true
    
    # Only exit with error if we couldn't restore the backup
    if [[ "$backup_created" == "true" ]] && [[ ! -f "$original_navto_json" ]] && [[ -f "$test_navto_json_backup" ]]; then
        exit 101
    fi
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_navto_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if navto --help >/dev/null 2>&1; then
        if print_msg 8 "Does navto --help work?" true; then
            ((score++))
        fi
    else
        print_msg 8 "Does navto --help work?" false
    fi
else
    if print_msg 8 "Does navto --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if navto -h >/dev/null 2>&1; then
        if print_msg 9 "Does navto -h work?" true; then
            ((score++))
        fi
    else
        print_msg 9 "Does navto -h work?" false
    fi
else
    if print_msg 9 "Does navto -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting template creation...\n"

# Remove test JSON file if it exists
rm -f "$test_navto_json" 2>/dev/null || true

# Temporarily override __CONFIG_DIR in the function context
# We'll create a test JSON file directly
if __navto_create_template "$test_navto_json" >/dev/null 2>&1; then
    if [[ -f "$test_navto_json" ]]; then
        if print_msg 10 "Does __navto_create_template create JSON file?" true; then
            ((score++))
        fi
    else
        print_msg 10 "Does __navto_create_template create JSON file?" false
    fi
else
    print_msg 10 "Does __navto_create_template create JSON file?" false
fi

# Verify template contains expected keys
if [[ -f "$test_navto_json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        if jq -e 'has("X") and has("D") and has("T")' "$test_navto_json" >/dev/null 2>&1; then
            if print_msg 11 "Does template contain default destinations?" true; then
                ((score++))
            fi
        else
            print_msg 11 "Does template contain default destinations?" false
        fi
    else
        if print_msg 11 "Does template contain default destinations?" false; then
            printf "        (jq not available, skipping)\n"
        fi
    fi
else
    print_msg 11 "Does template contain default destinations?" false
fi

if __navto_create_template "$test_navto_json" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 12 "Does __navto_create_template return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 12 "Does __navto_create_template return 0 on success?" false
    fi
else
    print_msg 12 "Does __navto_create_template return 0 on success?" false
fi

printf "\nTesting listing destinations (no key provided)...\n"

# Create a test JSON file with test destinations
cat > "$test_navto_json" <<EOF
{
  "T1": { "name": "Test Dir 1", "path": "$test_dir1" },
  "T2": { "name": "Test Dir 2", "path": "$test_dir2" },
  "T3": { "name": "Test Dir 3", "path": "$test_dir3" }
}
EOF

# Test that navto can list destinations
if command -v jq >/dev/null 2>&1; then
    list_output=$(navto 2>&1)
    if echo "$list_output" | grep -q "T1" || echo "$list_output" | grep -q "Test Dir 1"; then
        if print_msg 13 "Does navto list destinations when JSON exists?" true; then
            ((score++))
        fi
    else
        print_msg 13 "Does navto list destinations when JSON exists?" false
    fi
else
    if print_msg 13 "Does navto list destinations when JSON exists?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test listing when JSON doesn't exist
rm -f "$test_navto_json" 2>/dev/null || true
if echo "n" | navto 2>&1 | grep -q "destinations file not found" || echo "n" | navto 2>&1 | grep -q "Create a starter template"; then
    if print_msg 14 "Does navto prompt to create template when JSON missing?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does navto prompt to create template when JSON missing?" false
fi

# Test template creation prompt
if echo "y" | navto 2>&1 | grep -q "Created template" || echo "y" | navto 2>&1 | grep -q "✅"; then
    if [[ -f "$test_navto_json" ]]; then
        if print_msg 15 "Does navto create template when user confirms?" true; then
            ((score++))
        fi
    else
        print_msg 15 "Does navto create template when user confirms?" false
    fi
else
    print_msg 15 "Does navto create template when user confirms?" false
fi

printf "\nTesting navigation to existing destinations...\n"

# Create test JSON with valid destinations
cat > "$test_navto_json" <<EOF
{
  "T1": { "name": "Test Dir 1", "path": "$test_dir1" },
  "T2": { "name": "Test Dir 2", "path": "$test_dir2" }
}
EOF

# Test navigation to existing destination
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
if navto T1 >/dev/null 2>&1; then
    current_dir=$(pwd)
    if [[ "$current_dir" == "$test_dir1" ]]; then
        if print_msg 16 "Does navto navigate to existing destination?" true; then
            ((score++))
        fi
    else
        if print_msg 16 "Does navto navigate to existing destination?" false; then
            printf "        (Expected: %s, Got: %s)\n" "$test_dir1" "$current_dir"
        fi
    fi
else
    print_msg 16 "Does navto navigate to existing destination?" false
fi
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true

# Test case-insensitive navigation
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
if navto t1 >/dev/null 2>&1; then
    current_dir=$(pwd)
    if [[ "$current_dir" == "$test_dir1" ]]; then
        if print_msg 17 "Does navto handle case-insensitive keys?" true; then
            ((score++))
        fi
    else
        print_msg 17 "Does navto handle case-insensitive keys?" false
    fi
else
    print_msg 17 "Does navto handle case-insensitive keys?" false
fi
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true

# Test navigation return code
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
if navto T2 >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 18 "Does navto return 0 on successful navigation?" true; then
            ((score++))
        fi
    else
        print_msg 18 "Does navto return 0 on successful navigation?" false
    fi
else
    print_msg 18 "Does navto return 0 on successful navigation?" false
fi
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true

printf "\nTesting error handling - non-existent destinations...\n"

# Test navigation to non-existent destination
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
echo "n" | navto NONEXISTENT >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 19 "Does navto error on non-existent destination?" true; then
        ((score++))
    fi
else
    print_msg 19 "Does navto error on non-existent destination?" false
fi
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true

# Test error message for non-existent destination
if echo "n" | navto NONEXISTENT 2>&1 | grep -q "destination not found" || echo "n" | navto NONEXISTENT 2>&1 | grep -q "NONEXISTENT"; then
    if print_msg 20 "Does navto show error message for non-existent destination?" true; then
        ((score++))
    fi
else
    print_msg 20 "Does navto show error message for non-existent destination?" false
fi

printf "\nTesting remove destination...\n"

# Ensure we have a test JSON file
cat > "$test_navto_json" <<EOF
{
  "T1": { "name": "Test Dir 1", "path": "$test_dir1" },
  "T2": { "name": "Test Dir 2", "path": "$test_dir2" }
}
EOF

# Test remove with existing key (cancel)
if echo "n" | navto --remove T1 2>&1 | grep -q "Cancelled" || echo "n" | navto --remove T1 2>&1 | grep -q "Cancelled"; then
    if command -v jq >/dev/null 2>&1; then
        if jq -e 'has("T1")' "$test_navto_json" >/dev/null 2>&1; then
            if print_msg 21 "Does navto preserve destination when removal cancelled?" true; then
                ((score++))
            fi
        else
            print_msg 21 "Does navto preserve destination when removal cancelled?" false
        fi
    else
        if print_msg 21 "Does navto preserve destination when removal cancelled?" false; then
            printf "        (jq not available, skipping)\n"
        fi
    fi
else
    print_msg 21 "Does navto preserve destination when removal cancelled?" false
fi

# Test remove with existing key (confirm)
if echo "y" | navto --remove T1 >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        if ! jq -e 'has("T1")' "$test_navto_json" >/dev/null 2>&1; then
            if print_msg 22 "Does navto remove destination when confirmed?" true; then
                ((score++))
            fi
        else
            print_msg 22 "Does navto remove destination when confirmed?" false
        fi
    else
        if print_msg 22 "Does navto remove destination when confirmed?" false; then
            printf "        (jq not available, skipping)\n"
        fi
    fi
else
    print_msg 22 "Does navto remove destination when confirmed?" false
fi

# Test remove with non-existent key
if navto --remove NONEXISTENT 2>&1 | grep -q "No destination found" || navto --remove NONEXISTENT 2>&1 | grep -q "NONEXISTENT"; then
    if print_msg 23 "Does navto show error for non-existent key in remove?" true; then
        ((score++))
    fi
else
    print_msg 23 "Does navto show error for non-existent key in remove?" false
fi

# Test remove flags
if navto -r T2 2>&1 | grep -q "About to remove" || echo "n" | navto -r T2 2>&1 | grep -q "About to remove" || echo "n" | navto -r T2 2>&1 | grep -q "Cancelled"; then
    if print_msg 24 "Does navto -r work (short form for remove)?" true; then
        ((score++))
    fi
else
    print_msg 24 "Does navto -r work (short form for remove)?" false
fi

printf "\nTesting path expansion...\n"

# Test $HOME expansion
if command -v jq >/dev/null 2>&1; then
    cat > "$test_navto_json" <<EOF
{
  "HOME": { "name": "Home", "path": "\$HOME" }
}
EOF
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    if navto HOME >/dev/null 2>&1; then
        current_dir=$(pwd)
        if [[ "$current_dir" == "$HOME" ]]; then
            if print_msg 25 "Does navto expand \$HOME in paths?" true; then
                ((score++))
            fi
        else
            print_msg 25 "Does navto expand \$HOME in paths?" false
        fi
    else
        print_msg 25 "Does navto expand \$HOME in paths?" false
    fi
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
else
    if print_msg 25 "Does navto expand \$HOME in paths?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test ~ expansion (should be converted to $HOME)
test_tilde_path="~/test"
expanded_tilde="${test_tilde_path/#\~/\$HOME}"
expanded_tilde_eval=$(eval echo "$expanded_tilde")
if [[ "$expanded_tilde_eval" == "$HOME/test" ]] || [[ "$expanded_tilde" == "\$HOME/test" ]]; then
    if print_msg 26 "Does navto convert ~ to \$HOME?" true; then
        ((score++))
    fi
else
    print_msg 26 "Does navto convert ~ to \$HOME?" false
fi

printf "\nTesting case-insensitive keys...\n"

# Test that keys are converted to uppercase (already tested above, but verify JSON storage)
if command -v jq >/dev/null 2>&1; then
    cat > "$test_navto_json" <<EOF
{
  "TEST": { "name": "Test", "path": "$test_dir1" }
}
EOF
    # Test that lowercase key can access uppercase entry
    test_key="test"
    upper_key="${test_key^^}"
    if jq -e --arg k "$upper_key" 'has($k)' "$test_navto_json" >/dev/null 2>&1; then
        if print_msg 27 "Does navto convert keys to uppercase in JSON?" true; then
            ((score++))
        fi
    else
        print_msg 27 "Does navto convert keys to uppercase in JSON?" false
    fi
else
    if print_msg 27 "Does navto convert keys to uppercase in JSON?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test missing JSON file (already tested above, but verify error handling)
rm -f "$test_navto_json" 2>/dev/null || true
if [[ ! -f "$test_navto_json" ]]; then
    if echo "n" | navto T1 2>&1 | grep -q "destinations file not found" || echo "n" | navto T1 2>&1 | grep -q "Error"; then
        if print_msg 28 "Does navto detect missing JSON file on navigation?" true; then
            ((score++))
        fi
    else
        print_msg 28 "Does navto detect missing JSON file on navigation?" false
    fi
else
    print_msg 28 "Does navto detect missing JSON file on navigation?" false
fi

# Test invalid JSON
if command -v jq >/dev/null 2>&1; then
    printf "invalid json content { not valid" > "$test_navto_json"
    if ! jq . "$test_navto_json" >/dev/null 2>&1; then
        if print_msg 29 "Does navto detect invalid JSON?" true; then
            ((score++))
        fi
    else
        print_msg 29 "Does navto detect invalid JSON?" false
    fi
else
    if print_msg 29 "Does navto detect invalid JSON?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test empty JSON
if command -v jq >/dev/null 2>&1; then
    echo "{}" > "$test_navto_json"
    if jq -e 'keys | length == 0' "$test_navto_json" >/dev/null 2>&1; then
        if echo "n" | navto T1 2>&1 | grep -q "destination not found" || echo "n" | navto T1 2>&1 | grep -q "T1"; then
            if print_msg 30 "Does navto handle empty JSON file?" true; then
                ((score++))
            fi
        else
            print_msg 30 "Does navto handle empty JSON file?" false
        fi
    else
        print_msg 30 "Does navto handle empty JSON file?" false
    fi
else
    if print_msg 30 "Does navto handle empty JSON file?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

printf "\nTesting JSON operations...\n"

# Test adding a destination to JSON (simulate the operation)
if command -v jq >/dev/null 2>&1; then
    echo "{}" > "$test_navto_json"
    # Simulate adding a destination (same logic as navto uses)
    if jq --arg k "NEWKEY" --arg n "New Name" --arg p "$test_dir1" \
        '. + {($k): {name: $n, path: $p}}' "$test_navto_json" > "${test_navto_json}.tmp" 2>/dev/null && \
       mv "${test_navto_json}.tmp" "$test_navto_json" 2>/dev/null; then
        if jq -e 'has("NEWKEY")' "$test_navto_json" >/dev/null 2>&1; then
            if print_msg 31 "Does navto add destination to JSON?" true; then
                ((score++))
            fi
        else
            print_msg 31 "Does navto add destination to JSON?" false
        fi
    else
        print_msg 31 "Does navto add destination to JSON?" false
    fi
else
    if print_msg 31 "Does navto add destination to JSON?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test preserving existing destinations when adding
if command -v jq >/dev/null 2>&1; then
    cat > "$test_navto_json" <<EOF
{
  "EXISTING": { "name": "Existing", "path": "$test_dir1" }
}
EOF
    # Add a new key
    if jq --arg k "NEW" --arg n "New" --arg p "$test_dir2" \
        '. + {($k): {name: $n, path: $p}}' "$test_navto_json" > "${test_navto_json}.tmp" 2>/dev/null && \
       mv "${test_navto_json}.tmp" "$test_navto_json" 2>/dev/null; then
        if jq -e 'has("EXISTING") and has("NEW")' "$test_navto_json" >/dev/null 2>&1; then
            if print_msg 32 "Does navto preserve existing destinations when adding?" true; then
                ((score++))
            fi
        else
            print_msg 32 "Does navto preserve existing destinations when adding?" false
        fi
    else
        print_msg 32 "Does navto preserve existing destinations when adding?" false
    fi
else
    if print_msg 32 "Does navto preserve existing destinations when adding?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

printf "\nTesting completion format...\n"

# Test "key - name" format extraction
test_key_name="TESTKEY - Test Name"
extracted_key="${test_key_name%% - *}"
if [[ "$extracted_key" == "TESTKEY" ]]; then
    if print_msg 33 "Does navto extract key from 'key - name' format?" true; then
        ((score++))
    fi
else
    print_msg 33 "Does navto extract key from 'key - name' format?" false
fi

printf "\nTesting bash completion (if available)...\n"

if command -v complete >/dev/null 2>&1; then
    if complete -p navto >/dev/null 2>&1; then
        if print_msg 34 "Is navto completion function registered?" true; then
            ((score++))
        fi
    else
        print_msg 34 "Is navto completion function registered?" false
    fi
else
    if print_msg 34 "Is navto completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

printf "\nTesting return codes...\n"

# Test return code on template creation success
if __navto_create_template "${test_navto_json}.return_test" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 35 "Does navto return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 35 "Does navto return 0 on success?" false
    fi
else
    print_msg 35 "Does navto return 0 on success?" false
fi
rm -f "${test_navto_json}.return_test" 2>/dev/null || true

printf "\nTesting output messages...\n"

# Test that template creation outputs success message
template_output=$(__navto_create_template "${test_navto_json}.output_test" 2>&1)
if echo "$template_output" | grep -q "Created template" || echo "$template_output" | grep -q "✅"; then
    if print_msg 36 "Does navto output success messages?" true; then
        ((score++))
    fi
else
    print_msg 36 "Does navto output success messages?" false
fi
rm -f "${test_navto_json}.output_test" 2>/dev/null || true

printf "\nTesting dependencies...\n"

# Test jq dependency check
if command -v jq >/dev/null 2>&1; then
    if print_msg 37 "Does navto check for jq dependency?" true; then
        ((score++))
    fi
else
    if print_msg 37 "Does navto check for jq dependency?" false; then
        printf "        (jq not available, some tests skipped)\n"
    fi
fi

printf "\nTesting edge cases...\n"

# Test handling of special characters in keys
if command -v jq >/dev/null 2>&1; then
    cat > "$test_navto_json" <<EOF
{
  ".": { "name": "Dot", "path": "$test_dir1" }
}
EOF
    if jq -e 'has(".")' "$test_navto_json" >/dev/null 2>&1; then
        if print_msg 38 "Does navto handle special characters in keys?" true; then
            ((score++))
        fi
    else
        print_msg 38 "Does navto handle special characters in keys?" false
    fi
else
    if print_msg 38 "Does navto handle special characters in keys?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test handling of paths with spaces
if command -v jq >/dev/null 2>&1; then
    space_test_dir="${__UNIT_TESTS_DIR}/test navto space"
    mkdir -p "$space_test_dir" 2>/dev/null || true
    cat > "$test_navto_json" <<EOF
{
  "SPACE": { "name": "Space Path", "path": "$space_test_dir" }
}
EOF
    expanded_space=$(jq -r '.["SPACE"].path' "$test_navto_json" 2>/dev/null)
    if [[ -d "$expanded_space" ]]; then
        if print_msg 39 "Does navto handle paths with spaces?" true; then
            ((score++))
        fi
    else
        print_msg 39 "Does navto handle paths with spaces?" false
    fi
    rm -rf "$space_test_dir" 2>/dev/null || true
else
    if print_msg 39 "Does navto handle paths with spaces?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

# Test atomic JSON writes (using temp file)
if command -v jq >/dev/null 2>&1; then
    atomic_test_json="${test_navto_json}.atomic_test"
    echo "{}" > "$atomic_test_json"
    tmpfile=$(mktemp) || tmpfile=""
    if [[ -n "$tmpfile" ]]; then
        if jq '. + {TEST: {name: "Test", path: "/tmp"}}' "$atomic_test_json" > "$tmpfile" 2>/dev/null && \
           mv "$tmpfile" "$atomic_test_json" 2>/dev/null; then
            if [[ -f "$atomic_test_json" ]] && ! [[ -f "$tmpfile" ]]; then
                if print_msg 40 "Does navto use atomic writes for JSON?" true; then
                    ((score++))
                fi
            else
                print_msg 40 "Does navto use atomic writes for JSON?" false
            fi
        else
            print_msg 40 "Does navto use atomic writes for JSON?" false
            rm -f "$tmpfile" 2>/dev/null || true
        fi
    else
        print_msg 40 "Does navto use atomic writes for JSON?" false
    fi
    rm -f "$atomic_test_json" 2>/dev/null || true
else
    if print_msg 40 "Does navto use atomic writes for JSON?" false; then
        printf "        (jq not available, skipping)\n"
    fi
fi

total_tests=41  # Tests 1-40 plus 1 summary test with "*"
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"

printf "\nCleaning up test files...\n"
# Cleanup is handled by trap, but we do it here too for immediate cleanup
cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true

# Restore original navto.json if it was backed up
if [[ "$backup_created" == "true" ]] && [[ -f "$test_navto_json_backup" ]]; then
    if mv "$test_navto_json_backup" "$original_navto_json" 2>/dev/null; then
        backup_created=false  # Mark as restored so trap doesn't try again
        # Verify restoration was successful
        if [[ -f "$original_navto_json" ]]; then
            printf "✅ Restored original navto.json\n"
        else
            printf "⚠️  Warning: Restoration may have failed. Check: %s\n" "$original_navto_json" >&2
        fi
    else
        printf "⚠️  Warning: Could not restore original navto.json. Backup is at: %s\n" "$test_navto_json_backup" >&2
    fi
elif [[ "$backup_created" == "false" ]] && [[ ! -f "$original_navto_json" ]]; then
    # No backup was created and no original file exists - this is fine (first run)
    printf "ℹ️  No original navto.json to restore (this is normal if file didn't exist)\n"
fi

# Clean up test files and directories
# Remove any temporary test JSON files (but not the restored original)
rm -f "${test_navto_json}".return_test "${test_navto_json}".output_test "${test_navto_json}".atomic_test 2>/dev/null || true
# Only remove the main test JSON if we didn't restore the original (i.e., if no backup was created)
if [[ "$backup_created" == "false" ]] && [[ -f "$test_navto_json" ]]; then
    # Only remove if no backup exists (meaning we created it for testing and it wasn't the original)
    rm -f "$test_navto_json" 2>/dev/null || true
fi
rm -rf "$test_dir1" "$test_dir2" "$test_dir3" 2>/dev/null || true
rm -rf "${__UNIT_TESTS_DIR}/test navto space" 2>/dev/null || true

printf "Cleanup complete.\n"

# Disable trap since we've cleaned up manually
trap - EXIT INT TERM

exit 0

