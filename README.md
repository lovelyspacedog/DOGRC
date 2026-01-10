# DOGRC

**DOGRC** is a modular, extensible bash configuration system that provides a comprehensive set of utilities, aliases, and plugins for enhancing your shell experience.

> ⚠️ **Status: Alpha** - This project is currently in alpha development (v0.2.2). Features may change, and there may be bugs. Use at your own discretion.

## Features

- 🎯 **Modular Architecture** - Organized plugin system with clear separation of concerns
- ⚙️ **Configurable** - JSON-based configuration for easy feature toggling
- 🔌 **Extensible** - Easy to add custom plugins and aliases
- 🛠️ **Rich Utilities** - File operations, navigation, information tools, and more
- 📦 **Self-Contained** - All configuration in one directory (`~/DOGRC`)
- 🔄 **Update-Friendly** - Update system that preserves user customizations
- 🧪 **Well-Tested** - Comprehensive unit test suite (35+ test files, 45+ passing tests)
- ⚡ **Parallel Testing** - Run tests in parallel for faster execution
- 📊 **Test Staging** - Targeted testing with `--stage` flag

## Installation

### Prerequisites

**Required:**
- `bash` (4.0+)
- `jq` - JSON processor (for configuration parsing)
- `kitty` - Terminal emulator (for certain utilities)

**Recommended:**
- `nvim` - Text editor (used in multiple plugins)
- `pokemon-colorscripts` - For pokefetch plugin
- `fastfetch` - System information tool
- `yay` - AUR helper (Arch Linux)
- `flatpak` - Application framework

**Optional:**
- `eza` - Enhanced `ls` replacement
- `zoxide` - Smart directory navigation
- `starship` - Prompt customization
- `fortune` - Fortune cookies
- And many more (see installation script for full list)

### Quick Install

1. Clone or download the DOGRC repository
2. Navigate to the DOGRC directory
3. Run the installation script:

```bash
bash install/_INSTALL.sh
```

The installer will:
- Check for required dependencies
- Backup your existing `~/.bashrc` and `~/.bash_profile`
- Copy DOGRC to `~/DOGRC`
- Generate user-configurable files
- Verify the installation
- Create a redirect in `~/.bashrc` to source DOGRC

4. Start a new shell session or run:

```bash
source ~/.bashrc
```

## Project Structure

```
DOGRC/
├── .bashrc                 # Main entry point
├── config/
│   ├── DOGRC.json         # Feature flags and configuration
│   └── preamble.sh        # User-configurable preamble
├── core/
│   ├── aliases.sh         # User-configurable aliases
│   └── dependency_check.sh # Dependency checking utilities
├── plugins/
│   ├── drchelp.sh         # Help system (centralized help for all commands)
│   ├── file-operations/   # File management plugins
│   │   ├── archive.sh     # Archive extraction and compression
│   │   ├── backup.sh      # Timestamped backups
│   │   ├── blank.sh       # Empty files with safety countdown
│   │   ├── checksum-verify.sh # File checksum verification/generation
│   │   ├── dupefind.sh    # Find duplicate files by content hash
│   │   ├── find-empty-dirs.sh # Find and optionally delete empty directories
│   │   ├── mkcd.sh        # Create directory and cd into it
│   │   ├── sanitize-filenames.sh # Clean filenames (remove special chars)
│   │   ├── sort-downloads.sh # Organize Downloads directory
│   │   └── swap.sh        # Swap file names
│   ├── information/       # System information plugins
│   │   ├── analyze-file.sh
│   │   ├── cpuinfo.sh
│   │   ├── disk-usage.sh  # Enhanced disk usage analyzer
│   │   ├── drcfortune.sh
│   │   ├── drcversion.sh
│   │   ├── network-info.sh # Network diagnostics
│   │   ├── pokefetch.sh
│   │   ├── system-stats.sh # System statistics with live updates
│   │   └── weather.sh
│   ├── navigation/        # Directory navigation plugins
│   │   ├── cd-cdd-zd.sh   # Enhanced cd commands
│   │   ├── dots.sh        # Navigate dotfiles
│   │   ├── navto.sh       # Quick navigation to bookmarks
│   │   └── slashback.sh   # Quick directory navigation up (/ // ///)
│   ├── utilities/         # Utility functions
│   │   ├── automotd.sh
│   │   ├── bashrc.sh
│   │   ├── calc.sh
│   │   ├── fastnote.sh
│   │   ├── genpassword.sh
│   │   ├── motd.sh
│   │   ├── prepfile.sh    # Prepare new script files
│   │   ├── runtests.sh    # Run unit test suite
│   │   ├── timer.sh
│   │   ├── update.sh
│   │   ├── url-shortener.sh # URL shortening service
│   │   └── ... (many more)
│   └── user-plugins/      # User-created plugins
│       └── example.sh
├── install/
│   ├── _INSTALL.sh        # Installation script
│   ├── _UPDATE.sh         # Update script
│   └── generate_template.sh # Template generator
├── unit-tests/            # Unit tests for plugins
│   ├── _TEST-ALL.sh       # Test runner with tmux interface
│   ├── _test-all-fb.sh    # CI-mode test runner
│   ├── test-archive.sh
│   ├── test-backup.sh
│   ├── test-dupefind.sh
│   └── ... (30+ test files)
└── reports/               # Documentation
    ├── COMPARISON_REPORT.md
    └── MIGRATION_0.1.5_TO_0.1.6.md
```

