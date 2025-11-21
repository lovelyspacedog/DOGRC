#!/bin/bash
# Sourcing Guard - check if prepfile function already exists
if declare -f prepfile >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

prepfile() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    # Check all arguments for help flags (needed for alias compatibility)
    local arg
    for arg in "$@"; do
        if [[ "${arg,,}" == "--help" ]] || [[ "${arg,,}" == "-h" ]]; then
            if declare -f drchelp >/dev/null 2>&1; then
                drchelp prepfile
                return 0
            else
                echo "Error: drchelp not available" >&2
                return 1
            fi
        fi
    done
    
    local file_type="bash"
    local filename=""
    local override=false
    
    # Parse arguments to find type flag, override flag, and filename
    local i=1
    while [[ $i -le $# ]]; do
        local arg="${!i}"
        case "${arg,,}" in
            --override|-or)
                override=true
                printf "Warning: Override enabled!\n" >&2
                ;;
            --bash|--sh)
                file_type="bash"
                ;;
            --python|--py)
                file_type="python"
                ;;
            --rust|--rs)
                file_type="rust"
                ;;
            --go)
                file_type="go"
                ;;
            --javascript|--js)
                file_type="javascript"
                ;;
            --typescript|--ts)
                file_type="typescript"
                ;;
            --c)
                file_type="c"
                ;;
            --c++|--cpp)
                file_type="cpp"
                ;;
            --java)
                file_type="java"
                ;;
            --ruby|--rb)
                file_type="ruby"
                ;;
            --perl|--pl)
                file_type="perl"
                ;;
            --php)
                file_type="php"
                ;;
            --lua)
                file_type="lua"
                ;;
            --zsh)
                file_type="zsh"
                ;;
            --fish)
                file_type="fish"
                ;;
            *)
                # Not a type flag or override flag, treat as filename (first non-flag argument)
                if [[ -z "$filename" ]] && [[ "$arg" != -* ]]; then
                    filename="$arg"
                fi
                ;;
        esac
        ((i++))
    done
    
    # If filename is still empty after parsing, use default
    
    # Set default filename if not provided
    if [[ -z "$filename" ]]; then
        case "$file_type" in
            bash|sh) filename="main.sh" ;;
            python|py) filename="main.py" ;;
            rust|rs) filename="main.rs" ;;
            go) filename="main.go" ;;
            javascript|js) filename="main.js" ;;
            typescript|ts) filename="main.ts" ;;
            c) filename="main.c" ;;
            cpp) filename="main.cpp" ;;
            java) filename="Main.java" ;;
            ruby|rb) filename="main.rb" ;;
            perl|pl) filename="main.pl" ;;
            php) filename="main.php" ;;
            lua) filename="main.lua" ;;
            zsh) filename="main.zsh" ;;
            fish) filename="main.fish" ;;
            *) filename="main.sh" ;;
        esac
    else
        # Add extension if not present
        case "$file_type" in
            bash|sh)
                [[ "$filename" != *.sh ]] && filename="$filename.sh"
                ;;
            python|py)
                [[ "$filename" != *.py ]] && filename="$filename.py"
                ;;
            rust|rs)
                [[ "$filename" != *.rs ]] && filename="$filename.rs"
                ;;
            go)
                [[ "$filename" != *.go ]] && filename="$filename.go"
                ;;
            javascript|js)
                [[ "$filename" != *.js ]] && filename="$filename.js"
                ;;
            typescript|ts)
                [[ "$filename" != *.ts ]] && filename="$filename.ts"
                ;;
            c)
                [[ "$filename" != *.c ]] && filename="$filename.c"
                ;;
            cpp)
                [[ "$filename" != *.cpp ]] && filename="$filename.cpp"
                ;;
            java)
                [[ "$filename" != *.java ]] && filename="$filename.java"
                ;;
            ruby|rb)
                [[ "$filename" != *.rb ]] && filename="$filename.rb"
                ;;
            perl|pl)
                [[ "$filename" != *.pl ]] && filename="$filename.pl"
                ;;
            php)
                [[ "$filename" != *.php ]] && filename="$filename.php"
                ;;
            lua)
                [[ "$filename" != *.lua ]] && filename="$filename.lua"
                ;;
            zsh)
                [[ "$filename" != *.zsh ]] && filename="$filename.zsh"
                ;;
            fish)
                [[ "$filename" != *.fish ]] && filename="$filename.fish"
                ;;
        esac
    fi
    
    # Check if file already exists (unless override is set)
    if [[ "$override" == false ]] && [[ -f "$filename" ]]; then
        printf "Can't create %s, file already exists\n" "$filename" >&2
        printf "Use --override to overwrite the file\n" >&2
        return 1
    fi
    
    ensure_commands_present --caller "prepfile" chmod || {
        return $?
    }
    
    # Generate template based on file type
    case "$file_type" in
        bash|sh)
            cat > "$filename" << 'BASH_EOF'
