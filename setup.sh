#!/usr/bin/env bash

install_homebrew() {
    # Check for Homebrew, install if we don't have it
    if test ! "$(which brew)"; then
        echo "Installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi

    brew install pyenv
    brew cleanup
}

setup_pyenv() {
	LATEST_PYTHON_VERSION="$(pyenv install --list | grep -v - | grep -v b | tail -1 | tr -d '[:space:]')"
	pyenv install "${LATEST_PYTHON_VERSION}"
	pyenv global "${LATEST_PYTHON_VERSION}"
	pyenv rehash
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
if test ! -f ~/.zprofile; then
    echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
fi
source ~/.zprofile
python --version

# Run main ansible playbook
pip install ansible
ansible-galaxy install -r requirements.yml
if [[ "${IN_VAGRANT}" == "true" ]]; then
    ansible-playbook ./main.yml --extra-vars "ansible_become_pass=vagrant" -v
else
	ansible-playbook ./main.yml --ask-become-pass
fi
