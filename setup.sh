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
	if test ! "$(which pyenv)"; then
		LATEST_PYTHON_VERSION="$(pyenv install --list | grep -v - | grep -v b | tail -1 | tr -d '[:space:]')"
		pyenv install "${LATEST_PYTHON_VERSION}"
		pyenv global "${LATEST_PYTHON_VERSION}"
		pyenv rehash
	fi
}

install_ansible() {
	pip install ansible
}


install_homebrew
setup_pyenv
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
source ~/.bashrc
python --version

# Run main ansible playbook
pip install ansible
ansible-galaxy install -r requirements.yml
if [[ "${IN_VAGRANT}" == "true" ]]; then
    ansible-playbook ./main.yml --extra-vars "ansible_become_pass=vagrant" -v
else
	ansible-playbook ./main.yml --ask-become-pass
fi