## Configuration

### DOGRC.json

Edit `~/DOGRC/config/DOGRC.json` to enable/disable features:

```json
{
    "version": "0.2.2",
    "enable_update_check": true,
    "enable_user_plugins": true,
    "enable_aliases": true,
    "enable_blesh": true,
    "enable_hyprland_wlcopy": true,
    "enable_shell_mommy": true,
    "enable_starship": true,
    "enable_vimkeys": true,
    "enable_drchelp": true,
    "enable_zoxide": true,
    "enable_automotd": true
}
```

### Customization

**User Aliases** (`~/DOGRC/core/aliases.sh`):
- Add your custom aliases here
- This file is preserved during updates

**User Configuration** (`~/DOGRC/config/preamble.sh`):
- Add environment variables, custom functions, or initialization code
- Supports interactive and non-interactive shell modes
- This file is preserved during updates

**User Plugins** (`~/DOGRC/plugins/user-plugins/`):
- Add your own `.sh` scripts here
- See `example.sh` for a template
- Plugins are automatically sourced if `enable_user_plugins` is true

## Available Commands

Run `drchelp` to see all available commands, or `drchelp <command>` for detailed help on a specific command.

### File Operations

- **`backup`** - Create timestamped backups of files or directories
  - `backup file.txt` - Create backup with timestamp
  - `backup --store file.txt` - Store backup in ~/Documents/BAK
  - `backup --directory` - Backup current directory
  - Supports `--help` or `-h` for detailed help

- **`extract`** - Extract archives (tar, gz, bz2, zip, rar, 7z, etc.)
  - `extract archive.tar.gz` - Extract archive
  - Supports multiple formats automatically

- **`compress`** - Create archives from files or directories
  - `compress file.txt` - Create .gz file (default for files)
  - `compress directory` - Create .tar.gz (default for directories)
  - `compress file.txt zip` - Create specific format

- **`swap`** - Safely swap two file names
  - `swap file1.txt file2.txt` - Swap filenames

- **`blank`** - Empty files with safety countdown
  - `blank file.txt` - Empty file after countdown confirmation
  - `blank file.txt --touch` - Create file if it doesn't exist
  - Supports `--help` or `-h` for detailed help

- **`dupefind`** - Find duplicate files by content hash
  - `dupefind` - Find duplicates in current directory
  - `dupefind /path/to/directory` - Find duplicates in specified directory
  - `dupefind --md5` - Use MD5 hash (default is SHA256)
  - `dupefind --recursive` - Recursive search
  - Supports `--help` or `-h` for detailed help

- **`checksum-verify`** - Verify file integrity or generate checksums
  - `checksum-verify file.txt <checksum>` - Verify file against checksum
  - `checksum-verify --generate file.txt` - Generate checksum (SHA256 default)
  - `checksum-verify --recursive directory` - Generate checksums for all files in directory
  - `checksum-verify --check checksums.txt` - Verify all files listed in a checksum file
  - Supports MD5, SHA1, SHA256 (default), SHA512
  - Supports `--help` or `-h` for detailed help

