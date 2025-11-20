#!/bin/bash

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command-line arguments
FAIL_FAST=false
QUIET=false

for arg in "$@"; do
    case "$arg" in
        --fail-fast|-f)
            FAIL_FAST=true
            ;;
        --quiet|-q)
            QUIET=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --fail-fast, -f    Stop on first test failure"
            echo "  --quiet, -q        Minimal output (only summary)"
            echo "  --help, -h         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

declare -i passed=0
declare -i failed=0

# Run all unit tests in the unit-tests directory
for test in "${__UNIT_TESTS_DIR}"/*.sh; do
    # Get just the filename (basename) and convert to lowercase for comparison
    test_basename=$(basename "$test")
    test_basename_lower="${test_basename,,}"
    
    # Skip helper files and test runners
    [[ "$test_basename_lower" == "_test-all.sh" ]] && continue
    [[ "$test_basename_lower" == "_test-all-fb.sh" ]] && continue
    [[ "$test_basename_lower" == "_test-results-helper.sh" ]] && continue
    
    if [[ "$QUIET" == "false" ]]; then
        echo "[ >>>> ]  Running $test_basename"
    fi
    
    # Capture test output in quiet mode
    if [[ "$QUIET" == "true" ]]; then
        if bash "$test" >/dev/null 2>&1; then
            ((passed++))
        else
            ((failed++))
            if [[ "$FAIL_FAST" == "true" ]]; then
                echo "[ FAIL ]  $test_basename failed (fail-fast enabled, stopping)" >&2
                exit 1
            fi
        fi
    else
        if bash "$test"; then
            echo "[ <<<< ]  $test_basename completed"
            ((passed++))
        else
            echo "[ <<<< ]  $test_basename failed"
            ((failed++))
            if [[ "$FAIL_FAST" == "true" ]]; then
                echo "[ FAIL ]  Fail-fast enabled, stopping after first failure" >&2
                exit 1
            fi
        fi
        echo ""
    fi
done

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
    exit 2  # Exit 2 indicates no tests found (different from test failure)
fi