#!/usr/bin/env bash

function find_homebrew_bin() {
    # Find homebrew
    if [ -f "/opt/homebrew/bin/brew" ]; then
        echo "/opt/homebrew/bin/brew"
        return 0
    elif [ -f "/usr/local/bin/brew" ]; then
        echo "/usr/local/bin/brew"
        return 0
    else
        # Homebrew not found
        return 1
    fi
}

function add_homebrew_path() {
    local path=$1

    # Add to .zprofile only if not already there
    if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
        echo '' >> ~/.zprofile
        echo "eval \"\$(${path} shellenv)\"" >> ~/.zprofile
    fi

    # Source for current shell
    eval "$(${path} shellenv)"
}

install_homebrew() {
    # Check for Homebrew, install if we don't have it
    if test ! "$(which brew)"; then
        echo "Installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

        local homebrew_bin
        if homebrew_bin=$(find_homebrew_bin); then
            add_homebrew_path "${homebrew_bin}"
        else
            echo "Error: Homebrew installation failed or not found"
            return 1
        fi
    fi
}

setup_pyenv() {
    if test ! "$(which pyenv)"; then
        echo "Setup PyEnv..."
        brew install pyenv
        LATEST_PYTHON_VERSION="$(pyenv install -l | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d '[:space:]')"
    	pyenv install "${LATEST_PYTHON_VERSION}"
    	pyenv global "${LATEST_PYTHON_VERSION}"
    	pyenv rehash

        # shellcheck disable=SC2016
        echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
        eval "$(pyenv init --path)"
    fi
}

install_ansible() {
    echo "Installing Ansible..."
	pip install ansible
}


# source .zprofile if it exists
if [[ -r ~/.zprofile ]]; then
    # shellcheck source=/dev/null
    source ~/.zprofile
fi

install_homebrew
setup_pyenv
brew cleanup
hash -r
python --version

# Run main ansible playbook
pip install ansible
ansible-galaxy install -r requirements.yml
ansible-playbook ./main.yml