- **`find-empty-dirs`** - Find and optionally delete empty directories
  - `find-empty-dirs` - Find empty directories recursively
  - `find-empty-dirs --delete` - Delete empty directories (with confirmation)
  - Supports `--help` or `-h` for detailed help

- **`sort-downloads`** - Organize Downloads directory
  - `sort-downloads` - Organize by extension
  - `sort-downloads --by-date` - Organize by date (year-month)
  - `sort-downloads --dry-run` - Preview changes without moving files
  - Supports `--help` or `-h` for detailed help

- **`sanitize-filenames`** - Clean filenames (remove special characters)
  - `sanitize-filenames file.txt` - Clean single file
  - `sanitize-filenames directory` - Clean all files in directory (recursive)
  - `sanitize-filenames --dry-run` - Preview changes
  - Supports `--help` or `-h` for detailed help

- **`mkcd`** - Create directory and change into it
  - `mkcd newdir` - Create and cd into directory
  - Automatically lists directory contents

### Navigation

- **`navto`** - Quick navigation to bookmarked directories
  - `navto` - List bookmarks
  - `navto <bookmark>` - Jump to bookmark

- **`dots`** - Navigate to dotfiles directory
  - `dots` - Go to dotfiles directory

- **`cd`, `cdd`, `zd`** - Enhanced cd commands
  - `cd` - Standard cd (enhanced)
  - `cdd` - Change directory and display contents
  - `zd` - Smart directory navigation with zoxide

- **`/`, `//`, `///`, etc.** - Quick navigation up directory levels
  - `/` - Go up 1 level
  - `//` - Go up 2 levels
  - `///` - Go up 3 levels
  - And so on...

### Information

- **`analyze-file`** - Comprehensive file analysis
  - Shows file size, type, permissions, hash, and more

- **`cpuinfo`** - Display CPU information

- **`drcversion`** - Show DOGRC version

- **`drcfortune`** - Display fortune messages

- **`pokefetch`** - Pokemon-themed system information display
  - `pokefetch` - Display pokemon-themed system info
  - `pokefetch --relocate /path/to/file.txt` - Custom output file location
  - `pokefetch -l /path/to/file.txt` - Short form for relocate flag

- **`weather`** - Weather information (supports multiple cities)

- **`network-info`** - Network diagnostics and information
  - `network-info` - Display network interfaces and IP addresses
  - `network-info --speed` - Test network speed (requires speedtest-cli)
  - `network-info --ports` - List listening ports
  - `network-info --connections` - Display active network connections
  - Supports `--help` or `-h` for detailed help

- **`system-stats`** - Enhanced system statistics
  - `system-stats` - Display CPU, memory, disk, and network stats
  - `system-stats --watch` - Live updating mode
  - `system-stats --json` - JSON output format
  - `system-stats --interval 2` - Custom update interval (seconds)
  - Supports `--help` or `-h` for detailed help

- **`disk-usage`** - Enhanced disk usage analyzer
  - `disk-usage` - Display disk usage with tree view
  - `disk-usage --top 10` - Show top N largest directories
  - `disk-usage --clean` - Suggest files to clean
  - Supports `--help` or `-h` for detailed help

### Utilities

- **`calc`** - Calculator utility

- **`genpassword`** - Generate secure passwords

- **`timer`** - Timer utility with notifications
  - `timer <name>` - Start a timer with name
  - `timer LIST` - List all active timers
  - `timer CLEAR` - Clear all timers
  - `timer --use-dir /path/to/dir` - Use custom directory for timer files
  - `timer -ud /path/to/dir` - Short form for use-dir flag

- **`pastethis`** - Upload files to Pastebin service
  - `pastethis file.txt` - Upload file to Pastebin
  - `pastethis --format python file.py` - Specify syntax highlighting
  - `pastethis --private` - Make paste private (unlisted)
  - `pastethis --title "My Code"` - Set paste title
  - `pastethis --expiration 1D` - Set expiration time (1D, 1W, 1M, N)
  - Reads API key from `~/Documents/pastebin-api-key`
  - Supports 200+ syntax highlighting formats
  - Supports `--help` or `-h` for detailed help

