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
total_tests=0

# Write results file
if type write_test_results >/dev/null 2>&1; then
    if [[ $score -eq $total_tests ]]; then
        write_test_results "PASSED" "$score" "$total_tests" "$percentage"
    else
        write_test_results "FAILED" "$score" "$total_tests" "$percentage"
    fi
fi
printf "Running unit tests for prepfile.sh...\n\n"

# Mark test as running (total_tests will be incremented dynamically)
if type write_test_results >/dev/null 2>&1; then
    write_test_results "RUNNING" "0" "0" "0.0"
fi

# Sanity checks
if [[ -f "${__CORE_DIR}/dependency_check.sh" ]]; then
    if print_msg 1 "Can I find dependency_check.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
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
    ((total_tests++))
else
    print_msg 2 "Can I source dependency_check.sh?" false
    printf "Error: Test cannot continue. Dependency check.sh not found.\n" >&2
    exit 1
fi

if [[ -f "${__PLUGINS_DIR}/utilities/prepfile.sh" ]]; then
    if print_msg 3 "Can I find prepfile.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 3 "Can I find prepfile.sh?" false
    printf "Error: Test cannot continue. prepfile.sh not found.\n" >&2
    exit 1
fi

# Source prepfile.sh
if source "${__PLUGINS_DIR}/utilities/prepfile.sh" 2>/dev/null; then
    if print_msg 4 "Can I source prepfile.sh?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 4 "Can I source prepfile.sh?" false
    printf "Error: Test cannot continue. prepfile.sh not found.\n" >&2
    exit 1
fi

# Check if prepfile function exists
if declare -f prepfile >/dev/null 2>&1; then
    if print_msg 5 "Does prepfile function exist?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 5 "Does prepfile function exist?" false
    printf "Error: prepfile function not found.\n" >&2
    exit 1
fi

# Create temporary directory for testing
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT INT TERM

# Mock drchelp for help tests
drchelp() {
    if [[ "$1" == "prepfile" ]]; then
        echo "prepfile - Prepare New File with Language Templates"
        return 0
    fi
    return 1
}

# Test help flags
cd "$TEST_DIR" || exit 1
if prepfile --help 2>&1 | grep -q "prepfile - Prepare New File"; then
    if print_msg 6 "Does prepfile --help work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 6 "Does prepfile --help work?" false
    ((total_tests++))
fi

cd "$TEST_DIR" || exit 1
if prepfile -h 2>&1 | grep -q "prepfile - Prepare New File"; then
    if print_msg 7 "Does prepfile -h work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 7 "Does prepfile -h work?" false
    ((total_tests++))
fi

# Test help flags with type flags (alias compatibility)
cd "$TEST_DIR" || exit 1
if prepfile --bash --help 2>&1 | grep -q "prepfile - Prepare New File"; then
    if print_msg 8 "Does prepfile --bash --help work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 8 "Does prepfile --bash --help work?" false
    ((total_tests++))
fi

cd "$TEST_DIR" || exit 1
if prepfile --python -h 2>&1 | grep -q "prepfile - Prepare New File"; then
    if print_msg 9 "Does prepfile --python -h work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 9 "Does prepfile --python -h work?" false
    ((total_tests++))
fi

# Test default behavior (no arguments)
cd "$TEST_DIR" || exit 1
echo "n" | prepfile >/dev/null 2>&1
if [[ -f "main.sh" ]] && [[ -x "main.sh" ]] && head -1 "main.sh" | grep -q "#!/usr/bin/env bash"; then
    if print_msg 10 "Does prepfile create main.sh by default?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 10 "Does prepfile create main.sh by default?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test all type flags - Bash
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --bash test1 >/dev/null 2>&1
if [[ -f "test1.sh" ]] && [[ -x "test1.sh" ]] && head -1 "test1.sh" | grep -q "#!/usr/bin/env bash"; then
    if print_msg 11 "Does --bash flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 11 "Does --bash flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --sh test2 >/dev/null 2>&1
