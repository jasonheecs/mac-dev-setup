#!/usr/bin/env bash

install_homebrew() {
    # Check for Homebrew, install if we don't have it
    if test ! "$(which brew)"; then
        echo "Installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

        echo >> ~/.zprofile
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
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

        echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
        eval "$(pyenv init --path)"
    fi
}

install_ansible() {
	pip install ansible
}

function source_if_exists()
{
    if [[ -r $1 ]]; then
        source $1
    fi
}

source_if_exists ~/.zprofile
install_homebrew
setup_pyenv
brew cleanup

source ~/.zprofile
hash -r
python --version

# Run main ansible playbook
pip install ansible
ansible-galaxy install -r requirements.yml
if [[ "${IN_VAGRANT}" == "true" ]]; then
    ansible-playbook ./main.yml --extra-vars "ansible_become_pass=vagrant" -v
else
    ansible-playbook ./main.yml
fi
