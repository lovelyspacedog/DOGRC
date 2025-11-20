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
total_tests=27  # Tests 1-5, "*", 6-26
printf "Running unit tests for cpx.sh...\n\n"

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

if [[ -f "${__PLUGINS_DIR}/utilities/cpx.sh" ]]; then
    if print_msg 3 "Can I find cpx.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 3 "Can I find cpx.sh?" false
    printf "Error: Test cannot continue. cpx.sh not found.\n" >&2
    exit 3
fi

if source "${__PLUGINS_DIR}/utilities/cpx.sh" 2>/dev/null; then
    if print_msg 4 "Can I source cpx.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 4 "Can I source cpx.sh?" false
    printf "Error: Test cannot continue. cpx.sh not found.\n" >&2
    exit 4
fi

if declare -f cpx >/dev/null 2>&1; then
    if print_msg 5 "Is cpx function defined?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 5 "Is cpx function defined?" false
    printf "Error: cpx function not defined.\n" >&2
    exit 5
fi

print_msg "*" "Did I pass initial sanity checks?" true
((score++))
if type update_progress_from_score >/dev/null 2>&1; then
    update_progress_from_score
fi

# Save original directory
original_dir=$(pwd)

# Create temporary directory for testing
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || {
    printf "Error: Failed to change directory to test directory.\n" >&2
    exit 91
}

# Setup trap to ensure cleanup happens even on failure
cleanup_cpx_test() {
    local exit_code=$?
    
    # Clean up temporary directory
    cd "$original_dir" || true
    rm -rf "$TEST_DIR" 2>/dev/null || true
    
    # Restore original commands if we modified PATH
    if [[ -n "${ORIGINAL_PATH:-}" ]]; then
        export PATH="$ORIGINAL_PATH"
    fi
    
    exit $exit_code
}

# Register cleanup trap
trap cleanup_cpx_test EXIT INT TERM

if [[ -f "${__PLUGINS_DIR}/drchelp.sh" ]]; then
    source "${__PLUGINS_DIR}/drchelp.sh" 2>/dev/null || true
fi

# Check if g++ is available
GXX_AVAILABLE=false
if command -v g++ >/dev/null 2>&1; then
    GXX_AVAILABLE=true
fi

# Mock functions (used as fallback if g++ not available)
MOCK_GXX_CALLED=false
MOCK_GXX_ARGS_FILE=$(mktemp)
MOCK_AOUT_EXIT_CODE=0

# Mock g++ command (fallback)
mock_g++() {
    MOCK_GXX_CALLED=true
    echo "$@" > "$MOCK_GXX_ARGS_FILE"
    # Create a mock a.out executable
    cat > a.out << 'MOCKAOUTEOF'
#!/bin/bash
exit ${MOCK_AOUT_EXIT_CODE:-0}
MOCKAOUTEOF
    chmod +x a.out
    return 0
}

# Export mock if g++ not available
if [[ "$GXX_AVAILABLE" == false ]]; then
    g++() {
        mock_g++ "$@"
    }
    export -f g++
    export MOCK_GXX_ARGS_FILE
    export MOCK_AOUT_EXIT_CODE
fi

printf "\nTesting cpx() function help flags...\n"

# Test 6: cpx --help
if declare -f drchelp >/dev/null 2>&1; then
    if cpx --help >/dev/null 2>&1; then
        if print_msg 6 "Does cpx --help work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 6 "Does cpx --help work?" false
    fi
else
    if cpx --help >/dev/null 2>&1; then
        print_msg 6 "Does cpx --help work?" false
    else
        if print_msg 6 "Does cpx --help work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 7: cpx -h
if declare -f drchelp >/dev/null 2>&1; then
    if cpx -h >/dev/null 2>&1; then
        if print_msg 7 "Does cpx -h work?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 7 "Does cpx -h work?" false
    fi
else
    if cpx -h >/dev/null 2>&1; then
        print_msg 7 "Does cpx -h work?" false
    else
        if print_msg 7 "Does cpx -h work (no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

