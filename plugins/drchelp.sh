#!/bin/bash
# Sourcing Guard - check if drchelp function already exists
if declare -f drchelp >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__PLUGINS_DIR}/../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__PLUGINS_DIR}/.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

drchelp() {
    if ! ensure_commands_present --caller "drchelp" cat; then
        return 123
    fi
    
    # If a function name is provided, show its help
    if [[ -n "$1" ]]; then
        case "$1" in
            backup)
                cat <<EOF
backup - Create Timestamped Backups

Create timestamped backups of files or directories with optional storage location.

Usage: backup [OPTIONS] <file|directory>
       backup --directory [OPTIONS] [directory]

Description:
  - Creates timestamped backups of files or directories
  - Supports both single file and directory backup modes
  - Can store backups in a central location or next to the original
  - Timestamp format: YYYYMMDDHHMMSS
  - Preserves file permissions and directory structure

Options:
  --store, -s              Store backup in ~/Documents/BAK directory
  --directory, --dir, -d   Backup the current directory (directory mode)
  --                       Separator for file path (useful when path starts with -)

Modes:
  File Mode (default):
    - Creates backup of a single file
    - Backup stored as: <filename>.bak.<timestamp>
    - Or in ~/Documents/BAK/ if --store is used

  Directory Mode (--directory):
    - Creates backup of current working directory
    - Backup stored as: <dirname>.bak.<timestamp>
    - Or in ~/Documents/BAK/ if --store is used
    - Preserves entire directory structure

Behavior:
  - File mode: requires file path as argument
  - Directory mode: uses current directory when --directory flag is set
  - Creates ~/Documents/BAK directory automatically if --store is used
  - Returns error if file/directory doesn't exist
  - Returns error if backup directory creation fails

Dependencies:
  - cp (for copying files)
  - date (for timestamp generation)
  - basename (for extracting filenames)
  - mkdir (for creating backup directories)
  - find (for directory backup mode)

Examples:
  backup file.txt                    # Create backup: file.txt.bak.20250115143022
  backup --store file.txt            # Store in ~/Documents/BAK/file.txt.bak.20250115143022
  backup --directory                 # Backup current directory
  backup --directory --store         # Backup current directory to ~/Documents/BAK/
  backup --store --directory         # Same as above (order doesn't matter)

Note: The timestamp ensures backups are unique and sortable. Directory backups
      preserve the entire structure and exclude the backup directory itself to
      avoid recursive copying. Use --store to keep all backups in a central location.
      Tab completion is available for flags and file/directory paths.
EOF
                return 0
                ;;
            blank)
                cat <<EOF
blank - Empty File Contents

Remove all contents from a file without deleting it, leaving it empty.

Usage: blank [OPTIONS] <filename>
       blank <filename> [OPTIONS]

Description:
  - Empties the contents of an existing file
  - File remains but contains no data (0 bytes)
  - Optionally creates the file if it doesn't exist
  - Preserves file permissions and metadata
  - Useful for clearing log files or resetting configuration files

Options:
  --touch, --TOUCH, -t, -T
                      Create the file if it doesn't exist
                      Shows a warning message when creating a new file
                      If file exists, empties it as normal (no warning)
  -x, --no-countdown, --skip-countdown
                      Skip the 3-second countdown and empty immediately
                      Useful for scripts and automated operations
                      Still shows countdown if used in non-interactive contexts

Behavior:
  - Without --touch: requires file to exist, returns error if missing
  - With --touch: creates empty file if it doesn't exist (with warning)
  - Shows 3-second countdown before clearing (interactive shells only)
  - Countdown can be cancelled by pressing any key
  - Use -x flag to skip countdown and clear immediately
  - Always empties the file after creation/verification
  - File size becomes 0 bytes
  - File permissions and ownership are preserved
  - Returns error if file creation fails (when --touch is used)

Dependencies:
  - touch (for creating files when --touch flag is used)
  - Shell redirection (for emptying files)

Examples:
  blank file.txt                    # Empty file.txt with 3-second countdown
  blank -x file.txt                 # Immediately empty file.txt (no countdown)
  blank --touch newfile.txt         # Create and empty newfile.txt (with warning + countdown)
  blank -t -x log.txt               # Create and immediately empty log.txt (no countdown)
  blank existing.log                # Empty existing.log with countdown
  blank -x existing.log             # Immediately empty existing.log
  blank --touch existing.log        # Empty existing.log (touch ignored, shows countdown)

Note: The function safely empties files without removing them. This is useful
      for clearing log files, resetting configuration files, or initializing
      empty files. By default, a 3-second countdown is shown before clearing
      (in interactive shells), allowing you to cancel by pressing any key. Use
      the -x flag to skip the countdown and clear immediately, which is useful
      for scripts and automated operations. Use --touch to create the file if
      it doesn't exist, which will show a warning message. If the file already
      exists, the --touch flag is ignored and no warning is shown. The function
      preserves file permissions and metadata, only removing the file contents.
EOF
                return 0
                ;;
            compress)
                cat <<EOF
compress - Create Archives

Create archives from files or directories in various formats.

Usage: compress <file|directory> [format]

Description:
  - Creates archives from files or directories
  - Supports multiple archive formats
  - Automatically determines default format based on input type
  - Uses appropriate compression tool for each format
  - Preserves original files (uses -k flag for gzip/bzip2)

Supported Formats:
  - tar.bz2, tbz2  - tar archive compressed with bzip2
  - tar.gz, tgz    - tar archive compressed with gzip
  - bz2            - bzip2 compressed file
  - rar            - RAR archive
  - gz             - gzip compressed file
  - tar            - tar archive (uncompressed)
  - zip            - ZIP archive
  - Z              - compress compressed file
  - 7z             - 7-Zip archive

Default Behavior:
  - Files: defaults to gz format (creates file.gz)
  - Directories: defaults to tar.gz format (creates directory.tar.gz)

Behavior:
  - Requires file or directory as first argument
  - Optional format as second argument
  - Checks if input exists before creating archive
  - Prevents overwriting existing output files
  - Preserves original files (keeps original with -k flag)
  - Returns error if input doesn't exist
  - Returns error if output file already exists
  - Returns error if format is not supported

Dependencies:
  - tar (for .tar, .tar.bz2, .tar.gz, .tbz2, .tgz files)
  - bzip2 (for .bz2 files)
  - rar (for .rar files)
  - gzip (for .gz files)
  - zip (for .zip files)
  - compress (for .Z files)
  - 7z (for .7z files)

Examples:
  compress file.txt           # Creates file.txt.gz (default for files)
  compress directory/         # Creates directory.tar.gz (default for directories)
  compress file.txt zip       # Creates file.txt.zip
  compress dir/ tar.bz2       # Creates dir.tar.bz2
  compress data.txt 7z        # Creates data.txt.7z

Note: This function is the opposite of extract(). It creates archives from
      files or directories. The original files are preserved (not deleted).
      Default format is gz for files and tar.gz for directories. Use the
      second argument to specify a different format. Tab completion is
      available for file/directory paths (first argument) and supported
      archive formats (second argument).
EOF
                return 0
                ;;
            dupefind|finddupes)
                cat <<EOF
dupefind - Find Duplicate Files

Find duplicate files by comparing their content using hash algorithms.

Usage: dupefind [OPTIONS] [directory|file]
       finddupes [OPTIONS] [directory|file]

Description:
  - Finds duplicate files by comparing file content using hash algorithms
  - Supports MD5 and SHA256 hash algorithms
  - Works with files and directories
  - Groups duplicates together for easy identification
  - Shows file sizes and wasted space
  - Can automatically delete duplicates or use interactive mode

Options:
  --md5, -m              Use MD5 hash algorithm (faster, less secure)
  --sha256, -s           Use SHA256 hash algorithm (slower, more secure)
  --delete, -d           Automatically delete duplicate files (keeps first file)
  --interactive, -i      Interactive mode for manual selection of files to keep/delete
  --no-size              Don't display file sizes
  --min-size <size>      Only check files larger than specified size
                        Supports suffixes: K (KB), M (MB), G (GB)
                        Example: --min-size 1M (only files > 1MB)
  --                     Separator for directory/file path

Default Behavior:
  - Uses MD5 hash if available (fallback to SHA256)
  - Searches current directory if no path specified
  - Displays duplicates grouped by hash
  - Shows file sizes and wasted space
  - Does not delete files (display only)

Hash Algorithms:
  - MD5: Faster, suitable for most use cases
  - SHA256: More secure, slower, recommended for verification

Modes:
  Display Mode (default):
    - Finds and displays all duplicate files
    - Groups duplicates by content hash
    - Shows which files are duplicates
    - Displays wasted space

  Delete Mode (--delete):
    - Automatically keeps the first file in each duplicate group
    - Deletes all other duplicates
    - No confirmation (use with caution)
    - Shows what files are kept and deleted

  Interactive Mode (--interactive):
    - Shows each duplicate group
    - Allows manual selection of files to keep
    - Prompts for confirmation before deletion
    - Provides full control over which duplicates to remove

Behavior:
  - Scans all files in specified directory recursively
  - Calculates hash for each file (respecting --min-size)
  - Groups files with identical hashes
  - Displays duplicates with file paths and sizes
  - Shows total wasted space
  - In delete mode: keeps first file, deletes rest
  - In interactive mode: prompts for each deletion

Dependencies:
  - find (for file discovery)
  - stat (for file size)
  - md5sum or md5 (for MD5 hashing)
  - sha256sum or sha256 (for SHA256 hashing)
  - sort (for grouping duplicates)
  - bc (optional, for size formatting)

Examples:
  dupefind                              # Find duplicates in current directory
  dupefind ~/Documents                  # Find duplicates in Documents
  dupefind --sha256 ~/Pictures          # Use SHA256 hash for Pictures
  dupefind --min-size 1M                # Only check files larger than 1MB
  dupefind --delete ~/Downloads         # Delete duplicates automatically
  dupefind --interactive ~/Music        # Interactive mode for Music
  dupefind --no-size ~/Videos           # Don't show file sizes
  dupefind --min-size 10M --sha256      # Large files with SHA256

Note: The function finds duplicates by comparing file content, not filenames.
      Two files with different names but identical content will be identified
      as duplicates. Use --delete with caution as it permanently removes files.
      Interactive mode is safer for manual review. The --min-size option is
      useful for skipping small files when looking for large duplicates.
      Tab completion is available for directory/file paths.
EOF
                return 0
                ;;
            checksum-verify)
                cat <<EOF
checksum-verify - File Checksum Verification and Generation

Verify file integrity using checksums or generate checksums for files.

Usage: checksum-verify <file> <checksum> [OPTIONS]
       checksum-verify --generate <file> [OPTIONS]
       checksum-verify --recursive <directory> [OPTIONS]
       checksum-verify --check <checksum_file> [OPTIONS]

Description:
  - Verify file integrity by comparing checksums
  - Generate checksums for individual files or entire directories
  - Verify all files listed in a checksum file (recursive verification)
  - Supports multiple hash algorithms: MD5, SHA1, SHA256, SHA512
  - Useful for verifying file integrity after downloads
  - Ensures files haven't been corrupted or tampered with

Options:
  --generate, -g              Generate checksum for file (instead of verifying)
  --recursive, -r             Recursively generate checksums for all files in directory
  --check, -c                 Read checksums from file and verify them
  --algorithm, -a <algorithm> Specify hash algorithm (default: sha256)
                              Supported: md5, sha1, sha256, sha512
  --help, -h                  Show this help message
  --                          Separator for arguments

Algorithms:
  md5:
    - Fastest, but less secure
    - 32 hexadecimal characters
    - Use for quick integrity checks

  sha1:
    - Faster than SHA256, but deprecated for security
    - 40 hexadecimal characters
    - Use for legacy compatibility

  sha256 (default):
    - Recommended for most use cases
    - 64 hexadecimal characters
    - Good balance of security and speed

  sha512:
    - Most secure, but slower
    - 128 hexadecimal characters
    - Use for high-security applications

Modes:
  Verify Mode (default):
    - Compares file checksum with provided checksum
    - Returns 0 if checksums match, 1 if they don't
    - Shows detailed comparison results
    - Example: checksum-verify file.txt abc123def456...

  Generate Mode (--generate):
    - Generates checksum for the specified file
    - Outputs only the checksum (suitable for scripts)
    - Example: checksum-verify --generate file.txt

Behavior:
  - Automatically detects available checksum commands
  - Supports both GNU coreutils (md5sum, sha*sum) and BSD (md5, shasum)
  - Normalizes checksums (removes spaces, converts to lowercase)
  - Validates file existence before processing
  - Provides clear success/failure messages

Dependencies:
  Required (at least one per algorithm):
    - md5sum or md5 (for MD5)
    - sha1sum or shasum (for SHA1)
    - sha256sum or shasum (for SHA256)
    - sha512sum or shasum (for SHA512)

Examples:
  # Verify a file's checksum
  checksum-verify file.txt abc123def456...
  checksum-verify file.txt abc123def456... --algorithm sha256

  # Generate a checksum
  checksum-verify --generate file.txt
  checksum-verify --generate file.txt --algorithm md5
  checksum-verify -g file.txt -a sha512

  # Recursive generation for a directory
  checksum-verify --recursive my_folder > my_folder.sha256

  # Recursive verification from a checksum file
  checksum-verify --check my_folder.sha256

  # Verify with different algorithm
  checksum-verify file.txt abc123... --algorithm sha1

  # Store checksum for later verification
  checksum-verify --generate file.txt > file.txt.sha256
  checksum-verify file.txt $(cat file.txt.sha256)

Output Format:
  Verify Mode (match):
    ✓ Checksums match
      File: file.txt
      Algorithm: sha256
      Checksum: abc123def456...

  Verify Mode (mismatch):
    ✗ Checksums do NOT match
      File: file.txt
      Algorithm: sha256
      Expected: abc123def456...
      Actual:   xyz789ghi012...

  Generate Mode:
    abc123def456...  (just the checksum)

Note: The function automatically detects which checksum commands are available
      on your system. On Linux, it uses md5sum/sha*sum. On macOS/BSD, it uses
      md5/shasum. Checksums are normalized (lowercase, no spaces) for comparison.
      The default algorithm is SHA256, which provides a good balance of security
      and performance. For maximum security, use SHA512. For quick checks, use MD5.
EOF
                return 0
                ;;
            find-empty-dirs)
                cat <<EOF
find-empty-dirs - Find Empty Directories

Find empty directories recursively in a specified directory tree.

Usage: find-empty-dirs [OPTIONS] [directory]

Description:
  - Finds all empty directories recursively in the specified directory
  - Empty directories contain no files or subdirectories
  - Can optionally delete found empty directories with confirmation
  - Useful for cleanup projects and removing unused directory structures
  - Displays relative paths for cleaner output

Options:
  --delete, -d           Delete found empty directories (with confirmation)
  --                     Separator for directory path

Default Behavior:
  - Searches current directory (.) if no directory specified
  - Lists all empty directories found
  - Does not delete directories (display only)
  - Shows count of empty directories found

Delete Mode (--delete):
  - Prompts for confirmation before deletion (interactive shells only)
  - Deletes all found empty directories
  - Reports success/failure for each deletion
  - Returns error if any deletion fails

Behavior:
  - Recursively searches from the specified directory
  - Uses find with -type d -empty to identify empty directories
  - Excludes the starting directory itself (uses -mindepth 1)
  - Displays relative paths when possible for cleaner output
  - In delete mode: requires confirmation in interactive shells
  - In delete mode: skips confirmation in non-interactive shells (use with caution)

Dependencies:
  - find (for directory discovery)

Examples:
  find-empty-dirs                    # Find empty directories in current directory
  find-empty-dirs ~/Projects         # Find empty directories in Projects
  find-empty-dirs --delete           # Find and delete empty directories (with confirmation)
  find-empty-dirs --delete ~/Old     # Find and delete empty directories in Old folder

Note: Empty directories are those that contain no files or subdirectories.
      The function uses find's -empty flag which checks for truly empty directories.
      Use --delete with caution as it permanently removes directories. In interactive
      shells, you'll be prompted for confirmation. The function will not delete the
      starting directory itself, only subdirectories within it.
