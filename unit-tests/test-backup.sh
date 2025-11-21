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
total_tests=33  # Tests 1-31 plus 2 summary tests with "*"
printf "Running unit tests for backup.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/file-operations/backup.sh" ]]; then
    if print_msg 3 "Can I find backup.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find backup.sh?" false
    printf "Error: Test cannot continue. Backup.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/file-operations/backup.sh" 2>/dev/null; then
    if print_msg 4 "Can I source backup.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source backup.sh?" false
    printf "Error: Test cannot continue. Backup.sh not found.\n" >&2
    exit 4
fi

if declare -f backup >/dev/null 2>&1; then
    if print_msg 5 "Is backup function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is backup function defined?" false
    printf "Error: backup function not defined.\n" >&2
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

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_backup_$$"
readonly TEST_BACKUP_DIR="${TEST_PREFIX}_dir"

# Clean up any leftover backup directories from previous test runs (older than 10 minutes)
# This helps prevent interference in parallel mode
original_dir=$(basename "${__UNIT_TESTS_DIR}")
current_time=$(date +%s)
shopt -s nullglob
for bak_dir in "${original_dir}".bak.*; do
    if [[ -d "$bak_dir" ]]; then
        file_time=$(stat -c %Y "$bak_dir" 2>/dev/null || echo 0)
        time_diff=$((current_time - file_time))
        # Remove if older than 10 minutes (600 seconds) - old leftover from previous runs
        if [[ $time_diff -gt 600 ]]; then
            rm -rf "$bak_dir" 2>/dev/null || true
        fi
    fi
done
shopt -u nullglob

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if backup --help >/dev/null 2>&1; then
        if print_msg 6 "Does backup --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
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
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
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

if printf "${test_content}" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file.txt"; then
    if print_msg 8 "Can I create ${TEST_PREFIX}_file.txt?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 8 "Can I create ${TEST_PREFIX}_file.txt?" false
    printf "Error: Test cannot continue. Failed to create ${TEST_PREFIX}_file.txt.\n" >&2
    exit 8
fi

print_msg "*" "Did I create test files?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

printf "\nTesting error handling...\n"

if ! backup "nonexistent.txt" 2>/dev/null; then
    if print_msg 9 "Does backup error on non-existent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 9 "Does backup error on non-existent file?" false
fi

if backup "nonexistent.txt" 2>&1 | grep -q "Error:"; then
    if print_msg 10 "Does backup output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does backup output error message?" false
fi

if ! backup --unknown-flag 2>/dev/null; then
    if print_msg 11 "Does backup error on unknown option?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does backup error on unknown option?" false
fi

printf "\nTesting basic file backup...\n"