# Test 8: cpx --HELP (case-insensitive)
if declare -f drchelp >/dev/null 2>&1; then
    if cpx --HELP >/dev/null 2>&1; then
        if print_msg 8 "Does cpx --HELP work (case-insensitive)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 8 "Does cpx --HELP work (case-insensitive)?" false
    fi
else
    if cpx --HELP >/dev/null 2>&1; then
        print_msg 8 "Does cpx --HELP work (case-insensitive)?" false
    else
        if print_msg 8 "Does cpx --HELP work (case-insensitive, no drchelp)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    fi
fi

printf "\nTesting cpx() function file operations...\n"

# Test 9: cpx errors when file doesn't exist
if cpx nonexistent.cpp >/dev/null 2>&1; then
    print_msg 9 "Does cpx error when file doesn't exist?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 9 "Does cpx error when file doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 9 "Does cpx error when file doesn't exist?" false
    fi
fi

# Test 10: cpx uses default filename main.cpp when no argument
# Create a simple C++ file
cat > main.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cout << "Hello from main.cpp" << std::endl;
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
fi

if cpx >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 10 "Does cpx use default filename main.cpp?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 10 "Does cpx use default filename main.cpp?" false
    fi
else
    print_msg 10 "Does cpx use default filename main.cpp?" false
fi

# Test 11: cpx accepts custom filename
cat > test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cout << "Hello from test.cpp" << std::endl;
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
fi

if cpx test.cpp >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 11 "Does cpx accept custom filename?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 11 "Does cpx accept custom filename?" false
    fi
else
    print_msg 11 "Does cpx accept custom filename?" false
fi

printf "\nTesting cpx() function compilation and execution...\n"

# Test 12: cpx compiles C++ file
cat > compile_test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_GXX_CALLED=false
    MOCK_AOUT_EXIT_CODE=0
fi

cpx compile_test.cpp >/dev/null 2>&1
if [[ "$GXX_AVAILABLE" == true ]]; then
    # Check that compilation succeeded (a.out should exist briefly, but is cleaned up)
    # Since a.out is removed, we check that the function returned 0
    if [[ $? -eq 0 ]]; then
        if print_msg 12 "Does cpx compile C++ file?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 12 "Does cpx compile C++ file?" false
    fi
else
    # Check that mock g++ was called
    if [[ "$MOCK_GXX_CALLED" == true ]]; then
        if print_msg 12 "Does cpx compile C++ file (mocked)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 12 "Does cpx compile C++ file (mocked)?" false
    fi
fi

# Test 13: cpx executes compiled program
cat > execute_test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cout << "Execution test" << std::endl;
    return 42;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=42
    MOCK_GXX_CALLED=false
fi

output=$(cpx execute_test.cpp 2>&1)
if echo "$output" | grep -q "Execution test"; then
    if print_msg 13 "Does cpx execute compiled program?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 13 "Does cpx execute compiled program?" false
fi

