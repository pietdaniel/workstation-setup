#!/bin/bash
set -e

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "amzn" ]]; then
            echo "amazon"
        elif [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID" == "fedora" ]]; then
            echo "fedora"
        else
            echo "unsupported"
        fi
    else
        echo "unsupported"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"

# Install dependencies based on OS
case "$OS" in
    darwin)
        # Install Homebrew if not installed
        if ! command -v brew &>/dev/null; then
            echo "Homebrew is not installed. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            (echo; echo 'eval $(/opt/homebrew/bin/brew shellenv)') >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        # Install Ansible via Homebrew
        if ! command -v ansible &>/dev/null; then
            echo "Installing Ansible via Homebrew..."
            brew install ansible
        fi
        ;;

    amazon)
        # Install Ansible via pip on Amazon Linux
        if ! command -v ansible &>/dev/null; then
            echo "Installing pip and Ansible on Amazon Linux..."
            sudo dnf install -y python3-pip
            pip3 install --user ansible
            # Add local bin to PATH for this session
            export PATH="$HOME/.local/bin:$PATH"
        fi
        ;;

    fedora)
        # Install Ansible via dnf on Fedora
        if ! command -v ansible &>/dev/null; then
            echo "Installing Ansible via dnf..."
            sudo dnf install -y ansible
        fi
        ;;

    *)
        echo "Unsupported operating system. Exiting..."
        exit 1
        ;;
esac

# Verify Ansible installation and run playbook
if command -v ansible &>/dev/null; then
    echo "Ansible is installed. Running the playbook..."
    ansible-playbook -vvv -i localhost, playbook.yaml --connection=local
else
    echo "Failed to install Ansible. Exiting..."
    exit 1
fi

# Post-install instructions (macOS only)
if [[ "$OS" == "darwin" ]]; then
    echo ""
    echo "If this is the first time be sure to run:"
    echo "  yabai --start-service"
    echo "  skhd --start-service"
fi