EOF
                return 0
                ;;
            calc)
                cat <<EOF
calc - Command Line Calculator

Perform mathematical calculations using bc (basic calculator).

Usage: calc <expression>

Description:
  - Evaluates mathematical expressions using bc
  - Supports floating point arithmetic
  - Automatically removes trailing zeros from results
  - Provides 10 decimal places of precision

Behavior:
  - Requires a mathematical expression as argument
  - Expression is evaluated by bc with scale=10 (10 decimal places)
  - Result is cleaned to remove unnecessary trailing zeros
  - Returns error if expression is invalid or empty

Dependencies:
  - bc (basic calculator)

Examples:
  calc '2 + 3'                       # Result: 5
  calc '2 + 3.5 * 4'                 # Result: 16
  calc '10 / 3'                      # Result: 3.3333333333
  calc 'sqrt(16)'                    # Result: 4
  calc '2^8'                         # Result: 256

Note: Expressions must be quoted if they contain spaces or special characters.
      The function uses bc's standard syntax. Complex expressions may require
      parentheses for proper evaluation order.
EOF
                return 0
                ;;
            cd|cdd|zd)
                cat <<EOF
cd/cdd/zd - Enhanced Directory Navigation

Enhanced cd commands with automatic directory listing and zoxide integration.

Functions:
  cd    - Enhanced cd that defaults to HOME when no argument provided
  cdd   - Change directory and display contents (cd + list)
  zd    - Smart directory navigation with zoxide integration

Usage: cd [directory]
       cdd <directory>
       zd [directory]

Description:
  cd:   - Standard cd command enhancement
        - Without arguments: changes to HOME directory
        - With arguments: works like standard cd

  cdd:  - Change directory and display contents
        - Validates directory exists before changing
        - Automatically lists directory contents after changing
        - Uses eza if available, otherwise falls back to ls
        - Shows current directory path with folder emoji

  zd:   - Smart directory navigation with zoxide
        - Uses zoxide's z command if available (smart directory jumping)
        - Falls back to standard cd if zoxide is not available
        - Automatically lists directory contents after changing
        - Uses eza if available, otherwise falls back to ls
        - Shows current directory path with folder emoji

Behavior:
  - cd:  Returns 0 on success, preserves cd's exit codes
  - cdd: Validates directory exists, returns error if not found
  - zd:  Tries zoxide first, falls back to cd if unavailable
  - All functions use eza with icons if available
  - Falls back to ls -Al --color=auto if eza is not available

Dependencies:
  - cd (builtin)
  - eza (optional, for enhanced listing with icons)
  - ls (fallback if eza not available)
  - zoxide (optional, for zd smart navigation)

Examples:
  cd                    # Change to HOME directory
  cd /tmp               # Change to /tmp
  cdd Documents         # Change to Documents and list contents
  zd proj               # Smart jump to project directory (if zoxide available)
  zd                    # Change to HOME directory

Note: The cd function overrides the builtin cd command. The cdd and zd functions
      provide enhanced navigation with automatic directory listing. zd leverages
      zoxide's smart directory jumping which learns your navigation patterns.
EOF
                return 0
                ;;
            slashback|/|//|///|////|/////|//////)
                cat <<EOF
slashback - Quick Directory Navigation Upwards

Navigate up directory levels using slash functions.

Usage: / [levels]
       // [levels]
       /// [levels]
       etc.

Description:
  - Provides quick shortcuts to navigate up the directory tree
  - Each slash represents one directory level up
  - Functions are named with slashes: /, //, ///, ////, /////, //////
  - Allows rapid navigation without typing "cd ../.." repeatedly
  - Uses FUNCNAME to determine depth automatically

Available Functions:
  /        - Navigate up 1 directory level (parent)
  //       - Navigate up 2 directory levels (grandparent)
  ///      - Navigate up 3 directory levels
  ////     - Navigate up 4 directory levels
  /////    - Navigate up 5 directory levels
  //////   - Navigate up 6 directory levels

Behavior:
  - The number of slashes determines how many levels up to navigate
  - Each slash function calls the internal __slashback function
  - Uses FUNCNAME[1] to determine the caller's name length
  - Changes directory relative to current location
  - Works from any directory in the filesystem
  - Returns cd's exit code

Dependencies:
  - cd (builtin)

Examples:
  /              # Go up 1 level: cd ..
  //             # Go up 2 levels: cd ../..
  ///            # Go up 3 levels: cd ../../..
  ////           # Go up 4 levels: cd ../../../..
  /////          # Go up 5 levels: cd ../../../../..
  //////         # Go up 6 levels: cd ../../../../../..

Note: These are bash functions with special names (just slashes). They provide
      a convenient way to quickly navigate up the directory tree without typing
      multiple "../" sequences. The functions automatically determine the depth
      based on the function name length using FUNCNAME. This is faster and more
      intuitive than typing multiple "../" sequences.
EOF
                return 0
                ;;
            analyze-file|analyze_file)
                cat <<EOF
analyze-file - File Analysis Tool

Provide detailed file analysis and information.

Usage: analyze-file <file>
       analyze-file --help|-h

Description:
  - Analyzes files and provides comprehensive information
  - Shows file size, permissions, ownership, and type
  - Displays line count, word count, and character count for text files
  - Generates SHA256 hash for security verification
  - Works with any file type
  - Provides human-readable output with formatting and emojis
  - Detects file types: text, executable, archive, image, video, audio

Options:
  --help, -h    Show this help message

Behavior:
  - Without arguments: shows usage help and returns error
  - With --help or -h: shows detailed help and returns success
  - With file path: analyzes the file and displays comprehensive information
  - Returns error if file doesn't exist
  - Returns error if required dependencies are missing

File Type Detection:
  - Text files: Shows line count, word count, character count
  - Executable files: Shows executable status and shebang
  - Archive files: Detects tar, gz, bz2, zip, rar, 7z formats
  - Image files: Detects jpg, jpeg, png, gif, bmp, svg, webp formats
  - Video files: Detects mp4, avi, mkv, mov, wmv, flv, webm formats
  - Audio files: Detects mp3, wav, flac, ogg, aac, m4a formats

Output Sections:
  - Basic Information: Size, modification date, permissions, owner
  - File Type: Detected file type from file command
  - Type-Specific Analysis: Additional info based on file type
  - SHA256 Hash: Cryptographic hash for verification
  - Additional Info: Inode, hard links, device information

Dependencies:
  - file (file type detection)
  - stat (file statistics)
  - du (disk usage)
  - wc (word count)
  - sha256sum (hash generation)
  - head, grep, cut (for text processing)

Examples:
  analyze-file document.txt        # Analyze text file
  analyze-file script.sh           # Analyze shell script
  analyze-file image.jpg           # Analyze image file
  analyze-file archive.tar.gz      # Analyze archive file
  analyze-file --help              # Show help message

Note: The function provides different analysis based on detected file type.
      Text files get detailed line/word/character counts, while binary files
      get type-specific detection. The SHA256 hash is always generated for
      security verification purposes. Output uses emojis and colors for
      better readability.
EOF
                return 0
                ;;
            automotd)
                cat <<EOF
automotd - Automatic Message of the Day Generator

Automatically generates a daily message of the day (MOTD) with a fortune.

Description:
  - Runs automatically when bashrc is sourced (if enabled)
  - Creates a daily fortune message in \$HOME/motd.txt
  - Only updates once per day (checks timestamp in \$HOME/motd.time)
  - Displays the fortune when a new shell session starts
  - Can be dismissed with "motd shoo"

How it works:
  - Checks if 24 hours have passed since last update
  - If yes, generates a new fortune and saves it to \$HOME/motd.txt
  - Only creates motd.txt if it doesn't already exist (won't override existing file)
  - The motd.txt file is displayed by the motd command

Behavior:
  - Runs automatically when sourced from .bashrc (if enable_automotd is true)
  - Checks timestamp in \$HOME/motd.time to determine if 24 hours have passed
  - Creates \$HOME/motd.txt with fortune cookie if it doesn't exist
  - Updates timestamp file after checking
  - Non-interactive - runs silently in background

Dependencies:
  - fortune (fortune cookie generator)
  - jq (JSON processor, for dependency checking)

Files created:
  - \$HOME/motd.time - Timestamp of last update (Unix epoch seconds)
  - \$HOME/motd.txt - The daily fortune message (only created if missing)

Configuration:
  - Enable/disable: Edit DOGRC.json
    Set "enable_automotd": true or false
  - Default: true (enabled by default)

Examples:
  # automotd runs automatically when .bashrc is sourced
  # To view the generated MOTD:
  motd print
  
  # To remove the MOTD:
  motd shoo
  
  # To manually create/edit MOTD:
  motd make

Note: This script runs automatically and is not called directly by users.
      It's controlled by the enable_automotd setting in DOGRC.json.
      The script only creates motd.txt if it doesn't exist, so manually
      created MOTD files won't be overwritten. The timestamp check ensures
      the script only updates once per day, even if the shell is started
      multiple times.
EOF
                return 0
                ;;
            available)
                cat <<EOF
available - List Available Bash Functions

List all bash functions currently defined in the shell in a formatted table.

Usage: available [OPTIONS]

Description:
  - Displays all functions available after sourcing ~/.bashrc
  - Shows functions in a formatted 3-column table
  - Filters out functions starting with underscore by default
  - Can be run as a function or as a standalone script

Options:
  --all, -a        Show all functions (including those starting with underscore)
  --hold, -h       Same as --all (show all functions)

Behavior:
  - When run as a function: lists functions in current shell session
  - When run as a script: sources ~/.bashrc in a subshell first, then lists functions
  - Functions are sorted alphabetically
  - Long function names are truncated with "..." if they exceed 27 characters
  - By default, filters out functions starting with underscore (internal/private functions)

Function Filtering:
  - Default mode: Excludes functions starting with underscore (_)
  - All mode (--all/--hold): Shows all functions including internal ones
  - Internal functions are typically helper functions used by plugins

Dependencies:
  - compgen (bash builtin, for listing functions)
  - sort (for alphabetical sorting)
  - printf (for formatted output)

Examples:
  available              # List all public functions (excludes _* functions)
  available --all        # List all functions including internal ones
  available -a           # Same as --all
  available --hold       # Same as --all
  available -h           # Same as --all

Note: By default, functions starting with underscore are filtered out to reduce
      clutter from internal/private functions. Use --all or --hold to see all
      functions. This is useful for discovering what functions are available
      in your shell environment. The function complements drchelp, which provides
      detailed help for specific functions.
EOF
                return 0
                ;;
            dots)
                cat <<EOF
dots - Manage and Navigate .config Directories

Quick access to list and navigate directories in ~/.config.

Usage: dots <command> [directory]
       dots <directory>

Description:
  - Lists all directories in ~/.config
  - Navigates to specific .config subdirectories
  - Lists contents of .config subdirectories
  - Provides convenient shortcuts for dotfile management
  - Includes bash completion support

Commands:
  ls [dir]         List all .config directories, or contents of a specific directory
  <dir>            Navigate to a .config subdirectory and list its contents
  help             Show help message

Special Cases:
  .config          Can be used to refer to ~/.config itself (both for ls and navigation)

Behavior:
  - Without arguments: shows usage help
  - "dots ls": lists all directories in ~/.config (grouped by first letter, colored)
  - "dots ls <dir>": lists contents of ~/.config/<dir>
  - "dots <dir>": changes to ~/.config/<dir> and lists its contents
  - Uses eza if available, otherwise falls back to ls
  - Returns error if directory doesn't exist

Bash Completion:
  - Tab completion is automatically registered
  - Completes with directory names from ~/.config
  - Supports "ls" and "help" commands
  - Includes ".config" as a special completion option

Dependencies:
  - find, sort, xargs, ls (for listing)
  - eza (optional, for enhanced listing with icons)
  - cd (builtin, for navigation)

Examples:
  dots ls                    # List all .config directories
  dots ls hypr              # List contents of ~/.config/hypr
  dots hypr                 # Navigate to ~/.config/hypr and list contents
  dots waybar               # Navigate to ~/.config/waybar and list contents
  dots .config              # Navigate to ~/.config itself
  dots ls .config           # List contents of ~/.config
  dots help                 # Show help message

Note: All operations work within ~/.config/ directory. The function will
      change your current directory when navigating to a subdirectory.
      Directory listing is colorized and grouped by first letter for
      better readability. Bash completion makes it easy to discover
      available .config directories.
EOF
                return 0
                ;;
            navto)
                cat <<EOF
navto - Quick Navigation to Predefined Destinations

Navigate to predefined directory destinations using short keys.

Usage: navto [destination-key]
       navto --remove|-r|--delete|-d <destination-key>

Description:
  - Manages a JSON file of destination shortcuts stored in config/navto.json
  - Navigates to directories by typing a short key (e.g., "D" for Documents)
  - Automatically creates template with common destinations on first use
  - Allows adding and removing destinations interactively
  - Provides bash completion with destination names
  - Automatically detects and offers to remove stale destinations

Commands:
  <key>                    Navigate to destination by key
  (no args)                List all available destinations
  --remove|-r|--delete|-d  Remove a destination (prompts for confirmation)

Default Destinations (created on first use):
  X    - Home (\$HOME)
  D    - Documents (\$HOME/Documents)
  P    - Pictures (\$HOME/Pictures)
  V    - Videos (\$HOME/Videos)
  M    - Music (\$HOME/Music)
  L    - Downloads (\$HOME/Downloads)
  C    - Code (\$HOME/Code)
  .    - Dotfiles (\$HOME/.config)
  T    - Temporary (/tmp)

Behavior:
  - Without arguments: lists all available destinations with keys, names, and paths
  - With key: navigates to the destination and lists directory contents
  - If destination doesn't exist: prompts to add it interactively
  - If path no longer exists: prompts to remove the stale destination
  - Keys are case-insensitive (automatically converted to uppercase)
  - Paths can use \$HOME variable (stored as \$HOME, expanded when used)
  - Uses eza if available, otherwise falls back to ls
  - Creates config/navto.json automatically if it doesn't exist (with template)

Bash Completion:
  - Tab completion is automatically registered
  - Shows "key - name" format for easy selection
  - Completes with all available destination keys
  - Supports removal flags (--remove, -r, --delete, -d)

Interactive Features:
  - Adding destinations: prompts for name and path, validates path exists
  - Removing destinations: shows destination info and prompts for confirmation
  - Template creation: offers to create default template if file doesn't exist
  - Stale detection: automatically detects and offers to remove broken paths

Dependencies:
  - jq (for JSON manipulation)
  - cd (builtin, for navigation)
  - eza (optional, for enhanced listing with icons)
  - ls (fallback if eza not available)
  - mktemp, mv, rm (for atomic file operations)

Files:
  - config/navto.json - JSON file storing destination keys, names, and paths

Examples:
  navto                    # List all available destinations
  navto D                  # Navigate to Documents
  navto X                  # Navigate to Home
  navto .                  # Navigate to .config
  navto --remove OLD       # Remove destination with key "OLD"
  navto -r TEST            # Remove destination with key "TEST"

Note: The navto.json file is stored in the DOGRC config directory. Keys are
      case-insensitive and automatically converted to uppercase. Paths can
      contain environment variables like \$HOME which are expanded when
      navigating. The function provides a convenient way to create shortcuts
      for frequently accessed directories. Bash completion makes it easy to
      discover and select destinations.
EOF
                return 0
                ;;
            cpuinfo)
                cat <<EOF
cpuinfo - Display CPU Usage Information

Display current CPU usage and top CPU-consuming processes.

Usage: cpuinfo

Description:
  - Shows current CPU usage percentage
  - Displays top 10 processes by CPU usage
  - Provides quick overview of system CPU load
  - Useful for monitoring system performance

Behavior:
  - Extracts CPU usage from top command output
  - Sorts processes by CPU usage (highest first)
  - Limits output to top 10 processes
  - Returns 0 on success

