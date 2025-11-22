# Plugin Suggestions for DOGRC

This document contains suggestions for new plugins and extensions that could be added to DOGRC. These suggestions are organized by category and follow the existing plugin architecture patterns.

## File Operations

### 1. `find-empty-dirs.sh`
Find empty directories recursively.
- `find-empty-dirs [directory]` - Find empty directories
- `find-empty-dirs --delete` - Delete empty directories (with confirmation)
- Use cases: Cleanup projects, remove unused directory structures

### 2. `organize-downloads.sh`
Organize files in Downloads directory by type/date.
- `organize-downloads` - Organize ~/Downloads by file extension
- `organize-downloads --by-date` - Organize by date
- `organize-downloads --dry-run` - Preview changes
- Use cases: Automatic file organization

### 3. `sanitize-filenames.sh`
Clean filenames (remove special chars, normalize spaces).
- `sanitize-filenames [file|directory]` - Clean filenames
- `sanitize-filenames --dry-run` - Preview changes
- `sanitize-filenames --replace-spaces` - Replace spaces with underscores
- Dependencies: `rename`, `find`
- Use cases: Fix problematic filenames, prepare files for cross-platform use

### 4. `disk-usage.sh`
Enhanced disk usage analyzer with tree view.
- `disk-usage [directory]` - Show disk usage tree
- `disk-usage --top 10` - Show top 10 largest directories
- `disk-usage --clean` - Suggest files to clean (temp files, caches)
- Dependencies: `du`, `tree` (optional)
- Use cases: Find space hogs, cleanup suggestions

### 5. `symlink-manager.sh`
Create and manage symbolic links with safety checks.
- `symlink-manager create source target` - Create symlink
- `symlink-manager list` - List all symlinks in directory
- `symlink-manager check` - Check for broken symlinks
- `symlink-manager repair` - Repair broken symlinks
- Use cases: Dotfile management, linking configs

## Information

### 7. `network-info.sh`
Display network information and diagnostics.
- `network-info` - Show network interfaces and IPs
- `network-info --speed` - Test network speed
- `network-info --ports` - Show listening ports
- `network-info --connections` - Show active connections
- Dependencies: `ip`, `ss`, `speedtest-cli` (optional)
- Use cases: Network troubleshooting, monitoring

### 8. `system-stats.sh`
Enhanced system statistics with live updates.
- `system-stats` - Show CPU, memory, disk, network stats
- `system-stats --watch` - Live updating stats
- `system-stats --json` - Output as JSON
- Dependencies: `vmstat`, `iostat` (optional)
- Use cases: System monitoring, performance analysis

### 9. `git-info.sh`
Enhanced Git repository information display.
- `git-info` - Show git repo status, branches, remotes
- `git-info --graph` - Show branch graph
- `git-info --stats` - Show commit statistics
- Dependencies: `git`
- Use cases: Quick git status, repo overview

### 10. `package-info.sh`
Display package information (works with multiple package managers).
- `package-info [package]` - Show package info
- `package-info --installed` - List installed packages
- `package-info --outdated` - List outdated packages
- Supports: `pacman`, `apt`, `yum`, `dnf`, `flatpak`, `snap`
- Use cases: Package management, system overview

### 11. `process-info.sh`
Enhanced process information and management.
- `process-info [pid|name]` - Show detailed process info
- `process-info --tree` - Show process tree
- `process-info --cpu` - Show top CPU processes
- `process-info --memory` - Show top memory processes
- Dependencies: `ps`, `pstree`
- Use cases: Process monitoring, debugging

### 12. `battery-info.sh`
Battery status and information (for laptops).
- `battery-info` - Show battery status
- `battery-info --watch` - Monitor battery levels
- `battery-info --estimate` - Estimate battery life
- Dependencies: `acpi` or `upower`
- Use cases: Laptop battery monitoring

## Navigation

### 13. `history-search.sh`
Enhanced command history search and navigation.
- `history-search [pattern]` - Search command history
- `history-search --most-used` - Show most used commands
- `history-search --recent` - Show recent commands
- Integration with `fc` and `history`
- Use cases: Command recall, productivity

### 14. `quick-jump.sh`
Quick jump to frequently used files/directories (complement to navto).
- `quick-jump` - Interactive menu of recent locations
- `quick-jump add [path]` - Add to jump list
- `quick-jump --edit` - Edit jump list
- Dependencies: `fzf` (optional, for fuzzy search)
- Use cases: Fast navigation, productivity

### 15. `bookmark-manager.sh`
Enhanced bookmark system for files and directories.
- `bookmark add [name] [path]` - Add bookmark
- `bookmark list` - List all bookmarks
- `bookmark go [name]` - Jump to bookmark
- `bookmark edit` - Edit bookmarks interactively
- JSON-based storage (like navto)
- Use cases: File/directory organization

