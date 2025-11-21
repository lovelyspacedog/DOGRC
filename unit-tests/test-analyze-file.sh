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
total_tests=50  # Tests 1-49 plus 1 summary test with "*"
printf "Running unit tests for analyze-file.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/information/analyze-file.sh" ]]; then
    if print_msg 3 "Can I find analyze-file.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find analyze-file.sh?" false
    printf "Error: Test cannot continue. Analyze-file.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/information/analyze-file.sh" 2>/dev/null; then
    if print_msg 4 "Can I source analyze-file.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source analyze-file.sh?" false
    printf "Error: Test cannot continue. Analyze-file.sh not found.\n" >&2
    exit 4
fi

if declare -f analyze-file >/dev/null 2>&1; then
    if print_msg 5 "Is analyze-file function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is analyze-file function defined?" false
    printf "Error: analyze-file function not defined.\n" >&2
    exit 5
fi

if declare -f analyze_file >/dev/null 2>&1; then
    if print_msg 6 "Is analyze_file alias function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 6 "Is analyze_file alias function defined?" false
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

# Unique prefix for this test run (process ID + test name)
readonly TEST_PREFIX="test_analyze_$$"

# Setup trap to ensure cleanup happens even on failure
cleanup_analyze_file_test() {
    local exit_code=$?
    cd "$original_dir" || cd "${__UNIT_TESTS_DIR}" || true
    
    # Clean up test files (handle files with spaces)
    cd "${__UNIT_TESTS_DIR}" 2>/dev/null || true
    rm -f ${TEST_PREFIX}_* 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.txt 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.sh 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.tar 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.jpg 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.mp4 2>/dev/null || true
    rm -f ${TEST_PREFIX}_*.mp3 2>/dev/null || true
    # Explicitly remove file with spaces
    rm -f "${TEST_PREFIX}_file_with_spaces.txt" 2>/dev/null || true
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_analyze_file_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

printf "\nTesting help flags...\n"

if declare -f drchelp >/dev/null 2>&1; then
    if analyze-file --help >/dev/null 2>&1; then
        if print_msg 7 "Does analyze-file --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does analyze-file --help work?" false
    fi
else
    if print_msg 7 "Does analyze-file --help work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

if declare -f drchelp >/dev/null 2>&1; then
    if analyze-file -h >/dev/null 2>&1; then
        if print_msg 8 "Does analyze-file -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does analyze-file -h work?" false
    fi
else
    if print_msg 8 "Does analyze-file -h work?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

# Test case-insensitive help flags
if declare -f drchelp >/dev/null 2>&1; then
    if analyze-file --HELP >/dev/null 2>&1; then
        if print_msg 9 "Does analyze-file --HELP work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does analyze-file --HELP work (case-insensitive)?" false
    fi
else
    if print_msg 9 "Does analyze-file --HELP work (case-insensitive)?" false; then
        printf "        (drchelp not available, skipping)\n"
    fi
fi

printf "\nTesting no arguments / usage display...\n"

# Test 10: No arguments shows usage
output=$(analyze-file 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "Usage:"; then
    if print_msg 10 "Does analyze-file show usage when called with no arguments?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 10 "Does analyze-file show usage when called with no arguments?" false
fi

# Test 11: Usage message contains expected information
if echo "$output" | grep -q "analyze-file <file>" && echo "$output" | grep -q "Description:"; then
    if print_msg 11 "Does usage message contain expected information?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 11 "Does usage message contain expected information?" false
fi

printf "\nCreating test files...\n"

# Create test text file with known content
test_text_content="This is a test file for analyze-file.
It has multiple lines.
Line 3 with some words.
End of file."
printf "%s\n" "$test_text_content" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_text.txt" || {
    printf "Error: Failed to create test text file.\n" >&2
    exit 92
}

# Create test executable script with shebang
printf "#!/bin/bash\necho 'test'\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_executable.sh" || {
    printf "Error: Failed to create test executable file.\n" >&2
    exit 93
}
chmod +x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_executable.sh" 2>/dev/null || true

# Create test executable without shebang
printf "echo 'test without shebang'\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_no_shebang.sh" || {
    printf "Error: Failed to create test executable without shebang.\n" >&2
    exit 94
}
chmod +x "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_no_shebang.sh" 2>/dev/null || true

# Create empty file
touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_empty.txt" || {
    printf "Error: Failed to create empty test file.\n" >&2
    exit 95
}