if [[ -f "test2.sh" ]] && [[ -x "test2.sh" ]]; then
    if print_msg 12 "Does --sh flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 12 "Does --sh flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Python
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python test3 >/dev/null 2>&1
if [[ -f "test3.py" ]] && [[ -x "test3.py" ]] && head -1 "test3.py" | grep -q "#!/usr/bin/env python3"; then
    if print_msg 13 "Does --python flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 13 "Does --python flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --py test4 >/dev/null 2>&1
if [[ -f "test4.py" ]] && [[ -x "test4.py" ]]; then
    if print_msg 14 "Does --py flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 14 "Does --py flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Rust
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --rust test5 >/dev/null 2>&1
if [[ -f "test5.rs" ]] && ! [[ -x "test5.rs" ]] && grep -q "fn main()" "test5.rs"; then
    if print_msg 15 "Does --rust flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 15 "Does --rust flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --rs test6 >/dev/null 2>&1
if [[ -f "test6.rs" ]] && grep -q "fn main()" "test6.rs"; then
    if print_msg 16 "Does --rs flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 16 "Does --rs flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Go
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --go test7 >/dev/null 2>&1
if [[ -f "test7.go" ]] && ! [[ -x "test7.go" ]] && grep -q "package main" "test7.go" && grep -q "func main()" "test7.go"; then
    if print_msg 17 "Does --go flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 17 "Does --go flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test JavaScript
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --javascript test8 >/dev/null 2>&1
if [[ -f "test8.js" ]] && [[ -x "test8.js" ]] && head -1 "test8.js" | grep -q "#!/usr/bin/env node"; then
    if print_msg 18 "Does --javascript flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 18 "Does --javascript flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --js test9 >/dev/null 2>&1
if [[ -f "test9.js" ]] && [[ -x "test9.js" ]]; then
    if print_msg 19 "Does --js flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 19 "Does --js flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test TypeScript
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --typescript test10 >/dev/null 2>&1
if [[ -f "test10.ts" ]] && ! [[ -x "test10.ts" ]] && [[ ! -s "test10.ts" ]] || [[ $(wc -c < "test10.ts") -le 1 ]]; then
    if print_msg 20 "Does --typescript flag work (empty template)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 20 "Does --typescript flag work (empty template)?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --ts test11 >/dev/null 2>&1
if [[ -f "test11.ts" ]]; then
    if print_msg 21 "Does --ts flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 21 "Does --ts flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test C
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --c test12 >/dev/null 2>&1
if [[ -f "test12.c" ]] && ! [[ -x "test12.c" ]] && grep -q "#include <stdio.h>" "test12.c" && grep -q "int main()" "test12.c"; then
    if print_msg 22 "Does --c flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 22 "Does --c flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test C++
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --cpp test13 >/dev/null 2>&1
if [[ -f "test13.cpp" ]] && ! [[ -x "test13.cpp" ]] && grep -q "#include <iostream>" "test13.cpp" && grep -q "int main()" "test13.cpp"; then
    if print_msg 23 "Does --cpp flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 23 "Does --cpp flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --c++ test14 >/dev/null 2>&1
if [[ -f "test14.cpp" ]] && ! [[ -x "test14.cpp" ]]; then
    if print_msg 24 "Does --c++ flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 24 "Does --c++ flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Java
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --java test15 >/dev/null 2>&1
if [[ -f "test15.java" ]] && ! [[ -x "test15.java" ]] && grep -q "public class Main" "test15.java" && grep -q "public static void main" "test15.java"; then
    if print_msg 25 "Does --java flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 25 "Does --java flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Ruby
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --ruby test16 >/dev/null 2>&1
if [[ -f "test16.rb" ]] && [[ -x "test16.rb" ]] && head -1 "test16.rb" | grep -q "#!/usr/bin/env ruby"; then
    if print_msg 26 "Does --ruby flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 26 "Does --ruby flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --rb test17 >/dev/null 2>&1
