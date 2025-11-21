# Migration Considerations: DOGRC 0.1.5 → 0.1.6

**Date:** 2025-11-21  
**Upgrade Path:** 0.1.5 → 0.1.6  
**Status:** ✅ Safe Upgrade - No Breaking Changes

---

## Executive Summary

This upgrade from version 0.1.5 to 0.1.6 is **backwards compatible** and introduces no breaking changes. All existing functionality is preserved, and user customizations are automatically migrated during the upgrade process.

**Migration Risk Level:** 🟢 **Low** - Safe to upgrade

---

## What's Preserved During Migration

The update script (`_UPDATE.sh`) automatically preserves the following user customizations:

### ✅ Fully Preserved

1. **User Aliases** (`core/aliases.sh`)
   - All custom aliases are extracted and merged into the new aliases file
   - New default aliases (including `changelog`) are added automatically
   - User customizations are appended with a comment header

2. **Preamble Snippets** (`config/preamble.sh`)
   - All user snippets in `--non-interactive`, `--interactive`, and `--after-loading` branches are preserved
   - Merged back into the new preamble.sh file

3. **Configuration Settings** (`config/DOGRC.json`)
   - All `enable_*` feature flags are preserved
   - Version number is automatically updated to `0.1.6`
   - User preferences for all features are maintained

4. **Navigation Bookmarks** (`config/navto.json`)
   - All navigation bookmarks are preserved
   - User-defined shortcuts remain functional

5. **Disabled Features** (`config/disabled.json`)
   - User customizations to disabled plugins/functions/aliases are preserved
   - Only template values are replaced if unchanged

6. **User Plugins** (`plugins/user-plugins/*.sh`)
   - All user-created plugins are copied to the new installation
   - Custom plugins remain functional after upgrade

7. **Unit Tests** (`unit-tests/`)
   - Standard test files are replaced with new versions
   - User-created test files (non-standard naming) are preserved
   - User test directories (`user-tests/`, `custom/`) are preserved

---

## New Features Added

### 1. dupefind Plugin
- **Location:** `plugins/file-operations/dupefind.sh`
- **Functionality:** Find duplicate files by content hash (MD5/SHA256)
- **Migration Impact:** None - New plugin, no conflicts
- **Documentation:** Available via `dupefind --help` or `drchelp dupefind`

### 2. Parallel Test Execution
- **Feature:** `--parallel` flag for test runner
- **Migration Impact:** None - Test files updated for parallel safety
- **Note:** Existing test files work in both sequential and parallel modes

### 3. Enhanced Test Runner
- **Feature:** `--stage` flag for targeted testing
- **Migration Impact:** None - New feature, backwards compatible

### 4. pokefetch Enhancement
- **New Flag:** `--relocate` (`-l`, `-L`) to specify custom output file
- **Migration Impact:** None - Optional flag, defaults unchanged
- **Default Behavior:** Still uses `/tmp/pokefetch.txt` if flag not specified

### 5. timer Enhancement
- **New Flag:** `--use-dir` (`-ud`, `-UD`) to specify custom timer directory
- **Migration Impact:** None - Optional flag, defaults unchanged
- **Default Behavior:** Still uses `/tmp` if flag not specified

---

## Behavior Changes

### Version Comparison Enhancement
- **What Changed:** Now handles 4+ part version strings (e.g., `0.1.5.12`)
- **Previous Behavior:** Only compared first 3 parts
- **New Behavior:** Compares all parts with proper padding
- **Migration Impact:** ✅ Improved behavior, backwards compatible
- **Example:** `0.1.5.12` vs `0.1.5.1` now correctly identifies the newer version

**Note:** If you use `config/version.fake` with 4-part versions, comparisons will now be more accurate.

---

## Files Modified During Upgrade

### Regenerated from Templates
These files are regenerated from templates but user customizations are merged:

- `core/aliases.sh` - User aliases merged back
- `config/preamble.sh` - User snippets merged back
- `config/DOGRC.json` - Version updated, enable_* values preserved
- `config/disabled.json` - Preserved if customized

### Replaced Files
These files are replaced with new versions:

- All plugin files (updated with new features/bug fixes)
- All test files (updated for parallel execution safety)
- Test runner scripts (`_TEST-ALL.sh`, `_test-all-fb.sh`)
- Helper scripts (`_test-results-helper.sh`)

### New Files Added
- `plugins/file-operations/dupefind.sh` - New plugin
- `unit-tests/test-dupefind.sh` - New test file

---

## Potential Issues and Solutions

### Issue 1: changelog Alias Not Available After Upgrade
**Status:** ✅ Resolved  
**Description:** New `changelog` alias is automatically added during upgrade

**Solution:** The alias is included in the new `aliases.sh` template and is automatically added when the file is regenerated.

### Issue 2: Version Comparison with 4-Part Versions
**Status:** ✅ Improved  
**Description:** Version comparison now handles 4+ part versions correctly

**Impact:** Users with `version.fake` files using 4-part versions will see more accurate update checks.