Dependencies:
  - top (for CPU usage information)
  - grep (for filtering output)
  - awk (for text processing)
  - cut (for extracting CPU percentage)
  - ps (for process listing)
  - head (for limiting output)

Examples:
  cpuinfo               # Display CPU usage and top processes

Output Format:
  CPU Usage:
  <percentage>%

  Top CPU Processes:
  [ps aux output sorted by CPU usage, top 10]

Note: The function provides a quick snapshot of CPU usage. For continuous
      monitoring, consider using top or htop directly. The CPU percentage
      is extracted from top's output and may vary slightly from other tools.
EOF
                return 0
                ;;
            system-stats)
                cat <<EOF
system-stats - Enhanced System Statistics Display

Display comprehensive system statistics including CPU, memory, disk, and network.

Usage: system-stats [OPTIONS]

Description:
  - Shows CPU usage percentage
  - Displays memory statistics (total, used, free, available, percentage)
  - Shows disk usage for root filesystem
  - Displays network statistics (if available)
  - Shows system uptime and load average
  - Supports live updating with --watch mode
  - Can output as JSON format for scripting

Options:
  --watch, -w              Enable watch mode (live updating display)
  --json, -j               Output statistics as JSON format
  --interval, -i <seconds> Set update interval for watch mode (default: 2 seconds)
  --help, -h               Show this help message

Modes:
  Default Mode:
    - Displays statistics once and exits
    - Human-readable formatted output
    - Shows all available statistics

  Watch Mode (--watch):
    - Continuously updates the display
    - Clears screen before each update
    - Updates at specified interval (default: 2 seconds)
    - Press Ctrl+C to exit
    - Useful for real-time monitoring

  JSON Mode (--json):
    - Outputs statistics in JSON format
    - Suitable for scripting and automation
    - Can be combined with --watch for continuous JSON output
    - Each update is a complete JSON object

Statistics Displayed:
  CPU:
    - Current CPU usage percentage
    - Uses top or vmstat (whichever is available)

  Memory:
    - Total memory
    - Used memory (with percentage)
    - Free memory
    - Available memory
    - Memory usage percentage

  Disk:
    - Root filesystem usage percentage
    - Uses df command

  Network:
    - RX (receive) statistics (if available)
    - TX (transmit) statistics (if available)
    - Requires ifconfig or similar tool

  System:
    - System uptime
    - Load average (1, 5, 15 minutes)

Dependencies:
  Required:
    - free (memory statistics)
    - df (disk usage)
    - uptime (system uptime)

  Optional (for enhanced features):
    - top or vmstat (CPU usage - more accurate)
    - ifconfig or ip (network statistics)
    - /proc/loadavg (load average on Linux)

Examples:
  system-stats                    # Display statistics once
  system-stats --watch            # Live updating display (2 second interval)
  system-stats --watch --interval 5  # Live updating (5 second interval)
  system-stats --json             # Output as JSON
  system-stats --watch --json     # Continuous JSON output
  system-stats -w -i 1            # Watch mode with 1 second interval

Output Format:
  Default (human-readable):
    ═══════════════════════════════════════════════════════════
                        SYSTEM STATISTICS
    ═══════════════════════════════════════════════════════════
    
    CPU Usage:        <percentage>
    
    Memory:
      Total:          <size>
      Used:           <size> (<percentage>%)
      Free:           <size>
      Available:      <size>
    
    Disk Usage (/):   <percentage>
    
    Network:
      RX:             <status>
      TX:             <status>
    
    System:
      Uptime:         <time>
      Load Average:   <1min, 5min, 15min>
    ═══════════════════════════════════════════════════════════

  JSON Format:
    {
      "cpu": { "usage": "<percentage>" },
      "memory": {
        "total": "<size>",
        "used": "<size>",
        "free": "<size>",
        "available": "<size>",
        "percent": <number>
      },
      "disk": { "usage": "<percentage>" },
      "network": {
        "rx": "<status>",
        "tx": "<status>"
      },
      "system": {
        "uptime": "<time>",
        "load_average": "<values>"
      }
    }

Note: The function adapts to available system tools. Some statistics may
      show "N/A" if required tools are not available. CPU usage detection
      varies by system - Linux systems typically provide more detailed
      information. Network statistics require appropriate network tools
      and may not be available on all systems. Watch mode uses clear to
      refresh the display - ensure your terminal supports ANSI escape codes.
      Tab completion is available for flags and options.
EOF
                return 0
                ;;
            network-info)
                cat <<EOF
network-info - Network Information and Diagnostics

Display comprehensive network information including interfaces, IPs, speed tests, ports, and connections.

Usage: network-info [OPTIONS]

Description:
  - Shows network interfaces and their IP addresses
  - Displays default gateway and DNS servers
  - Can test network speed (requires speedtest-cli)
  - Shows listening ports on the system
  - Displays active network connections
  - Useful for network troubleshooting and monitoring
  - Adapts to available system tools (ip, ifconfig, ss, netstat)

Options:
  --speed, -s              Test network speed (requires speedtest-cli)
  --ports, -p              Show listening ports
  --connections, -c        Show active network connections
  --help, -h               Show this help message

Modes:
  Default Mode (no flags):
    - Shows network interfaces and IP addresses
    - Displays default gateway
    - Shows DNS servers
    - Uses ip command on Linux, ifconfig on macOS/BSD

  Speed Test Mode (--speed):
    - Runs network speed test using speedtest-cli
    - Shows download and upload speeds
    - Requires speedtest-cli to be installed
    - May take a minute to complete

  Ports Mode (--ports):
    - Lists all listening ports on the system
    - Shows port number, protocol, and process
    - Uses ss command (preferred) or netstat (fallback)
    - Limited to top 20 ports for readability

  Connections Mode (--connections):
    - Shows active network connections
    - Displays local and remote addresses
    - Shows connection state
    - Uses ss command (preferred) or netstat (fallback)
    - Limited to top 20 connections for readability

Flags can be combined:
  - network-info --ports --connections  # Show both ports and connections
  - network-info -s -p                  # Test speed and show ports

Network Interface Information:
  - Lists all network interfaces (wired, wireless, virtual)
  - Shows IPv4 addresses for each interface
  - Displays default gateway (router IP)
  - Shows configured DNS servers
  - Format varies by system (Linux vs macOS/BSD)

Speed Test:
  - Uses speedtest-cli or speedtest command
  - Tests download and upload speeds
  - Connects to nearest speedtest server
  - Results shown in Mbps (megabits per second)
  - Requires internet connection

Listening Ports:
  - Shows ports that are listening for incoming connections
  - Includes both TCP and UDP ports
  - Displays associated process name (if available)
  - Useful for identifying running services
  - Helps with firewall configuration

Active Connections:
  - Shows established network connections
  - Displays both incoming and outgoing connections
  - Shows connection state (ESTABLISHED, TIME_WAIT, etc.)
  - Useful for monitoring network activity
  - Helps identify suspicious connections

Dependencies:
  Required (at least one):
    - ip (Linux, preferred) or ifconfig (macOS/BSD/Linux fallback)
  
  Optional (for enhanced features):
    - ss (Linux, preferred for ports/connections)
    - netstat (fallback for ports/connections)
    - speedtest-cli (for speed testing)
    - speedtest (alternative speed test tool)

Installation:
  Linux (Debian/Ubuntu):
    sudo apt install iproute2        # For ip and ss commands
    sudo apt install net-tools       # For netstat (if ss not available)
    pip install speedtest-cli        # For speed testing
  
  Linux (RHEL/CentOS):
    sudo yum install iproute         # For ip and ss commands
    sudo yum install net-tools       # For netstat
    pip install speedtest-cli        # For speed testing
  
  macOS:
    # ifconfig and netstat are built-in
    pip install speedtest-cli        # For speed testing

Examples:
  network-info                       # Show interfaces and IPs (default)
  network-info --speed               # Test network speed
  network-info --ports               # Show listening ports
  network-info --connections         # Show active connections
  network-info -s -p                 # Test speed and show ports
  network-info --ports --connections # Show ports and connections
  network-info -p -c                 # Short flags for ports and connections

Output Format:
  Default (Interfaces):
    ═══════════════════════════════════════════════════════════
                      NETWORK INTERFACES
    ═══════════════════════════════════════════════════════════
    
    Interfaces and IP Addresses:
      wlp5s0:
        IP: 192.168.1.100/24
    
    Default Gateway:
      192.168.1.1
    
    DNS Servers:
      8.8.8.8
      8.8.4.4
    ═══════════════════════════════════════════════════════════

  Ports:
    ═══════════════════════════════════════════════════════════
                      LISTENING PORTS
    ═══════════════════════════════════════════════════════════
    
    Port  Protocol  Process
    ───────────────────────────────────────────────────────
    22    tcp       sshd
    80    tcp       nginx
    443   tcp       nginx
    ═══════════════════════════════════════════════════════════

  Connections:
    ═══════════════════════════════════════════════════════════
                    ACTIVE CONNECTIONS
    ═══════════════════════════════════════════════════════════
    
    Local Address          Remote Address         State
    ────────────────────────────────────────────────────────────────────
    192.168.1.100:54321    8.8.8.8:53            ESTABLISHED
    ═══════════════════════════════════════════════════════════

Note: The function automatically detects available tools and uses the best
      option. On Linux, 'ip' and 'ss' are preferred over 'ifconfig' and
      'netstat' as they are more modern and provide better information.
      Port and connection listings are limited to 20 entries for readability.
      For full listings, use the tools directly (ss -tulpn, netstat -tulpn).
      Speed testing requires an active internet connection and may take
      a minute to complete. Tab completion is available for flags.
EOF
                return 0
                ;;
            disk-usage|diskusage)
                cat <<EOF
disk-usage - Enhanced Disk Usage Analyzer

Enhanced disk usage analyzer with tree view and cleanup suggestions.

Usage: disk-usage [OPTIONS] [directory]
       disk-usage [directory] [OPTIONS]
       diskusage [OPTIONS] [directory]

Description:
  - Shows disk usage tree for a directory (default: current directory)
  - Displays top N largest directories with --top flag
  - Suggests files to clean (temp files, caches) with --clean flag
  - Uses human-readable file sizes throughout
  - Provides comprehensive disk space analysis

Options:
  --top, -t <number>       Show top N largest directories
                           Example: disk-usage --top 10
                           Shortcut: disk-usage 10
  --clean, -c              Suggest files to clean (temp files, caches)
                           Scans common cache/temp locations
                           Shows estimated total cleanable space
  --help, -h               Show this help message
  --                       Separator for directory path (useful when path starts with -)

Modes:
  Default Mode:
    - Shows disk usage tree using du command
    - Uses tree command if available (optional dependency)
    - Displays up to 2 levels deep by default
    - Output sorted by size (human-readable)
    - Defaults to current directory if no path specified

  Top N Mode (--top):
    - Shows only the N largest directories
    - Sorted by size (largest first)
    - Numbered list format
    - Faster than full tree view

  Clean Mode (--clean):
    - Scans common temp/cache locations:
      * ~/.cache, ~/.tmp, ~/tmp
      * /tmp, /var/tmp
      * ~/.local/share/Trash, ~/.thumbnails
      * ~/.npm, ~/.yarn
      * ~/.pip/cache
      * ~/.m2/repository
      * ~/.gradle/caches
      * ~/.rustup, ~/.cargo/registry
      * ~/.go/pkg
    - Shows size for each directory found
    - Calculates estimated total cleanable space
    - Displays human-readable totals
    - Provides safety warnings

Behavior:
  - Default mode: shows disk usage tree (current directory if not specified)
  - Top N mode: requires numeric argument for --top flag (or as positional arg)
  - Clean mode: ignores directory argument, scans predefined locations
  - Validates directory exists before processing (default and top modes)
  - Returns error if directory doesn't exist (default and top modes)
  - Returns error if --top is used without a numeric argument
  - Handles permission errors gracefully (suppresses errors from du)

Directory Resolution:
  - Accepts relative and absolute paths
  - Expands to absolute path for display
  - Current directory (.) is used if no directory specified
  - Works with paths starting with - using -- separator

Output Format:
  Default Mode:
    📊 DISK USAGE TREE
    ===================
    Directory: /absolute/path
    
    [Tree view or du output sorted by size]

  Top N Mode:
    📊 TOP N LARGEST DIRECTORIES
    ======================================
    Directory: /absolute/path
    
    1.  <size>  /path/to/dir1
    2.  <size>  /path/to/dir2
    ...

  Clean Mode:
    🧹 CLEANUP SUGGESTIONS
    ====================
    
      📁 /path/to/cache
         Size: <human-readable-size>
    
      💡 Estimated total cleanable: ~<total-size>
    
      Note: Review these directories before deleting.
            Some may contain important cached data.

Dependencies:
  - du (required, for disk usage calculation)
  - sort (required, for sorting output)
  - tree (optional, for enhanced tree view in default mode)
  - numfmt or awk (optional, for human-readable total in clean mode)
  - cut, head, tail, nl (for output formatting)

Examples:
  disk-usage                            # Show disk usage tree for current directory
  disk-usage /home                      # Show disk usage tree for /home
  disk-usage --top 10                   # Show top 10 largest directories
  disk-usage 10                         # Same as above (shorthand)
  disk-usage --top 5 /var               # Show top 5 largest directories in /var
  disk-usage --clean                    # Suggest files to clean
  disk-usage --help                     # Show help message
  diskusage                             # Same as disk-usage (alias)

Note: The function provides multiple ways to analyze disk usage. Default mode
      gives a comprehensive tree view, while --top mode is faster for finding
      space hogs. The --clean mode scans common cache locations but doesn't
      automatically delete anything - review suggestions before cleaning. The
      tree command is optional - if not available, the function falls back to
      du output. All sizes are displayed in human-readable format (KB, MB, GB).
      Permission errors are suppressed for better user experience, but may
      affect accuracy if run without appropriate permissions.
EOF
                return 0
                ;;
            cpx)
                cat <<EOF
cpx - Compile and Execute C++ Files

Quickly compile and run C++ source files with automatic cleanup.

Usage: cpx [file.cpp]

Description:
  - Compiles C++ source files using g++
  - Automatically executes the compiled program
  - Displays exit code after execution
  - Cleans up compiled binary (a.out) automatically
  - Defaults to main.cpp if no file specified

Behavior:
  - Without arguments: uses main.cpp as default
  - Compiles file using g++
  - Executes ./a.out after successful compilation
  - Displays exit code of the program
  - Removes a.out file after execution
  - Returns error if file doesn't exist or compilation fails

Dependencies:
  - g++ (C++ compiler)

Examples:
  cpx                    # Compile and run main.cpp
  cpx program.cpp        # Compile and run program.cpp
  cpx test.cpp           # Compile and run test.cpp

Output:
  [Program output]
  Exit Code: <exit_code>

Note: The function always creates and removes a.out in the current directory.
      If a.out already exists, it will be overwritten. The exit code is
      displayed after program execution to help with debugging.
EOF
                return 0
                ;;
            dl-paper)
                cat <<EOF
dl-paper - Download Wallpaper Clips with yt-dlp

List available formats or download video clips for use as wallpapers.

Usage: dl-paper <url> [--cookies <file>]
       dl-paper down|d|- [--cookies <file>] <format> <url>

Description:
  - Lists available video formats for a URL
  - Downloads a 4-minute clip (60-300 seconds) from a video
  - Uses ffmpeg to extract the clip segment
  - Designed for downloading wallpaper clips from video sources
  - Supports cookies for accessing age-restricted or region-locked content
  - Videos are always produced without audio (silent) to reduce file size

Modes:
  Format Listing:  dl-paper <url> [--cookies <file>]
                   Shows all available formats for the video URL
                   Cookies can be specified before or after the URL
  
  Download:        dl-paper down [--cookies <file>] <format> <url>
                   dl-paper d [--cookies <file>] <format> <url>
                   dl-paper - [--cookies <file>] <format> <url>
                   Downloads a 4-minute clip (60-300 seconds) using the specified format
                   Download trigger (down/d/-) can appear anywhere in arguments
                   Cookies can be specified anywhere in the argument list
                   Videos are always produced without audio