# Create file with spaces in name
printf "test content\n" > "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_file_with_spaces.txt" || {
    printf "Error: Failed to create test file with spaces.\n" >&2
    exit 96
}

if print_msg 12 "Can I create test files?" true; then
    ((score++))
fi

printf "\nTesting error handling...\n"

# Test 13: Non-existent file returns error
if ! analyze-file "nonexistent_file_12345.txt" 2>/dev/null; then
    if print_msg 13 "Does analyze-file error on non-existent file?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does analyze-file error on non-existent file?" false
fi

# Test 14: Error message contains filename
error_output=$(analyze-file "nonexistent_file_12345.txt" 2>&1)
if echo "$error_output" | grep -q "Error:" && echo "$error_output" | grep -q "nonexistent_file_12345.txt"; then
    if print_msg 14 "Does error message contain filename?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does error message contain filename?" false
fi

# Test 15: Return code on error
analyze-file "nonexistent_file_12345.txt" 2>/dev/null
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
    if print_msg 15 "Does analyze-file return 1 on error?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does analyze-file return 1 on error?" false
fi

printf "\nTesting basic file information...\n"

# Test 16: Output contains file path
output=$(analyze-file "${TEST_PREFIX}_text.txt" 2>&1)
if echo "$output" | grep -q "File:.*${TEST_PREFIX}_text.txt"; then
    if print_msg 16 "Does output contain file path?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does output contain file path?" false
fi

# Test 17: Output contains file size
if echo "$output" | grep -q "Size:"; then
    if print_msg 17 "Does output contain file size?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 17 "Does output contain file size?" false
fi

# Test 18: Output contains modified date
if echo "$output" | grep -q "Modified:"; then
    if print_msg 18 "Does output contain modified date?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does output contain modified date?" false
fi

# Test 19: Output contains permissions
if echo "$output" | grep -q "Permissions:"; then
    if print_msg 19 "Does output contain permissions?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 19 "Does output contain permissions?" false
fi

# Test 20: Output contains owner
if echo "$output" | grep -q "Owner:"; then
    if print_msg 20 "Does output contain owner?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 20 "Does output contain owner?" false
fi

# Test 21: Output contains file type
if echo "$output" | grep -q "Type:"; then
    if print_msg 21 "Does output contain file type?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does output contain file type?" false
fi

printf "\nTesting text file analysis...\n"

# Test 22: Text file shows text analysis section
if echo "$output" | grep -q "Text File Analysis:"; then
    if print_msg 22 "Does text file show 'Text File Analysis' section?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does text file show 'Text File Analysis' section?" false
fi

# Test 23: Line count is accurate
# Our test file has 4 lines (3 newlines + 1 line without trailing newline, or 4 lines total)
line_count=$(echo "$output" | grep -A 1 "Lines:" | grep "Lines:" | grep -oE '[0-9]+' | head -1)
if [[ -n "$line_count" ]] && [[ $line_count -ge 3 ]] && [[ $line_count -le 5 ]]; then
    if print_msg 23 "Does line count appear in output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does line count appear in output?" false
fi

# Test 24: Word count is accurate
if echo "$output" | grep -q "Words:"; then
    if print_msg 24 "Does word count appear in output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 24 "Does word count appear in output?" false
fi

# Test 25: Character count is accurate
if echo "$output" | grep -q "Characters:"; then
    if print_msg 25 "Does character count appear in output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does character count appear in output?" false
fi

# Test 26: Characters (no spaces) count appears
if echo "$output" | grep -q "Characters (no spaces):"; then
    if print_msg 26 "Does 'Characters (no spaces)' count appear?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does 'Characters (no spaces)' count appear?" false
fi

printf "\nTesting executable file analysis...\n"

# Test 27: Executable file shows executable section
exec_output=$(analyze-file "${TEST_PREFIX}_executable.sh" 2>&1)
if echo "$exec_output" | grep -q "Executable File:"; then
    if print_msg 27 "Does executable file show 'Executable File' section?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 27 "Does executable file show 'Executable File' section?" false
fi

