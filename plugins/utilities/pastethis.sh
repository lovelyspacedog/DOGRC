#!/bin/bash
# Sourcing Guard - check if pastethis function already exists
if declare -f pastethis >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

pastethis() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp pastethis
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi

    ensure_commands_present --caller "pastethis" curl cat grep || {
        return $?
    }

    # Check if API key file exists and is readable
    local api_key_file="/home/tony/Documents/pastebin-api-key"
    if [[ ! -f "$api_key_file" ]] || [[ ! -r "$api_key_file" ]]; then
        echo "Error: Pastebin API key file not found or not readable: $api_key_file" >&2
        return 1
    fi

    local pastebin_api_key="$(cat "$api_key_file")"
    if [[ -z "$pastebin_api_key" ]]; then
        echo "Error: Pastebin API key is empty" >&2
        return 1
    fi

    local file_to_paste=""
    local privacy="public"
    local title=""
    local expires="10M"
    local format="Text"
    local url="https://pastebin.com/api/api_post.php"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file|-f)
                local file_to_paste="${2}"
                shift 2
                ;;
            --privacy|-p)
                local privacy="${2}"
                shift 2
                ;;
            --title|-t)
                local title="${2}"
                shift 2
                ;;
            --pastebin-api-key|-k)
                local pastebin_api_key="${2}"
                shift 2
                ;;
            --expires|-e)
                local expires="${2}"
                shift 2
                ;;
            --format|-r)
                local format="${2}"
                shift 2
                ;;
            -n)
                local expires="n"
                shift
                ;;
            *)
                local file_to_paste="${1}"
                shift
        esac
    done

    if [[ -z "${file_to_paste}" ]]; then
        echo "Error: No file to paste" >&2
        return 1
    fi

    if [[ -s "${file_to_paste}" ]]; then
        local file_content="$(cat "${file_to_paste}")"
    else
        echo "Error: File ${file_to_paste} is missing/empty" >&2
        return 2
    fi

    # Auto-detect format from file extension if not specified or explicitly requested
    if [[ "${format}" == "Text" ]] || [[ "${format}" == "auto" ]]; then
        local -A extension_map=(
            # Programming Languages
            ["sh"]="Bash"
            ["bash"]="Bash"
            ["zsh"]="Bash"
            ["fish"]="Bash"
            ["py"]="Python"
            ["pyc"]="Python"
            ["pyw"]="Python"
            ["pyi"]="Python"
            ["pyx"]="Python"
            ["pxd"]="Python"
            ["pxi"]="Python"
            ["js"]="JavaScript"
            ["jsx"]="JavaScript"
            ["mjs"]="JavaScript"
            ["ts"]="TypeScript"
            ["tsx"]="TypeScript"
            ["mts"]="TypeScript"
            ["cts"]="TypeScript"
            ["java"]="Java"
            ["class"]="Java"
            ["jar"]="Java"
            ["scala"]="Scala"
            ["sc"]="Scala"
            ["kt"]="Kotlin"
            ["kts"]="Kotlin"
            ["cs"]="C#"
            ["vb"]="VisualBasic"
            ["fs"]="F#"
            ["fsx"]="F#"
            ["fsi"]="F#"
            ["ml"]="OCaml"
            ["mli"]="OCaml"
            ["fs"]="F#"
            ["fsx"]="F#"
            ["elm"]="Haskell"
            ["hs"]="Haskell"
            ["lhs"]="Haskell"
            ["c"]="C"
            ["h"]="C"
            ["cpp"]="C++"
            ["cc"]="C++"
            ["cxx"]="C++"
            ["hpp"]="C++"
            ["hxx"]="C++"
            ["h++"]="C++"
            ["rs"]="Rust"
            ["rlib"]="Rust"
            ["go"]="Go"
            ["mod"]="Go"
            ["swift"]="Swift"
            ["m"]="Objective C"
            ["mm"]="Objective C"
            ["php"]="PHP"
            ["phtml"]="PHP"
            ["php3"]="PHP"
            ["php4"]="PHP"
            ["php5"]="PHP"
            ["php7"]="PHP"
            ["phps"]="PHP"
            ["rb"]="Ruby"
            ["rbw"]="Ruby"
            ["rake"]="Ruby"
            ["gemspec"]="Ruby"
            ["pl"]="Perl"
            ["pm"]="Perl"
            ["t"]="Perl"
            ["pod"]="Perl"
            ["lua"]="Lua"
            ["tcl"]="TCL"
            ["r"]="R"
            ["R"]="R"
            ["rmd"]="R"
            ["Rmd"]="R"
            ["jl"]="Julia"
            ["dart"]="Dart"
            ["ex"]="Elixir"
            ["exs"]="Elixir"
            ["clj"]="Clojure"
            ["cljs"]="Clojure"
            ["elm"]="Elm"
            ["hs"]="Haskell"
            ["ml"]="OCaml"
            ["fs"]="F#"
            ["vb"]="VisualBasic"
            ["coffee"]="CoffeeScript"
            ["litcoffee"]="CoffeeScript"
            ["ls"]="LiveScript"

            # Web Technologies
            ["html"]="HTML"
            ["htm"]="HTML"
            ["xhtml"]="HTML"
            ["xml"]="XML"
            ["css"]="CSS"
            ["scss"]="CSS"
            ["sass"]="CSS"
            ["less"]="CSS"
            ["json"]="JSON"
            ["yaml"]="YAML"
            ["yml"]="YAML"

            # Shell/Config
            ["Dockerfile"]="Docker"
            ["dockerfile"]="Docker"
            ["Makefile"]="Make"
            ["makefile"]="Make"
            ["CMakeLists.txt"]="CMake"
            ["conf"]="Properties"
            ["config"]="Properties"
            ["ini"]="INI file"
            ["cfg"]="INI file"
            ["toml"]="YAML"
            ["lock"]="JSON"

            # Data/Documents
            ["sql"]="SQL"
            ["csv"]="SQL"
            ["tsv"]="SQL"
            ["md"]="Markdown"
            ["markdown"]="Markdown"
            ["txt"]="Text"
            ["log"]="Apache Log"
            ["diff"]="Diff"
            ["patch"]="Diff"

            # Other
            ["asm"]="ASM (NASM)"
            ["s"]="ASM (NASM)"
            ["tex"]="Latex"
            ["bib"]="BibTeX"
            ["rkt"]="Racket"
            ["scm"]="Scheme"
            ["ss"]="Scheme"
        )

        # Extract file extension and try to detect format
        local filename="${file_to_paste##*/}"
        if [[ "$filename" == *.* ]]; then
            local extension="${filename##*.}"
            if [[ -n "${extension_map[$extension]}" ]]; then
                format="${extension_map[$extension]}"
            fi
        fi
    fi

    # Set default title to filename if not specified
    if [[ -z "${title}" ]]; then
        title="${file_to_paste##*/}"
    fi

    case "${privacy}" in
        "public"|0)
            local privacy_param="0"
            ;;
        "unlisted"|1)
            local privacy_param="1"
            ;;
        "private"|2)
            local privacy_param="2"
            ;;
        *)
            echo "Error: Invalid privacy level: ${privacy}" >&2
            return 3
            ;;
    esac

    case "${expires,,}" in
        "n"|"never")
            local expires_param="N"
            ;;
        "10m"|"10 minutes")
            local expires_param="10M"
            ;;
        "1h"|"1 hour")
            local expires_param="1H"
            ;;
        "1d"|"1 day")
            local expires_param="1D"
            ;;
        "1w"|"1 week")
            local expires_param="1W"
            ;;
        "2w"|"2 weeks")
            local expires_param="2W"
            ;;
        "1m"|"1 month")
            local expires_param="1M"
            ;;
        "6m"|"6 months")
            local expires_param="6M"
            ;;
        "1y"|"1 year")
            local expires_param="1Y"
            ;;
        *)
            echo "Error: Invalid expiration duration: ${expires}" >&2
            echo "Valid durations: n, 10m, 1h, 1d, 1w, 2w, 1m, 6m, 1y" >&2
            return 4
            ;;
    esac

    local -A format_map=(
        ["4CS"]="4cs"
        ["6502 ACME Cross Assembler"]="6502acme"
        ["6502 Kick Assembler"]="6502kickass"
        ["6502 TASM/64TASS"]="6502tasm"
        ["ABAP"]="abap"
        ["ActionScript"]="actionscript"
        ["ActionScript 3"]="actionscript3"
        ["Ada"]="ada"
        ["AIMMS"]="aimms"
        ["ALGOL 68"]="algol68"
        ["Apache Log"]="apache"
        ["AppleScript"]="applescript"
        ["APT Sources"]="apt_sources"
        ["Arduino"]="arduino"
        ["ARM"]="arm"
        ["ASM (NASM)"]="asm"
        ["ASP"]="asp"
        ["Asymptote"]="asymptote"
        ["autoconf"]="autoconf"
        ["Autohotkey"]="autohotkey"
        ["AutoIt"]="autoit"
        ["Avisynth"]="avisynth"
        ["Awk"]="awk"
        ["BASCOM AVR"]="bascomavr"
        ["Bash"]="bash"
        ["Basic4GL"]="basic4gl"
        ["Batch"]="dos"
        ["BibTeX"]="bibtex"
        ["Blitz3D"]="b3d"
        ["Blitz Basic"]="blitzbasic"
        ["BlitzMax"]="bmx"
        ["BNF"]="bnf"
        ["BOO"]="boo"
        ["BrainFuck"]="bf"
        ["C"]="c"
        ["C#"]="csharp"
        ["C (WinAPI)"]="c_winapi"
        ["C++"]="cpp"
        ["C++ (WinAPI)"]="cpp-winapi"
        ["C++ (with Qt extensions)"]="cpp-qt"
        ["C: Loadrunner"]="c_loadrunner"
        ["CAD DCL"]="caddcl"
        ["CAD Lisp"]="cadlisp"
        ["Ceylon"]="ceylon"
        ["CFDG"]="cfdg"
        ["C for Macs"]="c_mac"
        ["ChaiScript"]="chaiscript"
        ["Chapel"]="chapel"
        ["C Intermediate Language"]="cil"
        ["Clojure"]="clojure"
        ["Clone C"]="klonec"
        ["Clone C++"]="klonecpp"
        ["CMake"]="cmake"
        ["COBOL"]="cobol"
        ["CoffeeScript"]="coffeescript"
        ["ColdFusion"]="cfm"
        ["CSS"]="css"
        ["Cuesheet"]="cuesheet"
        ["D"]="d"
        ["Dart"]="dart"
        ["DCL"]="dcl"
        ["DCPU-16"]="dcpu16"
        ["DCS"]="dcs"
        ["Delphi"]="delphi"
        ["Delphi Prism (Oxygene)"]="oxygene"
        ["Diff"]="diff"
        ["DIV"]="div"
        ["DOT"]="dot"
        ["E"]="e"
        ["Easytrieve"]="ezt"
        ["ECMAScript"]="ecmascript"
        ["Eiffel"]="eiffel"
        ["Email"]="email"
        ["EPC"]="epc"
        ["Erlang"]="erlang"
        ["Euphoria"]="euphoria"
        ["F#"]="fsharp"
        ["Falcon"]="falcon"
        ["Filemaker"]="filemaker"
        ["FO Language"]="fo"
        ["Formula One"]="f1"
        ["Fortran"]="fortran"
        ["FreeBasic"]="freebasic"
        ["FreeSWITCH"]="freeswitch"
        ["GAMBAS"]="gambas"
        ["Game Maker"]="gml"
        ["GDB"]="gdb"
        ["GDScript"]="gdscript"
        ["Genero"]="genero"
        ["Genie"]="genie"
        ["GetText"]="gettext"
        ["Go"]="go"
        ["Godot GLSL"]="godot-glsl"
        ["Groovy"]="groovy"
        ["GwBasic"]="gwbasic"
        ["Haskell"]="haskell"
        ["Haxe"]="haxe"
        ["HicEst"]="hicest"
        ["HQ9 Plus"]="hq9plus"
        ["HTML"]="html4strict"
        ["HTML 5"]="html5"
        ["Icon"]="icon"
        ["IDL"]="idl"
        ["INI file"]="ini"
        ["Inno Script"]="inno"
        ["INTERCAL"]="intercal"
        ["IO"]="io"
        ["ISPF Panel Definition"]="ispfpanel"
        ["J"]="j"
        ["Java"]="java"
        ["Java 5"]="java5"
        ["JavaScript"]="javascript"
        ["JCL"]="jcl"
        ["jQuery"]="jquery"
        ["JSON"]="json"
        ["Julia"]="julia"
        ["KiXtart"]="kixtart"
        ["Kotlin"]="kotlin"
        ["KSP (Kontakt Script)"]="ksp"
        ["Latex"]="latex"
        ["LDIF"]="ldif"
        ["Liberty BASIC"]="lb"
        ["Linden Scripting"]="lsl2"
        ["Lisp"]="lisp"
        ["LLVM"]="llvm"
        ["Loco Basic"]="locobasic"
        ["Logtalk"]="logtalk"
        ["LOL Code"]="lolcode"
        ["Lotus Formulas"]="lotusformulas"
        ["Lotus Script"]="lotusscript"
        ["LScript"]="lscript"
        ["Lua"]="lua"
        ["M68000 Assembler"]="m68k"
        ["MagikSF"]="magiksf"
        ["Make"]="make"
        ["MapBasic"]="mapbasic"
        ["Markdown"]="markdown"
        ["MatLab"]="matlab"
        ["Mercury"]="mercury"
        ["MetaPost"]="metapost"
        ["mIRC"]="mirc"
        ["MIX Assembler"]="mmix"
        ["MK-61/52"]="mk-61"
        ["Modula 2"]="modula2"
        ["Modula 3"]="modula3"
        ["Motorola 68000 HiSoft Dev"]="68000devpac"
        ["MPASM"]="mpasm"
        ["MXML"]="mxml"
        ["MySQL"]="mysql"
        ["Nagios"]="nagios"
        ["NetRexx"]="netrexx"
        ["newLISP"]="newlisp"
        ["Nginx"]="nginx"
        ["Nim"]="nim"
        ["NullSoft Installer"]="nsis"
        ["Oberon 2"]="oberon2"
        ["Objeck Programming Language"]="objeck"
        ["Objective C"]="objc"
        ["OCaml"]="ocaml"
        ["OCaml Brief"]="ocaml-brief"
        ["Octave"]="octave"
        ["OpenBSD PACKET FILTER"]="pf"
        ["OpenGL Shading"]="glsl"
        ["Open Object Rexx"]="oorexx"
        ["Openoffice BASIC"]="oobas"
        ["Oracle 8"]="oracle8"
        ["Oracle 11"]="oracle11"
        ["Oz"]="oz"
        ["ParaSail"]="parasail"
        ["PARI/GP"]="parigp"
        ["Pascal"]="pascal"
        ["Pawn"]="pawn"
        ["PCRE"]="pcre"
        ["Per"]="per"
        ["Perl"]="perl"
        ["Perl 6"]="perl6"
        ["Phix"]="phix"
        ["PHP"]="php"
        ["PHP Brief"]="php-brief"
        ["Pic 16"]="pic16"
        ["Pike"]="pike"
        ["Pixel Bender"]="pixelbender"
        ["PL/I"]="pli"
        ["PL/SQL"]="plsql"
        ["PostgreSQL"]="postgresql"
        ["PostScript"]="postscript"
        ["POV-Ray"]="povray"
        ["PowerBuilder"]="powerbuilder"
        ["PowerShell"]="powershell"
        ["ProFTPd"]="proftpd"
        ["Progress"]="progress"
        ["Prolog"]="prolog"
        ["Properties"]="properties"
        ["ProvideX"]="providex"
        ["Puppet"]="puppet"
        ["PureBasic"]="purebasic"
        ["PyCon"]="pycon"
        ["Python"]="python"
        ["Python for S60"]="pys60"
        ["q/kdb+"]="q"
        ["QBasic"]="qbasic"
        ["QML"]="qml"
        ["R"]="rsplus"
        ["Racket"]="racket"
        ["Rails"]="rails"
        ["RBScript"]="rbs"
        ["REBOL"]="rebol"
        ["REG"]="reg"
        ["Rexx"]="rexx"
        ["Robots"]="robots"
        ["Roff Manpage"]="roff"
        ["RPM Spec"]="rpmspec"
        ["Ruby"]="ruby"
        ["Ruby Gnuplot"]="gnuplot"
        ["Rust"]="rust"
        ["SAS"]="sas"
        ["Scala"]="scala"
        ["Scheme"]="scheme"
        ["Scilab"]="scilab"
        ["SCL"]="scl"
        ["SdlBasic"]="sdlbasic"
        ["Smalltalk"]="smalltalk"
        ["Smarty"]="smarty"
        ["SPARK"]="spark"
        ["SPARQL"]="sparql"
        ["SQF"]="sqf"
        ["SQL"]="sql"
        ["SSH Config"]="sshconfig"
        ["StandardML"]="standardml"
        ["StoneScript"]="stonescript"
        ["SuperCollider"]="sclang"
        ["Swift"]="swift"
        ["SystemVerilog"]="systemverilog"
        ["T-SQL"]="tsql"
        ["TCL"]="tcl"
        ["Tera Term"]="teraterm"
        ["Text"]="text"
        ["TeXgraph"]="texgraph"
        ["thinBasic"]="thinbasic"
        ["TypeScript"]="typescript"
        ["TypoScript"]="typoscript"
        ["Unicon"]="unicon"
        ["UnrealScript"]="uscript"
        ["UPC"]="upc"
        ["Urbi"]="urbi"
        ["Vala"]="vala"
        ["VB.NET"]="vbnet"
        ["VBScript"]="vbscript"
        ["Vedit"]="vedit"
        ["VeriLog"]="verilog"
        ["VHDL"]="vhdl"
        ["VIM"]="vim"
        ["VisualBasic"]="vb"
        ["VisualFoxPro"]="visualfoxpro"
        ["Visual Pro Log"]="visualprolog"
        ["WhiteSpace"]="whitespace"
        ["WHOIS"]="whois"
        ["Winbatch"]="winbatch"
        ["XBasic"]="xbasic"
        ["XML"]="xml"
        ["Xojo"]="xojo"
        ["Xorg Config"]="xorg_conf"
        ["XPP"]="xpp"
        ["YAML"]="yaml"
        ["YARA"]="yara"
        ["Z80 Assembler"]="z80"
        ["ZXBasic"]="zxbasic"
    )

    if [[ -n "${format_map[${format}]}" ]]; then
        local format_param="${format_map[${format}]}"
    else
        echo "Error: Invalid format: ${format}" >&2
        echo "Valid formats: ${!format_map[@]}" >&2
        return 5
    fi

    local -a payload=("curl" "-X" "POST")
    payload+=("-d" "api_option=paste")
    payload+=("-d" "api_dev_key=${pastebin_api_key}")
    [[ -n "${title}" ]] && payload+=("-d" "api_paste_name=${title}")
    payload+=("-d" "api_paste_private=${privacy_param}")
    payload+=("-d" "api_paste_expire_date=${expires_param}")
    payload+=("-d" "api_paste_format=${format_param}")
    payload+=("--data-urlencode" "api_paste_code=${file_content}")
    payload+=("${url}")

    local result="$(curl -s "${payload[@]}")"
    if [[ -z "${result}" ]]; then
        echo "Error: Failed to paste to pastebin" >&2
        return 6
    fi

    # Check if the result looks like a valid pastebin URL
    if [[ "$result" =~ ^https://pastebin\.com/ ]]; then
        printf "\nPaste Configuration:\n"
        printf "  %-10s %s\n" "File:" "${file_to_paste}"
        printf "  %-10s %s\n" "Title:" "${title}"
        printf "  %-10s %s\n" "Format:" "${format}"
        printf "  %-10s %s\n" "Privacy:" "${privacy}"
        printf "  %-10s %s\n" "Expires:" "${expires}"
        printf "\n"
        echo "Paste created successfully: $result"
        return 0
    else
    echo "Error: Failed to create paste. Response: $result" >&2
    return 6
    fi
}

# Bash completion function for pastethis
_pastethis_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Handle different option types
    case "$prev" in
        --privacy|-p)
            # Complete privacy options
            COMPREPLY=($(compgen -W "public unlisted private" -- "$cur"))
            return 0
            ;;
        --expires|-e)
            # Complete expiration options
            COMPREPLY=($(compgen -W "n never 10m 10M '10 minutes' 1h 1H '1 hour' 1d 1D '1 day' 1w 1W '1 week' 2w 2W '2 weeks' 1m 1M '1 month' 6m 6M '6 months' 1y 1Y '1 year'" -- "$cur"))
            return 0
            ;;
        --format|-f)
            # Complete format options (common languages first, then all supported)
            local common_formats="bash python javascript typescript java c cpp rust go php html css json markdown sql text"
            # Add all format_map keys as well
            local all_formats="$common_formats auto"
            # Get format_map keys dynamically if possible
            if [[ -n "${__UTILITIES_DIR:-}" ]] && [[ -n "${__CORE_DIR:-}" ]]; then
                # This would require sourcing the format_map, which is complex in completion context
                # For now, stick with common formats
                all_formats="$common_formats auto"
            fi
            COMPREPLY=($(compgen -W "$all_formats" -- "$cur"))
            return 0
            ;;
        --file|-f)
            # Complete filenames
            COMPREPLY=($(compgen -f -- "$cur"))
            return 0
            ;;
        --pastebin-api-key|-k)
            # Don't complete API keys for security
            return 0
            ;;
        --title|-t)
            # Don't complete titles
            return 0
            ;;
    esac

    # If current word starts with a dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h --file -f --privacy -p --title -t --expires -e --format -r --pastebin-api-key -k -n" -- "$cur"))
        return 0
    fi

    # Default: complete with filenames (positional file argument)
    COMPREPLY=($(compgen -f -- "$cur"))
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _pastethis_completion pastethis 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pastethis "$@"
    exit $?
fi