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
printf "Running unit tests for backup.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/backup.sh" ]]; then
    if print_msg 3 "Can I find backup.sh?" true; then
        ((score++))
    fi
else
    print_msg 3 "Can I find backup.sh?" false
    printf "Error: Test cannot continue. Backup.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/backup.sh" 2>/dev/null; then
    if print_msg 4 "Can I source backup.sh?" true; then
        ((score++))
    fi
else
    print_msg 4 "Can I source backup.sh?" false
    printf "Error: Test cannot continue. Backup.sh not found.\n" >&2
    exit 4
fi

if declare -f backup >/dev/null 2>&1; then
    if print_msg 5 "Is backup function defined?" true; then
        ((score++))
    fi
else
    print_msg 5 "Is backup function defined?" false
    printf "Error: backup function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))

cd "${__UNIT_TESTS_DIR}" || {
    printf "Error: Failed to change directory to unit-tests.\n" >&2
    exit 91
}

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if backup --help >/dev/null 2>&1; then
        if print_msg 6 "Does backup --help work?" true; then
            ((score++))
        fi
    else
        print_msg 6 "Does backup --help work?" false
    fi
else
    if print_msg 6 "Does backup --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if backup -h >/dev/null 2>&1; then
        if print_msg 7 "Does backup -h work?" true; then
            ((score++))
        fi
    else
        print_msg 7 "Does backup -h work?" false
    fi
else
    if print_msg 7 "Does backup -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nCreating test files...\n"
test_content="This is a test file for backup.\nLine 2 of test file.\nEnd of test file.\n"

if printf "${test_content}" > "${__UNIT_TESTS_DIR}/test_backup_file.txt"; then
    if print_msg 8 "Can I create test_backup_file.txt?" true; then
        ((score++))
    fi
else
    print_msg 8 "Can I create test_backup_file.txt?" false
    printf "Error: Test cannot continue. Failed to create test_backup_file.txt.\n" >&2
    exit 8
fi

print_msg "*" "Did I create test files?" true
((score++))

printf "\nTesting error handling...\n"

if ! backup "nonexistent.txt" 2>/dev/null; then
    if print_msg 9 "Does backup error on non-existent file?" true; then
        ((score++))
    fi
else
    print_msg 9 "Does backup error on non-existent file?" false
fi

if backup "nonexistent.txt" 2>&1 | grep -q "Error:"; then
    if print_msg 10 "Does backup output error message?" true; then
        ((score++))
    fi
else
    print_msg 10 "Does backup output error message?" false
fi

if ! backup --unknown-flag 2>/dev/null; then
    if print_msg 11 "Does backup error on unknown option?" true; then
        ((score++))
    fi
else
    print_msg 11 "Does backup error on unknown option?" false
fi

printf "\nTesting basic file backup...\n"