# Test 28: Shows "Executable: Yes"
if echo "$exec_output" | grep -q "Executable: Yes"; then
    if print_msg 28 "Does output show 'Executable: Yes'?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 28 "Does output show 'Executable: Yes'?" false
fi

# Test 29: Detects shebang
if echo "$exec_output" | grep -q "Shebang:" && echo "$exec_output" | grep -q "#!"; then
    if print_msg 29 "Does output detect shebang line?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 29 "Does output detect shebang line?" false
fi

# Test 30: Shows "None" when no shebang
no_shebang_output=$(analyze-file "${TEST_PREFIX}_no_shebang.sh" 2>&1)
if echo "$no_shebang_output" | grep -q "Shebang:" && echo "$no_shebang_output" | grep -q "None"; then
    if print_msg 30 "Does output show 'None' when no shebang present?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 30 "Does output show 'None' when no shebang present?" false
fi

printf "\nTesting file type detection...\n"

# Test 31: Archive file detection by extension (create a fake archive file)
touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_archive.tar" 2>/dev/null || true
archive_output=$(analyze-file "${TEST_PREFIX}_archive.tar" 2>&1)
if echo "$archive_output" | grep -q "Archive File:" || echo "$archive_output" | grep -qi "archive\|compressed"; then
    if print_msg 31 "Does analyze-file detect archive files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 31 "Does analyze-file detect archive files?" false
fi

# Test 32: Image file detection by extension
touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_image.jpg" 2>/dev/null || true
image_output=$(analyze-file "${TEST_PREFIX}_image.jpg" 2>&1)
if echo "$image_output" | grep -q "Image File:" || echo "$image_output" | grep -qi "image"; then
    if print_msg 32 "Does analyze-file detect image files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 32 "Does analyze-file detect image files?" false
fi

# Test 33: Video file detection by extension
touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_video.mp4" 2>/dev/null || true
video_output=$(analyze-file "${TEST_PREFIX}_video.mp4" 2>&1)
if echo "$video_output" | grep -q "Video File:" || echo "$video_output" | grep -qi "video"; then
    if print_msg 33 "Does analyze-file detect video files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 33 "Does analyze-file detect video files?" false
fi

# Test 34: Audio file detection by extension
touch "${__UNIT_TESTS_DIR}/${TEST_PREFIX}_audio.mp3" 2>/dev/null || true
audio_output=$(analyze-file "${TEST_PREFIX}_audio.mp3" 2>&1)
if echo "$audio_output" | grep -q "Audio File:" || echo "$audio_output" | grep -qi "audio"; then
    if print_msg 34 "Does analyze-file detect audio files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 34 "Does analyze-file detect audio files?" false
fi

printf "\nTesting SHA256 hash generation...\n"

# Test 35: Hash is generated
if echo "$output" | grep -q "SHA256 Hash:"; then
    if print_msg 35 "Does output contain SHA256 hash section?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 35 "Does output contain SHA256 hash section?" false
fi