Behavior:
  - Format listing mode: URL can be first or after --cookies flag
  - Download mode: Download trigger (down/d/-) can appear anywhere in arguments
  - Cookies flag: Can appear anywhere in either mode (before or after other arguments)
  - Format codes can be found using the list mode
  - Uses ffmpeg as the downloader for clip extraction
  - Commands are case-insensitive (DOWN, D, or -)
  - All downloaded videos are silent (no audio track) to reduce file size

Argument Parsing:
  - Two-phase algorithm: First detects mode, then parses arguments
  - Scans all arguments to find download trigger (down/d/-)
  - Removes trigger from argument list before parsing
  - Flexible argument ordering: cookies, format, and URL can be in any order
  - Position-independent: download trigger doesn't need to be first argument

Dependencies:
  - yt-dlp (for video downloading and format listing)
  - ffmpeg (required for download mode, for clip extraction)

Examples:
  dl-paper https://youtube.com/watch?v=VIDEO_ID
           # List available formats
  
  dl-paper --cookies cookies.txt https://youtube.com/watch?v=VIDEO_ID
           # List formats with cookies (cookies can be before URL)
  
  dl-paper https://youtube.com/watch?v=VIDEO_ID --cookies cookies.txt
           # List formats with cookies (cookies can be after URL)
  
  dl-paper down 22 https://youtube.com/watch?v=VIDEO_ID
           # Download format 22 as a 4-minute silent clip
  
  dl-paper down 22 --cookies cookies.txt https://youtube.com/watch?v=VIDEO_ID
           # Download format 22 with cookies (cookies between format and URL)
  
  dl-paper --cookies cookies.txt d 109 https://youtube.com/watch?v=VIDEO_ID
           # Download format 109 with cookies (download trigger not first)
  
  dl-paper d best https://youtube.com/watch?v=VIDEO_ID
           # Download best quality format (case-insensitive)

Note: The download mode extracts a 4-minute segment (60-300 seconds) from the
      video, which is ideal for wallpaper loops. All videos are produced without
      audio to reduce file size. Use the list mode first to find the format code
      you want. Format codes are typically numbers or special codes like "best"
      or "worst". The function supports flexible argument ordering - the download
      trigger and cookies flag can appear anywhere in the argument list, making
      it convenient to use.
EOF
                return 0
                ;;
            drcfortune)
                cat <<EOF
drcfortune - Display Fortune Cookies with Typewriter Effect

Display fortune cookies with an animated typewriter effect and enhanced formatting.

Usage: drcfortune [OPTIONS] [fortune-args...]

Description:
  - Wrapper around the fortune command with visual enhancements
  - Displays fortune cookies with animated typewriter effect
  - Supports fortune cookie format (title + fortune text separated by "%")
  - Formats title in bold blue with dog paw emoji prefix
  - Provides customizable typewriter speeds for title and fortune text
  - Can disable typewriter effect for instant display
  - Supports case transformation and terminal clearing

Options:
  --zero              Disable typewriter effect (instant display)
  --custom <title_speed> <fortune_speed>
                     Set custom typewriter speeds (in seconds per character)
                     Use "-" for either speed to use default value
                     Example: --custom 0.05 0.005 (faster speeds)
                     Example: --custom - 0 (default title speed, instant fortune)
  --clear             Clear terminal before displaying fortune
  --upper             Convert fortune text to uppercase
  --lower             Convert fortune text to lowercase
  --no-a              Skip fortune -a flag (don't search all fortune files)
  [fortune-args...]   Additional arguments passed directly to fortune command

Typewriter Speeds:
  - Default title speed: 0.1 seconds per character
  - Default fortune speed: 0.01 seconds per character
  - Use --zero to disable typewriter effect completely
  - Use --custom to set custom speeds for title and/or fortune text
  - Speeds must be positive floating point numbers (e.g., 0.05, 0.1, 1.0)

Behavior:
  - Retrieves fortune using fortune command with -a and -c flags (unless --no-a)
  - Parses fortune cookie format: title and fortune text separated by "%" or "---"
  - If no separator found, treats entire output as fortune text
  - Processes title: removes parentheses, converts to uppercase, extracts basename if path-like
  - Applies case transformation if --upper or --lower flags are set
  - Clears terminal if --clear flag is set
  - Displays title (if present) in bold blue with 🐾 prefix using typewriter effect
  - Displays fortune text with typewriter effect
  - Ensures final newline is present

Fortune Cookie Format:
  - Standard format: title on one line, "%" on its own line, fortune text
  - Alternative format: title, "---" separator, fortune text
  - If no separator found, entire output is treated as fortune text
  - Title is processed and displayed separately from fortune text

Dependencies:
  - fortune (fortune cookie generator)
  - tput (for terminal capabilities)
  - head (for text processing)

Examples:
  drcfortune                    # Display fortune with default typewriter effect
  drcfortune --zero             # Display fortune instantly (no typewriter effect)
  drcfortune --clear            # Clear terminal before displaying fortune
  drcfortune --upper            # Display fortune text in uppercase
  drcfortune --lower            # Display fortune text in lowercase
  drcfortune --custom 0.05 0.005  # Faster typewriter speeds
  drcfortune --custom - 0       # Default title speed, instant fortune text
  drcfortune --no-a             # Skip -a flag (don't search all fortune files)
  drcfortune computers          # Pass "computers" argument to fortune command
  drcfortune --clear --upper    # Combine multiple flags

Note: The typewriter effect creates an animated display by printing each character
      with a small delay. Use --zero for instant display or --custom to adjust
      speeds. The --custom flag will echo the expanded command to stderr if you
      use "-" for either speed value. The title (if present) is always displayed
      in bold blue with a dog paw emoji prefix. Case transformation flags (--upper,
      --lower) only affect the fortune text, not the title. The --clear flag uses
      the clear command or ANSI escape sequences to clear the terminal screen.
EOF
                return 0
                ;;
            pokefetch)
                cat <<EOF
pokefetch - System Information with Pokemon Logo

Display system information using fastfetch with a random Pokemon ASCII art logo.

Usage: pokefetch [--relocate|--RELOCATE|-l|-L <file>]

Description:
  - Displays system information using fastfetch
  - Uses a random Pokemon ASCII art as the logo
  - Shows Pokemon name with battle message
  - Provides a fun and colorful way to view system info
  - Randomly selects from Pokemon #1-4 (Bulbasaur, Charmander, Squirtle, Pikachu)

Options:
  --relocate, --RELOCATE, -l, -L <file>
                      Specify custom location for temporary Pokemon ASCII art file
                      Default: /tmp/pokefetch.txt
                      The function will use <file> and derive a second file (<file>2)
                      for temporary processing

Behavior:
  - Generates random Pokemon ASCII art using pokemon-colorscripts
  - Extracts Pokemon name from the art
  - Displays system information with Pokemon logo using fastfetch
  - Shows "[ Pokemon Name ] Joins The Battle!" message
  - Uses temporary files for processing (default: /tmp/pokefetch.txt)
  - Returns 0 on success

Dependencies:
  - pokemon-colorscripts (for generating Pokemon ASCII art)
  - fastfetch (for displaying system information)
  - head, sed, mv (for text processing)

Files:
  - /tmp/pokefetch.txt - Default temporary file storing Pokemon ASCII art
  - <file> and <file>2 - Custom temporary files when --relocate is used

Examples:
  pokefetch                          # Display system info with random Pokemon logo
  pokefetch --relocate /path/to/file.dat    # Use custom file location
  pokefetch -l ~/my-pokemon.txt      # Use custom file location (short form)

Note: The function randomly selects from the first 4 Pokemon (Bulbasaur,
      Charmander, Squirtle, Pikachu) and displays them as ASCII art alongside
      your system information. The Pokemon name is extracted and displayed in
      a battle message. This provides a fun, colorful alternative to standard
      system information displays.
EOF
                return 0
                ;;
            weather)
                cat <<EOF
weather - Weather Information Display

Display weather information for your location or a specified location.

Usage: weather [mode] [flags] [location...]
       weather --help|-h
       weather help

Description:
  - Displays weather information using wttr.in service
  - Auto-detects your location using IP geolocation
  - Supports current weather and 3-day forecast
  - Can specify custom locations via flags
  - Provides formatted output with colored headers

Modes:
  (none)      Display both current weather and 3-day forecast
  current     Show only current weather
  forecast    Show only 3-day forecast
  help        Show help message

Flags:
  --help, -h        Show this help message
  --location, -l    Specify a custom location (passes remaining args to wttr)
  --wttr, -w        Pass remaining arguments directly to wttr function

Behavior:
  - Without arguments: shows help message
  - Without location flags: auto-detects city using ipinfo.io
  - With --location/--wttr: uses provided location and passes all remaining
    arguments to wttr() function
  - Location detection uses curl to query ipinfo.io/city
  - Returns error if location cannot be detected or provided

Location Detection:
  - Automatically detects city from your IP address
  - Uses ipinfo.io service for geolocation
  - Falls back to error if detection fails

Dependencies:
  - curl (for API requests and location detection)
  - head (for text processing)

Examples:
  weather                    # Show help
  weather --help             # Show help message
  weather current            # Current weather for auto-detected location
  weather forecast           # 3-day forecast for auto-detected location
  weather current --wttr "Orlando" n    # Current weather for Orlando with format 'n'
  weather --location "New York"         # Full weather for New York
  weather forecast -w "London"          # Forecast for London

Note: The function uses wttr.in service for weather data. When using
      --location or --wttr flags, all remaining arguments are passed directly
      to the wttr() function, allowing you to use any wttr.in format options.
      The auto-detection feature requires internet connectivity to query
      ipinfo.io. Tab completion is available for modes (current, forecast, help),
      flags (--help, -h, --location, -l, --wttr, -w), and 50 major cities (33 USA cities
      and 17 international cities) when using location flags. See also wttr()
      for direct access to wttr.in service.
EOF
                return 0
                ;;
            wttr)
                cat <<EOF
wttr - Direct Weather Query via wttr.in

Query weather information directly from wttr.in service.

Usage: wttr <location> [wttr-params...]

Description:
  - Direct interface to wttr.in weather service
  - Supports any location name or coordinates
  - Accepts wttr.in format parameters and options
  - Uses environment variable WTTR_PARAMS for default parameters
  - Respects Accept-Language header from LANG environment variable

Arguments:
  location        Location name, coordinates, or IP address
                  Spaces are automatically converted to '+' for URL encoding
  wttr-params     Additional parameters to pass to wttr.in
                  These are URL-encoded and added as query parameters

Environment Variables:
  WTTR_PARAMS     Default parameters to include in every request
                  Example: WTTR_PARAMS="format=j1" for JSON output
  LANG            Language preference (e.g., "en_US.UTF-8")
                  Only the language part (before underscore) is used

Behavior:
  - Converts location name spaces to '+' for URL encoding
  - Processes WTTR_PARAMS environment variable if set
  - URL-encodes all parameters using --data-urlencode
  - Sends request with Accept-Language header
  - Uses compressed transfer (--compressed)
  - Follows redirects and shows progress (-fGsS flags)

Dependencies:
  - curl (for HTTP requests)

Examples:
  wttr London              # Weather for London
  wttr "New York"          # Weather for New York (spaces converted to +)
  wttr Orlando n           # Weather for Orlando with format 'n'
  wttr 48.8566,2.3522      # Weather for coordinates (Paris)
  WTTR_PARAMS="format=j1" wttr Tokyo    # JSON format for Tokyo

Note: This is a direct wrapper around wttr.in service. All wttr.in format
      options and parameters are supported. The function automatically handles
      URL encoding of parameters. Tab completion is available with 50 major
      cities (33 USA cities including New York, Los Angeles, Chicago, Houston,
      Phoenix, Philadelphia, San Antonio, San Diego, Dallas, San Jose, Austin,
      Jacksonville, San Francisco, Indianapolis, Columbus, Fort Worth, Charlotte,
      Seattle, Denver, Washington, Boston, El Paso, Detroit, Nashville, Portland,
      Oklahoma City, Las Vegas, Memphis, Louisville, Baltimore, Milwaukee,
      Albuquerque, Tucson, Fresno, Sacramento; and 17 international cities
      including London, Tokyo, Paris, Sydney, Berlin, Moscow, Dubai, Singapore,
      Toronto, Mumbai, Barcelona, Rome, Amsterdam, Hong Kong, Seoul, Bangkok,
      Istanbul). For a more user-friendly interface with auto-detection and
      formatted output, see weather() function.
EOF
                return 0
                ;;
            drcversion)
                cat <<EOF
drcversion - Display DOGRC Version

Display the current version of DOGRC from configuration file.

Usage: drcversion

Description:
  - Reads version information from DOGRC.json configuration file
  - Displays version in a formatted message
  - Provides quick way to check installed DOGRC version

Behavior:
  - Reads version from config/DOGRC.json
  - Parses JSON to extract version field
  - Displays formatted version message
  - Returns 0 on success

Dependencies:
  - cat (for reading file)
  - jq (for JSON parsing)

Examples:
  drcversion             # Display: DOGRC Version <version>

Note: The version is read from the DOGRC.json configuration file in the
      config directory. This function helps identify which version of
      DOGRC is currently installed.
EOF
                return 0
                ;;
            drcupdate)
                cat <<EOF
drcupdate - Check for DOGRC Updates

Check if a newer version of DOGRC is available from the repository.

Usage: drcupdate [OPTIONS]

Description:
  - Checks for available DOGRC updates by comparing installed version with repository
  - Fetches remote version from GitHub repository
  - Uses semantic version comparison (same algorithm as _UPDATE.sh)
  - Supports version masking via version.fake file
  - Can run silently for automated checks (e.g., on shell startup)

Options:
  --silent, -s              Suppress output unless update is available
  --ignore-this-version, --ignore
                            Store current remote version in version.fake to ignore it
  --return-only             Compare versions without output, return exit code only
                            Exit codes: 0=up-to-date, 1=error, 2=update available, 3=downgrade possible
  --yes, -y                 Skip confirmation and automatically proceed with update

Version Detection:
  - Reads installed version from ~/DOGRC/config/DOGRC.json
  - If ~/DOGRC/config/version.fake exists, uses that version instead
  - Fetches remote version from GitHub repository
  - Compares versions using semantic versioning (major.minor.patch)

Behavior:
  - Without options: checks for updates and displays result
  - With --silent: only shows output if update is available
  - With --ignore-this-version: stores remote version in version.fake to ignore future checks
  - With --return-only: compares versions silently, returns exit code only (no output)
  - With --yes: skips confirmation prompt and automatically proceeds with auto-update
  - With --silent --yes: shows update message and automatically proceeds with auto-update
  
Exit Codes:
  Normal mode:
    - Returns 0 if check succeeds (regardless of update availability)
    - Returns 1 if DOGRC is not installed or version cannot be determined
    - Returns 123 if required dependencies are missing
  
  With --return-only:
    - Returns 0 if versions are equal (up-to-date)
    - Returns 1 if error occurs (DOGRC not installed, version cannot be determined, etc.)
    - Returns 2 if local version is older (update available)
    - Returns 3 if repository version is older (downgrade possible)

Version Masking:
  - Create ~/DOGRC/config/version.fake with a version to "fake" the installed version
  - Useful for testing or ignoring specific repository versions
  - Use --ignore-this-version to automatically create version.fake with current remote version
  - Delete version.fake to restore normal version checking

Dependencies:
  - curl (for fetching remote version from GitHub)
  - jq (for parsing JSON configuration files)

Files:
  - ~/DOGRC/config/DOGRC.json - Contains installed version
  - ~/DOGRC/config/version.fake - Optional file to override installed version

Examples:
  drcupdate                        # Check for updates (shows result)
  drcupdate --silent               # Check silently (only shows if update available)
  drcupdate --yes                  # Auto-update without confirmation
  drcupdate --silent --yes         # Check and auto-update silently
  drcupdate --ignore-this-version  # Ignore current remote version in future checks
  drcupdate --return-only          # Compare versions silently, check exit code
  
  # Use in scripts:
  drcupdate --return-only
  case \$? in
      0) echo "Up to date" ;;
      1) echo "Error occurred" ;;
      2) echo "Update available" ;;
      3) echo "Downgrade possible" ;;
  esac

