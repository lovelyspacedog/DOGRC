# DOGRC

**DOGRC** is a modular, extensible bash configuration system that provides a comprehensive set of utilities, aliases, and plugins for enhancing your shell experience.

> ⚠️ **Status: Alpha** - This project is currently in alpha development. Features may change, and there may be bugs. Use at your own discretion.

## Features

- 🎯 **Modular Architecture** - Organized plugin system with clear separation of concerns
- ⚙️ **Configurable** - JSON-based configuration for easy customization
- 🔌 **Extensible** - Easy to add custom plugins and aliases
- 🛠️ **Rich Utilities** - File operations, navigation, information tools, and more
- 📦 **Self-Contained** - All configuration in one directory (`~/DOGRC`)
- 🔄 **Update-Friendly** - Designed for easy updates while preserving user customizations (_UPDATE.sh not implemented yet)

## Installation

### Prerequisites

**Required:**
- `bash` (4.0+)
- `jq` - JSON processor
- `kitty` - Terminal emulator

**Recommended:**
- `nvim` - Text editor
- `pokemon-colorscripts` - For pokefetch plugin
- `fastfetch` - System information tool
- `yay` - AUR helper (Arch Linux)
- `flatpak` - Application framework

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
│   ├── drchelp.sh         # Help system
│   ├── file-operations/   # File management plugins
│   ├── information/       # System information plugins
│   ├── navigation/        # Directory navigation plugins
│   ├── utilities/         # Utility functions
│   └── user-plugins/      # User-created plugins
└── install/
    ├── _INSTALL.sh        # Installation script
    └── generate_template.sh # Template generator
```

## Configuration

### DOGRC.json

Edit `~/DOGRC/config/DOGRC.json` to enable/disable features:

```json
{
    "version": "0.1.0",
    "enable_aliases": true,
    "enable_automotd": true,
    "enable_blesh": true,
    "enable_drchelp": true,
    "enable_hyprland_wlcopy": true,
    "enable_shell_mommy": true,
    "enable_starship": true,
    "enable_user_plugins": true,
    "enable_vimkeys": true,
    "enable_zoxide": true
}
```

### Customization

**User Aliases** (`~/DOGRC/core/aliases.sh`):
- Add your custom aliases here
- This file is preserved during updates

**User Configuration** (`~/DOGRC/config/preamble.sh`):
- Add environment variables, custom functions, or initialization code
- Supports interactive and non-interactive shell modes

**User Plugins** (`~/DOGRC/plugins/user-plugins/`):
- Add your own `.sh` scripts here
- See `example.sh` for a template

## Available Commands

Run `drchelp` to see all available commands and their descriptions.

### Categories

**File Operations:**
- `backup` - Create timestamped backups
- `archive` / `extract` - Archive management
- `swap` - Swap file names
- `mkcd` - Create directory and cd into it

**Navigation:**
- `navto` - Quick navigation to bookmarked directories
- `dots` - Navigate dotfiles directory
- `cd-cdd-zd` - Enhanced cd commands

**Information:**
- `pokefetch` - Pokemon-themed system fetch
- `weather` - Weather information
- `cpuinfo` - CPU information
- `drcversion` - Show DOGRC version
- `drcfortune` - Fortune cookies

**Utilities:**
- `calc` - Calculator
- `genpassword` - Generate passwords
- `timer` - Timer utility
- `fastnote` - Quick note-taking
- `update` - System update helper
- `motd` - Message of the day management
- And many more...

## Updating

To update DOGRC, use the `_UPDATE.sh` script (when available). Your customizations in:
- `core/aliases.sh`
- `config/preamble.sh`
- `plugins/user-plugins/`

will be preserved during updates.

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

## Troubleshooting

**Installation fails:**
- Check that all required dependencies are installed
- Ensure `~/DOGRC` doesn't already exist (or is empty)
- Check file permissions

**Commands not found:**
- Make sure you've sourced `~/.bashrc` or started a new shell
- Verify `~/DOGRC/.bashrc` exists and is readable
- Check that plugins are enabled in `DOGRC.json`

**Syntax errors:**
- Run `bash -n ~/DOGRC/.bashrc` to check for syntax errors
- Verify your custom files (`preamble.sh`, `aliases.sh`) have valid syntax

## Contributing

This project is in alpha. Contributions, bug reports, and feature requests are welcome!

## License

[Add your license here]

## Acknowledgments

DOGRC is inspired by various bashrc configurations and aims to provide a modern, maintainable approach to shell configuration.

---

**Note:** This is alpha software. Features may change, and there may be bugs. Always backup your configuration before installing or updating.

