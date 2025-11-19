# DOGRC

**DOGRC** is a modular, extensible bash configuration system that provides a comprehensive set of utilities, aliases, and plugins for enhancing your shell experience.

> ⚠️ **Status: Alpha** - This project is currently in alpha development (v0.1.4). Features may change, and there may be bugs. Use at your own discretion.

## Features

- 🎯 **Modular Architecture** - Organized plugin system with clear separation of concerns
- ⚙️ **Configurable** - JSON-based configuration for easy feature toggling
- 🔌 **Extensible** - Easy to add custom plugins and aliases
- 🛠️ **Rich Utilities** - File operations, navigation, information tools, and more
- 📦 **Self-Contained** - All configuration in one directory (`~/DOGRC`)
- 🔄 **Update-Friendly** - Update system that preserves user customizations
- 🧪 **Well-Tested** - Unit tests for core functionality

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
│   │   ├── mkcd.sh        # Create directory and cd into it
│   │   └── swap.sh        # Swap file names
│   ├── information/       # System information plugins
│   │   ├── analyze-file.sh
│   │   ├── cpuinfo.sh
│   │   ├── drcfortune.sh
│   │   ├── drcversion.sh
│   │   ├── pokefetch.sh
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
│   │   ├── timer.sh
│   │   ├── update.sh
│   │   └── ... (many more)
│   └── user-plugins/      # User-created plugins
│       └── example.sh
├── install/
│   ├── _INSTALL.sh        # Installation script
│   ├── _UPDATE.sh         # Update script
│   └── generate_template.sh # Template generator
└── unit-tests/            # Unit tests for plugins
    ├── test-archive.sh
    ├── test-backup.sh
    ├── test-mkcd.sh
    └── test-swap.sh
```

## Configuration

### DOGRC.json

Edit `~/DOGRC/config/DOGRC.json` to enable/disable features:

```json
{
    "version": "0.1.4",
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

- **`weather`** - Weather information (supports multiple cities)

### Utilities

- **`calc`** - Calculator utility

- **`genpassword`** - Generate secure passwords

- **`timer`** - Timer utility with notifications

- **`fastnote`** - Quick note-taking utility

- **`update`** - System update helper (Arch Linux)

- **`motd`** - Message of the day management

- **`bashrc`** - Manage .bashrc files
  - `bashrc --edit` - Edit .bashrc
  - `bashrc --edit dogrc` - Edit DOGRC .bashrc
  - `bashrc --edit preamble` - Edit preamble.sh
  - `bashrc --edit config` - Edit DOGRC.json

- **`drcupdate`** - Update DOGRC system

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
- `plugins/user-plugins/`

will be preserved during updates.

The update system:
- Backs up current installation
- Copies new files from repository
- Restores your customizations
- Updates version number
- Shows changelog

Automatic update checks can be enabled/disabled via `enable_update_check` in `DOGRC.json`.

## Testing

DOGRC includes unit tests for core file operations plugins:

```bash
cd ~/DOGRC/unit-tests
./test-archive.sh         # Test archive.sh (extract, compress)
./test-backup.sh          # Test backup.sh
./test-mkcd.sh            # Test mkcd.sh
./test-swap.sh            # Test swap.sh
```

All tests report pass/fail status with percentage completion.

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

**v0.1.4** (Current)
- Added `enable_update_check` configuration option
- Standardized `--help/-h` flag support across all plugins
- Enhanced `bashrc.sh` with new `--edit` options
- Improved various plugins with help flag support
- Bug fixes and improvements

See `install/_UPDATE.sh` for detailed changelog.

## License

[Add your license here]

## Acknowledgments

DOGRC is inspired by various bashrc configurations and aims to provide a modern, maintainable approach to shell configuration.

Made by Tony Pup (c) 2025. All rights reserved. Rarf~~! <3

---

**Note:** This is alpha software. Features may change, and there may be bugs. Always backup your configuration before installing or updating.

