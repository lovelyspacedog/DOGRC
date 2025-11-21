#!/bin/bash

# DOGRC Unit Test Runner
# Runs all unit tests in tmux with split panes showing overview and execution
# Each test writes its results to a .results file that is read by the overview
#
# Usage:
#   ./_TEST-ALL.sh                  # Interactive mode with tmux (default, sequential)
#   ./_TEST-ALL.sh --parallel       # Interactive mode with parallel execution
#   ./_TEST-ALL.sh -EGG             # Interactive mode with cbonsai in right pane
#   ./_TEST-ALL.sh --ci             # CI mode (delegates to _test-all-fb.sh)
#   ./_TEST-ALL.sh --ci --quiet --fail-fast  # CI mode with options

readonly __UNIT_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __TESTING_DIR="$(cd "${__UNIT_TESTS_DIR}/.." && pwd)"

# Check for --ci flag and delegate to _test-all-fb.sh if present
# Make check case-insensitive and handle variations
CI_MODE=false
STAGE_MODE=false
PARALLEL_MODE=false
EGG_MODE=false
STAGE_TARGET=""
for arg in "$@"; do
    # Check for --ci (case-insensitive)
    if [[ "${arg,,}" == "--ci" ]] || [[ "$arg" == "--ci" ]]; then
        CI_MODE=true
        # Continue checking for other flags even in CI mode
    fi
    # Check for --stage, --STAGE, -s, -S (case-insensitive)
    if [[ "${arg,,}" == "--stage" ]] || [[ "$arg" == "--STAGE" ]] || [[ "$arg" == "-s" ]] || [[ "$arg" == "-S" ]]; then
        STAGE_MODE=true
        # Continue to find the target test file argument
    fi
    # Check for --parallel, --PARALLEL, -p, -P (case-insensitive)
    if [[ "${arg,,}" == "--parallel" ]] || [[ "$arg" == "--PARALLEL" ]] || [[ "$arg" == "-p" ]] || [[ "$arg" == "-P" ]]; then
        PARALLEL_MODE=true
        # Debug: confirm parallel mode was detected
        echo "Parallel mode enabled" >&2
    fi
    # Check for -EGG, --EGG, -egg, --egg (case-insensitive)
    if [[ "${arg,,}" == "-egg" ]] || [[ "${arg,,}" == "--egg" ]] || [[ "$arg" == "-EGG" ]] || [[ "$arg" == "--EGG" ]]; then
        EGG_MODE=true
    fi
done

if [[ "$CI_MODE" == "true" ]]; then
    # Delegate to the CI-friendly test runner
    ci_runner="${__UNIT_TESTS_DIR}/_test-all-fb.sh"
    if [[ ! -f "$ci_runner" ]]; then
        echo "Error: CI test runner not found: $ci_runner" >&2
        exit 1
    fi
    # Pass through all arguments except --ci
    args=()
    for a in "$@"; do
        [[ "$a" != "--ci" ]] && args+=("$a")
    done
    # Use exec to replace this process - CRITICAL: script must not continue past this point
    # If exec fails for any reason, exit immediately
    # DEBUG: About to exec to _test-all-fb.sh - this should prevent tmux from starting
    exec bash "$ci_runner" "${args[@]}"
    # If we reach here, exec failed - exit immediately to prevent tmux from starting
    echo "ERROR: exec failed! CI mode detected but exec did not work. Aborting to prevent tmux." >&2
    exit 1
fi

# Safety check: If CI_MODE is still true here, something went wrong with exec
# Exit immediately to prevent any tmux code from running
if [[ "$CI_MODE" == "true" ]]; then
    echo "Error: CI mode detected but exec failed - aborting to prevent tmux" >&2
    exit 1
fi

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Check if tmux is available
if ! command -v tmux >/dev/null 2>&1; then
    echo -e "${RED}Error: tmux is not installed${NC}" >&2
    echo -e "${YELLOW}Please install tmux to use this test runner${NC}" >&2
    exit 1
fi