Update Process:
  When an update is available, the function can:
  - Auto-update: Use --yes flag to automatically clone repository to /tmp and run update
  - Manual update: Follow these steps:
    1. Navigate to your cloned DOGRC repository directory
       Repository URL: https://github.com/lovelyspacedog/DOGRC
    2. Run: git pull
    3. Run: ./install/_UPDATE.sh

Note: The function uses the same version comparison algorithm as _UPDATE.sh for
      consistency. Version masking via version.fake allows you to test updates
      or ignore specific repository versions. The --silent flag is useful for
      automated checks that run on shell startup without cluttering output.
      The update script must be run from the git repository directory, not from
      ~/DOGRC/ (which is the installation directory). Tab completion is
      available for all flags.
EOF
                return 0
                ;;
            genpassword)
                cat <<EOF
genpassword - Generate Random Passwords

Generate secure random passwords of specified length with optional special characters.

Usage: genpassword [length] [--special|-s]

Description:
  - Generates cryptographically secure random passwords
  - Uses /dev/urandom as entropy source
  - Supports custom length (default: 16 characters)
  - Optional special character inclusion
  - Safe for use in scripts and automation

Options:
  --special, -s    Include special characters in password
                   Characters: !@#$%^&*()+=\-[]{}|;:,.<>?

Arguments:
  length           Password length (positive integer, default: 16)

Character Sets:
  Default:         A-Z, a-z, 0-9, underscore (_)
  With --special:  A-Z, a-z, 0-9, underscore, and special characters

Behavior:
  - Default length is 16 characters if not specified
  - Numeric arguments are interpreted as length
  - Special characters flag can be combined with length
  - Uses tr to filter characters from /dev/urandom
  - Returns 0 on success

Dependencies:
  - tr (for character filtering)
  - head (for limiting output length)
  - xargs (for output formatting)

Examples:
  genpassword                    # Generate 16-character password
  genpassword 20                 # Generate 20-character password
  genpassword --special          # Generate 16-character password with special chars
  genpassword 32 -s              # Generate 32-character password with special chars
  genpassword -s 24              # Generate 24-character password with special chars

Note: Passwords are generated using /dev/urandom which provides cryptographically
      secure random data. The function is suitable for generating passwords for
      accounts, API keys, or any other security-sensitive purposes.
EOF
                return 0
                ;;
            url-shortener)
                cat <<EOF
url-shortener - URL Shortening Service

Shorten long URLs using various free URL shortening services.

Usage: url-shortener <url> [OPTIONS]
       url-shortener [url] --service [service]
       shorturl <url> [OPTIONS]              # Shortcut alias

Description:
  - Shortens long URLs using free URL shortening services
  - Supports multiple services: is.gd, tinyurl
  - Automatically copies shortened URL to clipboard (if available)
  - No API keys required for supported services
  - Useful for sharing long URLs in messages, emails, or documents

Options:
  --service, -s <service>   Specify shortening service (default: is.gd)
                            Supported: is.gd, tinyurl
  --show-service            Display service name with shortened URL
  --help, -h                Show this help message
  --                        Separator for URL (useful when URL starts with -)

Services:
  is.gd (default):
    - Free, no API key required
    - Returns JSON response
    - Fast and reliable
    - Example: https://is.gd/create.php?format=json&url=<url>

  tinyurl:
    - Free, no API key required
    - Returns shortened URL directly
    - Simple and straightforward
    - Example: https://tinyurl.com/api-create.php?url=<url>

Behavior:
  - Requires a valid URL starting with http:// or https://
  - Validates URL format before sending request
  - Automatically copies result to clipboard if available
  - Shows error messages if shortening fails
  - Returns 0 on success, non-zero on error

Clipboard Support:
  - Automatically copies shortened URL to clipboard if available
  - Supports: wl-copy (Wayland), xclip (X11), pbcopy (macOS)
  - Shows "(Copied to clipboard)" message when successful
  - Works silently if clipboard tools are not available

Dependencies:
  Required:
    - curl (for API requests)
  
  Optional (for enhanced features):
    - jq (for better JSON parsing with is.gd)
    - wl-copy, xclip, or pbcopy (for clipboard support)

Examples:
  url-shortener https://example.com/very/long/url/path
  url-shortener https://example.com --service is.gd
  url-shortener https://example.com -s tinyurl
  url-shortener --service tinyurl https://example.com
  url-shortener --show-service https://example.com
  url-shortener -- https://example.com  # Use -- if URL starts with -
  shorturl https://example.com          # Shortcut alias
  shorturl https://example.com -s tinyurl  # Shortcut with options

Output Format:
  Default:
    https://is.gd/abc123
    (Copied to clipboard)
  
  With --show-service:
    https://is.gd/abc123 (is.gd)
    (Copied to clipboard)

Error Handling:
  - Validates URL format (must start with http:// or https://)
  - Checks for network connectivity
  - Handles API errors gracefully
  - Shows descriptive error messages
  - Returns appropriate exit codes

Note: The function requires an active internet connection to shorten URLs.
      Services may have rate limits or restrictions. The shortened URLs
      are permanent and will continue to work as long as the service
      remains operational. Clipboard copying is optional and will not
      fail if clipboard tools are unavailable. Tab completion is available
      for flags and service names. A shortcut alias 'shorturl' is available
      as a convenience (e.g., shorturl <url>).
EOF
                return 0
                ;;
            shorturl)
                # Redirect to url-shortener help
                if declare -f drchelp >/dev/null 2>&1; then
                    drchelp url-shortener
                    return 0
                else
                    echo "Error: drchelp not available" >&2
                    return 1
                fi
                ;;
            fastnote)
                cat <<EOF
fastnote - Quick Note Management

Manage quick scratchpad notes stored in numbered files.

Usage: fastnote [NUMBER] [ACTION]
       fastnote list
       fastnote clear

Description:
  - Creates and manages quick notes in ~/.fastnotes/ directory
  - Notes are stored as numbered files (notes_0.txt, notes_1.txt, etc.)
  - Opens notes in your default editor for quick editing
  - Provides a simple scratchpad system for temporary notes

Commands:
  list            List all available notes with previews
  clear           Remove all notes (prompts for confirmation, defaults to N)
  <number>        Open/edit a note by number (default action)
  <number> open   Open/edit a note by number (explicit)
  <number> cat    Print note contents to stdout
  <number> delete Delete a note by number

Behavior:
  - Without arguments: opens note 0 (creates if it doesn't exist)
  - "fastnote list": lists all available notes with first-line previews (truncated to 60 chars)
  - "fastnote clear": removes all notes after confirmation (prompts with [y/N], defaults to N)
  - "fastnote <n>": opens note number n in editor (creates if needed)
  - "fastnote <n> open": explicitly opens note number n in editor (creates if needed)
  - "fastnote <n> cat": prints note contents to stdout (does not create if missing)
  - "fastnote <n> delete": deletes note number n
  - Creates ~/.fastnotes directory automatically if it doesn't exist
  - Uses \$EDITOR environment variable (defaults to nvim)
  - Clear command shows count of notes that will be deleted
  - Clear command requires explicit confirmation (y or yes, case-insensitive)
  - Tab completion available for commands (LIST, CLEAR) and note numbers with previews

Dependencies:
  - mkdir (for creating directory)
  - touch (for creating note files)
  - basename, sed, head (for listing notes with previews)
  - cat (for printing note contents)
  - rm (for deleting notes)
  - read (for confirmation prompts)
  - Editor specified in \$EDITOR (default: nvim)

Files:
  - ~/.fastnotes/notes_*.txt - Note files (numbered)

Examples:
  fastnote              # Open note 0
  fastnote 1            # Open note 1
  fastnote list         # List all notes with previews
  fastnote 2 cat        # Print contents of note 2
  fastnote 5 open       # Explicitly open note 5
  fastnote 2 delete     # Delete note 2
  fastnote clear        # Remove all notes (prompts for confirmation)

Note: Note numbers must be positive integers or zero. The function will
      create note files automatically if they don't exist when opened (but not
      for "cat" command). The "list" command shows previews of the first line
      of each note (truncated to 60 characters). Tab completion is available
      for commands (shown in uppercase: LIST, CLEAR) and note numbers with
      previews. The "clear" command prompts for confirmation before deleting
      all notes, and defaults to "N" (no) for safety. Only "y" or "yes"
      (case-insensitive) will proceed with deletion.
EOF
                return 0
                ;;
            pastethis)
                cat <<EOF
pastethis - Paste Files to Pastebin

Upload files to Pastebin with automatic syntax highlighting and customizable options.

Usage: pastethis [OPTIONS] <file>
       pastethis -n <file>                    # Never expires
       pastethis --help

Description:
  - Uploads file contents to Pastebin with syntax highlighting
  - Supports 200+ programming languages and file formats
  - Automatically detects format from file extension (can be overridden)
  - Customizable privacy, expiration, and title settings

Options:
  --file|-f <file>           Specify file to paste (can also be positional argument)
  --privacy|-p <level>       Privacy level: public, unlisted, private (default: public)
  --title|-t <title>         Custom title for the paste (default: filename with extension)
  --expires|-e <duration>    Expiration time: n(never), 10m, 1h, 1d, 1w, 2w, 1m, 6m, 1y (default: 10M)
  --format|-r <language>     Syntax highlighting language (default: auto-detect from extension)
  --pastebin-api-key|-k <key> Override API key (normally read from ~/Documents/pastebin-api-key)
  -n                         Never expires (shortcut for --expires n)

Arguments:
  <file>                     File to paste (positional argument, same as --file)

Privacy Levels:
  - public (0)               Visible to everyone, appears in recent pastes
  - unlisted (1)             Not listed in recent pastes but accessible via direct link
  - private (2)              Only accessible to you (requires account and API key)

Expiration Times:
  - n, never                 Paste never expires
  - 10m, 10 minutes         Expires in 10 minutes
  - 1h, 1 hour              Expires in 1 hour
  - 1d, 1 day               Expires in 1 day
  - 1w, 1 week              Expires in 1 week
  - 2w, 2 weeks             Expires in 2 weeks
  - 1m, 1 month             Expires in 1 month
  - 6m, 6 months            Expires in 6 months
  - 1y, 1 year              Expires in 1 year

Format Options:
  - auto                     Explicitly request auto-detection from file extension
  - [language name]          Any supported language (see full list below)
  - text                     Plain text (no syntax highlighting)

Supported Languages (200+):
  Programming: Bash, Python, JavaScript, TypeScript, Java, C/C++, Rust, Go, Ruby, PHP, etc.
  Web: HTML, CSS, XML, JSON, YAML, Markdown
  Data: SQL, CSV, Diff, Log files
  Config: INI, TOML, Properties
  Other: Docker, Make, LaTeX, Assembly, etc.

Auto-Detection Examples:
  - script.py      → Python
  - config.json    → JSON
  - README.md      → Markdown
  - Dockerfile     → Docker
  - Makefile       → Make

Dependencies:
  - curl (for HTTP requests)
  - cat (for reading files)
  - API key file: ~/Documents/pastebin-api-key (must exist and be readable)

Files:
  - ~/Documents/pastebin-api-key - Contains your Pastebin API key
  - Input file (any readable file to be pasted)

Examples:
  pastethis script.py                           # Auto-detect Python highlighting
  pastethis -n script.py                        # Never expires, auto-detect Python
  pastethis --format auto config.json           # Explicit auto-detection for JSON
  pastethis --privacy unlisted --title "My Code" script.sh
  pastethis --expires 1d --format "C++" program.cpp
  pastethis --privacy private --expires 1w important.txt

Note: Requires a valid Pastebin API key stored in ~/Documents/pastebin-api-key.
      The API key file should contain only the key string. Format auto-detection
      works for 100+ file extensions and can be overridden with --format. All
      pastes return a direct URL to the created paste. Tab completion is
      available for all options, privacy levels, expiration times, format names,
      and filenames.
EOF
                return 0
                ;;
            h)
                cat <<EOF
h - Enhanced History Search

Search and manage bash command history with enhanced features.

Usage: h [search-term]
       h --edit|-e

Description:
  - Search bash history for commands matching a pattern
  - Case-insensitive search by default
  - Edit history file directly
  - Display full history when no arguments provided

Commands:
  (no args)        Display full command history
  <search-term>    Search history for commands containing search term (case-insensitive)
  --edit, -e       Open ~/.bash_history in nvim for editing

Behavior:
  - Without arguments: displays entire history
  - With search term: filters history using grep -i
  - With --edit: opens history file in nvim editor
  - Case-insensitive matching for search
  - Returns 0 on success

Dependencies:
  - grep (for history search)
  - nvim (for editing history, when using --edit)

Examples:
  h                    # Show full history
  h git                # Search for commands containing "git"
  h cd                 # Search for commands containing "cd"
  h --edit             # Edit history file in nvim
  h -e                 # Same as --edit

Note: The search is case-insensitive and matches any command containing the
      search term. Use --edit to manually edit your history file, which is
      useful for removing sensitive information or cleaning up history.
EOF
                return 0
                ;;
            extract)
                cat <<EOF
extract - Extract Archives

Extract various archive formats based on file extension.

Usage: extract <archive-file>

Description:
  - Automatically detects archive type from file extension
  - Extracts archives to the current directory
  - Supports multiple archive formats
  - Uses appropriate extraction tool for each format
  - Works with files in the current directory

Supported Formats:
  - .tar.bz2  - tar archive compressed with bzip2
  - .tar.gz   - tar archive compressed with gzip
  - .bz2      - bzip2 compressed file
  - .rar      - RAR archive
  - .gz       - gzip compressed file
  - .tar      - tar archive (uncompressed)
  - .tbz2     - tar archive compressed with bzip2
  - .tgz      - tar archive compressed with gzip
  - .zip      - ZIP archive
  - .Z        - compress compressed file
  - .7z       - 7-Zip archive

Behavior:
  - File must exist and be a regular file
  - Automatically selects extraction method based on file extension
  - Extracts contents to the current directory
  - Returns error if file doesn't exist or is not a file
  - Returns error if archive format is not supported

Dependencies:
  - tar (for .tar, .tar.bz2, .tar.gz, .tbz2, .tgz files)
  - bunzip2 (for .bz2 files)
  - unrar (for .rar files)
  - gunzip (for .gz files)
  - unzip (for .zip files)
  - uncompress (for .Z files)
  - 7z (for .7z files)

Examples:
  extract archive.tar.gz      # Extract tar.gz archive
  extract file.zip            # Extract ZIP archive
  extract data.tar.bz2        # Extract tar.bz2 archive
  extract archive.7z          # Extract 7-Zip archive

Note: The function automatically detects the archive type from the file extension
      and uses the appropriate extraction tool. Unsupported formats will
      display an error message. Tab completion is available and filters to
      only show supported archive file types (.tar.bz2, .tar.gz, .bz2, .rar,
      .gz, .tar, .tbz2, .tgz, .zip, .Z, .7z). See also compress() for creating archives.
EOF
                return 0
                ;;
            mkcd)
                cat <<EOF
mkcd - Make Directory and Change Into It

Create a directory and immediately change into it, displaying contents.

Usage: mkcd <directory>

Description:
  - Creates directory (and parent directories if needed)
  - Automatically changes into the newly created directory
  - Displays directory contents after creation
  - Combines mkdir -p and cd into one command

Behavior:
  - Creates directory using mkdir -p (creates parent directories if needed)
  - Changes into the directory after creation
  - Displays current directory path with folder emoji
  - Lists directory contents using eza (if available) or ls
  - Returns error if directory creation or cd fails

Dependencies:
  - mkdir (for creating directories)
  - cd (builtin, for changing directory)
  - eza (optional, for enhanced listing with icons)
  - ls (fallback if eza not available)

Examples:
  mkcd newproject           # Create newproject/ and change into it
  mkcd ~/Documents/notes    # Create nested directories and change into notes/
  mkcd path/to/directory    # Create full path and change into directory/