#!/usr/bin/env bash

BASH_EOF
            ;;
        python|py)
            cat > "$filename" << 'PYTHON_EOF'
#!/usr/bin/env python3

PYTHON_EOF
            ;;
        rust|rs)
            cat > "$filename" << 'RUST_EOF'
fn main() {
    
}

RUST_EOF
            ;;
        go)
            cat > "$filename" << 'GO_EOF'
package main

func main() {
    
}

GO_EOF
            ;;
        javascript|js)
            cat > "$filename" << 'JS_EOF'
#!/usr/bin/env node

JS_EOF
            ;;
        typescript|ts)
            cat > "$filename" << 'TS_EOF'

TS_EOF
            ;;
        c)
            cat > "$filename" << 'C_EOF'
#include <stdio.h>

int main() {
    return 0;
}

C_EOF
            ;;
        cpp)
            cat > "$filename" << 'CPP_EOF'
#include <iostream>

int main() {
    return 0;
}

CPP_EOF
            ;;
        java)
            cat > "$filename" << 'JAVA_EOF'
public class Main {
    public static void main(String[] args) {
        
    }
}

JAVA_EOF
            ;;
        ruby|rb)
            cat > "$filename" << 'RUBY_EOF'
#!/usr/bin/env ruby

RUBY_EOF
            ;;
        perl|pl)
            cat > "$filename" << 'PERL_EOF'
#!/usr/bin/env perl
use strict;
use warnings;

PERL_EOF
            ;;
        php)
            cat > "$filename" << 'PHP_EOF'
#!/usr/bin/env php
<?php

PHP_EOF
            ;;
        lua)
            cat > "$filename" << 'LUA_EOF'
#!/usr/bin/env lua

LUA_EOF
            ;;
        zsh)
            cat > "$filename" << 'ZSH_EOF'
#!/usr/bin/env zsh

ZSH_EOF
            ;;
        fish)
            cat > "$filename" << 'FISH_EOF'
#!/usr/bin/env fish

FISH_EOF
            ;;
        *)
            # Default to bash
            cat > "$filename" << 'BASH_EOF'
#!/usr/bin/env bash

BASH_EOF
            ;;
    esac
    
    # Make executable for script languages
    case "$file_type" in
        bash|sh|python|py|javascript|js|ruby|rb|perl|pl|php|lua|zsh|fish)
            chmod +x "$filename"
            ;;
    esac
    
    if [[ "$override" == true ]] && [[ -f "$filename" ]]; then
        printf "Overwritten %s (%s template)\n" "$filename" "$file_type"
    else
        printf "Created %s (%s template)\n" "$filename" "$file_type"
    fi
    
    # Only prompt for editing if stdin is available and we're in an interactive shell
    if [[ -t 0 ]] && [[ "${-}" == *i* ]]; then
        printf "Would you like to edit the file? (y/n): "
        if read -n 1 -r ans 2>/dev/null; then
            echo
            if [[ $ans =~ ^[Yy]$ ]]; then
                local editor="${EDITOR:-nvim}"
                ensure_commands_present --caller "prepfile edit" "$editor" || {
                    return $?
                }
                "$editor" "$filename"
                return 0
            fi
        else
            # If read fails, silently continue without editing
            echo
        fi
    fi
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    prepfile "$@"
    exit $?
fi