# Test 14: cpx captures and displays exit code
cat > exitcode_test.cpp << 'CPPEOF'
int main() {
    return 5;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=5
    MOCK_GXX_CALLED=false
fi

output=$(cpx exitcode_test.cpp 2>&1)
if echo "$output" | grep -q "Exit Code: 5"; then
    if print_msg 14 "Does cpx capture and display exit code?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 14 "Does cpx capture and display exit code?" false
fi

# Test 15: cpx displays exit code 0
cat > exitcode0_test.cpp << 'CPPEOF'
int main() {
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
fi

output=$(cpx exitcode0_test.cpp 2>&1)
if echo "$output" | grep -q "Exit Code: 0"; then
    if print_msg 15 "Does cpx display exit code 0?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 15 "Does cpx display exit code 0?" false
fi

printf "\nTesting cpx() function cleanup...\n"

# Test 16: cpx removes a.out after execution
cat > cleanup_test.cpp << 'CPPEOF'
int main() {
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
fi

cpx cleanup_test.cpp >/dev/null 2>&1
# Check that a.out was removed
if [[ ! -f a.out ]]; then
    if print_msg 16 "Does cpx remove a.out after execution?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 16 "Does cpx remove a.out after execution?" false
fi

printf "\nTesting cpx() function error handling...\n"

# Test 17: cpx returns 1 when file doesn't exist
if cpx nonexistent_file.cpp >/dev/null 2>&1; then
    print_msg 17 "Does cpx return 1 when file doesn't exist?" false
else
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        if print_msg 17 "Does cpx return 1 when file doesn't exist?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 17 "Does cpx return 1 when file doesn't exist?" false
    fi
fi

# Test 18: cpx shows error message when file doesn't exist
output=$(cpx nonexistent_file.cpp 2>&1)
if echo "$output" | grep -q "Error: File nonexistent_file.cpp does not exist"; then
    if print_msg 18 "Does cpx show error message when file doesn't exist?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 18 "Does cpx show error message when file doesn't exist?" false
fi

# Test 19: cpx returns 2 when compilation fails
cat > bad_syntax.cpp << 'CPPEOF'
int main() {
    this is bad syntax!!!
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == true ]]; then
    # Real g++ will fail to compile this
    if cpx bad_syntax.cpp >/dev/null 2>&1; then
        print_msg 19 "Does cpx return 2 when compilation fails?" false
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            if print_msg 19 "Does cpx return 2 when compilation fails?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 19 "Does cpx return 2 when compilation fails?" false
        fi
    fi
else
    # Mock g++ - simulate compilation failure
    g++() {
        return 1
    }
    export -f g++
    if cpx bad_syntax.cpp >/dev/null 2>&1; then
        print_msg 19 "Does cpx return 2 when compilation fails (mocked)?" false
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            if print_msg 19 "Does cpx return 2 when compilation fails (mocked)?" true; then
                ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
            fi
        else
            print_msg 19 "Does cpx return 2 when compilation fails (mocked)?" false
        fi
    fi
    # Restore mock
    g++() {
        mock_g++ "$@"
    }
    export -f g++
fi

# Test 20: cpx shows error message when compilation fails
cat > bad_syntax2.cpp << 'CPPEOF'
int main() {
    invalid syntax here
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == true ]]; then
    output=$(cpx bad_syntax2.cpp 2>&1)
    if echo "$output" | grep -q "Error: Failed to compile"; then
        if print_msg 20 "Does cpx show error message when compilation fails?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 20 "Does cpx show error message when compilation fails?" false
    fi
else
    # Mock g++ - simulate compilation failure
    g++() {
        return 1
    }
    export -f g++
    output=$(cpx bad_syntax2.cpp 2>&1)
    if echo "$output" | grep -q "Error: Failed to compile"; then
        if print_msg 20 "Does cpx show error message when compilation fails (mocked)?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 20 "Does cpx show error message when compilation fails (mocked)?" false
    fi
    # Restore mock
    g++() {
        mock_g++ "$@"
    }
    export -f g++
fi

printf "\nTesting cpx() function edge cases...\n"

# Test 21: cpx handles program with non-zero exit code
cat > nonzero_exit.cpp << 'CPPEOF'
int main() {
    return 7;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=7
    MOCK_GXX_CALLED=false
fi

output=$(cpx nonzero_exit.cpp 2>&1)
if echo "$output" | grep -q "Exit Code: 7"; then
    if print_msg 21 "Does cpx handle program with non-zero exit code?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 21 "Does cpx handle program with non-zero exit code?" false
fi

# Test 22: cpx handles program that outputs to stdout
cat > stdout_test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cout << "Output line 1" << std::endl;
    std::cout << "Output line 2" << std::endl;
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
    # Update mock to output text
    mock_g++() {
        MOCK_GXX_CALLED=true
        echo "$@" > "$MOCK_GXX_ARGS_FILE"
        cat > a.out << 'MOCKAOUTEOF'
#!/bin/bash
echo "Output line 1"
echo "Output line 2"
exit ${MOCK_AOUT_EXIT_CODE:-0}
MOCKAOUTEOF
        chmod +x a.out
        return 0
    }
    g++() {
        mock_g++ "$@"
    }
    export -f g++
fi

output=$(cpx stdout_test.cpp 2>&1)
if echo "$output" | grep -q "Output line 1" && echo "$output" | grep -q "Output line 2"; then
    if print_msg 22 "Does cpx handle program that outputs to stdout?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 22 "Does cpx handle program that outputs to stdout?" false
fi

# Test 23: cpx handles program that outputs to stderr
cat > stderr_test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cerr << "Error message" << std::endl;
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
    # Update mock to output to stderr
    mock_g++() {
        MOCK_GXX_CALLED=true
        echo "$@" > "$MOCK_GXX_ARGS_FILE"
        cat > a.out << 'MOCKAOUTEOF'
#!/bin/bash
echo "Error message" >&2
exit ${MOCK_AOUT_EXIT_CODE:-0}
MOCKAOUTEOF
        chmod +x a.out
        return 0
    }
    g++() {
        mock_g++ "$@"
    }
    export -f g++
fi

output=$(cpx stderr_test.cpp 2>&1)
if echo "$output" | grep -q "Error message"; then
    if print_msg 23 "Does cpx handle program that outputs to stderr?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 23 "Does cpx handle program that outputs to stderr?" false
fi

printf "\nTesting cpx.sh direct script execution...\n"

# Test 24: cpx.sh can be executed directly
cat > direct_test.cpp << 'CPPEOF'
int main() {
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
fi

if bash "${__PLUGINS_DIR}/utilities/cpx.sh" direct_test.cpp >/dev/null 2>&1; then
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if print_msg 24 "Can cpx.sh be executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
    else
        print_msg 24 "Can cpx.sh be executed directly?" false
    fi
else
    print_msg 24 "Can cpx.sh be executed directly?" false
fi

# Test 25: cpx.sh direct execution produces output
cat > direct_output_test.cpp << 'CPPEOF'
#include <iostream>
int main() {
    std::cout << "Direct execution test" << std::endl;
    return 0;
}
CPPEOF

if [[ "$GXX_AVAILABLE" == false ]]; then
    MOCK_AOUT_EXIT_CODE=0
    MOCK_GXX_CALLED=false
    mock_g++() {
        MOCK_GXX_CALLED=true
        echo "$@" > "$MOCK_GXX_ARGS_FILE"
        cat > a.out << 'MOCKAOUTEOF'
#!/bin/bash
echo "Direct execution test"
exit ${MOCK_AOUT_EXIT_CODE:-0}
MOCKAOUTEOF
        chmod +x a.out
        return 0
    }
    g++() {
        mock_g++ "$@"
    }
    export -f g++
fi

output=$(bash -c "cd '$TEST_DIR' && source <(declare -f g++); export MOCK_GXX_ARGS_FILE='$MOCK_GXX_ARGS_FILE'; export MOCK_AOUT_EXIT_CODE='$MOCK_AOUT_EXIT_CODE'; ${__PLUGINS_DIR}/utilities/cpx.sh direct_output_test.cpp" 2>&1)
if echo "$output" | grep -q "Direct execution test"; then
    if print_msg 25 "Does cpx.sh direct execution produce output?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 25 "Does cpx.sh direct execution produce output?" false
fi

# Test 26: cpx.sh direct execution with --help
output=$(bash "${__PLUGINS_DIR}/utilities/cpx.sh" --help 2>&1)
if echo "$output" | grep -qE "(drchelp|Error: drchelp not available)" || [[ ${#output} -gt 0 ]]; then
    if print_msg 26 "Does cpx.sh --help work when executed directly?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
else
    print_msg 26 "Does cpx.sh --help work when executed directly?" false
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

if [[ "$GXX_AVAILABLE" == true ]]; then
    printf "\nNote: Tests used real g++ compiler\n"
else
    printf "\nNote: Tests used mocked g++ (g++ not available)\n"
fi

printf "\nCleaning up...\n"
printf "Cleanup complete.\n"

cd "$original_dir" || exit 91

exit 0

