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

`roles/macos_system_settings/` owns UI automation, with separate task files and
AppleScripts for each settings area. Its keyboard task disables automatic
keyboard brightness adjustment and sets the backlight brightness to zero.

Run only the keyboard backlight task:

```sh
ANSIBLE_BECOME_ASK_PASS=false ansible-playbook -i localhost, playbook.yaml --connection=local --tags macos_keyboard_backlight
```

Run as the logged-in desktop user, without sudo. The app running Ansible needs
Accessibility access under System Settings → Privacy & Security → Accessibility;
macOS may also ask for permission to automate System Events. The script opens
System Settings and checks the resulting control values. UI actions are skipped
in Ansible check mode.

The selectors target English System Settings on macOS 27. If Apple changes the
layout, update `roles/macos_system_settings/files/keyboard.applescript`. A Mac
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