## Utilities

### 16. `url-shortener.sh`
Shorten URLs using various services.
- `url-shortener [url]` - Shorten URL (use default service)
- `url-shortener [url] --service [service]` - Specify service
- Supports: `is.gd`, `tinyurl`, `bitly` (with API key)
- Dependencies: `curl`, `jq`
- Use cases: Quick URL shortening

### 17. `qr-generator.sh`
Generate QR codes from text/URLs.
- `qr-generator "text"` - Generate QR code
- `qr-generator "url" --display` - Display QR in terminal
- `qr-generator --read [image]` - Read QR code from image
- Dependencies: `qrencode`, `zbarimg`
- Use cases: Sharing URLs, text, Wi-Fi passwords

### 18. `base64-encode.sh`
Quick base64 encoding/decoding utility.
- `base64-encode [file|text]` - Encode to base64
- `base64-decode [file|text]` - Decode from base64
- `base64-encode --file [file]` - Encode file to stdout
- Use cases: Data encoding, API tokens

### 19. `checksum-verify.sh`
Verify file checksums and integrity.
- `checksum-verify [file] [checksum]` - Verify checksum
- `checksum-verify --generate [file]` - Generate checksum
- Supports: MD5, SHA1, SHA256, SHA512
- Use cases: File integrity, downloads verification

### 20. `clipboard-manager.sh`
Enhanced clipboard management with history.
- `clipboard-manager history` - Show clipboard history
- `clipboard-manager clear` - Clear clipboard
- `clipboard-manager save` - Save to file
- Integrates with `xclip`, `wl-clipboard`, `pbcopy`
- Use cases: Clipboard history, productivity

### 21. `color-picker.sh`
Pick colors from terminal or images.
- `color-picker` - Interactive color picker
- `color-picker --hex` - Output hex code
- `color-picker --rgb` - Output RGB values
- Dependencies: `gcolor3`, `colorpicker` (optional)
- Use cases: Design, theming

### 22. `countdown.sh`
Countdown timer with notifications.
- `countdown [seconds]` - Start countdown
- `countdown 5m` - 5 minutes (supports m/h suffixes)
- `countdown --message "message"` - Custom notification message
- Complements `timer.sh` with visual countdown
- Use cases: Pomodoro, reminders, cooking

### 23. `screenshot.sh`
Quick screenshot utility with various options.
- `screenshot` - Full screen screenshot
- `screenshot --region` - Select region
- `screenshot --window` - Active window
- `screenshot --clipboard` - Copy to clipboard
- Dependencies: `maim`, `scrot`, or `flameshot`
- Use cases: Quick screenshots

### 24. `search-replace.sh`
Find and replace text in files with safety features.
- `search-replace [pattern] [replacement] [file]` - Replace in file
- `search-replace --recursive [directory]` - Replace in directory
- `search-replace --dry-run` - Preview changes
- `search-replace --backup` - Create backups
- Dependencies: `sed`, `grep`
- Use cases: Bulk text replacement, refactoring

### 25. `todo-manager.sh`
Simple todo list manager with persistence.
- `todo add "task"` - Add todo item
- `todo list` - List todos
- `todo complete [id]` - Mark as complete
- `todo delete [id]` - Delete todo
- JSON-based storage
- Use cases: Quick task management

### 26. `unit-converter.sh`
Convert units (temperature, length, weight, etc.).
- `unit-convert 100 F C` - Convert temperature
- `unit-convert 10 km miles` - Convert distance
- `unit-convert --list` - List supported units
- Use cases: Quick unit conversions

### 27. `wifi-manager.sh`
WiFi network management and information.
- `wifi-manager list` - List available networks
- `wifi-manager connect [ssid]` - Connect to network
- `wifi-manager status` - Show connection status
- `wifi-manager password [ssid]` - Show saved password
- Dependencies: `nmcli`, `iw`, `wpa_supplicant`
- Use cases: WiFi management

### 28. `docker-helper.sh`
Docker container and image management shortcuts.
- `docker-helper ps` - Enhanced container list
- `docker-helper clean` - Clean unused containers/images
- `docker-helper logs [container]` - Enhanced log viewer
- `docker-helper stats` - Resource usage stats
- Dependencies: `docker`
- Use cases: Docker management

### 29. `git-helper.sh`
Git workflow shortcuts and automation.
- `git-helper status` - Enhanced git status
- `git-helper commit-push "message"` - Commit and push
- `git-helper branch-cleanup` - Delete merged branches
- `git-helper stash-list` - Enhanced stash management
- Dependencies: `git`
- Use cases: Git productivity