**Solution:** No action needed - behavior is improved automatically.

### Issue 3: Test Files with Custom Naming
**Status:** ✅ Preserved  
**Description:** User-created test files are automatically preserved

**Solution:** Test files that don't match standard patterns (`test-*.sh`, `_TEST-*.sh`, `_test-*.sh`) are preserved during upgrade.

---

## Upgrade Instructions

### Automatic Upgrade (Recommended)

1. Ensure you're in the DOGRC git repository directory:
   ```bash
   cd ~/Code/DOGRC  # or wherever your DOGRC repo is
   ```

2. Run the update script:
   ```bash
   bash install/_UPDATE.sh
   ```

3. Review the upgrade summary displayed at the end

4. Start a new shell session or reload:
   ```bash
   source ~/.bashrc
   ```

### What Happens During Upgrade

1. **Backup Creation**
   - Entire `~/DOGRC` directory is backed up with timestamp
   - `~/.bashrc` is backed up (if it exists)

2. **Customization Extraction**
   - User aliases extracted from old `aliases.sh`
   - Preamble snippets extracted from old `preamble.sh`
   - Enable_* values extracted from `DOGRC.json`

3. **Fresh Installation**
   - Old installation is removed
   - New version is installed from template
   - Essential files are regenerated

4. **Customization Restoration**
   - User aliases merged into new `aliases.sh`
   - Preamble snippets merged into new `preamble.sh`
   - Enable_* values restored to new `DOGRC.json`
   - Other config files restored (`navto.json`, `disabled.json`, user plugins, user tests)

5. **Verification**
   - All files are validated
   - Syntax checks performed
   - Summary displayed

---

## Rollback Procedure

If you encounter issues after upgrading:

1. The backup directory is preserved: `~/DOGRC.backup.TIMESTAMP`

2. To rollback manually:
   ```bash
   rm -rf ~/DOGRC
   mv ~/DOGRC.backup.TIMESTAMP ~/DOGRC
   ```

3. Restore `.bashrc` if needed:
   ```bash
   cp ~/.bashrc.backup.TIMESTAMP ~/.bashrc
   ```

---

## Testing Recommendations

After upgrading, consider running the test suite to verify everything works:

```bash
cd ~/DOGRC/unit-tests
./_TEST-ALL.sh
```

Or use the `runtests` command if available:
```bash
runtests
```

---

## Known Limitations

1. **changelog Alias Variable Expansion**
   - The `changelog` alias uses `$EDITOR` and `$__DOGRC_DIR`
   - Ensure `$EDITOR` is set (defaults to system default editor if not)
   - `$__DOGRC_DIR` is automatically set by DOGRC

2. **Version Comparison Edge Cases**
   - Very old version strings (pre-0.1.0) may behave differently
   - Version strings with non-numeric parts are not supported

3. **Test File Naming**
   - User test files must not match standard patterns to be preserved
   - Files matching `test-*.sh`, `_TEST-*.sh`, or `_test-*.sh` will be replaced

---

## Checklist for Upgrade

- [ ] Review this migration report
- [ ] Ensure DOGRC is at version 0.1.5 (check with `drcversion`)
- [ ] Backup any critical customizations outside of DOGRC (extra safety)
- [ ] Run `install/_UPDATE.sh`
- [ ] Review the upgrade summary
- [ ] Test key plugins: `dupefind --help`, `pokefetch --relocate /tmp/test.txt`, `timer --use-dir /tmp/mytimers test`
- [ ] Run test suite to verify installation
- [ ] Check that custom aliases are preserved: `aliases`
- [ ] Verify navigation bookmarks: `navto --list` (if using navto)

---

## Support and Troubleshooting

If you encounter issues during or after upgrade:

1. Check the backup directory: `ls -la ~/DOGRC.backup.*`
2. Review upgrade logs in the terminal output
3. Check `~/DOGRC/config/DOGRC.json` for correct version
4. Verify customizations in `~/DOGRC/core/aliases.sh`
5. Check `~/DOGRC/config/preamble.sh` for preserved snippets

---

## Version Comparison Examples

The improved version comparison handles these cases correctly:

| Version A | Version B | Result | Notes |
|-----------|-----------|--------|-------|
| 0.1.5 | 0.1.6 | B newer | Standard 3-part comparison |
| 0.1.5 | 0.1.5.1 | B newer | 4-part version correctly handled |
| 0.1.5.12 | 0.1.5.9 | A newer | Build number comparison works |
| 0.1.5 | 0.1.5.0 | Equal | Padding handled correctly |

---

## Summary

✅ **Safe to upgrade** - No breaking changes  
✅ **All customizations preserved** - Automatic migration  
✅ **New features available** - dupefind plugin, parallel tests, enhanced flags  
✅ **Improved functionality** - Better version comparison, test suite enhancements  

**Recommendation:** Proceed with upgrade. The migration process is automated and safe.

---

*This report was generated on 2025-11-21 for DOGRC version 0.1.6*

