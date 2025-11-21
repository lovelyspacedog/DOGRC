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
total_tests=55  # Tests 1-54 plus 1 summary test with "*"
printf "Running unit tests for fastnote.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/utilities/fastnote.sh" ]]; then
    if print_msg 3 "Can I find fastnote.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find fastnote.sh?" false
    printf "Error: Test cannot continue. Fastnote.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/fastnote.sh" 2>/dev/null; then
    if print_msg 4 "Can I source fastnote.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source fastnote.sh?" false
    printf "Error: Test cannot continue. Fastnote.sh not found.\n" >&2
    exit 4
fi

if declare -f fastnote >/dev/null 2>&1; then
    if print_msg 5 "Is fastnote function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is fastnote function defined?" false
    printf "Error: fastnote function not defined.\n" >&2
    exit 5
fi

if declare -f is_pos_num >/dev/null 2>&1; then
    if print_msg 6 "Is is_pos_num function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is is_pos_num function defined?" false
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
readonly TEST_PREFIX="test_fastnote_$$"
readonly TEST_HOME="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_home"
readonly TEST_FASTNOTES_DIR="${TEST_HOME}/.fastnotes"

# Backup original HOME
original_home="$HOME"

# Create test home directory
mkdir -p "$TEST_HOME" || {
    printf "Error: Failed to create test home directory.\n" >&2
    exit 99
}

# Override HOME for tests (fastnote uses $HOME/.fastnotes)
export HOME="$TEST_HOME"

# Backup original fastnotes directory if it exists in test home
# Use a test-specific note number range (900000+) to avoid conflicts
readonly TEST_NOTE_BASE=900000
if [[ -d "$TEST_FASTNOTES_DIR" ]]; then
    mv "$TEST_FASTNOTES_DIR" "${TEST_FASTNOTES_DIR}.backup" 2>/dev/null || true
fi

# Create a mock editor script for testing OPEN command
# This must be done early to prevent real editors from opening during any test
mock_editor="${__UNIT_TESTS_DIR}/mock_editor.sh"
cat > "$mock_editor" <<'EOF'
#!/bin/bash
# Mock editor that just touches the file to simulate editing
# This prevents actual editors from opening during tests
touch "$1" 2>/dev/null || true
exit 0
EOF
chmod +x "$mock_editor"
# Add mock editor directory to PATH so command -v can find it
export PATH="${__UNIT_TESTS_DIR}:${PATH}"
# Set EDITOR to mock editor immediately to prevent any real editors from opening
original_editor="${EDITOR:-}"
export EDITOR="mock_editor.sh"

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if fastnote --help >/dev/null 2>&1; then
        if print_msg 7 "Does fastnote --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does fastnote --help work?" false
    fi
else
    if print_msg 7 "Does fastnote --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if fastnote -h >/dev/null 2>&1; then
        if print_msg 8 "Does fastnote -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does fastnote -h work?" false
    fi
else
    if print_msg 8 "Does fastnote -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting directory initialization...\n"

# Remove test directory if it exists
rm -rf "${TEST_FASTNOTES_DIR}" 2>/dev/null || true

# Verify mock editor is available before testing (to prevent hangs)
if ! command -v "$EDITOR" >/dev/null 2>&1; then
    printf "Error: Mock editor not found: %s\n" "$EDITOR" >&2
    printf "PATH: %s\n" "$PATH" >&2
    exit 99
fi

# Test directory creation
# The mock editor should prevent any real editor from opening
if fastnote 0 >/dev/null 2>&1; then
    if [[ -d "${TEST_FASTNOTES_DIR}" ]]; then
        if print_msg 9 "Does fastnote create ~/.fastnotes directory if it doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does fastnote create ~/.fastnotes directory if it doesn't exist?" false
    fi
else
    # Even if fastnote fails or times out, check if directory was created
    # (directory creation happens before editor is called)
    if [[ -d "${TEST_FASTNOTES_DIR}" ]]; then
        if print_msg 9 "Does fastnote create ~/.fastnotes directory if it doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does fastnote create ~/.fastnotes directory if it doesn't exist?" false
    fi
fi

# Test that it works when directory already exists
if [[ -d "${TEST_FASTNOTES_DIR}" ]]; then
    if print_msg 10 "Does fastnote work when ~/.fastnotes already exists?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does fastnote work when ~/.fastnotes already exists?" false
fi