### 30. `rsync-wrapper.sh`
Enhanced rsync wrapper with common presets.
- `rsync-wrapper backup [source] [dest]` - Backup with rsync
- `rsync-wrapper sync [source] [dest]` - Two-way sync
- `rsync-wrapper --dry-run` - Preview changes
- `rsync-wrapper --exclude [pattern]` - Exclude patterns
- Dependencies: `rsync`
- Use cases: File synchronization, backups

## Development Tools

### 31. `format-code.sh`
Format code files with appropriate formatters.
- `format-code [file]` - Auto-format based on extension
- `format-code --all` - Format all files in directory
- Supports: `bash` (shfmt), `python` (black), `js` (prettier), `rust` (rustfmt)
- Dependencies: Various formatters
- Use cases: Code formatting

### 32. `lint-code.sh`
Lint code files with appropriate linters.
- `lint-code [file]` - Lint based on extension
- `lint-code --fix` - Auto-fix issues
- Supports: `bash` (shellcheck), `python` (pylint), `js` (eslint)
- Dependencies: Various linters
- Use cases: Code quality

### 33. `git-hooks.sh`
Manage Git hooks easily.
- `git-hooks install` - Install common hooks
- `git-hooks add [hook-name] [script]` - Add custom hook
- `git-hooks list` - List installed hooks
- Use cases: Git automation, quality gates

## New Category: Security

### 34. `password-checker.sh`
Check password strength and common vulnerabilities.
- `password-checker [password]` - Check password strength
- `password-checker --generate` - Generate strong password
- Integration with Have I Been Pwned API (optional)
- Use cases: Password security

### 35. `ssh-key-manager.sh`
Manage SSH keys easily.
- `ssh-key-manager list` - List all SSH keys
- `ssh-key-manager generate [name]` - Generate new key
- `ssh-key-manager add [key]` - Add key to ssh-agent
- Dependencies: `ssh-keygen`, `ssh-add`
- Use cases: SSH key management

### 36. `cert-checker.sh`
Check SSL certificate information and expiration.
- `cert-checker [domain]` - Check certificate info
- `cert-checker --expiry [domain]` - Show expiration date
- `cert-checker --file [cert.pem]` - Check local certificate
- Dependencies: `openssl`
- Use cases: Certificate monitoring

## New Category: Media

### 37. `image-optimizer.sh`
Optimize images (resize, compress, convert).
- `image-optimizer [file]` - Optimize image
- `image-optimizer --resize 800x600` - Resize image
- `image-optimizer --format jpg` - Convert format
- Dependencies: `imagemagick`, `optipng`, `jpegoptim`
- Use cases: Image optimization

### 38. `video-info.sh`
Get video file information.
- `video-info [file]` - Show video metadata
- `video-info --duration` - Show duration only
- `video-info --codec` - Show codec info
- Dependencies: `ffprobe` (ffmpeg)
- Use cases: Video file inspection

### 39. `audio-extract.sh`
Extract audio from video files.
- `audio-extract [video]` - Extract audio
- `audio-extract --format mp3` - Specify format
- Dependencies: `ffmpeg`
- Use cases: Audio extraction

## Implementation Notes

All plugins should follow the existing patterns:
1. **Sourcing Guard** - Prevent duplicate definitions
2. **Directory Variables** - Use `__DOGRC_DIR`, `__PLUGINS_DIR`, etc.
3. **Dependency Checks** - Use `ensure_commands_present`
4. **Help Flags** - Support `--help` and `-h` (delegate to `drchelp`)
5. **Error Handling** - Proper exit codes and error messages
6. **Bash Completion** - Add completion functions where applicable
7. **Documentation** - Register with `drchelp.sh`

## Priority Recommendations

Based on common use cases and DOGRC's current feature set:

**High Priority:**
1. `symlink-manager.sh` - Fits file-operations category
2. `sanitize-filenames.sh` - Common need, fits file-operations
3. `git-info.sh` / `git-helper.sh` - Development workflow
4. `network-info.sh` - System information
5. `search-replace.sh` - Text manipulation utility

**Medium Priority:**
6. `disk-usage.sh` - System monitoring
7. `countdown.sh` - Complement to timer
8. `todo-manager.sh` - Productivity utility
9. `checksum-verify.sh` - File integrity
10. `process-info.sh` - System information

**Nice to Have:**
- Remaining plugins based on user needs and dependencies

## Adding New Plugins

To add a new plugin:
1. Create file in appropriate category directory
2. Follow the template from `plugins/user-plugins/example.sh`
3. Add help documentation to `plugins/drchelp.sh`
4. Create unit test in `unit-tests/test-[plugin].sh`
5. Update README.md if it's a major feature