- **`fastnote`** - Quick note-taking utility

- **`update`** - System update helper (Arch Linux)

- **`motd`** - Message of the day management
  - Supports pager for long messages (>20 lines)

- **`prepfile`** - Prepare new script files with proper headers
  - `prepfile script.sh` - Create bash script with header
  - `prepfile script.py` - Create Python script with header
  - Supports multiple languages (bash, python, rust, go, javascript, typescript, C, C++, java, ruby, perl, php, lua, zsh, fish)
  - Automatically makes script files executable

- **`runtests`** - Run unit test suite
  - `runtests` - Run all unit tests interactively
  - `runtests --ci` - Run tests in CI mode
  - `runtests --parallel` - Run tests in parallel mode
  - `runtests --stage <test-name>` - Run specific test and neighbors
  - `runtests --egg` - Easter egg mode (animated bonsai tree)

- **`bashrc`** - Manage .bashrc files
  - `bashrc --edit` - Edit .bashrc
  - `bashrc --edit dogrc` - Edit DOGRC .bashrc
  - `bashrc --edit preamble` - Edit preamble.sh
  - `bashrc --edit config` - Edit DOGRC.json

- **`drcupdate`** - Update DOGRC system

- **`url-shortener`** / **`shorturl`** - URL shortening service
  - `url-shortener https://example.com` - Shorten URL (is.gd default)
  - `url-shortener --service tinyurl https://example.com` - Use tinyurl
  - `url-shortener --show-service https://example.com` - Show service name
  - `shorturl https://example.com` - Alias for url-shortener
  - Automatically copies to clipboard if available
  - Supports `--help` or `-h` for detailed help

- And many more...

## Help System

DOGRC includes a centralized help system accessible via `drchelp`:

```bash
drchelp                    # List all available commands
drchelp backup            # Show detailed help for backup command
drchelp extract           # Show detailed help for extract command
# ... and so on
```

Most commands also support `--help` or `-h` flags that delegate to `drchelp`:

```bash
backup --help             # Same as: drchelp backup
extract -h                # Same as: drchelp extract
```

## Updating

DOGRC includes an update system that preserves your customizations:

```bash
cd ~/Code/DOGRC           # Navigate to repository
bash install/_UPDATE.sh   # Run update script
```

Your customizations in:
- `core/aliases.sh`
- `config/preamble.sh`
- `config/disabled.json` - Fine-grained feature disabling
- `config/navto.json` - Navigation bookmarks
- `plugins/user-plugins/`
- `unit-tests/` - User-created test files

will be preserved during updates.

The update system:
- Backs up current installation
- Copies new files from repository
- Restores your customizations
- Updates version number
- Shows changelog

Automatic update checks can be enabled/disabled via `enable_update_check` in `DOGRC.json`.

## Testing

DOGRC includes comprehensive unit tests for all plugins:

```bash
cd ~/DOGRC/unit-tests
./_TEST-ALL.sh                  # Run all tests interactively with tmux interface
./_TEST-ALL.sh --ci             # Run tests in CI mode
./_TEST-ALL.sh --parallel       # Run tests in parallel (faster execution)
./_TEST-ALL.sh --stage dupefind # Run specific test and neighbors
./_TEST-ALL.sh --egg            # Easter egg mode (animated bonsai tree)
./test-archive.sh               # Test archive.sh (extract, compress)
./test-backup.sh                # Test backup.sh
./test-dupefind.sh              # Test dupefind.sh
./test-mkcd.sh                  # Test mkcd.sh
./test-swap.sh                  # Test swap.sh
# ... and many more (27+ test files)
```

The test suite includes:
- Real-time progress tracking with split pane display
- Elapsed time tracking for suite and individual tests
- **30+ test files** covering all 48+ plugins
- **Parallel execution support** (`--parallel` flag) for faster test runs
- **Test staging** (`--stage` flag) for targeted testing
- **Easter egg mode** (`--egg` flag) with animated bonsai tree
- Resource monitoring (htop/top) during parallel execution
- All tests report pass/fail status with percentage completion
- Comprehensive cleanup of temporary files and directories

You can also use the `runtests` command from anywhere to run the test suite.