if backup "${TEST_PREFIX}_file.txt" >/dev/null 2>&1; then
    backup_file=$(ls -1 ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 12 "Does backup create .bak.* file?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 12 "Does backup create .bak.* file?" false
    fi
    rm -f ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true
else
    print_msg 12 "Does backup create .bak.* file?" false
fi

if backup "${TEST_PREFIX}_file.txt" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 13 "Does backup return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 13 "Does backup return 0 on success?" false
    fi
    rm -f ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true
else
    print_msg 13 "Does backup return 0 on success?" false
fi

if backup "${TEST_PREFIX}_file.txt" 2>&1 | grep -q "Backup created"; then
    if print_msg 14 "Does backup output success message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does backup output success message?" false
fi
rm -f ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true

backup "${TEST_PREFIX}_file.txt" >/dev/null 2>&1
backup_file=$(ls -1 ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null | head -1)
if [[ -n "$backup_file" ]]; then
    original_content="$(cat ${TEST_PREFIX}_file.txt)"
    backup_content="$(cat "$backup_file")"
    if [[ "$original_content" == "$backup_content" ]]; then
        if print_msg 15 "Does backup preserve file content?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
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
    if backup --store "${TEST_PREFIX}_file.txt" >/dev/null 2>&1; then
        backup_file=$(ls -1 "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null | head -1)
        if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
            if print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false
        fi
        rm -f "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true
    else
        print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false
    fi
else
    if print_msg 16 "Does backup --store create backup in ~/Documents/BAK?" false; then
        printf "        (Cannot create ~/Documents/BAK, skipping)\n"
    fi
fi

if backup -s "${TEST_PREFIX}_file.txt" >/dev/null 2>&1; then
    backup_file=$(ls -1 "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" false
    fi
    rm -f "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true
else
    print_msg 17 "Does backup -s create backup in ~/Documents/BAK?" false
fi

printf "\nTesting directory backup...\n"

mkdir -p "${TEST_BACKUP_DIR}"
printf "content1" > "${TEST_BACKUP_DIR}/file1.txt"
printf "content2" > "${TEST_BACKUP_DIR}/file2.txt"

# Get list of existing backup directories before creating new one
existing_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
backup_output=$(backup --directory 2>&1)
backup_exit_code=$?
if [[ $backup_exit_code -eq 0 ]]; then
    # Extract backup directory path from output: "Backup created at /path/to/backup"
    backup_dir=$(echo "$backup_output" | sed -n 's/.*Backup created at \(.*\)/\1/p')
    # If extraction failed, find the new backup directory by comparing before/after
    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        current_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
        # Find the difference - the new backup directory
        backup_dir=$(comm -13 <(echo "$existing_baks" || echo "") <(echo "$current_baks" || echo "") | head -1 | xargs)
    fi
    # Extract just the basename if full path was extracted
    backup_dir_basename=$(basename "$backup_dir" 2>/dev/null || echo "$backup_dir")
    if [[ -n "$backup_dir_basename" ]] && [[ -d "$backup_dir_basename" ]]; then
        # backup --directory backs up the current directory, so ${TEST_BACKUP_DIR} should be a subdirectory
        if [[ -f "$backup_dir_basename/${TEST_BACKUP_DIR}/file1.txt" ]] && [[ -f "$backup_dir_basename/${TEST_BACKUP_DIR}/file2.txt" ]]; then
            if print_msg 18 "Does backup --directory create directory backup?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 18 "Does backup --directory create directory backup?" false
        fi
        # Remove the specific backup directory we created
        rm -rf "$backup_dir_basename" 2>/dev/null || true
    else
        print_msg 18 "Does backup --directory create directory backup?" false
    fi
else
    print_msg 18 "Does backup --directory create directory backup?" false
fi
rm -rf "${TEST_BACKUP_DIR}" 2>/dev/null || true

existing_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
backup_output=$(backup -d 2>&1)
backup_exit_code=$?
if [[ $backup_exit_code -eq 0 ]]; then
    # Extract backup directory path from output
    backup_dir=$(echo "$backup_output" | sed -n 's/.*Backup created at \(.*\)/\1/p')
    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        current_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
        backup_dir=$(comm -13 <(echo "$existing_baks" || echo "") <(echo "$current_baks" || echo "") | head -1 | xargs)
    fi
    backup_dir_basename=$(basename "$backup_dir" 2>/dev/null || echo "$backup_dir")
    if [[ -n "$backup_dir_basename" ]] && [[ -d "$backup_dir_basename" ]]; then
        if print_msg 19 "Does backup -d create directory backup?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
        rm -rf "$backup_dir_basename" 2>/dev/null || true
    else
        print_msg 19 "Does backup -d create directory backup?" false
    fi
else
    print_msg 19 "Does backup -d create directory backup?" false
fi

existing_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
backup_output=$(backup --dir 2>&1)
backup_exit_code=$?
if [[ $backup_exit_code -eq 0 ]]; then
    # Extract backup directory path from output
    backup_dir=$(echo "$backup_output" | sed -n 's/.*Backup created at \(.*\)/\1/p')
    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        current_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
        backup_dir=$(comm -13 <(echo "$existing_baks" || echo "") <(echo "$current_baks" || echo "") | head -1 | xargs)
    fi
    backup_dir_basename=$(basename "$backup_dir" 2>/dev/null || echo "$backup_dir")
    if [[ -n "$backup_dir_basename" ]] && [[ -d "$backup_dir_basename" ]]; then
        if print_msg 20 "Does backup --dir create directory backup?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
        rm -rf "$backup_dir_basename" 2>/dev/null || true
    else
        print_msg 20 "Does backup --dir create directory backup?" false
    fi
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
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
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

backup "${TEST_PREFIX}_file.txt" >/dev/null 2>&1
sleep 1
backup "${TEST_PREFIX}_file.txt" >/dev/null 2>&1
backup_count=$(ls -1 ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null | wc -l)
if [[ $backup_count -ge 2 ]]; then
    if print_msg 22 "Does backup create multiple backups?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does backup create multiple backups?" false
fi
rm -f ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true

printf "\nTesting return codes...\n"

backup "nonexistent.txt" >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 23 "Does backup return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does backup return non-zero on error?" false
fi

printf "\nTesting edge cases...\n"

test_file_with_spaces="${TEST_PREFIX}_test file with spaces.txt"
printf "test with spaces" > "$test_file_with_spaces"
if backup "$test_file_with_spaces" >/dev/null 2>&1; then
    backup_file=$(find . -maxdepth 1 -name "${TEST_PREFIX}_test file with spaces.txt.bak.*" -print0 | xargs -0 | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if print_msg 24 "Does backup work with filenames containing spaces?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 24 "Does backup work with filenames containing spaces?" false
    fi
    rm -f "${TEST_PREFIX}_test file with spaces.txt"* 2>/dev/null || true
else
    print_msg 24 "Does backup work with filenames containing spaces?" false
    rm -f "${TEST_PREFIX}_test file with spaces.txt"* 2>/dev/null || true
fi

empty_test_file="${TEST_PREFIX}_empty_file.txt"
printf "" > "$empty_test_file"
if backup "$empty_test_file" >/dev/null 2>&1; then
    backup_file=$(ls -1 ${TEST_PREFIX}_empty_file.txt.bak.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        if [[ ! -s "$backup_file" ]]; then
            if print_msg 25 "Does backup work with empty files?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 25 "Does backup work with empty files?" false
        fi
    else
        print_msg 25 "Does backup work with empty files?" false
    fi
    rm -f ${TEST_PREFIX}_empty_file.txt ${TEST_PREFIX}_empty_file.txt.bak.* 2>/dev/null || true
else
    print_msg 25 "Does backup work with empty files?" false
    rm -f ${TEST_PREFIX}_empty_file.txt ${TEST_PREFIX}_empty_file.txt.bak.* 2>/dev/null || true
fi

mkdir -p "${TEST_PREFIX}_empty_test"
cd "${TEST_PREFIX}_empty_test" || exit 91
existing_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
backup_output=$(backup --directory 2>&1)
backup_exit_code=$?
if [[ $backup_exit_code -eq 0 ]]; then
    # Extract backup directory path from output
    backup_dir=$(echo "$backup_output" | sed -n 's/.*Backup created at \(.*\)/\1/p')
    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        current_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
        backup_dir=$(comm -13 <(echo "$existing_baks" || echo "") <(echo "$current_baks" || echo "") | head -1 | xargs)
    fi
    backup_dir_basename=$(basename "$backup_dir" 2>/dev/null || echo "$backup_dir")
    if [[ -n "$backup_dir_basename" ]] && [[ -d "$backup_dir_basename" ]]; then
        if print_msg 26 "Does backup work with empty directories?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
        rm -rf "$backup_dir_basename" 2>/dev/null || true
    else
        print_msg 26 "Does backup work with empty directories?" false
    fi
else
    print_msg 26 "Does backup work with empty directories?" false
fi
cd "${__UNIT_TESTS_DIR}" || exit 91
rm -rf "${TEST_PREFIX}_empty_test" 2>/dev/null || true

printf "\nTesting bash completion (if available)...\n"

if command -v complete >/dev/null 2>&1; then
    if complete -p backup >/dev/null 2>&1; then
        if print_msg 27 "Is backup completion function registered?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
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

output=$(backup "${TEST_PREFIX}_file.txt" 2>&1)
if echo "$output" | grep -q "Backup created"; then
    if print_msg 28 "Does backup output success message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does backup output success message?" false
fi
rm -f ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true

error_output=$(backup "nonexistent.txt" 2>&1)
if echo "$error_output" | grep -q "Error:"; then
    if print_msg 29 "Does backup output error message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does backup output error message?" false
fi

if backup --store "${TEST_PREFIX}_file.txt" 2>&1 | grep -q "Backup created at.*Documents/BAK"; then
    if print_msg 30 "Does backup output store location in message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does backup output store location in message?" false
fi
rm -f "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true

existing_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
backup_output=$(backup --directory 2>&1)
backup_exit_code=$?
if echo "$backup_output" | grep -q "Backup created"; then
    if print_msg 31 "Does backup output directory backup message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    # Extract and remove the specific backup directory we created
    backup_dir=$(echo "$backup_output" | sed -n 's/.*Backup created at \(.*\)/\1/p')
    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        current_baks=$(ls -1d *.bak.* 2>/dev/null | sort || true)
        backup_dir=$(comm -13 <(echo "$existing_baks" || echo "") <(echo "$current_baks" || echo "") | head -1 | xargs)
    fi
    backup_dir_basename=$(basename "$backup_dir" 2>/dev/null || echo "$backup_dir")
    [[ -n "$backup_dir_basename" ]] && [[ -d "$backup_dir_basename" ]] && rm -rf "$backup_dir_basename" 2>/dev/null || true
else
    print_msg 31 "Does backup output directory backup message?" false
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

printf "\nCleaning up test files...\n"
cd "${__UNIT_TESTS_DIR}" || exit 91

# Clean up test-specific files
rm -f ${TEST_PREFIX}_file.txt ${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true
rm -f "${TEST_PREFIX}_test file with spaces.txt"* "${TEST_PREFIX}_empty_file.txt" "${TEST_PREFIX}_empty_file.txt.bak.*" 2>/dev/null || true
rm -rf "${TEST_PREFIX}_empty_test" 2>/dev/null || true
rm -rf "${TEST_BACKUP_DIR}" 2>/dev/null || true

# Clean up file backups in ~/Documents/BAK
rm -rf "${HOME}/Documents/BAK"/${TEST_PREFIX}_file.txt.bak.* 2>/dev/null || true

# Clean up directory backups in ~/Documents/BAK (only those created during this test run)
# We track backup directories by checking their modification time (within last 5 minutes to be safe)
if [[ -d "${HOME}/Documents/BAK" ]]; then
    original_dir=$(basename "${__UNIT_TESTS_DIR}")
    current_time=$(date +%s)
    # Remove directory backups that were created during this test run (within last 5 minutes)
    for bak_dir in "${HOME}/Documents/BAK"/${original_dir}.bak.*; do
        if [[ -d "$bak_dir" ]]; then
            file_time=$(stat -c %Y "$bak_dir" 2>/dev/null || echo 0)
            time_diff=$((current_time - file_time))
            # Remove if created within last 5 minutes (300 seconds) - should cover entire test duration
            if [[ $time_diff -le 300 ]]; then
                rm -rf "$bak_dir" 2>/dev/null || true
            fi
        fi
    done 2>/dev/null || true
fi

# Clean up directory backups in current directory (unit-tests.bak.*)
# Only remove those created during this test run (within last 5 minutes)
original_dir=$(basename "${__UNIT_TESTS_DIR}")
current_time=$(date +%s)
shopt -s nullglob
for bak_dir in "${original_dir}".bak.*; do
    if [[ -d "$bak_dir" ]]; then
        file_time=$(stat -c %Y "$bak_dir" 2>/dev/null || echo 0)
        time_diff=$((current_time - file_time))
        # Remove if created within last 5 minutes (300 seconds) - should cover entire test duration
        if [[ $time_diff -le 300 ]]; then
            rm -rf "$bak_dir" 2>/dev/null || true
        fi
    fi
done
shopt -u nullglob

printf "Cleanup complete.\n"

exit 0