Note: The function uses mkdir -p which creates parent directories as needed.
      After creation, it automatically changes into the directory and displays
      its contents. This is useful for quickly setting up new project directories.
EOF
                return 0
                ;;
            motd)
                cat <<EOF
motd - Message of the Day

Display, create, or manage your daily message.

Usage: motd [COMMAND]

Description:
  - Displays the message of the day from ~/motd.txt
  - Allows you to create or edit the message of the day
  - Can remove the message of the day file
  - Provides a simple way to show daily messages when starting shell sessions
  - Automatically uses a pager for long messages (over 20 lines)

Commands:
  (no args)      Show help message
  print          Display the current message of the day
                 - If file is 20 lines or less: displays full content
                 - If file is over 20 lines: shows preview (first 5 lines) then
                   opens full content in a pager (read-only)
  make           Create or edit the message of the day
                 - If stdin is piped, writes stdin to ~/motd.txt
                 - If no stdin is piped, opens ~/motd.txt in \$EDITOR
  shoo           Remove the message of the day file

Behavior:
  - Without arguments: shows help message
  - "motd print": 
     * Files ≤20 lines: displays full content with 1 second pause
     * Files >20 lines: shows preview (first 5 lines with "..."), then opens
       full content in a pager with header (date/time and separator line)
     * Pager selection (in order): nvim (plugins disabled), \$EDITOR, \$PAGER, less
     * Content is piped through pager (read-only, cannot be modified)
  - "motd make": when data is piped in, writes to ~/motd.txt (creates/overwrites)
                 otherwise opens ~/motd.txt in editor (creates if it doesn't exist)
  - "motd shoo": deletes ~/motd.txt file
  - Commands are case-insensitive

Dependencies:
  - cat, head, wc (for displaying message and line counting)
  - rm (for removing file)
  - Editor specified in \$EDITOR (default: nvim)
  - Pager: nvim, \$EDITOR, \$PAGER, or less (for long messages)

Files:
  - ~/motd.txt - The message of the day file

Examples:
  motd              # Show help message
  motd print        # Display current message (uses pager if >20 lines)
  motd make         # Edit/create message in editor
  echo "Hello" | motd make   # Create/overwrite message from stdin
  motd shoo         # Delete message file

Note: This works in conjunction with automotd.sh (if implemented), which can
      automatically generate daily fortunes. The motd.txt file can also be
      manually created or edited. The "print" command is typically called
      automatically when starting a new shell session. For long messages (>20
      lines), a preview is shown followed by the full content in a read-only
      pager. When nvim is used as the pager, plugins are disabled for faster
      startup. Tab completion is available for subcommands (print, make, shoo).
EOF
                return 0
                ;;
            n)
                cat <<EOF
n - Quick Neovim Launcher

Quickly open files or directories in Neovim.

Usage: n [file|directory...]

Description:
  - Opens files or directories in Neovim
  - Defaults to current directory if no arguments provided
  - Provides convenient shortcut for nvim
  - Supports multiple files/directories

Behavior:
  - Without arguments: opens current directory (nvim .)
  - With arguments: opens specified files/directories
  - Passes all arguments directly to nvim
  - Returns nvim's exit code

Dependencies:
  - nvim (Neovim editor)

Examples:
  n                    # Open current directory in nvim
  n file.txt           # Open file.txt in nvim
  n src/ main.cpp      # Open multiple files/directories
  n .                  # Explicitly open current directory

Note: This is a convenience wrapper around nvim. All nvim features and
      command-line options work the same way. The function is useful for
      quick file editing without typing the full nvim command.
EOF
                return 0
                ;;
            openthis)
                cat <<EOF
openthis - Smart File and URL Opener

Open files, URLs, and executables using the appropriate application.

Usage: openthis <file|URL|executable> [arguments...]

Description:
  - Opens files and URLs using xdg-open
  - Executes executables in a new kitty terminal window
  - Opens script files in neovim for editing
  - Automatically detects file type and handles appropriately
  - Runs operations in background (non-blocking)
  - Provides convenient wrapper for opening various file types

Behavior:
  - Without arguments: returns immediately (no-op)
  - Executable files: runs in a new detached kitty window
  - Script files: opens in neovim for editing (in new kitty window)
  - Regular files: opens with default application via xdg-open
  - URLs: opens in default browser via xdg-open
  - All operations run in background (disowned)
  - Returns 0 on success

File Type Detection:
  - Script files (.sh, .bash, .zsh, .fish, .py, .pl, .rb, .js, .ts): open in neovim
    (takes priority - if a file is both executable and a script, it opens for editing)
  - Executable files (with execute permission): run in kitty terminal
  - All other files: opened with default application
  - URLs: opened with default browser

Dependencies:
  - xdg-open (for opening files and URLs)
  - kitty (for running executables and opening neovim)
  - nvim (for editing script files)

Examples:
  openthis document.pdf        # Open PDF with default viewer
  openthis https://example.com # Open URL in default browser
  openthis script.sh           # Open script in neovim for editing
  openthis ./executable        # Run executable in new kitty window
  openthis image.png           # Open image with default viewer

Note: The function automatically detects file type and handles it appropriately.
      Script files are checked first and opened in neovim for editing (in a new
      kitty window), even if they have execute permission. Executables that are
      not script files are run in a new detached kitty terminal window. All other
      files and URLs are opened with their default applications via xdg-open.
      All operations are non-blocking and run in the background. Tab completion
      is available for file paths, which naturally includes files with common
      extensions. This is particularly useful for quickly opening files, editing
      scripts, or running executables without blocking your terminal session.
EOF
                return 0
                ;;
            command-not-found|cmd-not-found|command_not_found_handle)
                cat <<EOF
command-not-found - Automatic Command Not Found Handler

Automatically searches for missing commands in package managers and offers to install them.

Usage: Automatically called by bash when a command is not found

Description:
  - Bash automatically calls this function when a command cannot be found
  - Searches for packages containing the missing command in yay (AUR + official repos)
  - Searches for applications in flatpak
  - Provides interactive installation prompts
  - Prioritizes official packages over AUR packages
  - Limits results to prevent overwhelming output

How It Works:
  - When you type a command that doesn't exist, bash automatically calls command_not_found_handle()
  - The function searches yay and flatpak for packages that might contain the command
  - Displays numbered list of found packages with source indicators
  - Prompts you to select a package for installation
  - Installs the selected package automatically

Features:
  - Smart package extraction: Handles yay's OSC 8 hyperlink escape sequences
  - Multiple extraction methods: Uses grep -P, perl, or basic regex for compatibility
  - Package prioritization: Official packages shown before AUR packages
  - Result limiting: Maximum 10 results per source (yay/flatpak)
  - Interactive installation: Prompts for confirmation before installing
  - Non-interactive safety: Only runs in interactive shells (has TTY)
  - Background searches: runs searches silently (no shell job notifications)
  - Cancel anytime: press any key during search to cancel immediately; on cancel it prints
    the standard "bash: <cmd>: command not found" and returns 127

Search Behavior:
  - Yay search: Searches both exact matches and broader patterns
    - Official packages (e.g., "core/package") prioritized over AUR
    - AUR packages (e.g., "aur/package") shown after official packages
  - Flatpak search: Searches application IDs and names
    - Extracts valid app IDs (e.g., "org.example.App")
    - Limits to 10 results

Installation:
  - Yay packages: Uses "yay -S --noconfirm" (requires sudo)
  - Flatpak packages: Uses "flatpak install --assumeyes --noninteractive"
    - Tries direct installation first
    - Falls back to flathub remote if needed

Dependencies:
  - yay (optional, for AUR and official repo search)
  - flatpak (optional, for flatpak application search)
  - grep, perl (for package name extraction)
  - sudo (for yay installation)

Examples:
  $ nonexistent-command
  # Automatically searches and shows:
  # 🔍 Searching yay (AUR + official)...
  #    Found 3 package(s) in yay:
  #     1) core/package-name
  #     2) aur/package-name
  #     3) extra/another-package
  # 
  # 🔍 Searching flatpak...
  #    Found 1 package(s) in flatpak:
  #     1) org.example.App
  # 
  # Would you like to install one of these packages? [y/N]:
  # [User selects package and it gets installed]
  # Note: You can press any key while it's searching to cancel. On cancel, it shows
  #       the standard "bash: <cmd>: command not found" message.

Behavior:
  - Only runs in interactive shells (checks for TTY)
  - Non-interactive shells get standard "command not found" error
  - 10-second timeout for initial installation prompt
  - If you decline installation or quit selection, it prints "Installation cancelled."
    and then the standard "bash: <cmd>: command not found"
  - Returns exit code 127 (command not found) if:
    - No packages found
    - User declines installation
    - Installation fails
    - Invalid choice entered

Note: This function is automatically called by bash when a command is not found.
      You don't call it directly - it runs automatically. The function name
      "command_not_found_handle" is special and recognized by bash. Once
      command-not-found.sh is sourced (via plugin loading), this handler becomes
      active. The function searches package managers intelligently, handling
      terminal escape sequences and prioritizing official packages over AUR.
EOF
                return 0
                ;;
            bashrc)
                cat <<EOF
bashrc - Edit .bashrc File or DOGRC Directory

Quick access to edit your .bashrc file or open the DOGRC directory in Neovim.

Usage: bashrc [--root|-r|--edit|-e [dogrc|preamble|config]]

Description:
  - Opens ~/.bashrc in nvim for editing (default behavior)
  - Can open the DOGRC directory in nvim with --root flag
  - Can open ~/DOGRC/.bashrc with --edit dogrc or -e dogrc
  - Can open ~/DOGRC/config/preamble.sh with --edit preamble or -e preamble
  - Can open ~/DOGRC/config/DOGRC.json with --edit config or -e config
  - Provides convenient shortcuts for editing bash configuration
  - Simple one-command access to your shell configuration

Options:
  --help, -h                    Show this help message
  --root, -r                    Open the DOGRC directory in nvim instead of ~/.bashrc
  --edit, -e                    Explicitly open ~/.bashrc in nvim (same as no argument)
  --edit dogrc, -e dogrc        Open ~/DOGRC/.bashrc in nvim
  --edit preamble, -e preamble  Open ~/DOGRC/config/preamble.sh in nvim
  --edit config, -e config      Open ~/DOGRC/config/DOGRC.json in nvim

Behavior:
  - Without arguments: opens ~/.bashrc in nvim editor
  - With --edit or -e: opens ~/.bashrc in nvim editor (explicit)
  - With --edit dogrc or -e dogrc: opens ~/DOGRC/.bashrc in nvim editor
  - With --edit preamble or -e preamble: opens ~/DOGRC/config/preamble.sh in nvim editor
  - With --edit config or -e config: opens ~/DOGRC/config/DOGRC.json in nvim editor
  - With --root or -r: opens the DOGRC directory in nvim
  - Returns nvim's exit code
  - Returns error if nvim is not available
  - Returns error if unknown option is provided

Dependencies:
  - nvim (Neovim editor)

Examples:
  bashrc              # Open ~/.bashrc in nvim
  bashrc --help       # Show help message
  bashrc -e dogrc     # Open ~/DOGRC/.bashrc in nvim
  bashrc -e preamble  # Open ~/DOGRC/config/preamble.sh in nvim
  bashrc -e config    # Open ~/DOGRC/config/DOGRC.json in nvim
  bashrc -r           # Open DOGRC directory in nvim

Note: This is a convenience function for quickly editing your .bashrc file or
      accessing the DOGRC directory. After making changes to .bashrc, you'll
      need to source the file or start a new shell session for changes to
      take effect. The --root flag is useful for editing DOGRC configuration
      files and plugins. Use --edit dogrc to edit the DOGRC project's .bashrc
      file directly. Use --edit preamble to edit the DOGRC preamble configuration.
      Use --edit config to edit the DOGRC JSON configuration file.
EOF
                return 0
                ;;
            notifywhendone)
                cat <<EOF
notifywhendone - Command Completion Notifications

Run a command and receive a desktop notification when it completes.

Usage: notifywhendone <command> [arguments...]

Description:
  - Executes a command and monitors its completion
  - Sends desktop notification when command finishes
  - Shows success or error status in notification
  - Displays elapsed time in notification
  - Useful for long-running commands

Behavior:
  - Records start time before executing command
  - Executes command with all provided arguments
  - Calculates elapsed time after completion
  - Formats elapsed time (seconds, minutes, or hours)
  - Sends notification with command, status, and elapsed time
  - Returns the command's exit code
  - Echoes notification message to stderr

Time Formatting:
  - Less than 60 seconds: "Xs" (e.g., "45s")
  - Less than 3600 seconds: "Xm Ys" (e.g., "5m 30s")
  - 3600+ seconds: "Xh Ym Zs" (e.g., "1h 15m 30s")

Notification Types:
  - Success: "Done" notification with success message
  - Error: "Error" notification with error code and message

Dependencies:
  - notify-send (for desktop notifications)
  - date (for timestamp tracking)

Examples:
  notifywhendone make              # Build project and notify when done
  notifywhendone rsync -av src/ dest/  # Sync files and notify
  notifywhendone long-script.sh    # Run script and notify on completion

Note: The function properly quotes command arguments in the notification message
      for readability. Notifications appear in your desktop environment's
      notification system. The elapsed time helps track how long commands take
      to complete. Useful for background tasks or long-running operations.
EOF
                return 0
                ;;
            pwd)
                cat <<EOF
pwd - Print Working Directory with Clipboard Support

Display current directory or copy it to clipboard.

Usage: pwd [c|C]

Description:
  - Enhanced pwd command with clipboard functionality
  - Displays current working directory (standard pwd behavior)
  - Can copy directory path to clipboard with 'c' or 'C' argument
  - Works like standard pwd when no arguments provided

Options:
  c, C    Copy current directory path to clipboard

Behavior:
  - Without arguments: works like standard pwd
  - With 'c' or 'C': copies path to clipboard and shows confirmation
  - Supports all standard pwd options
  - Returns 0 on success

Dependencies:
  - pwd (builtin)
  - wl-copy (for clipboard operations, when using c/C)

Examples:
  pwd                    # Display current directory
  pwd c                  # Copy current directory to clipboard
  pwd C                  # Same as above (case-insensitive)
  pwd -P                 # Display physical path (standard pwd option)

Note: The function overrides the builtin pwd command. When using the clipboard
      feature, the path is copied using wl-copy (Wayland clipboard). The
      confirmation message helps verify the operation completed successfully.
EOF
                return 0
                ;;
            prepfile)
                cat <<EOF
prepfile - Prepare New File with Language Templates

Create a new file with appropriate template based on language type.

Usage: prepfile [--type] [filename] [--override]
       prepfile [--override] [--type] [filename]
       prepfile [filename] [--type] [--override]

Description:
  - Creates a new file with language-specific template
  - Supports multiple programming languages and file types
  - Automatically adds appropriate file extension
  - Makes script files executable automatically
  - Optionally opens the file in your default editor
  - Prevents overwriting existing files (unless --override is used)
  - Defaults to bash script if no type specified

Options:
  --override, --OVERRIDE, -or, -OR
                      Overwrite existing files without prompting
                      Shows a warning message when enabled

Supported Types:
  --bash, --sh          Bash shell script (default)
  --python, --py        Python script
  --rust, --rs          Rust source file
  --go                  Go source file
  --javascript, --js    JavaScript file
  --typescript, --ts    TypeScript file
  --c                   C source file
  --cpp, --c++          C++ source file
  --java                Java source file
  --ruby, --rb          Ruby script
  --perl, --pl          Perl script
  --php                 PHP script
  --lua                 Lua script
  --zsh                 Zsh shell script
  --fish                Fish shell script

Behavior:
  - Without arguments: creates "main.sh" (bash template)
  - Type flag can appear before or after filename
  - Automatically adds appropriate extension if not present
  - Checks if file already exists before creating (prevents accidental overwrite)
  - Use --override flag to overwrite existing files
  - When overriding, displays "Warning: Override enabled!" message
  - Makes script files executable (bash, python, ruby, etc.)
  - Prompts to open in editor (y/n)
  - Uses \$EDITOR environment variable (defaults to nvim)