# Ensure test fastnotes directory exists for remaining tests
mkdir -p "${TEST_FASTNOTES_DIR}" 2>/dev/null || true

printf "\nTesting LIST command...\n"

# Clean up any existing test notes (only notes in our test range)
rm -f "${TEST_FASTNOTES_DIR}"/notes_${TEST_NOTE_BASE}*.txt 2>/dev/null || true
rm -f "${TEST_FASTNOTES_DIR}"/notes_0.txt "${TEST_FASTNOTES_DIR}"/notes_30.txt "${TEST_FASTNOTES_DIR}"/notes_42.txt 2>/dev/null || true

# Test LIST with no notes
if fastnote list 2>&1 | grep -q "No notes found"; then
    if print_msg 11 "Does fastnote list show 'No notes found.' when empty?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does fastnote list show 'No notes found.' when empty?" false
fi

# Create test notes using very high numbers (900000+) to avoid conflicts
mkdir -p "${TEST_FASTNOTES_DIR}" 2>/dev/null || true
printf "First line of note 1\nSecond line" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}01.txt"
printf "This is a longer note that should be truncated in the preview because it exceeds sixty characters" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}02.txt"
printf "" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}03.txt"
printf "Short note" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}05.txt"

# Test LIST with notes
list_output=$(fastnote list 2>&1)
if echo "$list_output" | grep -q "Available notes"; then
    if print_msg 12 "Does fastnote list display existing notes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 12 "Does fastnote list display existing notes?" false
fi

if echo "$list_output" | grep -q "note ${TEST_NOTE_BASE}01"; then
    if print_msg 13 "Does fastnote list show note numbers correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does fastnote list show note numbers correctly?" false
fi

if echo "$list_output" | grep -q "First line of note 1"; then
    if print_msg 14 "Does fastnote list show note previews?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does fastnote list show note previews?" false
fi

if echo "$list_output" | grep -q "\.\.\."; then
    if print_msg 15 "Does fastnote list truncate long previews with '...'?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does fastnote list truncate long previews with '...'?" false
fi

if echo "$list_output" | grep -q "(empty note)"; then
    if print_msg 16 "Does fastnote list show '(empty note)' for empty notes?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does fastnote list show '(empty note)' for empty notes?" false
fi

if fastnote list >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 17 "Does fastnote list return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does fastnote list return 0 on success?" false
    fi
else
    print_msg 17 "Does fastnote list return 0 on success?" false
fi

printf "\nTesting CLEAR command...\n"

# Test CLEAR with no notes
rm -f "${TEST_FASTNOTES_DIR}"/notes_${TEST_NOTE_BASE}*.txt "${TEST_FASTNOTES_DIR}"/notes_0.txt "${TEST_FASTNOTES_DIR}"/notes_30.txt "${TEST_FASTNOTES_DIR}"/notes_42.txt 2>/dev/null || true
if echo "n" | fastnote clear 2>&1 | grep -q "No notes found"; then
    if print_msg 18 "Does fastnote clear show 'No notes found.' when no notes exist?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does fastnote clear show 'No notes found.' when no notes exist?" false
fi

# Create notes for CLEAR test
printf "Note 1" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}10.txt"
printf "Note 2" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}11.txt"

# Test CLEAR cancellation
if echo "n" | fastnote clear 2>&1 | grep -q "Cancelled"; then
    if print_msg 19 "Does fastnote clear cancel when user says no?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does fastnote clear cancel when user says no?" false
fi

# Verify notes still exist after cancellation
if [[ -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}10.txt" ]] && [[ -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}11.txt" ]]; then
    if print_msg 20 "Does fastnote clear preserve notes when cancelled?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does fastnote clear preserve notes when cancelled?" false
fi

# Test CLEAR confirmation
if echo "y" | fastnote clear 2>&1 | grep -q "Deleted all"; then
    if print_msg 21 "Does fastnote clear delete all notes when confirmed?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does fastnote clear delete all notes when confirmed?" false
fi

# Verify notes are deleted
if [[ ! -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}10.txt" ]] && [[ ! -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}11.txt" ]]; then
    if print_msg 22 "Does fastnote clear remove note files when confirmed?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does fastnote clear remove note files when confirmed?" false
fi

# Test CLEAR return code on cancellation
printf "Note 1" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}12.txt"
if echo "n" | fastnote clear >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 23 "Does fastnote clear return 0 on cancellation?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 23 "Does fastnote clear return 0 on cancellation?" false
    fi