if [[ -f "test17.rb" ]] && [[ -x "test17.rb" ]]; then
    if print_msg 27 "Does --rb flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 27 "Does --rb flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Perl
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --perl test18 >/dev/null 2>&1
if [[ -f "test18.pl" ]] && [[ -x "test18.pl" ]] && head -1 "test18.pl" | grep -q "#!/usr/bin/env perl" && grep -q "use strict" "test18.pl" && grep -q "use warnings" "test18.pl"; then
    if print_msg 28 "Does --perl flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 28 "Does --perl flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --pl test19 >/dev/null 2>&1
if [[ -f "test19.pl" ]] && [[ -x "test19.pl" ]]; then
    if print_msg 29 "Does --pl flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 29 "Does --pl flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test PHP
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --php test20 >/dev/null 2>&1
if [[ -f "test20.php" ]] && [[ -x "test20.php" ]] && head -1 "test20.php" | grep -q "#!/usr/bin/env php" && grep -q "<?php" "test20.php"; then
    if print_msg 30 "Does --php flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 30 "Does --php flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Lua
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --lua test21 >/dev/null 2>&1
if [[ -f "test21.lua" ]] && [[ -x "test21.lua" ]] && head -1 "test21.lua" | grep -q "#!/usr/bin/env lua"; then
    if print_msg 31 "Does --lua flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 31 "Does --lua flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Zsh
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --zsh test22 >/dev/null 2>&1
if [[ -f "test22.zsh" ]] && [[ -x "test22.zsh" ]] && head -1 "test22.zsh" | grep -q "#!/usr/bin/env zsh"; then
    if print_msg 32 "Does --zsh flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 32 "Does --zsh flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test Fish
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --fish test23 >/dev/null 2>&1
if [[ -f "test23.fish" ]] && [[ -x "test23.fish" ]] && head -1 "test23.fish" | grep -q "#!/usr/bin/env fish"; then
    if print_msg 33 "Does --fish flag work?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 33 "Does --fish flag work?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test default filenames for each type
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python >/dev/null 2>&1
if [[ -f "main.py" ]]; then
    if print_msg 34 "Does prepfile --python create main.py by default?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 34 "Does prepfile --python create main.py by default?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --rust >/dev/null 2>&1
if [[ -f "main.rs" ]]; then
    if print_msg 35 "Does prepfile --rust create main.rs by default?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 35 "Does prepfile --rust create main.rs by default?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --java >/dev/null 2>&1
if [[ -f "Main.java" ]]; then
    if print_msg 36 "Does prepfile --java create Main.java by default (capitalized)?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 36 "Does prepfile --java create Main.java by default (capitalized)?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test extension handling
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python script >/dev/null 2>&1
if [[ -f "script.py" ]]; then
    if print_msg 37 "Does prepfile add .py extension if missing?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 37 "Does prepfile add .py extension if missing?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python script.py >/dev/null 2>&1
if [[ -f "script.py" ]]; then
    if print_msg 38 "Does prepfile preserve .py extension if present?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 38 "Does prepfile preserve .py extension if present?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test type flag position (before or after filename)
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --go app >/dev/null 2>&1
if [[ -f "app.go" ]]; then
    if print_msg 39 "Does prepfile work with type flag before filename?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 39 "Does prepfile work with type flag before filename?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile app --go >/dev/null 2>&1
if [[ -f "app.go" ]]; then
    if print_msg 40 "Does prepfile work with type flag after filename?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 40 "Does prepfile work with type flag after filename?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test error handling - file already exists
cd "$TEST_DIR" || exit 1
touch existing.sh
if prepfile existing.sh 2>&1 <<< "n" | grep -q "Can't create.*file already exists"; then
    if print_msg 41 "Does prepfile error when file already exists?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 41 "Does prepfile error when file already exists?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test that existing file is not overwritten
cd "$TEST_DIR" || exit 1
echo "original content" > existing.sh
prepfile existing.sh 2>&1 <<< "n" >/dev/null
if [[ -f "existing.sh" ]] && grep -q "original content" "existing.sh"; then
    if print_msg 42 "Does prepfile preserve existing file content?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 42 "Does prepfile preserve existing file content?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test output message format