File Naming:
  - "prepfile" → creates "main.sh"
  - "prepfile --python app" → creates "app.py"
  - "prepfile script --go" → creates "script.go"
  - "prepfile --rust main.rs" → creates "main.rs" (extension preserved)

Templates:
  Each language type includes an appropriate empty template:
  - Scripts: include shebang line
  - Compiled languages: include main function/entry point
  - TypeScript: empty file (no shebang needed)

Dependencies:
  - chmod (for making files executable)
  - Editor specified in \$EDITOR (default: nvim, for optional editing)

Examples:
  prepfile                          # Create main.sh (bash)
  prepfile --python app             # Create app.py
  prepfile script --go              # Create script.go
  prepfile --rust main              # Create main.rs
  prepfile --cpp program            # Create program.cpp
  prepfile --java Main              # Create Main.java
  prepfile test --ruby              # Create test.rb
  prepfile --override --python app  # Overwrite app.py (if exists)
  prepfile -or script --go          # Overwrite script.go (if exists)
  prepfile --bash test.sh --override # Overwrite test.sh (if exists)

Note: By default, the function prevents accidental overwriting of existing files
      and will display an error message with instructions to use --override.
      Use --override, --OVERRIDE, -or, or -OR to overwrite existing files.
      Type flags can appear anywhere in the arguments. Script files (bash, python,
      ruby, etc.) are automatically made executable. Compiled language files
      (C, C++, Rust, Go, Java) are not made executable as they need to be compiled
      first. The override flag is case-insensitive and can appear anywhere in the
      argument list.
EOF
                return 0
                ;;
            silent)
                cat <<EOF
silent - Run Command Silently

Execute a command suppressing all output (stdout and stderr).

Usage: silent <command> [arguments...]

Description:
  - Runs a command with all output redirected to /dev/null
  - Suppresses both stdout and stderr
  - Returns the command's exit code
  - Useful for testing command success without output

Behavior:
  - Redirects stdout to /dev/null
  - Redirects stderr to /dev/null
  - Executes command with all provided arguments
  - Returns the command's exit code (0 for success, non-zero for failure)
  - No output is displayed

Dependencies:
  - None (uses shell builtins)

Examples:
  silent test -f file.txt        # Check if file exists silently
  silent mkdir newdir            # Create directory silently
  silent rm oldfile              # Remove file silently
  if silent command; then        # Use in conditionals
      echo "Command succeeded"
  fi

Note: The function is useful when you only care about whether a command
      succeeds or fails, not its output. It's commonly used in scripts
      for conditional logic based on command exit codes. The command's
      exit code is preserved, so it can be used in if statements.
EOF
                return 0
                ;;
            swap)
                cat <<EOF
swap - Swap Two Filenames

Safely exchange the names of two files.

Usage: swap <file1> <file2>

Description:
  - Exchanges the names of two files
  - Uses temporary file to ensure atomic operation
  - Warns if files have different extensions
  - Safe operation that prevents data loss

Behavior:
  - Validates both files exist before swapping
  - Uses temporary file (tmp.$$) for safe swapping
  - Warns if files have different extensions
  - Performs three mv operations: file1->tmp, file2->file1, tmp->file2
  - Returns error if either file doesn't exist
  - Returns error if swap operation fails

Safety Features:
  - Validates files exist before attempting swap
  - Uses process ID ($$) in temporary filename to avoid conflicts
  - Atomic operation (all or nothing)
  - Warning for different file extensions

Dependencies:
  - mv (for moving/renaming files)

Examples:
  swap file1.txt file2.txt       # Swap names of two files
  swap old.log new.log           # Exchange log file names
  swap backup.dat current.dat    # Swap data files

Warning Output:
  If files have different extensions, a warning is displayed:
  "Warning: Files have different extensions (.'ext1' vs .'ext2')"

Note: The swap operation is atomic - if any step fails, the operation
      is aborted. The temporary file uses the process ID ($$) to ensure
      uniqueness and avoid conflicts with other swap operations. The
      function warns about different extensions to help catch potential
      mistakes, but still proceeds with the swap. Tab completion is
      available for file paths. For the second argument, the first file
      is automatically excluded from completions to prevent swapping a
      file with itself.
EOF
                return 0
                ;;
            sort-downloads|sortdl)
                cat <<EOF
sort-downloads - Organize Downloads Directory

Organize files in Downloads directory by file extension or date into subdirectories.

Usage: sort-downloads [OPTIONS] [directory]
       sortdl [OPTIONS] [directory]

Description:
  - Organizes files in Downloads directory (or specified directory) into subdirectories
  - Can organize by file extension or by date (year-month)
  - Creates subdirectories automatically as needed
  - Handles duplicate filenames by appending numbers
  - Supports dry-run mode to preview changes before organizing
  - Preserves original filenames

Organization Modes:
  By Extension (default):
    - Groups files by their file extension (e.g., .pdf, .jpg, .txt)
    - Files without extensions go into "no-extension" folder
    - Extension names are converted to lowercase for consistency

  By Date:
    - Groups files by modification date in year-month format (e.g., 2024-01, 2024-02)
    - Useful for organizing by when files were downloaded
    - Files with unknown dates go into "unknown" folder

Options:
  --by-date, -d           Organize files by modification date (year-month)
                          Creates directories like: 2024-01, 2024-02, etc.
  --by-extension, -e      Organize files by file extension (default)
                          Creates directories based on file extensions
  --dry-run, -n           Preview changes without actually moving files
                          Shows what would be organized without doing it
                          Useful for verifying before organizing
  --directory, --dir <path>
                          Specify directory to organize (default: ~/Downloads)
                          If not specified, uses ~/Downloads
  --help, -h              Show this help message

Behavior:
  - Only processes files in the top-level of the specified directory
  - Does not process files in subdirectories (single level only)
  - Creates subdirectories as needed
  - If target file already exists, appends _1, _2, etc. to filename
  - Skips files that cannot be moved (shows error message)
  - Shows summary of how many files were organized

Dependencies:
  - find (for finding files)
  - mkdir (for creating directories)
  - mv (for moving files)
  - basename (for extracting filenames)
  - date or stat (for getting file modification dates)
  - file (for file type detection, optional)

Examples:
  # Organize ~/Downloads by file extension
  sort-downloads

  # Preview what would be organized (dry-run)
  sort-downloads --dry-run

  # Organize by date instead of extension
  sort-downloads --by-date

  # Organize a different directory
  sort-downloads --directory ~/Desktop/downloads

  # Use short alias
  sortdl --dry-run

  # Organize by date with preview
  sortdl -d -n

  # Organize custom directory by extension
  sort-downloads --dir /path/to/files --by-extension

Note: The function only processes files in the top-level directory, not subdirectories.
      Files are moved (not copied) to their organized locations. Use --dry-run to
      preview changes before organizing. Duplicate filenames are handled automatically
      by appending numbers. The function creates directories as needed and skips
      files that cannot be moved, showing errors for those cases. Tab completion
      is available for options and directory paths. The sortdl function is an
      alias that passes all arguments to sort-downloads.
EOF
                return 0
                ;;
            sanitize-filenames|sanitize_filenames|fixnames)
                cat <<EOF
sanitize-filenames - Clean Filenames

Clean filenames by removing special characters and normalizing spaces.

Usage: sanitize-filenames [OPTIONS] [file|directory]
       sanitize-filenames [file|directory] [OPTIONS]
       sanitize_filenames [OPTIONS] [file|directory]
       fixnames [OPTIONS] [file|directory]

Description:
  - Removes or replaces special characters in filenames
  - Normalizes multiple spaces (or replaces with underscores)
  - Makes filenames safe for cross-platform use
  - Works with single files or directories (recursive)
  - Preserves hidden files (leading dot)
  - Supports dry-run mode to preview changes

Options:
  --dry-run, -d           Preview changes without renaming files
                          Shows what would be renamed without actually doing it
                          Useful for verifying changes before applying
  --replace-spaces, -r    Replace spaces with underscores
                          Without this flag, multiple spaces are normalized to single space
                          Useful for preparing files for systems that don't handle spaces well
  --help, -h               Show this help message
  --                       Separator for file path (useful when path starts with -)

Modes:
  Single File Mode:
    - Sanitizes a single file
    - Defaults to current directory if no path specified
    - Shows preview or performs rename based on flags

  Directory Mode:
    - Processes all files and directories recursively
    - Processes files first, then directories (deepest to shallowest)
    - Handles nested directories correctly by processing from deepest level first
    - Skips items whose names don't change after sanitization

Sanitization Rules:
  - Removes or replaces special characters (keeps alphanumeric, dots, hyphens, underscores, spaces)
  - Problematic characters are replaced with underscores
  - Leading/trailing spaces, dots, and hyphens are removed
  - Multiple consecutive underscores/hyphens are normalized to single underscore
  - Hidden files (starting with dot) preserve their leading dot
  - Empty or invalid names are replaced with "sanitized_<timestamp>_<pid>"
  - Prevents renaming to "." or ".." (reserved directory names)

Space Handling:
  Without --replace-spaces:
    - Multiple spaces are normalized to single space
    - Leading/trailing spaces are removed
    - Preserves single spaces in filenames

  With --replace-spaces:
    - All spaces are replaced with underscores
    - Useful for systems that don't handle spaces well
    - Makes filenames URL-safe

Behavior:
  - Validates path exists before processing
  - Skips files whose names don't change after sanitization
  - Skips renaming if target name already exists (prevents overwrites)
  - Shows colored output: green (✓) for successful renames, yellow (⚠) for skips, red (✗) for errors
  - Displays summary statistics after processing
  - Returns error if any rename operations fail

Safety Features:
  - Dry-run mode to preview changes before applying
  - Skips items if target name already exists (prevents overwrites)
  - Processes directories from deepest to shallowest (handles nested dirs correctly)
  - Preserves hidden files (leading dot)
  - Validates path exists before processing

Dependencies:
  - find (for recursive directory processing)
  - mv (for renaming files)
  - sed (for text processing in sanitization)
  - awk, sort (optional, for sorting directories by depth)

Output Format:
  Default Mode:
    🧹 SANITIZING FILENAMES
    ======================
    Mode: Single file / Directory (recursive)
    [Options enabled]
    
    ✓ Renamed: 'old_name' -> 'new_name'
    ⚠ Skip: 'old_name' -> 'new_name' (target exists)
    ✗ Failed to rename: 'old_name'
    
    Summary:
      Files renamed: N
      Files unchanged: M
      Errors: K (if any)

  Dry Run Mode:
    🧹 SANITIZING FILENAMES
    ======================
    Mode: DRY RUN (preview only)
    
    [DRY RUN] Would rename: 'old_name' -> 'new_name'
    
    Summary:
      Files that would be renamed: N
      Files unchanged: M

Examples:
  sanitize-filenames                        # Sanitize current directory (recursive)
  sanitize-filenames file.txt               # Sanitize single file
  sanitize-filenames --dry-run .            # Preview changes in current directory
  sanitize-filenames -d ~/Downloads         # Preview changes in Downloads
  sanitize-filenames --replace-spaces .     # Replace spaces with underscores recursively
  sanitize-filenames -r file with spaces.txt # Replace spaces in single file
  sanitize-filenames -d -r ~/Music          # Preview replacing spaces in Music directory
  fixnames .                                # Same as sanitize-filenames (alias)
  sanitize_filenames --dry-run              # Same as sanitize-filenames (alias)

Aliases:
  sanitize_filenames    Alias for sanitize-filenames (with underscore)
  fixnames              Quick alias for sanitize-filenames

Note: The function is designed to make filenames safe for cross-platform use
      by removing special characters that may cause issues on different
      operating systems. Use --dry-run to preview changes before applying
      them. The function preserves hidden files (starting with dot) and
      processes directories from deepest to shallowest to handle nested
      directories correctly. If a target name already exists, the rename
      is skipped to prevent overwriting. The --replace-spaces flag is
      useful for preparing files for systems that don't handle spaces
      well in filenames.
EOF
                return 0
                ;;
            timer)
                cat <<EOF
timer - Simple Timer Utility

A lightweight timer utility that tracks elapsed time for named timers.

Usage: timer [--use-dir|--USE-DIR|-ud|-UD <directory>] [<timer-name>|CLEAR|LIST]

Description:
  - Creates and manages named timers
  - Tracks elapsed time since timer was set
  - Supports multiple concurrent timers
  - Provides simple start/stop/reset functionality
  - Stores timer data in files (default: /tmp/timer-*.txt)

Options:
  --use-dir, --USE-DIR, -ud, -UD <directory>
                      Specify custom directory for timer files
                      Default: /tmp
                      Timer files will be stored as: <directory>/timer-<name>.txt
                      Directory will be created if it doesn't exist

Commands:
  <timer-name>        Start or check elapsed time for a named timer
                      If timer doesn't exist, creates it and starts timing
                      If timer exists, shows elapsed time and offers to reset
                      Timer names are sanitized (spaces -> underscores, special chars removed)
                      Default name: "Timer"

  CLEAR              Clear all timers (requires confirmation)
                      Prompts for confirmation before deleting all timer files
                      Returns 0 on success, 4 on error

  LIST               List all active timers with elapsed times
                      Shows timer name and elapsed time in HH:MM:SS format
                      Returns 0 on success

Behavior:
  - Timer files store Unix timestamp (seconds since epoch)
  - Elapsed time calculated as: current_time - stored_timestamp
  - Timer names are case-insensitive for commands (CLEAR, LIST)
  - Timer names are sanitized: spaces become underscores, special chars removed
  - Interactive prompts for reset/clear (10 second timeout in non-interactive mode)
  - Returns appropriate exit codes for error handling

Exit Codes:
  0  - Success
  1  - Error creating timer file
  2  - Error reading timer file
  3  - Error deleting timer file (reset failed)
  4  - Error clearing timers

Files:
  - /tmp/timer-<name>.txt - Default location for timer files
  - <directory>/timer-<name>.txt - Custom location when --use-dir is used

Examples:
  timer                    # Start/check default "Timer"
  timer MyTask            # Start/check timer named "MyTask"
  timer LIST              # List all active timers
  timer CLEAR             # Clear all timers (with confirmation)
  timer --use-dir ~/timers MyTask    # Use custom directory for timer files
  timer -ud /tmp/mytimers MyTask     # Use custom directory (short form)

Note: Timer files persist across shell sessions. Use CLEAR to remove them.
      Timer names are automatically sanitized for filesystem safety. Spaces
      are converted to underscores, and special characters are removed. If
      a timer already exists, calling it again will show the elapsed time
      and prompt to reset. Tab completion is available for commands
      (CLEAR, LIST) and timer names.
EOF
                return 0
                ;;
            runtests)
                cat <<EOF
runtests - Run DOGRC Unit Test Suite

Launch the DOGRC unit test suite in a tmux session with real-time progress tracking.

Usage: runtests [--ci] [--quiet|-q] [--fail-fast|-f] [--parallel|-p]
                [--stage|-s <test-name>] [--egg|-EGG]
       runtests --help|-h

Description:
  - Runs all DOGRC unit tests in a tmux session with split panes (default)
  - CI mode (--ci): runs tests without tmux, suitable for CI/CD environments
  - Displays real-time overview of test progress and results
  - Shows live output from currently running tests
  - Tracks elapsed time for individual tests and overall suite
  - Automatically closes after tests complete (with 5 second delay)
  - Provides comprehensive test results summary
  - Flags can be combined (e.g., --parallel --stage backup)

