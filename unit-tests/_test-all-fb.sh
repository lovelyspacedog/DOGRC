#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command-line arguments
FAIL_FAST=false
QUIET=false
STAGE_MODE=false
STAGE_TARGET=""

for arg in "$@"; do
    case "$arg" in
        --fail-fast|-f)
            FAIL_FAST=true
            ;;
        --quiet|-q)
            QUIET=true
            ;;
        --stage|--STAGE|-s|-S)
            STAGE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [--stage <test-name>]"
            echo ""
            echo "Options:"
            echo "  --fail-fast, -f    Stop on first test failure"
            echo "  --quiet, -q        Minimal output (only summary)"
            echo "  --stage, -s <test> Run only the specified test and its adjacent tests"
            echo "  --help, -h         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            # Check if this is a stage target (non-flag argument after --stage)
            if [[ "$STAGE_MODE" == "true" ]] && [[ -z "$STAGE_TARGET" ]]; then
                # Skip if it's another flag
                if [[ "$arg" == --* ]] || [[ "$arg" == -[a-zA-Z] ]]; then
                    continue
                fi
                STAGE_TARGET="$arg"
            elif [[ "$STAGE_MODE" == "false" ]]; then
                echo "Unknown option: $arg" >&2
                echo "Use --help for usage information" >&2
                exit 1
            fi
            ;;
    esac
done

declare -i passed=0
declare -i failed=0

