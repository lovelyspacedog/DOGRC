#!/bin/bash
# Sourcing Guard - check if runtests function already exists
if declare -f runtests >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

runtests() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp runtests
            return 0
        else
            echo "Runs the DOGRC unit test suite in a tmux session."
            echo ""
            echo "Usage: runtests"
            echo ""
            echo "This command launches the unit test runner which displays:"
            echo "  - Left pane: Real-time overview of all test results"
            echo "  - Right pane: Live output from the currently running test"
            echo ""
            echo "Controls:"
            echo "  - Press 'q' to quit the test session"
            echo "  - Session auto-closes 5 seconds after all tests complete"
            return 0
        fi
    fi
    
    local test_runner="${__DOGRC_DIR}/unit-tests/_TEST-ALL.sh"
    
    if [[ ! -f "$test_runner" ]]; then
        echo "Error: Test runner not found at $test_runner" >&2
        return 1
    fi
    
    # Check if tmux is available
    if ! command -v tmux >/dev/null 2>&1; then
        echo "Error: tmux is required to run tests" >&2
        echo "Please install tmux to use the test runner" >&2
        return 1
    fi
    
    # Execute the test runner
    bash "$test_runner" "$@"
}