Modes:
  Interactive Mode (default):
    - Uses tmux with split panes for visual display
    - Real-time progress tracking with overview pane
    - Press 'q' to quit at any time
    - Supports --parallel for simultaneous test execution
    - Supports --stage for targeted testing (run specific test and neighbors)
    - Can combine --parallel and --stage for faster targeted testing
  
  Parallel Mode (--parallel):
    - Runs all tests simultaneously for faster execution
    - Resource monitor (htop/top) displays in right tmux pane
    - All test output redirected to /dev/null (cleaner display)
    - Significantly faster test suite execution
    - Can be combined with --stage to run selected tests in parallel
  
  Stage Mode (--stage):
    - Runs specific test and its adjacent tests (before and after)
    - Useful for debugging specific test failures
    - Faster than running entire test suite
    - Test name can be provided as full name (test-*.sh) or base name (without test- prefix)
    - Example: --stage dupefind runs test-dupefind.sh, test before it, and test after it
    - Can be combined with --parallel for faster execution of selected tests
  
  EGG Mode (--egg, -EGG):
    - Easter egg mode: displays animated bonsai tree (cbonsai) in right pane
    - Requires cbonsai to be installed (shows message if unavailable)
    - Provides visual entertainment while tests run
    - Bonsai tree remains until user quits
    - Can be combined with other flags for fun testing experience
  
  CI Mode (--ci):
    - Non-interactive mode suitable for CI/CD
    - No tmux dependency required
    - Supports --quiet and --fail-fast flags
    - Supports --stage for targeted testing
    - Returns proper exit codes (0=pass, 1=fail, 2=no tests)
    - Minimal output option available
    - Flags can be combined (e.g., --ci --quiet --fail-fast --stage backup)

Display:
  Left Pane (Overview):
    - Real-time status of all unit tests
    - Test name, status (PASSED/FAILED/RUNNING/PENDING), score, percentage
    - Individual test elapsed times
    - Overall suite statistics (total passed, percentage, elapsed time)
    - Color-coded status indicators

  Right Pane (Test Output):
    - Live output from the currently running test (interactive mode, sequential)
    - Resource monitor (htop/top) during parallel execution
    - Animated bonsai tree (cbonsai) in EGG mode (--egg)
    - Final summary after all tests complete (non-parallel, non-EGG mode)
    - Shows total score, percentage, and elapsed time

Options:
  --ci              Run in CI mode (non-interactive, no tmux)
  --quiet, -q       Minimal output (CI mode only, shows only summary)
  --fail-fast, -f   Stop on first test failure (CI mode only)
  --parallel, -p    Run tests in parallel mode (simultaneous execution)
                    Can be combined with --stage for parallel targeted testing
  --stage, -s       Run specific test and its adjacent tests
                    Requires test name argument (e.g., --stage dupefind)
                    Runs the target test plus the test before and after it
                    Can be combined with --parallel for faster execution
  --egg, -EGG       Easter egg mode: display animated bonsai tree (cbonsai) in right pane
                    Requires cbonsai to be installed
                    Can be combined with other flags for visual entertainment
  --help, -h        Show this help message

Flag Combinations:
  - --parallel --stage <test>  Run selected tests (target + neighbors) in parallel
  - --ci --quiet --fail-fast   CI mode with minimal output, stop on first failure
  - --ci --stage <test>        CI mode running only selected tests
  - --ci --quiet --stage <test> CI mode with minimal output for selected tests
  - --egg, -EGG                Display bonsai tree in right pane (easter egg mode)

Controls (Interactive Mode):
  - Press 'q' to quit the test session at any time
  - Session automatically closes 5 seconds after all tests complete
  - Overview is displayed in terminal after session closes

Behavior:
  Interactive Mode (default):
    - Creates a new tmux session named "dogrc-tests"
    - Splits window into two panes (40% left, 60% right)
    - Runs all test files from unit-tests/ directory
    - Updates overview in real-time as tests progress
    - Captures and displays final overview when session closes
    - Cleans up temporary files and tmux session on exit
  
  Parallel Mode (--parallel):
    - Runs all tests simultaneously in background
    - Resource monitor (htop/top) displays in right pane during execution
    - All test output redirected to /dev/null for cleaner display
    - Significantly faster test execution for large test suites
    - Protected resource monitor from interruption using exec and trap
    - Resource monitor remains until user quits
    - When combined with --stage, runs only selected tests in parallel
  
  EGG Mode (--egg, -EGG):
    - Displays animated bonsai tree (cbonsai) in right pane
    - Requires cbonsai to be installed (shows message if unavailable)
    - Provides visual entertainment while tests run
    - Bonsai tree remains until user quits
    - Can be combined with other flags for fun testing experience
  
  Stage Mode (--stage <test-name>):
    - Finds target test in sorted test list
    - Runs target test plus adjacent tests (before and after)
    - Useful for debugging specific test failures
    - Test name can be provided as full name (test-*.sh) or base name (without test- prefix)
    - Example: --stage dupefind matches test-dupefind.sh
    - When combined with --parallel, runs selected tests simultaneously
  
  CI Mode (--ci):
    - Delegates to _test-all-fb.sh test runner
    - Runs tests sequentially without tmux
    - Supports --quiet for minimal output
    - Supports --fail-fast to stop on first failure
    - Supports --stage for targeted testing
    - Returns exit code 0 if all tests pass, 1 if any fail, 2 if no tests found
    - All flags can be combined for flexible CI/CD usage

Test Results:
  - Each test writes results to a .results file
  - Results include: status, score, total tests, percentage
  - Overview aggregates results from all tests
  - Final summary shows overall pass rate and statistics

Dependencies:
  - tmux (required for interactive mode only, not needed for --ci)
  - bash (for running test scripts)
  - cbonsai (optional, required for --egg mode)
  - htop or top (optional, used in --parallel mode for resource monitoring)
  - All test dependencies (varies by test)

Files:
  - unit-tests/_TEST-ALL.sh - Main test runner script (interactive mode)
  - unit-tests/_test-all-fb.sh - CI-friendly test runner (used with --ci)
  - unit-tests/test-*.sh - Individual test scripts
  - unit-tests/*.results - Test result files (created during run)
  - /tmp/dogrc_*_$$.txt - Temporary files (cleaned up on exit)

Examples:
  runtests                            # Run all unit tests in tmux session (interactive)
  runtests --parallel                 # Run all tests in parallel mode (faster)
  runtests --stage dupefind           # Run test-dupefind.sh and adjacent tests
  runtests -s backup                  # Run test-backup.sh and adjacent tests (short form)
  runtests --parallel --stage backup  # Run selected tests in parallel mode
  runtests --egg                      # Run tests with animated bonsai tree (easter egg)
  runtests -EGG                       # Run tests with bonsai tree (short form)
  runtests --ci                       # Run tests in CI mode (non-interactive)
  runtests --ci --quiet               # Run tests in CI mode with minimal output
  runtests --ci --fail-fast           # Run tests in CI mode, stop on first failure
  runtests --ci --stage timer         # Run specific test in CI mode
  runtests --ci -q -f                 # Combine CI flags (quiet + fail-fast)
  runtests --ci --quiet --stage backup # CI mode with minimal output for selected tests
  runtests --help                     # Show this help message

CI/CD Usage:
  # GitHub Actions / GitLab CI / Jenkins
  bash unit-tests/_TEST-ALL.sh --ci --quiet
  
  # With fail-fast for faster feedback
  bash unit-tests/_TEST-ALL.sh --ci --quiet --fail-fast
  
  # Run specific test in CI mode
  bash unit-tests/_TEST-ALL.sh --ci --quiet --stage backup

Note: Interactive mode requires tmux to be installed. If tmux is not available
      and --ci is not specified, the function will display an error message.
      Use --ci flag for CI/CD environments or when tmux is not available.
      CI mode delegates to _test-all-fb.sh which provides proper exit codes
      for automated testing. The session automatically closes 5 seconds after
      all tests complete in interactive mode (non-parallel), giving you time to
      review the final results. You can press 'q' at any time to quit early in
      interactive mode. The overview pane updates every second with the latest
      test progress. Parallel mode runs tests simultaneously for faster execution
      and displays a resource monitor (htop/top) in the right pane. Stage mode
      is useful for debugging specific test failures by running only the target
      test and its neighbors. All temporary files are automatically cleaned up
      when the session ends.
EOF
                return 0
                ;;
            update)
                cat <<EOF
update - System Update Automation

Automatically update system packages using multiple package managers, with optional HyDE update checking.

Usage: update

Description:
  - Updates system packages using yay (AUR), flatpak, and topgrade
  - Runs all updates non-interactively
  - Optionally checks for HyDE updates if enabled in configuration
  - Provides composite exit code indicating which updates failed
  - Requires sudo privileges (passwordless sudo recommended)

Update Sources:
  - yay:      AUR packages and official Arch repositories
  - flatpak:  Flatpak applications
  - topgrade: System-wide updates (excluding pacdef, pacstall, flatpak)
  - HyDE:     HyDE scripts update (optional, if enabled)

HyDE Update Check:
  - Checks if 90+ days have passed since last HyDE update
  - Only runs if enable_hydecheck is true in ~/DOGRC/config/DOGRC.json
  - Prompts user to update HyDE if threshold is met
  - Optionally creates timeshift snapshot before updating (if enable_hydecheck_include_timeshift is true)
  - Updates timestamp file after successful HyDE update

Configuration:
  - enable_hydecheck: Enable/disable HyDE update checking (default: false)
  - enable_hydecheck_include_timeshift: Create timeshift snapshot before HyDE update (default: false)
  - Settings are read from ~/DOGRC/config/DOGRC.json
  - Timestamp stored in ~/DOGRC/config/hydecheck.timestamp

Behavior:
  - Checks for sudo availability and privileges
  - Prompts for sudo password if needed (sudo true)
  - Verifies passwordless sudo works (sudo -n true)
  - Runs each package manager update if available
  - Skips updates if package manager is not installed (with warning)
  - Checks HyDE update status if enabled in configuration
  - Prompts for HyDE update if 90+ days have passed
  - Optionally creates timeshift snapshot before HyDE update
  - Returns composite exit code indicating failures

Exit Codes:
  The function returns a composite code indicating which updates failed:
  - 0:    All updates succeeded
  - 1:    Only topgrade failed
  - 10:   Only flatpak failed
  - 11:   Both flatpak and topgrade failed
  - 100:  Only yay failed
  - 101:  yay and topgrade failed
  - 110:  yay and flatpak failed
  - 111:  All updates failed

  Formula: (yay_fail * 100) + (flatpak_fail * 10) + (topgrade_fail)

Dependencies:
  - sudo (required)
  - yay (optional, for AUR updates)
  - flatpak (optional, for Flatpak updates)
  - topgrade (optional, for system-wide updates)
  - jq (optional, for reading DOGRC.json configuration)
  - kitty (optional, for timeshift snapshot GUI)
  - timeshift (optional, for creating snapshots before HyDE update)
  - git (required for HyDE update process)

Files:
  - ~/DOGRC/config/DOGRC.json - Configuration file for feature flags
  - ~/DOGRC/config/hydecheck.timestamp - Timestamp of last HyDE update check

Examples:
  update                 # Update all available package sources

Note: The function requires sudo privileges. It's recommended to configure
      passwordless sudo for this function to work smoothly. Each package
      manager is optional - the function will skip unavailable managers
      with a warning. The composite exit code allows scripts to determine
      which specific updates failed. The topgrade command excludes pacdef,
      pacstall, and flatpak to avoid conflicts with the dedicated update
      commands. HyDE update checking is optional and controlled by the
      enable_hydecheck setting in DOGRC.json. If enabled, the function will
      prompt to update HyDE scripts if 90+ days have passed since the last
      update. The timeshift snapshot feature is also optional and controlled
      by enable_hydecheck_include_timeshift. If timeshift snapshot creation
      fails, the user can choose to continue without a snapshot.
EOF
                return 0
                ;;
            xx)
                cat <<EOF
xx - Open New Terminal Window and Exit Current Shell

Open a new kitty terminal window in the background and
exits the current shell.

Usage: xx

Description:
  - Launches a new kitty terminal window
  - Runs in background (non-blocking)
  - Disowns the process from current shell
  - Exits current shell after launching
  - Useful for quickly opening new terminal sessions

Behavior:
  - Uses nohup to run kitty in background
  - Redirects output to /dev/null
  - Disowns the process
  - Exits current shell (exit 0)
  - Non-interactive - no user input required

Dependencies:
  - nohup (for background execution)
  - kitty (terminal emulator)

Examples:
  xx                    # Open new kitty window and exit current shell

Note: This function is designed for kitty terminal emulator. After calling
      xx, the current shell session will exit. The new kitty window opens
      in the background. This is useful for quickly spawning new terminal
      sessions without manually opening a new window.
EOF
                return 0
                ;;
            drchelp|help|--help|--HELP|-h|-H)
                # Show default help message
                ;;
            *)
                echo "No manual entry found for: $1" >&2
                echo "Run 'drchelp' without arguments to see available functions." >&2
                return 1
                ;;
        esac
    fi
    
    # Default help
    cat <<EOF
Usage: drchelp [FUNCTION]

Show the manual for a specific DOGRC plugin function

Available functions:

Navigation:
  cd, cdd, zd        - Enhanced directory navigation with listing
  dots               - Manage and navigate .config directories
  navto              - Quick navigation to predefined destinations
  /, //, ///, etc.   - Quick navigation up directory levels (slashback)

File Operations:
  backup             - Create timestamped backups of files/directories
  checksum-verify    - File checksum verification and generation
  compress           - Create archives
  extract            - Extract archives
  find-empty-dirs    - Find empty directories recursively
  mkcd               - Make directory and change into it
  sanitize-filenames - Clean filenames (remove special chars, normalize spaces)
  swap               - Swap two filenames safely

Information:
  analyze-file       - File analysis tool with comprehensive information
  automotd           - Automatic message of the day generator
  cpuinfo            - Display CPU usage and top processes
  disk-usage         - Enhanced disk usage analyzer with tree view
  drcfortune         - Display fortune cookies with typewriter effect
  network-info       - Network information and diagnostics
  pokefetch          - System information with Pokemon logo
  system-stats       - Enhanced system statistics display
  weather            - Weather information display
  wttr               - Direct weather query via wttr.in
  drcversion         - Display DOGRC version
  drcupdate          - Check for DOGRC updates

Utilities:
  available          - List available bash functions
  bashrc             - Edit .bashrc file
  calc               - Command line calculator
  command-not-found  - Automatic command not found handler
  cpx                - Compile and execute C++ files
  dl-paper           - Download wallpaper clips from YouTube
  fastnote           - Quick note management
  genpassword        - Generate random passwords
  h                  - Enhanced history search
  motd               - Message of the day management
  n                  - Quick Neovim launcher
  openthis           - Smart file and URL opener
  notifywhendone     - Command completion notifications
  prepfile           - Prepare new file with language templates
  pwd                - Print working directory with clipboard support
  runtests           - Run DOGRC unit test suite
  shorturl           - URL shortening service (alias for url-shortener)
  silent             - Run command silently
  timer              - Named timer management
  update             - System update automation
  url-shortener      - URL shortening service
  xx                 - Open new terminal window

Examples:
  drchelp backup
  drchelp update
  drchelp cd
  drchelp genpassword
EOF
    return 0
}

# Bash completion function for drchelp
_drchelp_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # List of all available function names that can be viewed
    local functions=(
        "analyze-file"
        "automotd"
        "available"
        "backup"
        "bashrc"
        "calc"
        "cd"
        "cdd"
        "checksum-verify"
        "command-not-found"
        "compress"
        "cpuinfo"
        "disk-usage"
        "dupefind"
        "cpx"
        "dl-paper"
        "dots"
        "drcfortune"
        "drcupdate"
        "drcversion"
        "drchelp"
        "extract"
        "fastnote"
        "find-empty-dirs"
        "fixnames"
        "genpassword"
        "h"
        "mkcd"
        "motd"
        "n"
        "navto"
        "network-info"
        "notifywhendone"
        "openthis"
        "pokefetch"
        "prepfile"
        "pwd"
        "runtests"
        "sanitize-filenames"
        "shorturl"
        "silent"
        "slashback"
        "sort-downloads"
        "sortdl"
        "swap"
        "system-stats"
        "timer"
        "update"
        "url-shortener"
        "weather"
        "wttr"
        "xx"
        "zd"
        "/"
        "slashback"
    )
    
    # Complete with function names
    COMPREPLY=($(compgen -W "${functions[*]}" -- "$cur"))
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _drchelp_completion drchelp 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    drchelp "$@"
    exit $?
fi