# Get all test files
test_files=("${__UNIT_TESTS_DIR}"/test-*.sh)
if [[ ${#test_files[@]} -eq 0 ]] || [[ ! -f "${test_files[0]}" ]]; then
    echo "Error: No test files found in ${__UNIT_TESTS_DIR}" >&2
    exit 1
fi

# Sort test files alphabetically
IFS=$'\n' test_files=($(printf '%s\n' "${test_files[@]}" | sort))
unset IFS

# Handle --stage mode: find target test and include adjacent tests
if [[ "$STAGE_MODE" == "true" ]]; then
    if [[ -z "$STAGE_TARGET" ]]; then
        echo "Error: --stage flag requires a test file name" >&2
        echo "Usage: $0 --stage <test-file>" >&2
        echo "Example: $0 --stage test-timer.sh" >&2
        echo "Example: $0 --stage timer" >&2
        echo "Available tests:" >&2
        for test_file in "${test_files[@]}"; do
            test_name=$(basename "$test_file" .sh)
            echo "  - $test_name" >&2
        done
        exit 1
    fi

    # If target is a full path, extract just the basename
    if [[ "$STAGE_TARGET" == */* ]]; then
        STAGE_TARGET=$(basename "$STAGE_TARGET")
    fi

    # Normalize target (remove test- prefix and .sh extension if present)
    normalized_target="${STAGE_TARGET#test-}"
    normalized_target="${normalized_target%.sh}"

    # Validate that we have a target
    if [[ -z "$normalized_target" ]]; then
        echo "Error: Invalid test target specified: ${STAGE_TARGET}" >&2
        exit 1
    fi

    # Find the target test in the sorted array
    target_index=-1
    i=0
    for test_file in "${test_files[@]}"; do
        test_name=$(basename "$test_file" .sh)
        test_base="${test_name#test-}"

        # Match by exact base name first (most specific)
        if [[ "$test_base" == "$normalized_target" ]]; then
            target_index=$i
            break
        fi
        # Then try full test name match
        if [[ "$test_name" == "$STAGE_TARGET" ]] || [[ "$test_name" == "test-${STAGE_TARGET}" ]]; then
            target_index=$i
            break
        fi
        ((i++))
    done

    # If still not found, try substring match as last resort
    if [[ $target_index -eq -1 ]]; then
        i=0
        for test_file in "${test_files[@]}"; do
            test_name=$(basename "$test_file" .sh)
            test_base="${test_name#test-}"
            # Substring match in the base name only
            if [[ "$test_base" == *"${normalized_target}"* ]]; then
                target_index=$i
                break
            fi
            ((i++))
        done
    fi

    if [[ $target_index -eq -1 ]]; then
        echo "Error: Test file not found: ${STAGE_TARGET}" >&2
        echo "Available tests:" >&2
        for test_file in "${test_files[@]}"; do
            test_name=$(basename "$test_file" .sh)
            echo "  - $test_name" >&2
        done
        exit 1
    fi

    # Save the target file path before rebuilding array
    target_file="${test_files[$target_index]}"

    # Build staged test list: target, one before, one after
    staged_files=()

    # Add previous test if exists
    if [[ $target_index -gt 0 ]]; then
        staged_files+=("${test_files[$((target_index - 1))]}")
    fi

    # Add target test
    staged_files+=("${test_files[$target_index]}")

    # Add next test if exists
    if [[ $target_index -lt $((${#test_files[@]} - 1)) ]]; then
        staged_files+=("${test_files[$((target_index + 1))]}")
    fi

    # Replace test_files array with staged files
    test_files=("${staged_files[@]}")

    echo "Stage mode: Running ${#test_files[@]} test(s)"
    for test_file in "${test_files[@]}"; do
        test_name=$(basename "$test_file" .sh)
        if [[ "$test_file" == "$target_file" ]]; then
            echo "  ► $test_name (target)"
        else
            echo "  • $test_name"
        fi
    done
    echo ""
fi

# Run all unit tests (or staged tests if --stage was used)
for test_file in "${test_files[@]}"; do
    # Get just the filename (basename) and convert to lowercase for comparison
    test_basename=$(basename "$test_file")
    test_basename_lower="${test_basename,,}"
    
    # Skip helper files and test runners
    [[ "$test_basename_lower" == "_test-all.sh" ]] && continue
    [[ "$test_basename_lower" == "_test-all-fb.sh" ]] && continue
    [[ "$test_basename_lower" == "_test-results-helper.sh" ]] && continue
    
    if [[ "$QUIET" == "false" ]]; then
        echo "[ >>>> ]  Running $test_basename"
    fi
    
    # Capture test output to parse results
    test_output=""
    test_exit_code=0
    
    if [[ "$QUIET" == "true" ]]; then
        test_output=$(bash "$test_file" 2>&1)
        test_exit_code=$?
    else
        test_output=$(bash "$test_file" 2>&1)
        test_exit_code=$?
        # Display output in non-quiet mode
        echo "$test_output"
    fi
    
    # Parse test results from output
    # Look for "Tests Passed: X / Y" pattern
    passed_count=0
    total_count=0
    percentage=0
    
    if echo "$test_output" | grep -qE "Tests Passed:"; then
        # Extract numbers from "Tests Passed: X / Y" - use more flexible pattern
        passed_line=$(echo "$test_output" | grep -E "Tests Passed:" | tail -1)
        if [[ -n "$passed_line" ]]; then
            # Extract all numbers from the line
            numbers_str=$(echo "$passed_line" | grep -oE "[0-9]+" | tr '\n' ' ')
            numbers=($numbers_str)
            if [[ ${#numbers[@]} -ge 2 ]]; then
                passed_count="${numbers[0]}"
                total_count="${numbers[1]}"
                if [[ "$passed_count" =~ ^[0-9]+$ ]] && [[ "$total_count" =~ ^[0-9]+$ ]] && [[ $total_count -gt 0 ]]; then
                    percentage=$((passed_count * 100 / total_count))
                fi
            fi
        fi
    fi
    
    # Determine if test passed (100% pass rate)
    test_passed=false
    if [[ $total_count -gt 0 ]] && [[ $passed_count -eq $total_count ]]; then
        test_passed=true
    elif [[ $test_exit_code -eq 0 ]] && [[ $total_count -eq 0 ]]; then
        # If no test count found but exit code is 0, assume passed (for scripts without test counting)
        test_passed=true
    fi
    
    if [[ "$test_passed" == "true" ]]; then
        if [[ "$QUIET" == "false" ]]; then
            echo "[ <<<< ]  $test_basename completed"
        fi
        ((passed++))
    else
        if [[ "$QUIET" == "false" ]]; then
            if [[ $total_count -gt 0 ]]; then
                echo "[ <<<< ]  $test_basename failed ($passed_count/$total_count tests passed, ${percentage}%)"
            else
                echo "[ <<<< ]  $test_basename failed (exit code: $test_exit_code)"
            fi
        else
            if [[ $total_count -gt 0 ]]; then
                echo "[ FAIL ]  $test_basename: $passed_count/$total_count tests passed (${percentage}%)" >&2
            else
                echo "[ FAIL ]  $test_basename failed (exit code: $test_exit_code)" >&2
            fi
        fi
        ((failed++))
        if [[ "$FAIL_FAST" == "true" ]]; then
            if [[ $total_count -gt 0 ]]; then
                echo "[ FAIL ]  Fail-fast enabled, stopping after $test_basename ($passed_count/$total_count tests passed, ${percentage}%)" >&2
            else
                echo "[ FAIL ]  Fail-fast enabled, stopping after $test_basename (exit code: $test_exit_code)" >&2
            fi
            exit 1
        fi
    fi
    
    if [[ "$QUIET" == "false" ]]; then
        echo ""
    fi
done

# Cleanup function for test files
cleanup_test_files() {
    # Clean up .results files
    if [[ -n "${__UNIT_TESTS_DIR:-}" ]] && [[ -d "$__UNIT_TESTS_DIR" ]]; then
        shopt -s nullglob
        for results_file in "${__UNIT_TESTS_DIR}"/*.results; do
            [[ -f "$results_file" ]] && rm -f "$results_file" 2>/dev/null || true
        done
        shopt -u nullglob
        
        # Clean up any leftover test directories
        shopt -s nullglob
        for test_dir in "${__UNIT_TESTS_DIR}"/test_pwd_* "${__UNIT_TESTS_DIR}"/test_timer_* "${__UNIT_TESTS_DIR}"/test_*_dir.* "${__UNIT_TESTS_DIR}"/test_*_timers; do
            [[ -d "$test_dir" ]] && rm -rf "$test_dir" 2>/dev/null || true
        done
        shopt -u nullglob
    fi
    
    # Clean up test files in /tmp/
    rm -f /tmp/pokefetch.txt /tmp/pokefetch.txt2 2>/dev/null || true
}

# Register cleanup trap
trap cleanup_test_files EXIT INT TERM

# Summary output
if [[ "$QUIET" == "false" ]]; then
    echo "[ >>>> ]  $passed tests passed"
    echo "[ <<<< ]  $failed tests failed"
    echo ""
fi

total=$((passed + failed))
if [[ $total -gt 0 ]]; then
    if [[ "$QUIET" == "false" ]]; then
        echo "[ >>>> ]  Total tests: $total"
        echo "[ <<<< ]  Passed: $passed"
        echo "[ <<<< ]  Failed: $failed"
        echo ""
        echo "[ >>>> ]  Pass percentage: $((passed * 100 / total))%"
        echo "[ <<<< ]  Failed percentage: $((failed * 100 / total))%"
    else
        # Minimal output for quiet mode
        echo "Tests: $total | Passed: $passed | Failed: $failed | Pass rate: $((passed * 100 / total))%"
    fi
    
    # Cleanup before exit
    cleanup_test_files
    
    # Exit with appropriate code for CI: 0 if all passed, 1 if any failed
    if [[ $failed -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
else
    if [[ "$QUIET" == "false" ]]; then
        echo "[ >>>> ]  No tests found to run"
    else
        echo "No tests found to run"
    fi
    
    # Cleanup before exit
    cleanup_test_files
    
    exit 2  # Exit 2 indicates no tests found (different from test failure)
fi