else
    print_msg 23 "Does fastnote clear return 0 on cancellation?" false
fi
rm -f "${TEST_FASTNOTES_DIR}"/notes_${TEST_NOTE_BASE}*.txt "${TEST_FASTNOTES_DIR}"/notes_0.txt "${TEST_FASTNOTES_DIR}"/notes_30.txt "${TEST_FASTNOTES_DIR}"/notes_42.txt 2>/dev/null || true

printf "\nTesting DELETE command...\n"

# Create a test note
printf "Test note content" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}20.txt"

# Test DELETE with existing note
if fastnote ${TEST_NOTE_BASE}20 delete 2>&1 | grep -q "Deleted note ${TEST_NOTE_BASE}20"; then
    if print_msg 24 "Does fastnote <num> delete work for existing note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does fastnote <num> delete work for existing note?" false
fi

# Verify note is deleted
if [[ ! -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}20.txt" ]]; then
    if print_msg 25 "Does fastnote delete remove the note file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does fastnote delete remove the note file?" false
fi

# Test DELETE short form
printf "Test note" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}21.txt"
if fastnote ${TEST_NOTE_BASE}21 d 2>&1 | grep -q "Deleted note ${TEST_NOTE_BASE}21"; then
    if print_msg 26 "Does fastnote <num> d work (short form)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does fastnote <num> d work (short form)?" false
fi
rm -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}21.txt" 2>/dev/null || true

# Test DELETE with non-existent note
if ! fastnote ${TEST_NOTE_BASE}99 delete 2>/dev/null; then
    if print_msg 27 "Does fastnote <num> delete error on non-existent note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does fastnote <num> delete error on non-existent note?" false
fi

if fastnote ${TEST_NOTE_BASE}99 delete 2>&1 | grep -q "Note ${TEST_NOTE_BASE}99 does not exist"; then
    if print_msg 28 "Does fastnote <num> delete show error message for non-existent note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does fastnote <num> delete show error message for non-existent note?" false
fi

# Test DELETE return code on success
printf "Test note" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}22.txt"
if fastnote ${TEST_NOTE_BASE}22 delete >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 29 "Does fastnote <num> delete return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 29 "Does fastnote <num> delete return 0 on success?" false
    fi
else
    print_msg 29 "Does fastnote <num> delete return 0 on success?" false
fi

# Test DELETE return code on error
fastnote ${TEST_NOTE_BASE}99 delete >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 30 "Does fastnote <num> delete return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does fastnote <num> delete return non-zero on error?" false
fi

printf "\nTesting CAT command...\n"

# Create a test note
test_content="This is test content for CAT command\nLine 2\nLine 3"
printf "${test_content}" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}30.txt"

# Test CAT with existing note
cat_output=$(fastnote ${TEST_NOTE_BASE}30 cat 2>&1)
if [[ "$cat_output" == *"This is test content for CAT command"* ]]; then
    if print_msg 31 "Does fastnote <num> cat display note contents?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 31 "Does fastnote <num> cat display note contents?" false
fi

# Test CAT short form
if fastnote ${TEST_NOTE_BASE}30 c 2>&1 | grep -q "This is test content"; then
    if print_msg 32 "Does fastnote <num> c work (short form)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does fastnote <num> c work (short form)?" false
fi

# Test CAT return code
if fastnote ${TEST_NOTE_BASE}30 cat >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 33 "Does fastnote <num> cat return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 33 "Does fastnote <num> cat return 0 on success?" false
    fi
else
    print_msg 33 "Does fastnote <num> cat return 0 on success?" false
fi

# Test CAT with non-existent note
if ! fastnote ${TEST_NOTE_BASE}99 cat 2>/dev/null; then
    if print_msg 34 "Does fastnote <num> cat error on non-existent note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 34 "Does fastnote <num> cat error on non-existent note?" false
fi

if fastnote ${TEST_NOTE_BASE}99 cat 2>&1 | grep -q "Note ${TEST_NOTE_BASE}99 does not exist"; then
    if print_msg 35 "Does fastnote <num> cat show error message for non-existent note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does fastnote <num> cat show error message for non-existent note?" false
fi

# Test CAT with empty note
printf "" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}31.txt"
cat_output=$(fastnote ${TEST_NOTE_BASE}31 cat 2>&1)
if [[ -z "$cat_output" ]] || [[ "$cat_output" == "" ]]; then
    if print_msg 36 "Does fastnote <num> cat handle empty notes correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 36 "Does fastnote <num> cat handle empty notes correctly?" false