# Get all test files
test_files=("${__UNIT_TESTS_DIR}"/test-*.sh)
if [[ ${#test_files[@]} -eq 0 ]] || [[ ! -f "${test_files[0]}" ]]; then
    echo -e "${RED}Error: No test files found in ${__UNIT_TESTS_DIR}${NC}" >&2
    exit 1
fi

# Sort test files alphabetically
IFS=$'\n' test_files=($(printf '%s\n' "${test_files[@]}" | sort))
unset IFS

# Handle --stage mode: find target test and include adjacent tests
if [[ "$STAGE_MODE" == "true" ]]; then
    # Find the target test file from arguments (after --stage flag)
    found_stage_flag=false
    for arg in "$@"; do
        # Check if this is a stage flag
        if [[ "${arg,,}" == "--stage" ]] || [[ "$arg" == "--STAGE" ]] || [[ "$arg" == "-s" ]] || [[ "$arg" == "-S" ]]; then
            found_stage_flag=true
            continue
        fi
        # If we found the flag, the next non-flag argument is the target
        if [[ "$found_stage_flag" == true ]]; then
            # Skip other flags (--ci, --quiet, etc.)
            if [[ "$arg" == --* ]] || [[ "$arg" == -[a-zA-Z] ]]; then
                continue
            fi
            # This should be the target test file
            STAGE_TARGET="$arg"
            found_stage_flag=false
            break
        fi
    done

    # If no target specified, use the next argument after flag or default
    if [[ -z "$STAGE_TARGET" ]]; then
        # Look for test filename pattern in remaining args
        for arg in "$@"; do
            if [[ "$arg" == test-*.sh ]] || [[ "$arg" == *test-*.sh ]] || [[ "$arg" == test-* ]] || [[ -f "$arg" ]]; then
                STAGE_TARGET="$arg"
                break
            fi
        done
    fi

    if [[ -z "$STAGE_TARGET" ]]; then
        echo -e "${RED}Error: --stage flag requires a test file name${NC}" >&2
        echo -e "${YELLOW}Usage: ${NC}./_TEST-ALL.sh --stage <test-file>" >&2
        echo -e "${YELLOW}Example: ${NC}./_TEST-ALL.sh --stage test-dupefind.sh" >&2
        echo -e "${YELLOW}Example: ${NC}./_TEST-ALL.sh --stage dupefind" >&2
        echo -e "${YELLOW}Available tests:${NC}" >&2
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
        echo -e "${RED}Error: Invalid test target specified: ${STAGE_TARGET}${NC}" >&2
        exit 1
    fi

    # Find the target test in the sorted array
    target_index=-1
    i=0
    for test_file in "${test_files[@]}"; do
        test_name=$(basename "$test_file" .sh)
        test_base="${test_name#test-}"

        # Match by exact base name first (most specific) - this is the primary match
        if [[ "$test_base" == "$normalized_target" ]]; then
            target_index=$i
            break
        fi
        # Then try full test name match (if user provided full name)
        if [[ "$test_name" == "$STAGE_TARGET" ]] || [[ "$test_name" == "test-${STAGE_TARGET}" ]]; then
            target_index=$i
            break
        fi
        ((i++))
    done

    # If still not found, try substring match as last resort (but only if no exact match)
    if [[ $target_index -eq -1 ]]; then
        i=0
        for test_file in "${test_files[@]}"; do
            test_name=$(basename "$test_file" .sh)
            test_base="${test_name#test-}"
            # Substring match in the base name only (not full path)
            if [[ "$test_base" == *"${normalized_target}"* ]]; then
                target_index=$i
                break
            fi
            ((i++))
        done
    fi

    if [[ $target_index -eq -1 ]]; then
        echo -e "${RED}Error: Test file not found: ${STAGE_TARGET}${NC}" >&2
        echo -e "${YELLOW}Available tests:${NC}" >&2
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

    echo -e "${CYAN}Stage mode: Running ${#test_files[@]} test(s)${NC}" >&2
    for test_file in "${test_files[@]}"; do
        test_name=$(basename "$test_file" .sh)
        if [[ "$test_file" == "$target_file" ]]; then
            echo -e "  ${BLUE}►${NC} ${GREEN}$test_name${NC} (target)" >&2
        else
            echo -e "  ${BLUE}•${NC} $test_name" >&2
        fi
    done
    echo >&2
fi

# Clean up any old .results files and test directories
for test_file in "${test_files[@]}"; do
    test_name=$(basename "$test_file" .sh)
    results_file="${__UNIT_TESTS_DIR}/${test_name}.results"
    rm -f "$results_file"
done

# Clean up any leftover test directories from previous runs
shopt -s nullglob
for test_dir in "${__UNIT_TESTS_DIR}"/test_pwd_* "${__UNIT_TESTS_DIR}"/test_timer_* "${__UNIT_TESTS_DIR}"/test_*_dir.* "${__UNIT_TESTS_DIR}"/test_*_timers; do
    [[ -d "$test_dir" ]] && rm -rf "$test_dir" 2>/dev/null || true
done
shopt -u nullglob

# Cleanup function to remove all results files and temporary files
cleanup_test_runner() {
    # Remove all .results files
    if [[ -n "${__UNIT_TESTS_DIR:-}" ]] && [[ -d "$__UNIT_TESTS_DIR" ]]; then
        printf "Cleaning up test results files...\n" >&2
        shopt -s nullglob
        for results_file in "${__UNIT_TESTS_DIR}"/*.results; do
            [[ -f "$results_file" ]] && rm -f "$results_file" 2>/dev/null || true
        done
        shopt -u nullglob
        
        # Clean up any leftover test directories (test_pwd_*, test_timer_*, etc.)
        printf "Cleaning up test directories...\n" >&2
        shopt -s nullglob
        for test_dir in "${__UNIT_TESTS_DIR}"/test_pwd_* "${__UNIT_TESTS_DIR}"/test_timer_* "${__UNIT_TESTS_DIR}"/test_*_dir.* "${__UNIT_TESTS_DIR}"/test_*_timers; do
            [[ -d "$test_dir" ]] && rm -rf "$test_dir" 2>/dev/null || true
        done
        shopt -u nullglob
    fi
    
    # Remove temporary files created by test runner (using $$ for current process)
    printf "Cleaning up temporary files...\n" >&2
    rm -f /tmp/dogrc_overview_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_init_left_$$.sh 2>/dev/null || true
    rm -f /tmp/dogrc_init_right_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_summary_$$.txt 2>/dev/null || true
    # Clean up all wrapper files (including parallel mode ones)
    shopt -s nullglob
    for wrapper_file in /tmp/dogrc_run_wrapper_*_$$.sh /tmp/dogrc_run_wrapper_$$.sh; do
        [[ -f "$wrapper_file" ]] && rm -f "$wrapper_file" 2>/dev/null || true
    done
    shopt -u nullglob
    rm -f /tmp/dogrc_suite_start_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_test_start_*_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_test_end_*_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_test_pid_*_$$.txt 2>/dev/null || true
    rm -f /tmp/dogrc_tests_complete_$$.txt 2>/dev/null || true
    
    # Clean up test-related files in /tmp/ (pokefetch.txt, old dogrc files, etc.)
    printf "Cleaning up test files in /tmp/...\n" >&2
    rm -f /tmp/pokefetch.txt 2>/dev/null || true
    rm -f /tmp/pokefetch.txt2 2>/dev/null || true
    # Clean up old dogrc_overview files (from previous runs)
    shopt -s nullglob
    for old_file in /tmp/dogrc_overview_*.txt /tmp/dogrc_init_left_*.sh /tmp/dogrc_init_right_*.txt; do
        [[ -f "$old_file" ]] && rm -f "$old_file" 2>/dev/null || true
    done
    shopt -u nullglob
    
    # Kill tmux session if it exists
    tmux kill-session -t "dogrc-tests" 2>/dev/null || true
    
    # Kill any background processes from this script
    local job_pids
    job_pids=$(jobs -p 2>/dev/null || true)
    if [[ -n "$job_pids" ]]; then
        echo "$job_pids" | while read -r pid; do
            [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
        done
    fi
}

# Register cleanup trap (will run on exit, interrupt, or termination)
# Use a flag to prevent multiple cleanups
CLEANUP_DONE=false
cleanup_with_exit() {
    if [[ "$CLEANUP_DONE" == "true" ]]; then
        return
    fi
    CLEANUP_DONE=true
    cleanup_test_runner
}

trap cleanup_with_exit EXIT INT TERM

# Function to read results from a .results file
read_results_file() {
    local results_file="$1"
    if [[ ! -f "$results_file" ]]; then
        echo "PENDING|0|0|0.0"
        return
    fi
    
    # Read the file - format: STATUS|SCORE|TOTAL|PERCENTAGE
    local line=$(head -1 "$results_file" 2>/dev/null || echo "")
    if [[ -z "$line" ]]; then
        echo "RUNNING|0|0|0.0"
        return
    fi
    
    echo "$line"
}

# Function to get visible length of a string (ignoring ANSI codes)
visible_length() {
    local str="$1"
    # Remove ANSI escape sequences and count characters
    # Use printf %b to interpret escape sequences, then strip them
    local clean_str=$(printf "%b" "$str" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo "$str" | sed 's/\x1b\[[0-9;]*m//g')
    echo -n "${#clean_str}"
}

# Function to pad a string to a specific visible width
pad_to_width() {
    local str="$1"
    local target_width="$2"
    local visible_len=$(visible_length "$str")
    local padding=$((target_width - visible_len))
    if [[ $padding -gt 0 ]]; then
        # Build padding string
        local pad_str=""
        local i=0
        while [[ $i -lt $padding ]]; do
            pad_str+=" "
            ((i++))
        done
        printf "%s%s" "$str" "$pad_str"
    else
        printf "%s" "$str"
    fi
}

# Function to format elapsed time
format_elapsed_time() {
    local seconds="$1"
    if [[ -z "$seconds" ]] || [[ "$seconds" -lt 0 ]]; then
        echo "-"
        return
    fi
    
    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${minutes}m ${secs}s"
    else
        local hours=$((seconds / 3600))
        local mins=$(((seconds % 3600) / 60))
        local secs=$((seconds % 60))
        echo "${hours}h ${mins}m ${secs}s"
    fi
}

# Function to get elapsed time for a test
get_test_elapsed_time() {
    local test_name="$1"
    local start_file="/tmp/dogrc_test_start_${test_name}_$$.txt"
    local end_file="/tmp/dogrc_test_end_${test_name}_$$.txt"
    
    if [[ ! -f "$start_file" ]]; then
        echo "0"
        return
    fi
    
    local start_time=$(cat "$start_file" 2>/dev/null || echo "0")
    local end_time
    
    # If test has completed, use the recorded end time; otherwise use current time
    if [[ -f "$end_file" ]]; then
        end_time=$(cat "$end_file" 2>/dev/null || echo "0")
    else
        end_time=$(date +%s)
    fi
    
    local elapsed=$((end_time - start_time))
    echo "$elapsed"
}

# Function to update the overview pane
update_overview() {
    local pane_id="$1"
    local overview_file="/tmp/dogrc_overview_$$.txt"
    local suite_start_file="/tmp/dogrc_suite_start_$$.txt"
    
    # Write initial overview
    printf "%b" "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}\n${CYAN}║${NC} ${BLUE}DOGRC Unit Test Suite - Overview${NC}                              ${CYAN}║${NC}\n${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}\n${CYAN}║${NC}                                                              ${CYAN}║${NC}\n${CYAN}║${NC} ${BLUE}Initializing...${NC}                                                  ${CYAN}║${NC}\n${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n" > "$overview_file"
    
    while true; do
        # Get total suite elapsed time
        local suite_elapsed=0
        if [[ -f "$suite_start_file" ]]; then
            local suite_start=$(cat "$suite_start_file" 2>/dev/null || echo "0")
            local current_time=$(date +%s)
            suite_elapsed=$((current_time - suite_start))
        fi
        local suite_elapsed_str=$(format_elapsed_time "$suite_elapsed")
        
        local total_score=0
        local total_tests=0
        local completed=0
        local running=0
        local failed=0
        
        # Build overview display
        local overview=""
        overview+="${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}\n"
        local header_line=" ${BLUE}DOGRC Unit Test Suite - Overview${NC}  ${BLUE}[${suite_elapsed_str}]${NC}"
        local padded_header=$(pad_to_width "$header_line" 62)
        overview+="${CYAN}║${NC}${padded_header}${CYAN}║${NC}\n"
        overview+="${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}\n"
        overview+="${CYAN}║${NC}                                                              ${CYAN}║${NC}\n"
        
        # Read results from .results files
        for test_file in "${test_files[@]}"; do
            local test_name=$(basename "$test_file" .sh)
            local results_file="${__UNIT_TESTS_DIR}/${test_name}.results"
            local results=$(read_results_file "$results_file")
            
            IFS='|' read -r status score total percentage <<< "$results"
            
            # Convert score and total to integers (default to 0 if empty or non-numeric)
            score=$((score + 0))
            total=$((total + 0))
            
            # Extract just the test name (remove test- prefix)
            local display_name="${test_name#test-}"
            
            # Truncate if too long (reduced to make room for elapsed time)
            if [[ ${#display_name} -gt 24 ]]; then
                display_name="${display_name:0:21}..."
            fi
            
            # Determine status color
            local status_color=""
            local status_text=""
            case "$status" in
                "RUNNING")
                    status_color="${YELLOW}"
                    status_text="RUNNING"
                    ((running++))
                    ;;
                "PASSED")
                    status_color="${GREEN}"
                    status_text="PASSED"
                    ((completed++))
                    # Always add to totals for PASSED tests
                    ((total_score += score))
                    ((total_tests += total))
                    if [[ "$score" -ne "$total" ]] || [[ "$total" -eq 0 ]]; then
                        ((failed++))
                    fi
                    ;;
                "FAILED")
                    status_color="${RED}"
                    status_text="FAILED"
                    ((failed++))
                    ((completed++))
                    # Always add to totals for FAILED tests
                    ((total_score += score))
                    ((total_tests += total))
                    ;;
                *)
                    status_color="${BLUE}"
                    status_text="PENDING"
                    ;;
            esac
            
            # Format percentage
            local pct_str=$(printf "%.1f" "$percentage" 2>/dev/null || echo "0.0")
            if (( $(echo "$percentage >= 100" | bc -l 2>/dev/null || echo 0) )); then
                pct_str="${GREEN}${pct_str}%${NC}"
            elif (( $(echo "$percentage >= 80" | bc -l 2>/dev/null || echo 0) )); then
                pct_str="${YELLOW}${pct_str}%${NC}"
            else
                pct_str="${RED}${pct_str}%${NC}"
            fi
            
            # Get elapsed time for this test
            local test_elapsed=$(get_test_elapsed_time "$test_name")
            local elapsed_str=$(format_elapsed_time "$test_elapsed")
            if [[ "$status" == "RUNNING" ]]; then
                elapsed_str="${YELLOW}${elapsed_str}${NC}"
            elif [[ "$status" == "PASSED" ]]; then
                elapsed_str="${GREEN}${elapsed_str}${NC}"
            elif [[ "$status" == "FAILED" ]]; then
                elapsed_str="${RED}${elapsed_str}${NC}"
            else
                elapsed_str="${BLUE}${elapsed_str}${NC}"
            fi
            
            # Add row - ensure exactly 62 visible characters for content (including leading space)
            if [[ "$status" == "PENDING" ]]; then
                local row_content=" ${BLUE}○${NC} $(printf "%-24s" "$display_name") ${BLUE}$(printf "%-7s" "$status_text")${NC}   -/-   -   ${BLUE}-${NC}"
                local padded_content=$(pad_to_width "$row_content" 62)
                overview+="${CYAN}║${NC}${padded_content}${CYAN}║${NC}\n"
            else
                local row_content=" ${status_color}●${NC} $(printf "%-24s" "$display_name") ${status_color}$(printf "%-7s" "$status_text")${NC} ${score}/${total} ${pct_str} ${elapsed_str}"
                local padded_content=$(pad_to_width "$row_content" 62)
                overview+="${CYAN}║${NC}${padded_content}${CYAN}║${NC}\n"
            fi
        done
        
        overview+="${CYAN}║${NC}                                                              ${CYAN}║${NC}\n"
        overview+="${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}\n"
        
        # Calculate overall percentage
        local overall_pct=0.0
        if [[ $total_tests -gt 0 ]]; then
            overall_pct=$(echo "scale=1; $total_score * 100 / $total_tests" | bc 2>/dev/null || echo "0.0")
        fi
        
        # Overall summary
        local overall_color="${GREEN}"
        if (( $(echo "$overall_pct < 100" | bc -l 2>/dev/null || echo 1) )); then
            overall_color="${YELLOW}"
        fi
        if (( $(echo "$overall_pct < 80" | bc -l 2>/dev/null || echo 1) )); then
            overall_color="${RED}"
        fi
        
        local overall_line=" ${BLUE}Overall:${NC} ${total_score}/${total_tests} tests passed ${overall_color}($(printf "%.1f" "$overall_pct")%)${NC}  ${BLUE}Elapsed: ${suite_elapsed_str}${NC}"
        local padded_overall=$(pad_to_width "$overall_line" 62)
        overview+="${CYAN}║${NC}${padded_overall}${CYAN}║${NC}\n"
        
        local status_line=" ${BLUE}Status:${NC} ${GREEN}${completed}${NC} completed, ${YELLOW}${running}${NC} running, ${BLUE}$((${#test_files[@]} - completed - running))${NC} pending"
        local padded_status=$(pad_to_width "$status_line" 62)
        overview+="${CYAN}║${NC}${padded_status}${CYAN}║${NC}\n"
        overview+="${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
        overview+="\n${CYAN}Press 'q' to quit${NC}\n"
        
        # Write overview to a fixed file that the pane can display
        printf "%b" "$overview" > "$overview_file"
        
        sleep 1
    done
}

# Function to write results to .results file
write_results() {
    local results_file="$1"
    local status="$2"
    local score="$3"
    local total="$4"
    local percentage="$5"
    
    echo "${status}|${score}|${total}|${percentage}" > "$results_file"
}

# Function to parse test output and extract results
parse_test_output() {
    local output="$1"
    local score=0
    local total=0
    local percentage=0.0
    
    # Try to extract from "Tests Passed: X / Y" pattern
    local passed_line=$(echo "$output" | grep -E "Tests Passed:.*[0-9]+.*/[0-9]+" -i | tail -1)
    if [[ -n "$passed_line" ]]; then
        local numbers_str=$(echo "$passed_line" | grep -oE "[0-9]+" | tr '\n' ' ')
        local numbers=($numbers_str)
        if [[ ${#numbers[@]} -ge 2 ]]; then
            score="${numbers[0]}"
            total="${numbers[1]}"
            if [[ "$score" =~ ^[0-9]+$ ]] && [[ "$total" =~ ^[0-9]+$ ]]; then
                percentage=$(echo "scale=1; $score * 100 / $total" | bc 2>/dev/null || echo "0.0")
            fi
        fi
    fi
    
    # Try "Score: X/Y" pattern as fallback
    if [[ $total -eq 0 ]]; then
        local score_line=$(echo "$output" | grep -E "Score:.*[0-9]+/[0-9]+" | tail -1)
        if [[ -n "$score_line" ]]; then
            local score_val=$(echo "$score_line" | sed -n 's/.*Score: \([0-9]*\)\/.*/\1/p')
            local total_val=$(echo "$score_line" | sed -n 's/.*Score: [0-9]*\/\([0-9]*\).*/\1/p')
            if [[ -n "$score_val" ]] && [[ -n "$total_val" ]] && [[ "$score_val" =~ ^[0-9]+$ ]] && [[ "$total_val" =~ ^[0-9]+$ ]]; then
                score="$score_val"
                total="$total_val"
                percentage=$(echo "scale=1; $score * 100 / $total" | bc 2>/dev/null || echo "0.0")
            fi
        fi
    fi
    
    echo "$score|$total|$percentage"
}

# Function to run a single test
run_test() {
    local test_file="$1"
    local right_pane="$2"
    local parallel_mode="${3:-false}"  # Optional third parameter for parallel mode
    
    local test_name=$(basename "$test_file" .sh)
    local results_file="${__UNIT_TESTS_DIR}/${test_name}.results"
    local start_file="/tmp/dogrc_test_start_${test_name}_$$.txt"
    local wrapper_file="/tmp/dogrc_run_wrapper_${test_name}_$$.sh"  # Unique wrapper per test
    
    # Record start time for this test
    date +%s > "$start_file"
    
    # Mark as running (test will update this itself)
    write_results "$results_file" "RUNNING" "0" "0" "0.0"
    
    # Only update right pane if not in parallel mode (to avoid conflicts)
    if [[ "$parallel_mode" != "true" ]] && [[ -n "$right_pane" ]]; then
        # Clear right pane and show test name
        tmux send-keys -t "$right_pane" C-c 2>/dev/null
        sleep 0.1
        tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; printf '\033[2J\033[H%b\n\n' '${CYAN}Running: $test_name${NC}'" C-m 2>/dev/null
        sleep 0.2
    fi
    
    # Create wrapper to suppress command echo and set results file
    # Use a here-doc with variable expansion to pass the results file path
    # The wrapper ensures results are written even if test exits early
    # Each test gets its own unique wrapper file to avoid conflicts in parallel mode
    cat > "$wrapper_file" << WRAPPER
#!/bin/bash
set +x  # Disable command tracing
export PS1='$ '
export __TEST_RESULTS_FILE="${results_file}"
unset PROMPT_COMMAND
unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null
set +H
set +m

# Source the test results helper if available (before trap so function is available)
RESULTS_HELPER="${__UNIT_TESTS_DIR}/_test-results-helper.sh"
if [[ -f "\$RESULTS_HELPER" ]]; then
    source "\$RESULTS_HELPER" 2>/dev/null || true
fi

# Trap to ensure results are written on exit
cleanup_test() {
    local exit_code=\$?
    local results_file="${results_file}"
    # Only write if results file doesn't have final status
    if [[ -f "\$results_file" ]]; then
        local status=\$(head -1 "\$results_file" 2>/dev/null | cut -d'|' -f1)
        if [[ "\$status" != "PASSED" ]] && [[ "\$status" != "FAILED" ]]; then
            # Test exited early without writing final results
            if type write_test_results >/dev/null 2>&1; then
                write_test_results "FAILED" "0" "0" "0.0"
            else
                echo "FAILED|0|0|0.0" > "\$results_file"
            fi
        fi
    else
        # No results file at all - test exited very early
        if type write_test_results >/dev/null 2>&1; then
            write_test_results "FAILED" "0" "0" "0.0"
        else
            echo "FAILED|0|0|0.0" > "\$results_file"
        fi
    fi
    exit \$exit_code
}
trap cleanup_test EXIT INT TERM

# Run the test
"\$@"
WRAPPER
    chmod +x "$wrapper_file"
    
    # Run the test - either through tmux or directly in background
    if [[ "$parallel_mode" == "true" ]] || [[ -z "$right_pane" ]]; then
        # Parallel mode: run directly in background without tmux pane
        # Redirect ALL output to /dev/null to prevent interference with htop/top
        # Tests should only communicate via results files, not terminal output
        # Start the test and return the PID immediately (don't wait)
        # Use nohup to ensure process survives if parent exits, and redirect all I/O
        nohup timeout 600 "$wrapper_file" bash --norc --noprofile "$test_file" >/dev/null 2>&1 </dev/null || true &
        local test_pid=$!
        
        # Store PID in a file so we can track it later
        local pid_file="/tmp/dogrc_test_pid_${test_name}_$$.txt"
        echo "$test_pid" > "$pid_file"
        
        # Start a background monitor for this test that will update end time when done
        # This monitor also has all output redirected
        (
            while kill -0 "$test_pid" 2>/dev/null; do
                sleep 1
            done
            # Process finished, record end time
            local end_file="/tmp/dogrc_test_end_${test_name}_$$.txt"
            date +%s > "$end_file" 2>/dev/null
            # Clean up PID file
            rm -f "$pid_file" 2>/dev/null || true
        ) >/dev/null 2>&1 &
        
        # Return immediately - don't wait for test to complete
        return 0
    else
        # Sequential mode: run through tmux pane
        tmux send-keys -t "$right_pane" "timeout 600 '$wrapper_file' bash --norc --noprofile '$test_file' || true" C-m 2>/dev/null
        
        # Wait for test to complete by checking results file
        local wait_count=0
        local max_wait=720  # 6 minutes (720 * 0.5s) to account for timeout + processing
        local last_file_mtime=0
        
        while [[ $wait_count -lt $max_wait ]]; do
            sleep 0.5
            ((wait_count++))
            
            # Check if results file exists and has a final status
            if [[ -f "$results_file" ]]; then
                local status=$(head -1 "$results_file" 2>/dev/null | cut -d'|' -f1)
                if [[ "$status" == "PASSED" ]] || [[ "$status" == "FAILED" ]]; then
                    # Record end time for this test
                    local end_file="/tmp/dogrc_test_end_${test_name}_$$.txt"
                    date +%s > "$end_file"
                    # Wait a bit more to ensure process has fully finished
                    sleep 0.5
                    break
                fi
                
                # Track file modification time to detect if test is still running
                local current_mtime=$(stat -c %Y "$results_file" 2>/dev/null || echo 0)
                if [[ $current_mtime -gt $last_file_mtime ]]; then
                    last_file_mtime=$current_mtime
                fi
                
                # If results file hasn't changed in 30 seconds and status is still RUNNING, it might be stuck
                if [[ $wait_count -gt 60 ]]; then
                    local file_age=$(($(date +%s) - $(stat -c %Y "$results_file" 2>/dev/null || echo 0)))
                    if [[ "$status" == "RUNNING" ]] && [[ $file_age -gt 30 ]]; then
                        # Test seems stuck, but wrapper will handle final results on exit
                        sleep 1
                        local final_status=$(head -1 "$results_file" 2>/dev/null | cut -d'|' -f1)
                        if [[ "$final_status" == "PASSED" ]] || [[ "$final_status" == "FAILED" ]]; then
                            break
                        fi
                    fi
                fi
            fi
        done
    fi
    
    # Final check - if still RUNNING after timeout, mark as failed
    if [[ -f "$results_file" ]]; then
        local status=$(head -1 "$results_file" 2>/dev/null | cut -d'|' -f1)
        if [[ "$status" == "RUNNING" ]]; then
            write_results "$results_file" "FAILED" "0" "0" "0.0"
            # Record end time for failed test
            local end_file="/tmp/dogrc_test_end_${test_name}_$$.txt"
            date +%s > "$end_file"
        fi
    else
        # No results file - mark as failed
        write_results "$results_file" "FAILED" "0" "0" "0.0"
        # Record end time for failed test
        local end_file="/tmp/dogrc_test_end_${test_name}_$$.txt"
        date +%s > "$end_file"
    fi
}

# Main execution
main() {
    # Record suite start time
    local suite_start_file="/tmp/dogrc_suite_start_$$.txt"
    date +%s > "$suite_start_file"
    
    # Kill any existing tmux session with our name
    tmux kill-session -t "dogrc-tests" 2>/dev/null || true
    
    # Create new tmux session
    tmux new-session -d -s "dogrc-tests" -x 120 -y 40
    
    # Set default shell to bash
    tmux set-option -t "dogrc-tests" default-command "/bin/bash --norc --noprofile"
    tmux set-option -t "dogrc-tests" default-shell "/bin/bash"
    
    # Split window into two panes (left 40%, right 60%)
    tmux split-window -h -t "dogrc-tests" -p 40
    
    # Get pane IDs
    local left_pane=$(tmux list-panes -t "dogrc-tests" -F "#{pane_id}" | head -1)
    local right_pane=$(tmux list-panes -t "dogrc-tests" -F "#{pane_id}" | tail -1)
    
    # Set pane titles based on mode
    tmux select-pane -t "$left_pane" -T "Overview"
    if [[ "$EGG_MODE" == "true" ]]; then
        tmux select-pane -t "$right_pane" -T "Bonsai"
    elif [[ "$PARALLEL_MODE" == "true" ]]; then
        tmux select-pane -t "$right_pane" -T "Resource Monitor"
    else
        tmux select-pane -t "$right_pane" -T "Test Output"
    fi
    
    # Set up key binding for 'q' to quit (kill session) - works from any pane
    tmux bind-key -n q kill-session -t "dogrc-tests" 2>/dev/null || true
    
    # Initialize left pane with watch loop for overview
    local overview_file="/tmp/dogrc_overview_$$.txt"
    local init_left="/tmp/dogrc_init_left_$$.sh"
    cat > "$init_left" << INITLEFT
#!/bin/bash
export PS1='$ '
unset PROMPT_COMMAND
unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null
set +H
set +m
overview_file="$overview_file"
while true; do
    if [[ -f "\$overview_file" ]]; then
        printf '\033[2J\033[H'
        cat "\$overview_file"
    else
        printf '\033[2J\033[H'
        echo "Waiting for overview..."
    fi
    sleep 1
done
INITLEFT
    chmod +x "$init_left"
    tmux send-keys -t "$left_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; bash '$init_left'" C-m 2>/dev/null
    
    # Initialize right pane based on mode
    if [[ "$EGG_MODE" == "true" ]]; then
        # EGG mode: Launch cbonsai in the right pane
        # Use exec to replace shell with cbonsai so it can't be interrupted
        if command -v cbonsai >/dev/null 2>&1; then
            # Launch cbonsai with -l -i -L 40 flags
            # Use exec so shell is replaced by cbonsai
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; trap '' INT TERM; exec cbonsai -l -i -L 40" C-m 2>/dev/null
        else
            # If cbonsai is not available, show a message
            local init_right="/tmp/dogrc_init_right_$$.txt"
            printf '\033[2J\033[H' > "$init_right"
            printf '%b\n' "${CYAN}DOGRC Unit Test Suite - EGG Mode${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}cbonsai Unavailable${NC}" >> "$init_right"
            printf '%b\n' "${YELLOW}cbonsai not found. Install cbonsai for bonsai tree display.${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}Tests are running.${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}Check the overview pane (left) for progress.${NC}" >> "$init_right"
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; cat '$init_right'" C-m 2>/dev/null
        fi
    elif [[ "$PARALLEL_MODE" == "true" ]]; then
        # Parallel mode: Launch htop (or top as fallback) for resource monitoring
        # Use exec to replace shell with htop/top so it can't be interrupted
        # Also disable job control signals that might interfere
        if command -v htop >/dev/null 2>&1; then
            # Launch htop in the right pane - use exec so shell is replaced by htop
            # This prevents shell from being killed and htop from being interrupted
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; trap '' INT TERM; exec htop" C-m 2>/dev/null
        elif command -v top >/dev/null 2>&1; then
            # Fallback to top if htop is not available
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; trap '' INT TERM; exec top" C-m 2>/dev/null
        else
            # If neither is available, show a message
            local init_right="/tmp/dogrc_init_right_$$.txt"
            printf '\033[2J\033[H' > "$init_right"
            printf '%b\n' "${CYAN}DOGRC Unit Test Suite - Parallel Mode${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}Resource Monitor Unavailable${NC}" >> "$init_right"
            printf '%b\n' "${YELLOW}htop or top not found. Install htop for system monitoring.${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}Tests are running in the background.${NC}" >> "$init_right"
            printf '%b\n' "${BLUE}Check the overview pane (left) for progress.${NC}" >> "$init_right"
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; cat '$init_right'" C-m 2>/dev/null
        fi
    else
        # Sequential mode: Show waiting message
        local init_right="/tmp/dogrc_init_right_$$.txt"
        printf '\033[2J\033[H' > "$init_right"
        printf '%b\n' "${CYAN}DOGRC Unit Test Suite${NC}" >> "$init_right"
        printf '%b\n' "${BLUE}Waiting for tests to start...${NC}" >> "$init_right"
        tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; cat '$init_right'" C-m 2>/dev/null
    fi
    
    # Start overview updater in background
    update_overview "$left_pane" &
    local overview_pid=$!
    
    # Run all tests (sequentially or in parallel depending on flag)
    (
        if [[ "$PARALLEL_MODE" == "true" ]]; then
            # Parallel execution: run all tests in background
            # Right pane already has htop/top running from initialization
            
            # Start all tests simultaneously
            # Each call to run_test starts a test in background and returns immediately
            local test_pids=()
            local start_time=$(date +%s)
            
            for test_file in "${test_files[@]}"; do
                # run_test starts the test in background and returns immediately in parallel mode
                run_test "$test_file" "$right_pane" "true"
            done
            
            local end_time=$(date +%s)
            local elapsed=$((end_time - start_time))
            # All tests should start in under 1 second (they're all starting in parallel)
            if [[ $elapsed -gt 1 ]]; then
                echo "Warning: Tests took ${elapsed}s to start (expected <1s for parallel)" >&2
            fi
            
            # Give all tests a moment to start and create their PID files
            sleep 0.5
            
            # Collect all PIDs from the PID files that were created
            for test_file in "${test_files[@]}"; do
                local test_name=$(basename "$test_file" .sh)
                local pid_file="/tmp/dogrc_test_pid_${test_name}_$$.txt"
                
                # Try reading the PID file multiple times if needed
                local attempts=0
                while [[ $attempts -lt 5 ]] && [[ ! -f "$pid_file" ]]; do
                    sleep 0.1
                    ((attempts++))
                done
                
                if [[ -f "$pid_file" ]]; then
                    local pid=$(cat "$pid_file" 2>/dev/null | tr -d '[:space:]' || echo "")
                    if [[ -n "$pid" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
                        # Verify the process is still running
                        if kill -0 "$pid" 2>/dev/null; then
                            test_pids+=("$pid")
                        fi
                    fi
                fi
            done
            
            # Wait for all tests to complete by monitoring their PIDs and results files
            local wait_count=0
            local max_wait=720  # 6 minutes per test, but in parallel should finish faster
            local all_complete=false
            
            while [[ $wait_count -lt $max_wait ]] && [[ "$all_complete" == "false" ]]; do
                sleep 1
                ((wait_count++))
                
                # Check if all tests have completed
                all_complete=true
                local still_running=0
                for pid in "${test_pids[@]}"; do
                    if kill -0 "$pid" 2>/dev/null; then
                        all_complete=false
                        ((still_running++))
                    fi
                done
                
                # Also check results files to see if all have final status
                local all_final=true
                for test_file in "${test_files[@]}"; do
                    local test_name=$(basename "$test_file" .sh)
                    local results_file="${__UNIT_TESTS_DIR}/${test_name}.results"
                    if [[ -f "$results_file" ]]; then
                        local status=$(head -1 "$results_file" 2>/dev/null | cut -d'|' -f1)
                        if [[ "$status" != "PASSED" ]] && [[ "$status" != "FAILED" ]]; then
                            all_final=false
                            break
                        fi
                    else
                        all_final=false
                        break
                    fi
                done
                
                # If all have final status, we're done (even if processes are still cleaning up)
                if [[ "$all_final" == "true" ]]; then
                    # Give processes a moment to finish cleanup
                    sleep 2
                    all_complete=true
                    break
                fi
                
                # Every 10 seconds, log progress
                if [[ $((wait_count % 10)) -eq 0 ]] && [[ $still_running -gt 0 ]]; then
                    echo "Still running: $still_running test(s)" >/dev/null
                fi
            done
            
            # Clean up any remaining processes
            for pid in "${test_pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null || true
                    wait "$pid" 2>/dev/null || true
                fi
            done
            
            # Clean up PID files
            shopt -s nullglob
            for pid_file in /tmp/dogrc_test_pid_*_$$.txt; do
                [[ -f "$pid_file" ]] && rm -f "$pid_file" 2>/dev/null || true
            done
            shopt -u nullglob
        else
            # Sequential execution: run tests one at a time
            for test_file in "${test_files[@]}"; do
                run_test "$test_file" "$right_pane" "false"
            done
        fi
        
        # Wait a bit for final updates
        sleep 2
        
        # Show final summary in right pane
        local summary_file="/tmp/dogrc_summary_$$.txt"
        {
            printf '\033[2J\033[H'
            printf '%b\n' "${CYAN}═══════════════════════════════════════════════════════════${NC}"
            printf '%b\n' "${BLUE}All Tests Completed${NC}"
            printf '%b\n' "${CYAN}═══════════════════════════════════════════════════════════${NC}"
            printf '\n'
            
            local total_score=0
            local total_tests=0
            for test_file in "${test_files[@]}"; do
                local test_name=$(basename "$test_file" .sh)
                local results_file="${__UNIT_TESTS_DIR}/${test_name}.results"
                if [[ -f "$results_file" ]]; then
                    IFS='|' read -r status score total percentage <<< "$(head -1 "$results_file")"
                    # Convert to integers (default to 0 if empty or non-numeric)
                    score=$((score + 0))
                    total=$((total + 0))
                    ((total_score += score))
                    ((total_tests += total))
                fi
            done
            
            # Calculate total elapsed time
            local suite_elapsed=0
            local suite_start_file="/tmp/dogrc_suite_start_$$.txt"
            if [[ -f "$suite_start_file" ]]; then
                local suite_start=$(cat "$suite_start_file" 2>/dev/null || echo "0")
                local current_time=$(date +%s)
                suite_elapsed=$((current_time - suite_start))
            fi
            local suite_elapsed_str=$(format_elapsed_time "$suite_elapsed")
            
            if [[ $total_tests -gt 0 ]]; then
                local final_pct=$(echo "scale=1; $total_score * 100 / $total_tests" | bc 2>/dev/null || echo "0.0")
                printf '%b\n' "${BLUE}Total Score:${NC} ${total_score}/${total_tests} tests passed"
                printf '%b\n' "${BLUE}Percentage:${NC} $(printf "%.1f" "$final_pct")%"
            fi
            printf '%b\n' "${BLUE}Total Elapsed Time:${NC} ${suite_elapsed_str}"
            printf '\n'
            printf '%b\n' "${CYAN}Press 'q' to quit (or wait 5 seconds for auto-close)${NC}"
        } > "$summary_file"
        
        # Only show summary in right pane if not in parallel or EGG mode
        # In parallel/EGG mode, keep htop/top/cbonsai running until user quits
        if [[ "$PARALLEL_MODE" != "true" ]] && [[ "$EGG_MODE" != "true" ]]; then
            tmux send-keys -t "$right_pane" "export PS1='$ '; unset PROMPT_COMMAND; unset -f command_not_found_handle pokefetch drcfortune 2>/dev/null; set +H; set +m; printf '\033[2J\033[H'; cat '$summary_file'" C-m 2>/dev/null
        else
            # In parallel/EGG mode, show summary in overview pane only
            # Right pane continues showing htop/top/cbonsai
            # Update overview to show completion status instead
            echo "All tests completed. Check overview pane for results. Press 'q' to quit." >/dev/null
        fi
        
        # Mark that tests are complete by creating a completion file
        echo "done" > "/tmp/dogrc_tests_complete_$$.txt"
    ) &
    local tests_pid=$!
    
    # Monitor for test completion in background and auto-close after delay
    (
        # Wait for tests to complete
        while [[ ! -f "/tmp/dogrc_tests_complete_$$.txt" ]]; do
            sleep 0.5
        done
        
        # Wait 5 seconds for user to review results, then auto-close
        sleep 5
        
        # If session still exists, kill it to unblock the main script
        if tmux has-session -t "dogrc-tests" 2>/dev/null; then
            tmux kill-session -t "dogrc-tests" 2>/dev/null || true
        fi
    ) &
    local monitor_pid=$!
    
    # Attach to tmux session immediately so user can see tests running
    # If user detaches (Ctrl+B D) or presses 'q', this will return
    # Also returns when monitor kills the session after tests complete
    tmux attach-session -t "dogrc-tests" 2>/dev/null || true
    
    # Clean up monitor process
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    
    # Check if session still exists - if not, user quit with 'q'
    if ! tmux has-session -t "dogrc-tests" 2>/dev/null; then
        # Session was killed (user pressed 'q'), capture overview and exit cleanly
        # Stop the overview updater and wait for final update
        kill $overview_pid 2>/dev/null || true
        wait $overview_pid 2>/dev/null || true
        sleep 0.5  # Give it a moment to write final update
        
        # Capture the final overview from the overview file
        local final_overview=""
        if [[ -f "$overview_file" ]]; then
            final_overview=$(cat "$overview_file" 2>/dev/null || echo "")
        fi
        
        # Kill background processes
        kill $tests_pid 2>/dev/null || true
        
        # Output the stored overview before exiting
        if [[ -n "$final_overview" ]]; then
            printf '\n'
            printf '%b' "$final_overview"
            printf '\n'
        fi
        
        return 0
    fi
    
    # Wait for tests to complete if they're still running
    wait $tests_pid 2>/dev/null || true
    
    # Stop the overview updater and wait for final update
    kill $overview_pid 2>/dev/null || true
    wait $overview_pid 2>/dev/null || true
    sleep 0.5  # Give it a moment to write final update
    
    # Capture the final overview from the overview file
    local final_overview=""
    if [[ -f "$overview_file" ]]; then
        final_overview=$(cat "$overview_file" 2>/dev/null || echo "")
    fi
    
    # Kill tmux session if it still exists
    if tmux has-session -t "dogrc-tests" 2>/dev/null; then
        tmux kill-session -t "dogrc-tests" 2>/dev/null || true
    fi
    
    # Kill any remaining background processes
    kill $tests_pid 2>/dev/null || true
    
    # Output the stored overview before exiting
    if [[ -n "$final_overview" ]]; then
        printf '\n'
        printf '%b' "$final_overview"
        printf '\n'
    fi
}

# Run main function (only if not in CI mode)
if [[ "$CI_MODE" != "true" ]]; then
    main
else
    echo "Error: CI mode active - main() should not be called" >&2
    exit 1
fi