cd "$TEST_DIR" || exit 1
output=$(echo "n" | prepfile --python test 2>&1)
if echo "$output" | grep -qE "Created test\.py \(python template\)"; then
    if print_msg 43 "Does prepfile output correct success message?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 43 "Does prepfile output correct success message?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test that script files are executable
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --bash test_script >/dev/null 2>&1
if [[ -x "test_script.sh" ]]; then
    if print_msg 44 "Are bash script files made executable?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 44 "Are bash script files made executable?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test that compiled language files are NOT executable
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --c test_c >/dev/null 2>&1
if [[ -f "test_c.c" ]] && ! [[ -x "test_c.c" ]]; then
    if print_msg 45 "Are C files NOT made executable?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 45 "Are C files NOT made executable?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
echo "n" | prepfile --rust test_rust >/dev/null 2>&1
if [[ -f "test_rust.rs" ]] && ! [[ -x "test_rust.rs" ]]; then
    if print_msg 46 "Are Rust files NOT made executable?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 46 "Are Rust files NOT made executable?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test filenames with spaces
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python "test file" >/dev/null 2>&1
if [[ -f "test file.py" ]]; then
    if print_msg 47 "Does prepfile handle filenames with spaces?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 47 "Does prepfile handle filenames with spaces?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test multiple type flags (last one should win)
cd "$TEST_DIR" || exit 1
echo "n" | prepfile --python --rust test_multi >/dev/null 2>&1
if [[ -f "test_multi.rs" ]] && grep -q "fn main()" "test_multi.rs"; then
    if print_msg 48 "Does prepfile use last type flag when multiple provided?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 48 "Does prepfile use last type flag when multiple provided?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test direct script execution
cd "$TEST_DIR" || exit 1
if bash "${__PLUGINS_DIR}/utilities/prepfile.sh" --python direct_test <<< "n" >/dev/null 2>&1; then
    if [[ -f "direct_test.py" ]]; then
        if print_msg 49 "Does prepfile.sh work when executed directly?" true; then
            ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
        fi
        ((total_tests++))
    else
        print_msg 49 "Does prepfile.sh work when executed directly?" false
        ((total_tests++))
    fi
else
    print_msg 49 "Does prepfile.sh work when executed directly?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Test error when drchelp not available
cd "$TEST_DIR" || exit 1
unset -f drchelp
if prepfile --help 2>&1 | grep -q "Error: drchelp not available"; then
    if print_msg 50 "Does prepfile error when drchelp not available?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 50 "Does prepfile error when drchelp not available?" false
    ((total_tests++))
fi
# Restore drchelp mock
drchelp() {
    if [[ "$1" == "prepfile" ]]; then
        echo "prepfile - Prepare New File with Language Templates"
        return 0
    fi
    return 1
}

# Test return codes
cd "$TEST_DIR" || exit 1
touch existing_file.sh
if ! prepfile existing_file.sh <<< "n" >/dev/null 2>&1; then
    if print_msg 51 "Does prepfile return non-zero when file exists?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 51 "Does prepfile return non-zero when file exists?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

cd "$TEST_DIR" || exit 1
if prepfile --python test_success <<< "n" >/dev/null 2>&1; then
    if print_msg 52 "Does prepfile return zero on success?" true; then
        ((score++))
        if type update_progress_from_score >/dev/null 2>&1; then
            update_progress_from_score
        fi
    fi
    ((total_tests++))
else
    print_msg 52 "Does prepfile return zero on success?" false
    ((total_tests++))
fi
rm -f "$TEST_DIR"/* 2>/dev/null

# Summary
((total_tests++))
if print_msg "*" "Total: $score/$((total_tests - 1)) tests passed" true; then
    ((score++))
    if type update_progress_from_score >/dev/null 2>&1; then
        update_progress_from_score
    fi
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
printf "Score: %d/%d (%.1f%%)\n" "$score" "$total_tests" "$(echo "scale=1; $score * 100 / $total_tests" | bc)"
printf "\n"

if [[ $score -eq $total_tests ]]; then
    exit 0
else
    exit 1
fi

