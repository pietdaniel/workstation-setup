#!/bin/bash

# Install Homebrew if not installed
if ! command -v brew > /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval $(/opt/homebrew/bin/brew shellenv)') >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Check if Ansible is installed
if ! command -v ansible > /dev/null; then
    echo "Ansible is not installed. Installing Ansible..."
    # Install Ansible using Homebrew
    brew install ansible
fi

# Verify Ansible installation
if command -v ansible > /dev/null; then
    echo "Ansible is installed. Running the playbook..."
    # Run your Ansible playbook here. Replace 'your_playbook.yml' with the path to your playbook
    ansible-playbook -vvv -i localhost, playbook.yaml --connection=local
else
    echo "Failed to install Ansible. Exiting..."
    exit 1
fi
