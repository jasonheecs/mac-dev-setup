#!/usr/bin/env bash
set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
readonly ZPROFILE="${HOME}/.zprofile"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

find_homebrew_bin() {
    local brew_paths=(
        "/opt/homebrew/bin/brew"
        "/usr/local/bin/brew"
    )
    
    for brew_path in "${brew_paths[@]}"; do
        if [[ -f "$brew_path" ]]; then
            echo "$brew_path"
            return 0
        fi
    done
    
    return 1
}

add_homebrew_to_shell() {
    local brew_path=$1

    # Add to .zprofile only if not already there
    if ! grep -q "brew shellenv" "$ZPROFILE" 2>/dev/null; then
        log_info "Adding Homebrew to $ZPROFILE"

        {
            echo ''
            echo "eval \"\$(${brew_path} shellenv)\""
        } >> "$ZPROFILE"
    fi

    # Source for current shell
    eval "$(${brew_path} shellenv)"
}

install_homebrew() {
    if command -v brew &>/dev/null; then
        log_info "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL ${HOMEBREW_INSTALL_URL})"
    
    local homebrew_bin
    if homebrew_bin=$(find_homebrew_bin); then
        add_homebrew_to_shell "$homebrew_bin"
        log_info "Homebrew installed successfully"
    else
        log_error "Homebrew installation failed or not found"
        return 1
    fi
}

get_latest_python_version() {
    local python_version
    python_version=$(pyenv install -l \
        | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' \
        | tail -1 \
        | tr -d '[:space:]')

    if [[ -z "$python_version" ]]; then
        log_error "Could not determine latest Python version"
        return 1
    fi

    echo "$python_version"
}

# https://stackoverflow.com/questions/76028283/missing-the-lzma-lib/76310848
install_python_dependencies() {
    brew install readline xz
}

setup_pyenv() {
    if command -v pyenv &>/dev/null; then
        log_info "pyenv already installed"
        return 0
    fi

    log_info "Setup PyEnv..."
    brew install pyenv

    install_python_dependencies

    local python_version
    if ! python_version=$(get_latest_python_version); then
        return 1
    fi

    log_info "Installing Python ${python_version}..."
	pyenv install "${python_version}"
	pyenv global "${python_version}"
	pyenv rehash

    # Add pyenv to .zprofile
    if ! grep -q "pyenv init" "$ZPROFILE" 2>/dev/null; then
        log_info "Adding pyenv to $ZPROFILE"
        # shellcheck disable=SC2016
        echo 'eval "$(pyenv init --path)"' >> "$ZPROFILE"
    fi

    eval "$(pyenv init --path)"
}

install_ansible() {
    if command -v ansible &>/dev/null; then
        log_info "ansible already installed"
    else
        log_info "Installing Ansible..."
        pip install --upgrade pip
        pip install ansible
    fi

    if [[ -f "requirements.yml" ]]; then
        log_info "Installing Ansible Galaxy requirements..."
        ansible-galaxy install -r requirements.yml
    else
        log_warn "requirements.yml not found, skipping Galaxy installs"
    fi
}

run_ansible_playbook() {
    if [[ ! -f "main.yml" ]]; then
        log_error "main.yml not found in current directory"
        return 1
    fi

    log_info "Running Ansible playbook..."
    ansible-playbook ./main.yml
}

show_system_info() {
    log_info "System information:"
    echo "  Python version: $(python --version 2>&1)"
    echo "  pip version: $(pip --version 2>&1)"
    echo "  Ansible version: $(ansible --version 2>&1 | head -1)"
}

main() {
    log_info "Starting setup script..."

    # source .zprofile if it exists
    if [[ -r $ZPROFILE ]]; then
        # shellcheck source=/dev/null
        source "$ZPROFILE"
    fi

    install_homebrew
    setup_pyenv
    brew cleanup
    hash -r
    
    install_ansible
    show_system_info
    run_ansible_playbook

    log_info "Setup complete!"
}

main "$@"
