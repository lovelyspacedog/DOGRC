#!/bin/bash
# Helper functions for unit tests to write results files
# Source this file in your test script to use write_test_results()
#
# REAL-TIME PROGRESS UPDATES:
# ===========================
# To enable real-time progress updates in the test overview pane:
#
# Option 1: Use print_msg_with_progress (Recommended)
#   - Replace your local print_msg function with print_msg_with_progress
#   - Initialize with: init_auto_progress <total_tests>
#   - Example:
#       total_tests=32
#       init_auto_progress "$total_tests"
#       if print_msg_with_progress 1 "Can I find file?" true; then
#           ((score++))
#       fi
#
# Option 2: Update from existing print_msg
#   - Keep your existing print_msg function
#   - Call update_progress_from_score after each test
#   - Example:
#       if print_msg 1 "Can I find file?" true; then
#           ((score++))
#           update_progress_from_score
#       fi
#
# Option 3: Manual updates
#   - Call update_test_progress after each test step
#   - Example:
#       if test_passes; then
#           ((score++))
#           update_test_progress "$score" "$total_tests"
#       fi

# Function to write test results to .results file
# Usage: write_test_results <status> <score> <total> [percentage]
# Status: RUNNING, PASSED, or FAILED
write_test_results() {
    local status="$1"
    local score="$2"
    local total="$3"
    local percentage="$4"
    
    # Use environment variable if set (preferred method for wrapper scripts)
    local results_file=""
    if [[ -n "$__TEST_RESULTS_FILE" ]]; then
        # Convert to absolute path if it's relative
        if [[ "$__TEST_RESULTS_FILE" != /* ]]; then
            # Try to resolve relative to current directory first
            if [[ -f "$__TEST_RESULTS_FILE" ]] || [[ -d "$(dirname "$__TEST_RESULTS_FILE" 2>/dev/null)" ]]; then
                results_file="$(cd "$(dirname "$__TEST_RESULTS_FILE")" 2>/dev/null && pwd)/$(basename "$__TEST_RESULTS_FILE")"
            else
                # If that fails, try relative to the helper script's directory
                local helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                results_file="${helper_dir}/$(basename "$__TEST_RESULTS_FILE")"
            fi
        else
            results_file="$__TEST_RESULTS_FILE"
        fi
    else
        # Try to find the test script from BASH_SOURCE
        local test_script=""
        local i=1
        while [[ $i -lt ${#BASH_SOURCE[@]} ]]; do
            test_script="${BASH_SOURCE[$i]}"
            if [[ "$test_script" == *"test-"*".sh" ]] && [[ "$test_script" != *"_test-results-helper.sh" ]] && [[ -f "$test_script" ]]; then
                break
            fi
            ((i++))
        done
        
        # Fall back to $0 if BASH_SOURCE didn't work
        if [[ -z "$test_script" ]] || [[ ! -f "$test_script" ]]; then
            test_script="${0}"
        fi
        
        # Build results file path - ensure it's absolute
        if [[ -f "$test_script" ]]; then
            local test_dir="$(cd "$(dirname "$test_script")" 2>/dev/null && pwd)"
            local test_name=$(basename "$test_script" .sh)
            results_file="${test_dir}/${test_name}.results"
        else
            # Last resort: use current directory
            local helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            # Can't determine which test, so fail silently
            return 1
        fi
    fi
    
    # Calculate percentage if not provided
    if [[ -z "$percentage" ]] && [[ "$total" -gt 0 ]]; then
        percentage=$(echo "scale=1; $score * 100 / $total" | bc 2>/dev/null || echo "0.0")
    fi
    
    # Ensure directory exists
    local results_dir="$(dirname "$results_file")"
    mkdir -p "$results_dir" 2>/dev/null || true
    
    # Write results file: STATUS|SCORE|TOTAL|PERCENTAGE
    echo "${status}|${score}|${total}|${percentage}" > "$results_file"
}

# Function to update test results incrementally after each test step
# This function maintains a running score and total, updating the results file in real-time
# Usage: update_test_progress <current_score> <current_total>
# This will automatically calculate percentage and keep status as RUNNING
# Example: After each test passes, call: update_test_progress $score $total_tests
update_test_progress() {
    local current_score="$1"
    local current_total="$2"
    
    # If total is 0, default to 1 to avoid division by zero
    if [[ -z "$current_total" ]] || [[ "$current_total" -eq 0 ]]; then
        current_total=1
    fi
    
    # Write as RUNNING status with current progress
    write_test_results "RUNNING" "$current_score" "$current_total"
}

# Function to initialize test progress tracking
# Call this at the start of your test with the expected total number of tests
# Usage: init_test_progress <total_tests>
# Example: init_test_progress 32
init_test_progress() {
    local total_tests="$1"
    if [[ -z "$total_tests" ]] || [[ "$total_tests" -eq 0 ]]; then
        total_tests=1
    fi
    write_test_results "RUNNING" "0" "$total_tests" "0.0"
}

# Global variables for automatic progress tracking (used by wrapper functions)
__TEST_PROGRESS_SCORE=0
__TEST_PROGRESS_TOTAL=0
__TEST_PROGRESS_INITIALIZED=false

# Function to initialize automatic progress tracking
# This sets up global variables that will be used by print_msg_with_progress
# Usage: init_auto_progress <total_tests>
# Example: init_auto_progress 32
# After calling this, use print_msg_with_progress instead of print_msg
init_auto_progress() {
    local total_tests="$1"
    if [[ -z "$total_tests" ]] || [[ "$total_tests" -eq 0 ]]; then
        total_tests=1
    fi
    __TEST_PROGRESS_SCORE=0
    __TEST_PROGRESS_TOTAL=$total_tests
    __TEST_PROGRESS_INITIALIZED=true
    write_test_results "RUNNING" "0" "$total_tests" "0.0"
}

# Enhanced print_msg function with automatic progress tracking
# This function automatically updates the results file after each test step
# Usage: print_msg_with_progress <test_num> <description> <passed> [increment_score]
#   test_num: Test number or "*" for summary
#   description: Test description
#   passed: "true", "false", "N/A", 1, or 0
#   increment_score: Optional, if "true" or 1, increments score even if test passed
#                    Default behavior: only increments if passed is true/1
# Example: print_msg_with_progress 1 "Can I find file?" true
#          print_msg_with_progress 2 "Does function work?" false
print_msg_with_progress() {
    local test_num="$1"
    local description="$2"
    local passed="$3"
    local increment_score="${4:-auto}"  # "auto", "true", or "false"
    
    # Truncate description if too long
    if [[ ${#description} -gt 70 ]]; then
        description="${description:0:67}..."
    fi
    
    # Sleep for visual effect (same as original print_msg)
    sleep 0.4
    
    # Determine if test passed and whether to increment score
    local should_increment=false
    if [[ "$passed" == "N/A" ]] || [[ "$passed" == "n/a" ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[  N/A   ]"
        # Don't increment for N/A tests
        should_increment=false
    elif [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ PASSED ]"
        # Increment score if test passed (unless explicitly told not to)
        if [[ "$increment_score" != "false" ]]; then
            should_increment=true
        fi
    else
        printf "%-8s %-70s %s\n" "[$test_num]" "$description" "[ FAILED ]"
        # Don't increment for failed tests (unless explicitly told to)
        if [[ "$increment_score" == "true" ]] || [[ "$increment_score" -eq 1 ]]; then
            should_increment=true
        fi
    fi
    
    # Update progress if auto-progress is initialized
    if [[ "$__TEST_PROGRESS_INITIALIZED" == "true" ]] && [[ "$should_increment" == "true" ]]; then
        ((__TEST_PROGRESS_SCORE++))
        update_test_progress "$__TEST_PROGRESS_SCORE" "$__TEST_PROGRESS_TOTAL"
    fi
    
    # Return appropriate exit code
    if [[ "$passed" == "true" ]] || [[ "$passed" -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# Helper function to update progress from existing print_msg functions
# Call this from your existing print_msg function after updating the score
# Usage: update_progress_from_score
# This reads the global 'score' and 'total_tests' variables
# Example: In your print_msg, after incrementing score, call: update_progress_from_score
update_progress_from_score() {
    # Try to read score and total_tests from parent scope
    # This works if called from a function that has access to these variables
    local current_score="${score:-0}"
    local current_total="${total_tests:-0}"
    
    # If auto-progress is initialized, use those values instead
    if [[ "$__TEST_PROGRESS_INITIALIZED" == "true" ]]; then
        current_score="$__TEST_PROGRESS_SCORE"
        current_total="$__TEST_PROGRESS_TOTAL"
    fi
    
    if [[ $current_total -gt 0 ]]; then
        update_test_progress "$current_score" "$current_total"
    fi
}

# Function to get current progress score (for use in tests)
get_progress_score() {
    if [[ "$__TEST_PROGRESS_INITIALIZED" == "true" ]]; then
        echo "$__TEST_PROGRESS_SCORE"
    else
        echo "${score:-0}"
    fi
}

# Function to get current progress total (for use in tests)
get_progress_total() {
    if [[ "$__TEST_PROGRESS_INITIALIZED" == "true" ]]; then
        echo "$__TEST_PROGRESS_TOTAL"
    else
        echo "${total_tests:-0}"
    fi
}

