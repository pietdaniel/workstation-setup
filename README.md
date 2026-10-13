Workstation Setup
===

This project is my workstation setup using Ansible. It includes configurations for
dotfiles, applications, and system settings to streamline the setup process on a
new machine.

# Project Structure

#### run.sh

Basic bootstrap script to install Ansible and run the playbook.

#### ./playbook.yaml

This is the entry point for the Ansible playbook. It includes all roles and tasks
needed to set up the workstation.

# Wiki

## macOS Caps Lock → Escape

The first role in the playbook, `macos_keyboard`, sets Caps Lock to Escape using
the current user's native, host-specific Modifier Keys preferences. It discovers
connected keyboards and preserves their other modifier mappings. The normal
Escape key keeps its existing behavior.

This uses ordinary Ansible tasks with macOS's built-in `hidutil` (discovery only),
`defaults`, and `plutil`; there is no custom Python module or background remapper.

Run just this configuration (without sudo):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags keyboard
```

Add `--check` to preview changes. Log out and back in after applying the setting.
If you used the retired `swap-escape-macos.sh`, restart instead to also clear its
temporary mapping.
Verify under System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys.
Connect external keyboards before running, or rerun this task after adding one.
Homebrew and Ansible are installed by `run.sh` before the playbook starts.

## macOS System Settings automation

`roles/macos_system_settings/` groups preferences by settings area, using native
preference tasks where possible and separate AppleScripts for UI automation.
Its keyboard tasks configure key repeat and disable the keyboard backlight.

Run only the key-repeat settings (fastest repeat and shortest delay available in
macOS Settings: `KeyRepeat=2`, `InitialKeyRepeat=15`):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_key_repeat
```

The task moves both sliders to their rightmost positions in System Settings and
verifies them. This applies the active settings rather than only writing saved
preferences. It closes System Settings afterward and skips UI actions in check mode.

Run only the keyboard backlight task:

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_keyboard_backlight
```

Run only the trackpad task (maximum tracking speed):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_trackpad
```

The task selects Point & Click, moves Tracking speed to its maximum, verifies
the slider, and closes System Settings.

Run only the built-in display task (the **More Space** scaling preset):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_display
```

The task reads the rightmost of the five display scaling presets, selects it,
verifies the active built-in display resolution, and closes System Settings.
It expects the thumbnail view. `display.js` uses macOS's built-in JavaScript for
Automation to read display labels that AppleScript's System Events cannot decode.

Run only appearance settings (always **Dark**, rather than Auto):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_appearance
```

The task disables automatic appearance switching and applies Dark immediately
through System Events' appearance API. No logout is required; System Settings is
closed afterward if open. In check mode, only the saved Auto preference is checked.

Run the desktop settings (solid-black background and icon layout):

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_desktop
```

The task applies macOS's bundled `Solid Colors/Black.png` to each desktop exposed
by System Events on the connected displays and verifies the saved picture paths.
It does not open System Settings. Additional Spaces or displays added later may
need the task rerun. Wallpaper changes are skipped in check mode.

The desktop icon settings are: stacks grouped by **Kind**, sorted by **Date
Added**, **16 × 16** icons, minimum grid spacing (`1`), **12-point** text, and
labels on the **right**. Other Finder preferences are preserved. Finder restarts
only when the icon preferences change.

Run or preview just the icon settings:

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_desktop_icons --check
```

Remove `--check` to apply. Check mode reads preferences without changing them or
restarting Finder.

Run only the region screenshot shortcuts:

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_screenshot_shortcuts
```

**Cmd+Shift+4** copies a selected area to the clipboard. **Control+Cmd+Shift+4**
saves it to a file with the floating thumbnail enabled. Full-screen screenshot
shortcuts and the existing save location are preserved. The task updates the
native shortcut preferences and activates them for the current session. Add
`--check` for a read-only preview.

Disable the screenshot shutter sound:

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_screenshot_sound
```

This turns off **Sound → Play user interface sound effects**, which also silences
other interface effects such as moving files to Trash. It does not mute app audio
or change output volume, startup sound, or volume-key feedback. The task verifies
the switch and closes System Settings afterward. UI actions are skipped in check
mode. It also runs as part of the full bootstrap or with the `macos_sound` tag.

Run as the logged-in desktop user, without sudo. For UI automation,
the app running Ansible needs
Accessibility access under System Settings → Privacy & Security → Accessibility;
macOS may also ask for permission to automate System Events. The script opens
System Settings and checks the resulting control values. UI actions are skipped
in Ansible check mode.

The selectors target English System Settings on macOS 27. If Apple changes the
layout, update the scripts in `roles/macos_system_settings/files/`. A Mac
without keyboard backlight controls reports an error rather than claiming success.

## How to update .zshrc

 - Open roles/dotfiles/files/.zshrc
 - Edit
 - Save
 - Push

## Codex configuration

`roles/codex/files/config.toml` contains portable Codex preferences and is
used only to seed `~/.codex/config.toml` on a machine where that file does not
yet exist. `roles/codex/files/rules/default.rules` is the managed default rules
file; the Codex role symlinks it to `~/.codex/rules/default.rules`.

The seed intentionally excludes authentication, project trust, hook trust
hashes, desktop device IDs, plugin and marketplace discovery, MCP runtime
paths, and history/databases. Update the managed rules file in this repository
and rerun the playbook to apply it on another machine.

## Alfred preferences

From this repository, run `j sync-alfred-prefs` (or `just sync-alfred-prefs`).
From another directory, run
`just --justfile /path/to/workstation-setup/Justfile sync-alfred-prefs`.
The recipe restores `prefs.zip` to the current user's
`~/Library/Application Support/Alfred/Alfred.alfredpreferences` directory.
