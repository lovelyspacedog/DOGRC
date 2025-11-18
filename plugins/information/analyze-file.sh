#!/bin/bash
# Sourcing Guard - check if analyze-file function already exists
if declare -f analyze-file >/dev/null 2>&1 || declare -f analyze_file >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

analyze-file() {
    ensure_commands_present --caller "analyze-file" file stat du wc sha256sum && {
        return $?
    }

    # Show help if no argument provided or if 'help' is requested
    if [[ -z "$1" ]] || [[ "${1^^}" == "HELP" ]]; then
        # Use >&2 for error if no argument, stdout otherwise.
        if [[ -z "$1" ]]; then
            out=">&2"
            ret=1
        else
            out=">&1"
            ret=0
        fi

        eval echo "Usage: analyze-file <file>" $out
        eval echo "" $out
        eval echo "Provide detailed file analysis and information" $out
        eval echo "" $out
        eval echo "Description:" $out
        eval echo "  - Analyzes files and provides comprehensive information" $out
        eval echo "  - Shows file size, permissions, ownership, and type" $out
        eval echo "  - Displays line count, word count, and character count for text files" $out
        eval echo "  - Generates SHA256 hash for security verification" $out
        eval echo "  - Works with any file type" $out
        eval echo "  - Provides human-readable output with formatting" $out
        eval echo "" $out
        eval echo "Dependencies:" $out
        eval echo "  - file (file type detection)" $out
        eval echo "  - stat (file statistics)" $out
        eval echo "  - du (disk usage)" $out
        eval echo "  - wc (word count)" $out
        eval echo "  - sha256sum (hash generation)" $out
        eval echo "" $out
        eval echo "Examples:" $out
        eval echo "  analyze-file document.txt" $out
        eval echo "  analyze-file script.sh" $out
        eval echo "  analyze-file image.jpg" $out
        eval echo "  analyze-file help" $out
        eval echo "" $out
        eval echo "Note: Provides different analysis based on file type" $out
        return $ret
    fi

    local file="$1"

    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' does not exist" >&2
        return 1
    fi

    echo -e "\n\033[36m📊 FILE ANALYSIS\033[0m"
    echo "================"
    echo "File: $file"
    echo ""

    # Basic file information
    echo "📏 Size: $(du -h "$file" | cut -f1)"
    echo "📅 Modified: $(stat -c "%y" "$file")"
    echo "🔐 Permissions: $(stat -c "%a" "$file")"
    echo "👤 Owner: $(stat -c "%U:%G" "$file")"
    echo ""

    # File type detection
    local file_type=$(file "$file" | cut -d: -f2)
    echo "📄 Type: $file_type"
    echo ""

    # Text file analysis
    if [[ "$file_type" == *"text"* ]] || [[ "$file_type" == *"ASCII"* ]] || [[ "$file_type" == *"UTF-8"* ]]; then
        echo "📝 Text File Analysis:"
        echo "  Lines: $(wc -l <"$file")"
        echo "  Words: $(wc -w <"$file")"
        echo "  Characters: $(wc -c <"$file")"
        echo "  Characters (no spaces): $(wc -m <"$file")"
        echo ""
    fi

    # Executable file analysis
    if [[ -x "$file" ]]; then
        echo "⚡ Executable File:"
        echo "  Executable: Yes"
        echo "  Shebang: $(head -1 "$file" | grep -E '^#!' || echo 'None')"
        echo ""
    fi

    # Archive file detection
    if [[ "$file_type" == *"archive"* ]] || [[ "$file_type" == *"compressed"* ]] || [[ "$file" =~ \.(tar|gz|bz2|zip|rar|7z)$ ]]; then
        echo "📦 Archive File:"
        echo "  Archive type detected"
        echo ""
    fi

    # Image file detection
    if [[ "$file_type" == *"image"* ]] || [[ "$file" =~ \.(jpg|jpeg|png|gif|bmp|svg|webp)$ ]]; then
        echo "🖼️  Image File:"
        echo "  Image type detected"
        echo ""
    fi

    # Video file detection
    if [[ "$file_type" == *"video"* ]] || [[ "$file" =~ \.(mp4|avi|mkv|mov|wmv|flv|webm)$ ]]; then
        echo "🎬 Video File:"
        echo "  Video type detected"
        echo ""
    fi

    # Audio file detection
    if [[ "$file_type" == *"audio"* ]] || [[ "$file" =~ \.(mp3|wav|flac|ogg|aac|m4a)$ ]]; then
        echo "🎵 Audio File:"
        echo "  Audio type detected"
        echo ""
    fi

    # Hash generation
    echo "🔒 SHA256 Hash:"
    echo "  $(sha256sum "$file" | cut -d' ' -f1)"
    echo ""

    # Additional file information
    echo "📋 Additional Info:"
    echo "  Inode: $(stat -c "%i" "$file")"
    echo "  Hard links: $(stat -c "%h" "$file")"
    echo "  Device: $(stat -c "%D" "$file")"
    echo ""

    return 0
}

# Alias for analyze_file (with underscore) for compatibility
analyze_file() {
    analyze-file "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analyze-file "$@"
    exit $?
fi