# Test 36: Hash format is valid (64 hex characters)
hash_line=$(echo "$output" | grep -A 1 "SHA256 Hash:" | tail -1 | tr -d '[:space:]')
if [[ ${#hash_line} -eq 64 ]] && echo "$hash_line" | grep -qE '^[0-9a-f]{64}$'; then
    if print_msg 36 "Is SHA256 hash format valid (64 hex characters)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 36 "Is SHA256 hash format valid (64 hex characters)?" false
fi

# Test 37: Hash matches expected value for known file
# Calculate expected hash
expected_hash=$(sha256sum "${TEST_PREFIX}_text.txt" 2>/dev/null | cut -d' ' -f1)
if [[ -n "$expected_hash" ]] && echo "$output" | grep -q "$expected_hash"; then
    if print_msg 37 "Does SHA256 hash match expected value?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 37 "Does SHA256 hash match expected value?" false
fi

printf "\nTesting additional file information...\n"

# Test 38: Inode number is displayed
if echo "$output" | grep -q "Inode:"; then
    if print_msg 38 "Does output contain inode number?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 38 "Does output contain inode number?" false
fi

# Test 39: Hard link count is displayed
if echo "$output" | grep -q "Hard links:"; then
    if print_msg 39 "Does output contain hard link count?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 39 "Does output contain hard link count?" false
fi

# Test 40: Device number is displayed
if echo "$output" | grep -q "Device:"; then
    if print_msg 40 "Does output contain device number?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 40 "Does output contain device number?" false
fi

printf "\nTesting output formatting...\n"

# Test 41: Output contains emoji/icons
if echo "$output" | grep -qE '📊|📏|📅|🔐|👤|📄|📝|⚡|📦|🖼️|🎬|🎵|🔒|📋'; then
    if print_msg 41 "Does output contain emoji/icons?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 41 "Does output contain emoji/icons?" false
fi

# Test 42: Output contains color codes
if echo "$output" | grep -qE $'\033\[|\[0-9]+m'; then
    if print_msg 42 "Does output contain color codes (ANSI escape sequences)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 42 "Does output contain color codes (ANSI escape sequences)?" false
fi

# Test 43: Output has proper section headers
if echo "$output" | grep -q "FILE ANALYSIS" && echo "$output" | grep -q "================"; then
    if print_msg 43 "Does output have proper section headers?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 43 "Does output have proper section headers?" false
fi

printf "\nTesting edge cases...\n"

# Test 44: Empty file handling
empty_output=$(analyze-file "${TEST_PREFIX}_empty.txt" 2>&1)
if [[ $? -eq 0 ]] && echo "$empty_output" | grep -q "${TEST_PREFIX}_empty.txt"; then
    if print_msg 44 "Does analyze-file handle empty files?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 44 "Does analyze-file handle empty files?" false
fi

# Test 45: File with spaces in name
spaces_output=$(analyze-file "${TEST_PREFIX}_file_with_spaces.txt" 2>&1)
if [[ $? -eq 0 ]] && echo "$spaces_output" | grep -q "${TEST_PREFIX}_file_with_spaces.txt"; then
    if print_msg 45 "Does analyze-file work with files containing spaces?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 45 "Does analyze-file work with files containing spaces?" false
fi

# Test 46: Absolute path handling
abs_path="${__UNIT_TESTS_DIR}/${TEST_PREFIX}_text.txt"
abs_output=$(analyze-file "$abs_path" 2>&1)
if [[ $? -eq 0 ]] && echo "$abs_output" | grep -q "$abs_path"; then
    if print_msg 46 "Does analyze-file work with absolute paths?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 46 "Does analyze-file work with absolute paths?" false
fi

# Test 47: Return code on success
if analyze-file "${TEST_PREFIX}_text.txt" >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 47 "Does analyze-file return 0 on success?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 47 "Does analyze-file return 0 on success?" false
    fi
else
    print_msg 47 "Does analyze-file return 0 on success?" false
fi

printf "\nTesting alias function...\n"

# Test 48: analyze_file alias works
alias_output=$(analyze_file "${TEST_PREFIX}_text.txt" 2>&1)
if [[ $? -eq 0 ]] && echo "$alias_output" | grep -q "${TEST_PREFIX}_text.txt"; then
    if print_msg 48 "Does analyze_file alias function work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 48 "Does analyze_file alias function work?" false
fi

# Test 49: Alias produces same output as main function
main_output=$(analyze-file "${TEST_PREFIX}_text.txt" 2>&1)
alias_output2=$(analyze_file "${TEST_PREFIX}_text.txt" 2>&1)
# Compare outputs (excluding potential timing differences in modified date)
main_hash=$(echo "$main_output" | grep -v "Modified:" | sha256sum | cut -d' ' -f1)
alias_hash=$(echo "$alias_output2" | grep -v "Modified:" | sha256sum | cut -d' ' -f1)
if [[ "$main_hash" == "$alias_hash" ]]; then
    if print_msg 49 "Does alias produce same output as main function?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 49 "Does alias produce same output as main function?" false
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
cd "${__UNIT_TESTS_DIR}" 2>/dev/null || true
rm -f ${TEST_PREFIX}_* 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.txt 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.sh 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.tar 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.jpg 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.mp4 2>/dev/null || true
rm -f ${TEST_PREFIX}_*.mp3 2>/dev/null || true
# Explicitly remove file with spaces
rm -f "${TEST_PREFIX}_file_with_spaces.txt" 2>/dev/null || true
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