## Uninstallation

To uninstall DOGRC:

1. Restore your original `.bashrc` from backup:
   ```bash
   cp ~/.bashrc.backup.* ~/.bashrc
   ```

2. Remove the DOGRC directory:
   ```bash
   rm -rf ~/DOGRC
   ```

3. Remove the MOTD file (optional):
   ```bash
   rm ~/motd.txt
   ```

4. Start a new shell session

## Troubleshooting

**Installation fails:**
- Check that all required dependencies are installed (`bash`, `jq`, `kitty`)
- Ensure `~/DOGRC` doesn't already exist (or is empty)
- Check file permissions
- Run installation script with `bash` explicitly: `bash install/_INSTALL.sh`

**Commands not found:**
- Make sure you've sourced `~/.bashrc` or started a new shell
- Verify `~/DOGRC/.bashrc` exists and is readable
- Check that plugins are enabled in `DOGRC.json`
- Verify `~/.bashrc` has the correct redirect to DOGRC

**Syntax errors:**
- Run `bash -n ~/DOGRC/.bashrc` to check for syntax errors
- Verify your custom files (`preamble.sh`, `aliases.sh`) have valid syntax
- Check plugin files in `plugins/` for syntax issues

**Update issues:**
- Make sure you're running the update script from the git repository location
- Check that `~/DOGRC` exists and is accessible
- Verify backups were created before update
- Check update script output for specific errors

**Help system not working:**
- Verify `drchelp` function is defined: `declare -f drchelp`
- Check that `enable_drchelp` is `true` in `DOGRC.json`
- Ensure `plugins/drchelp.sh` is readable

## Development

### Adding Custom Plugins

1. Create a new `.sh` file in `~/DOGRC/plugins/user-plugins/`
2. Follow the template in `example.sh`
3. Use sourcing guards to prevent duplicate definitions
4. Add dependency checks if needed
5. The plugin will be automatically sourced if `enable_user_plugins` is true

### Plugin Structure

Plugins should:
- Include a sourcing guard to prevent duplicate definitions
- Use `__DOGRC_DIR`, `__PLUGINS_DIR`, `__CORE_DIR` variables
- Source `dependency_check.sh` for dependency validation
- Support `--help` or `-h` flags (delegate to `drchelp`)
- Return appropriate exit codes
- Include bash completion where applicable

### Unit Testing

To create unit tests:
1. Create test file in `unit-tests/test-<plugin>.sh`
2. Follow the pattern from existing test files
3. Use `print_msg` function for consistent output
4. Include cleanup steps
5. Test error cases, edge cases, and success cases

## Contributing

This project is in alpha. Contributions, bug reports, and feature requests are welcome!

When contributing:
- Follow existing code style
- Add unit tests for new functionality
- Update `drchelp.sh` with help documentation
- Test on multiple systems if possible
- Document any new dependencies

## Version History

**v0.2.2** (Current)
- **Bug Fixes**:
  - **Update Script (`_UPDATE.sh`)**: Fixed critical syntax error in `preamble.sh` extraction logic
  - Improved robustness of preamble migration to correctly handle multi-line blocks (if/case/for) and comments
  - Added safer line reading to handle files without trailing newlines
  - Quoted reserved tokens in regex to prevent shell parser misinterpretation

**v0.2.1**
- **New Features**:
  - **pastethis Plugin**: New utility for uploading files to Pastebin
  - Supports 200+ syntax highlighting formats with intelligent auto-detection
  - Secure API key management (reads from `~/Documents/pastebin-api-key`)
  - Customizable privacy (public/unlisted/private), expiration times, and titles
  - Full bash completion for all flags and options
- **Enhancements**:
  - **Documentation**: Added comprehensive `drchelp` documentation for `pastethis`
  - **Installation/Update**: Integrated `pastethis` into `_INSTALL.sh` and `_UPDATE.sh` for verification and migration summary
- **Testing**: Added 56 enterprise-grade unit tests for `pastethis` with full support for parallel execution

**v0.2.0**
- **checksum-verify Plugin Enhancements**:
  - Added recursive directory checksum generation (`--recursive`, `-r`)
  - Added batch verification mode (`--check`, `-c`) to verify files from a checksum file
