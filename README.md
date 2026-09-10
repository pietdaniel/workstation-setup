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
