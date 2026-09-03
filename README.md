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
yet exist. The role installs the macOS Codex cask, but never replaces, merges,
or symlinks an existing config.

The seed intentionally excludes authentication, project trust, hook trust
hashes, desktop device IDs, plugin and marketplace discovery, MCP runtime
paths, and history/databases. Once seeded, all Codex-managed changes stay local
to that machine and never modify this repository.

# TODO

 - alfred just command includes the whole path which is wrong
 - capslock / escape swap needs to be a bootstrap script