- **Environment**: Improved `.bashrc` completion bindings (Tab cycles forward, Shift+Tab cycles backward)
- **Testing**: Integrated 5 new tests for `checksum-verify`, expanding test suite to 45+ passing tests

**v0.1.7**
- **8 New Plugins Added**:
  - **network-info**: Network diagnostics (interfaces, IPs, ports, connections, speed tests)
  - **system-stats**: Enhanced system statistics with live updates and JSON output
  - **url-shortener**: URL shortening service (is.gd, tinyurl) with `shorturl` alias
  - **checksum-verify**: File checksum verification/generation (MD5, SHA1, SHA256, SHA512)
  - **find-empty-dirs**: Find and optionally delete empty directories recursively
  - **sort-downloads**: Organize Downloads directory by extension or date
  - **sanitize-filenames**: Clean filenames (remove special chars, normalize spaces)
  - **disk-usage**: Enhanced disk usage analyzer with tree view and cleanup suggestions
- **Test Runner Enhancement**: Added `--egg` / `-EGG` flag for easter egg mode
  - Displays animated bonsai tree (cbonsai) in right pane during tests
- **Documentation**: Updated drchelp.sh with comprehensive help for all 8 new plugins
- **Installation**: Updated _INSTALL.sh to verify all new plugin files
- **Test Isolation**: Improved test isolation for parallel execution
- Added comprehensive unit tests for url-shortener, checksum-verify, and find-empty-dirs

**v0.1.6**
- **dupefind Plugin**: New file-operations plugin for finding duplicate files
  - Finds duplicates by content hash (MD5/SHA256)
  - Recursive directory scanning with detailed reporting
  - Comprehensive unit test suite (45 tests)
- **Parallel Test Execution**: Added `--parallel` flag for simultaneous test execution
  - Significantly faster test suite execution
  - Resource monitor (htop/top) in right tmux pane during parallel runs
  - All test files updated for parallel execution safety
- **Test Runner Enhancements**: Added `--stage` flag for targeted testing
  - Test specific test and its adjacent tests for faster debugging
- **pokefetch Enhancement**: Added `--relocate` flag for custom output location
- **timer Enhancement**: Added `--use-dir` flag for custom timer directory
- **Version Comparison**: Enhanced to handle 4+ part version strings (e.g., `0.1.5.12`)
- **Update Script Enhancements**: Improved migration logic
  - Added preservation of `disabled.json` user customizations
  - Added preservation of user-created test files
- **Test Suite Improvements**: Enhanced for parallel execution safety
  - Fixed race conditions and cleanup issues
  - Improved test score tabulation

**v0.1.5**
- **Unit Test Infrastructure**: Added comprehensive test runner with tmux interface
  - Real-time progress tracking with split pane display
  - Added unit tests for all 25+ plugins
  - Enhanced test infrastructure with helper functions
- **prepfile Utility**: Added new utility for preparing script files with proper headers
  - Multi-language support (bash, python, rust, go, javascript, typescript, C, C++, java, ruby, perl, php, lua, zsh, fish)
  - Automatic file extension handling and executable permissions
- **runtests Plugin**: Added utility plugin to run unit test suite
- **blank Plugin**: Added file emptying utility with safety countdown
- **motd Enhancement**: Added pager support for long messages (>20 lines)
- **compress() Fix**: Fixed exit code capture for gz and bz2 formats
- Enhanced drchelp documentation for all utilities
- Moved unit-tests to root level for better organization

**v0.1.4**
- Added `enable_update_check` configuration option
- Standardized `--help/-h` flag support across all plugins
- Enhanced `bashrc.sh` with new `--edit` options
- Improved various plugins with help flag support
- Bug fixes and improvements

See `install/changelog.txt` for detailed changelog.

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3).

DOGRC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html) for more details.

See the [LICENSE](LICENSE) file for the full license text.

## Acknowledgments

DOGRC is inspired by various bashrc configurations and aims to provide a modern, maintainable approach to shell configuration.

Made by Tony Pup (c) 2025. All rights reserved. Rarf~~! <3

---

**Note:** This is alpha software. Features may change, and there may be bugs. Always backup your configuration before installing or updating.