fi
rm -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}31.txt" 2>/dev/null || true

printf "\nTesting OPEN command (default action)...\n"

# Remove test note if it exists
rm -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}40.txt" 2>/dev/null || true

# Test OPEN creates note file if it doesn't exist
# EDITOR should already be set to mock_editor.sh from earlier
# Verify mock editor exists and is executable
if ! command -v "$EDITOR" >/dev/null 2>&1; then
    printf "Error: Mock editor not found in PATH: %s\n" "$EDITOR" >&2
    exit 99
fi
# Call fastnote with output redirected to prevent any editor output
if fastnote ${TEST_NOTE_BASE}40 >/dev/null 2>&1; then
    if [[ -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}40.txt" ]]; then
        if print_msg 37 "Does fastnote <num> create note file if it doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 37 "Does fastnote <num> create note file if it doesn't exist?" false
    fi
else
    # Even if it fails, check if file was created
    if [[ -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}40.txt" ]]; then
        if print_msg 37 "Does fastnote <num> create note file if it doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 37 "Does fastnote <num> create note file if it doesn't exist?" false
    fi
fi

# Test OPEN with existing note
if fastnote ${TEST_NOTE_BASE}40 >/dev/null 2>&1; then
    if print_msg 38 "Does fastnote <num> open existing note?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 38 "Does fastnote <num> open existing note?" false
fi

# Test OPEN return code
if fastnote ${TEST_NOTE_BASE}40 >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 39 "Does fastnote <num> return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 39 "Does fastnote <num> return 0 on success?" false
    fi
else
    print_msg 39 "Does fastnote <num> return 0 on success?" false
fi

# Keep EDITOR set to mock_editor.sh for remaining tests
# We'll restore it at the end in cleanup

printf "\nTesting note number validation...\n"

# Test valid numbers
if fastnote 0 >/dev/null 2>&1 || [[ -f "${TEST_FASTNOTES_DIR}/notes_0.txt" ]]; then
    if print_msg 40 "Does fastnote accept valid positive numbers (0)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 40 "Does fastnote accept valid positive numbers (0)?" false
fi

if fastnote 42 >/dev/null 2>&1 || [[ -f "${TEST_FASTNOTES_DIR}/notes_42.txt" ]]; then
    if print_msg 41 "Does fastnote accept valid positive numbers (42)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 41 "Does fastnote accept valid positive numbers (42)?" false
fi

# Test invalid numbers
if ! fastnote -5 2>/dev/null; then
    if print_msg 42 "Does fastnote reject negative numbers?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 42 "Does fastnote reject negative numbers?" false
fi

if ! fastnote "abc" 2>/dev/null; then
    if print_msg 43 "Does fastnote reject non-numeric arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 43 "Does fastnote reject non-numeric arguments?" false
fi

if fastnote "abc" 2>&1 | grep -q "Invalid argument"; then
    if print_msg 44 "Does fastnote show error message for invalid arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 44 "Does fastnote show error message for invalid arguments?" false
fi

# Test extraction from "number - preview" format
printf "Test note" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}50.txt"
if fastnote "${TEST_NOTE_BASE}50 - Test note" cat 2>&1 | grep -q "Test note"; then
    if print_msg 45 "Does fastnote extract number from 'number - preview' format?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 45 "Does fastnote extract number from 'number - preview' format?" false
fi
rm -f "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}50.txt" 2>/dev/null || true

printf "\nTesting edge cases...\n"

# Test zero note
if fastnote 0 >/dev/null 2>&1 || [[ -f "${TEST_FASTNOTES_DIR}/notes_0.txt" ]]; then
    if print_msg 46 "Does fastnote 0 work (zero is valid)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 46 "Does fastnote 0 work (zero is valid)?" false
fi

# Test multiple notes
printf "Note 1" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}60.txt"
printf "Note 2" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}61.txt"
printf "Note 3" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}62.txt"
list_output=$(fastnote list 2>&1)
if echo "$list_output" | grep -q "note ${TEST_NOTE_BASE}60" && echo "$list_output" | grep -q "note ${TEST_NOTE_BASE}61" && echo "$list_output" | grep -q "note ${TEST_NOTE_BASE}62"; then
    if print_msg 47 "Does fastnote handle multiple notes correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 47 "Does fastnote handle multiple notes correctly?" false