if backup "test_backup_file.txt" >/dev/null 2>&1; then
    backup_file=$(ls -1 test_backup_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 12 "Does backup create .bak.* file?" true; then
            ((score++))
        fi
    else
        print_msg 12 "Does backup create .bak.* file?" false
    fi
    rm -f test_backup_file.txt.bak.* 2>/dev/null || true
else
    print_msg 12 "Does backup create .bak.* file?" false
fi

if backup "test_backup_file.txt" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 13 "Does backup return 0 on success?" true; then
            ((score++))
        fi
    else
        print_msg 13 "Does backup return 0 on success?" false
    fi
    rm -f test_backup_file.txt.bak.* 2>/dev/null || true
else
    print_msg 13 "Does backup return 0 on success?" false
fi

if backup "test_backup_file.txt" 2>&1 | grep -q "Backup created"; then
    if print_msg 14 "Does backup output success message?" true; then
        ((score++))
    fi
else
    print_msg 14 "Does backup output success message?" false
fi
rm -f test_backup_file.txt.bak.* 2>/dev/null || true

backup "test_backup_file.txt" >/dev/null 2>&1
backup_file=$(ls -1 test_backup_file.txt.bak.* 2>/dev/null | head -1)
if [[ -n "$backup_file" ]]; then
    original_content="$(cat test_backup_file.txt)"
    backup_content="$(cat "$backup_file")"
    if [[ "$original_content" == "$backup_content" ]]; then
        if print_msg 15 "Does backup preserve file content?" true; then
            ((score++))
        fi
    else
        print_msg 15 "Does backup preserve file content?" false
    fi
    rm -f "$backup_file" 2>/dev/null || true
else
    print_msg 15 "Does backup preserve file content?" false
fi

printf "\nTesting --store flag...\n"

if [[ -d "${HOME}/Documents/BAK" ]] || mkdir -p "${HOME}/Documents/BAK" 2>/dev/null; then
    if backup --store "test_backup_file.txt" >/dev/null 2>&1; then
        backup_file=$(ls -1 "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* 2>/dev/null | head -1)
        if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
            if print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" true; then
                ((score++))
            fi
        else
            print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false
        fi
        rm -f "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* 2>/dev/null || true
    else
        print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false
    fi
else
    if print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false; then
        printf "        (Cannot create ~/Documents/BAK, skipping)\n"
    fi
fi

if backup -s "test_backup_file.txt" >/dev/null 2>&1; then
    backup_file=$(ls -1 "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" true; then
            ((score++))
        fi
    else
        print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" false
    fi
    rm -f "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* 2>/dev/null || true
else
    print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" false
fi

printf "\nTesting directory backup...\n"

mkdir -p "test_backup_dir"
printf "content1" > "test_backup_dir/file1.txt"
printf "content2" > "test_backup_dir/file2.txt"

if backup --directory >/dev/null 2>&1; then
    backup_dir=$(ls -1d *.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        # backup --directory backs up the current directory, so test_backup_dir should be a subdirectory
        if [[ -f "$backup_dir/test_backup_dir/file1.txt" ]] && [[ -f "$backup_dir/test_backup_dir/file2.txt" ]]; then
            if print_msg 18 "Does backup --directory create directory backup?" true; then
                ((score++))
            fi
        else
            print_msg 18 "Does backup --directory create directory backup?" false
        fi
    else
        print_msg 18 "Does backup --directory create directory backup?" false
    fi
    rm -rf *.bak.* 2>/dev/null || true
else
    print_msg 18 "Does backup --directory create directory backup?" false
fi
rm -rf "test_backup_dir" 2>/dev/null || true

if backup -d >/dev/null 2>&1; then
    backup_dir=$(ls -1d *.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        if print_msg 19 "Does backup -d create directory backup?" true; then
            ((score++))
        fi
    else
        print_msg 19 "Does backup -d create directory backup?" false
    fi
    rm -rf *.bak.* 2>/dev/null || true
else
    print_msg 19 "Does backup -d create directory backup?" false
fi

if backup --dir >/dev/null 2>&1; then
    backup_dir=$(ls -1d *.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        if print_msg 20 "Does backup --dir create directory backup?" true; then
            ((score++))
        fi
    else
        print_msg 20 "Does backup --dir create directory backup?" false
    fi
    rm -rf *.bak.* 2>/dev/null || true
else
    print_msg 20 "Does backup --dir create directory backup?" false
fi

printf "\nTesting directory backup with --store...\n"

if [[ -d "${HOME}/Documents/BAK" ]] || mkdir -p "${HOME}/Documents/BAK" 2>/dev/null; then
    original_dir=$(basename "$(pwd)")
    if backup --directory --store >/dev/null 2>&1; then
        backup_dir=$(ls -1d "${HOME}/Documents/BAK"/${original_dir}.bak.* 2>/dev/null | head -1)
        if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
            if print_msg 21 "Does backup --directory --store create backup in ~/Documents/BAK?" true; then
                ((score++))
            fi
        else
            print_msg 21 "Does backup --directory --store create backup in ~/Documents/BAK?" false
        fi
        rm -rf "${HOME}/Documents/BAK"/${original_dir}.bak.* 2>/dev/null || true
    else
        print_msg 21 "Does backup --directory --store create backup in ~/Documents/BAK?" false
    fi
else
    if print_msg 21 "Does backup --directory --store create backup in ~/Documents/BAK?" false; then
        printf "        (Cannot create ~/Documents/BAK, skipping)\n"
    fi
fi

printf "\nTesting multiple backups...\n"

backup "test_backup_file.txt" >/dev/null 2>&1
sleep 1
backup "test_backup_file.txt" >/dev/null 2>&1
backup_count=$(ls -1 test_backup_file.txt.bak.* 2>/dev/null | wc -l)
if [[ $backup_count -ge 2 ]]; then
    if print_msg 22 "Does backup create multiple backups?" true; then
        ((score++))
    fi
else
    print_msg 22 "Does backup create multiple backups?" false
fi
rm -f test_backup_file.txt.bak.* 2>/dev/null || true

printf "\nTesting return codes...\n"

backup "nonexistent.txt" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 23 "Does backup return non-zero on error?" true; then
        ((score++))
    fi
else
    print_msg 23 "Does backup return non-zero on error?" false
fi

printf "\nTesting edge cases...\n"

printf "test with spaces" > "test file with spaces.txt"
if backup "test file with spaces.txt" >/dev/null 2>&1; then
    backup_file=$(find . -maxdepth 1 -name "test file with spaces.txt.bak.*" -print0 | xargs -0 | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 24 "Does backup work with filenames containing spaces?" true; then
            ((score++))
        fi
    else
        print_msg 24 "Does backup work with filenames containing spaces?" false
    fi
    rm -f "test file with spaces.txt"* 2>/dev/null || true
else
    print_msg 24 "Does backup work with filenames containing spaces?" false
    rm -f "test file with spaces.txt"* 2>/dev/null || true
fi

printf "" > "empty_file.txt"
if backup "empty_file.txt" >/dev/null 2>&1; then
    backup_file=$(ls -1 empty_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if [[ ! -s "$backup_file" ]]; then
            if print_msg 25 "Does backup work with empty files?" true; then
                ((score++))
            fi
        else
            print_msg 25 "Does backup work with empty files?" false
        fi
    else
        print_msg 25 "Does backup work with empty files?" false
    fi
    rm -f empty_file.txt empty_file.txt.bak.* 2>/dev/null || true
else
    print_msg 25 "Does backup work with empty files?" false
    rm -f empty_file.txt empty_file.txt.bak.* 2>/dev/null || true
fi

mkdir -p "empty_test"
cd "empty_test" || exit 91
if backup --directory >/dev/null 2>&1; then
    backup_dir=$(ls -1d *.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        if print_msg 26 "Does backup work with empty directories?" true; then
            ((score++))
        fi
    else
        print_msg 26 "Does backup work with empty directories?" false
    fi
    rm -rf *.bak.* 2>/dev/null || true
else
    print_msg 26 "Does backup work with empty directories?" false
fi
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -rf "empty_test" 2>/dev/null || true

printf "\nTesting bash completion (if available)...\n"

if command -v complete >/dev/null 2>&1; then
    if complete -p backup >/dev/null 2>&1; then
        if print_msg 27 "Is backup completion function registered?" true; then
            ((score++))
        fi
    else
        print_msg 27 "Is backup completion function registered?" false
    fi
else
    if print_msg 27 "Is backup completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

printf "\nTesting output messages...\n"

output=$(backup "test_backup_file.txt" 2>&1)
if echo "$output" | grep -q "Backup created"; then
    if print_msg 28 "Does backup output success message?" true; then
        ((score++))
    fi
else
    print_msg 28 "Does backup output success message?" false
fi
rm -f test_backup_file.txt.bak.* 2>/dev/null || true

error_output=$(backup "nonexistent.txt" 2>&1)
if echo "$error_output" | grep -q "Error:"; then
    if print_msg 29 "Does backup output error message?" true; then
        ((score++))
    fi
else
    print_msg 29 "Does backup output error message?" false
fi

if backup --store "test_backup_file.txt" 2>&1 | grep -q "Backup created at.*Documents/BAK"; then
    if print_msg 30 "Does backup output store location in message?" true; then
        ((score++))
    fi
else
    print_msg 30 "Does backup output store location in message?" false
fi
rm -f "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* 2>/dev/null || true

if backup --directory 2>&1 | grep -q "Backup created"; then
    if print_msg 31 "Does backup output directory backup message?" true; then
        ((score++))
    fi
else
    print_msg 31 "Does backup output directory backup message?" false
fi
rm -rf *.bak.* 2>/dev/null || true

total_tests=33  # Tests 1-31 plus 2 summary tests with "*"
percentage=$((score * 100 / total_tests))

printf "\n"
printf "========================================\n"
printf "Test Results Summary\n"
printf "========================================\n"
printf "Tests Passed: %d / %d\n" "$score" "$total_tests"
printf "Percentage: %d%%\n" "$percentage"
printf "========================================\n"

printf "\nCleaning up test files...\n"
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -f test_backup_file.txt test_backup_file.txt.bak.* 2>/dev/null || true
rm -f "test file with spaces.txt"* empty_file.txt empty_file.txt.bak.* 2>/dev/null || true
rm -rf *.bak.* empty_test 2>/dev/null || true
rm -rf "${HOME}/Documents/BAK"/test_backup_file.txt.bak.* "${HOME}/Documents/BAK"/*.bak.* 2>/dev/null || true
printf "Cleanup complete.\n"

exit 0