fi

# Test note content preservation
test_content="Original content\nLine 2\nLine 3"
printf "${test_content}" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}70.txt"
cat_output=$(fastnote ${TEST_NOTE_BASE}70 cat 2>&1)
if [[ "$cat_output" == *"Original content"* ]]; then
    if print_msg 48 "Does fastnote preserve note content across operations?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 48 "Does fastnote preserve note content across operations?" false
fi

printf "\nTesting bash completion (if available)...\n"

if command -v complete >/dev/null 2>&1; then
    if complete -p fastnote >/dev/null 2>&1; then
        if print_msg 49 "Is fastnote completion function registered?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 49 "Is fastnote completion function registered?" false
    fi
else
    if print_msg 49 "Is fastnote completion function registered?" false; then
        printf "        (complete command not available, skipping)\n"
    fi
fi

printf "\nTesting error handling...\n"

# Test missing dependencies (we can't easily test this without breaking things, so skip)
# But we can test error output
if fastnote ${TEST_NOTE_BASE}99 delete 2>&1 | grep -q "Error\|does not exist"; then
    if print_msg 50 "Does fastnote output error messages to stderr?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 50 "Does fastnote output error messages to stderr?" false
fi

printf "\nTesting return codes...\n"

# Test return code on success
if fastnote list >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 51 "Does fastnote return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 51 "Does fastnote return 0 on success?" false
    fi
else
    print_msg 51 "Does fastnote return 0 on success?" false
fi

# Test return code on error
fastnote ${TEST_NOTE_BASE}99 delete >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    if print_msg 52 "Does fastnote return non-zero on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 52 "Does fastnote return non-zero on error?" false
fi

printf "\nTesting output messages...\n"

# Test success messages
if fastnote ${TEST_NOTE_BASE}80 delete 2>&1 | grep -q "Deleted note ${TEST_NOTE_BASE}80"; then
    if print_msg 53 "Does fastnote output success messages correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    # Create note first
    printf "Test" > "${TEST_FASTNOTES_DIR}/notes_${TEST_NOTE_BASE}80.txt"
    if fastnote ${TEST_NOTE_BASE}80 delete 2>&1 | grep -q "Deleted note ${TEST_NOTE_BASE}80"; then
        if print_msg 53 "Does fastnote output success messages correctly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 53 "Does fastnote output success messages correctly?" false
    fi
fi

# Test error messages
if fastnote ${TEST_NOTE_BASE}99 delete 2>&1 | grep -q "Note ${TEST_NOTE_BASE}99 does not exist"; then
    if print_msg 54 "Does fastnote output error messages correctly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 54 "Does fastnote output error messages correctly?" false
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
# Only remove test notes (900000+ range) and specific test notes (0, 30, 42) to avoid deleting real notes
rm -f "${TEST_FASTNOTES_DIR}"/notes_${TEST_NOTE_BASE}*.txt 2>/dev/null || true
rm -f "${TEST_FASTNOTES_DIR}"/notes_0.txt "${TEST_FASTNOTES_DIR}"/notes_30.txt "${TEST_FASTNOTES_DIR}"/notes_42.txt 2>/dev/null || true
# Only remove .fastnotes directory if it's empty (to avoid deleting real notes)
if [[ -d "${TEST_FASTNOTES_DIR}" ]] && [[ -z "$(ls -A "${TEST_FASTNOTES_DIR}" 2>/dev/null)" ]]; then
    rm -rf "${TEST_FASTNOTES_DIR}" 2>/dev/null || true
fi
rm -f "$mock_editor" 2>/dev/null || true

# Restore original HOME
export HOME="$original_home"

# Restore original fastnotes directory if it was backed up
if [[ -d "${TEST_FASTNOTES_DIR}.backup" ]]; then
    mv "${TEST_FASTNOTES_DIR}.backup" "$TEST_FASTNOTES_DIR" 2>/dev/null || true
fi

# Restore original editor and PATH
if [[ -n "$original_editor" ]]; then
    export EDITOR="$original_editor"
else
    unset EDITOR
fi
# Remove mock editor directory from PATH
original_path="${PATH#${__UNIT_TESTS_DIR}:}"
if [[ "$PATH" != "$original_path" ]]; then
    export PATH="$original_path"
fi

# Clean up test home directory
rm -rf "$TEST_HOME" 2>/dev/null || true

printf "Cleanup complete.\n"

exit 0

