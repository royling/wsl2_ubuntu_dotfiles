config_home=${XDG_CONFIG_HOME:-$HOME/.config}

empty_line() {
  echo >>${1:-$HOME/.bashrc}
}

setup_git() {
  # optional: install gh cli

  # global config
  git config --global user.name "Roy Ling"
  git config --global user.email royling0024@gmail.com

  # gitalias
  local dir=$config_home/gitalias
  mkdir -p "$dir"
  curl https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt -o "$dir/gitalias.txt"
  git config --global include.path "$dir/gitalias.txt"
}

install_homebrew() {
  # install essentials ahead
  # sudo apt install -q -y build-essential procps curl file git
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
  test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  empty_line
  echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.bashrc
}

main() {
  touch ~/.hushlogin

  # add aliases
  if [ -f ~/.bash_aliases ]; then
    cat bash_aliases >>~/.bash_aliases
  else
    cp bash_aliases ~/.bash_aliases
  fi

  #cp ssh_config ~/.ssh/config

  # install essentials
  sudo apt install -y build-essential procps curl file git

  setup_git

  install_homebrew

  # Starship
  command -v starship >/dev/null || (
    echo "Installing starship to customize prompts..."
    curl -sS https://starship.rs/install.sh | sh
    empty_line
    echo 'eval "$(starship init bash)"' >>$HOME/.bashrc
    touch $config_home/starship.toml
    source $HOME/.bashrc
  )

  # Programming langs
  # Install Nvm (Node.js/npm)
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION:-0.40.1}/install.sh | bash
  source $HOME/.bashrc
  if [ -n $NODEJS_VERSION ]; then
    nvm install $NODEJS_VERSION
  else
    nvm install --lts
  fi
  echo "Use node.js version: $(node -v)"

  # Python
  brew install pyenv
  empty_line
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
  echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
  echo 'eval "$(pyenv init -)"' >>~/.bashrc

  # install pyenv-virtualenv plugin
  brew install pyenv-virtualenv
  echo 'eval "$(pyenv virtualenv-init -)"' >>~/.bashrc

  sudo apt install -y libsqlite3-dev # tcl tcltls tcllib tclx python3-tk tk-dev
  local py_ver=${PYTHON_VERSION:-3.11.10}
  pyenv install $py_ver
  pyenv global $py_ver

  # Golang
  wget -q -O /tmp/go.tar.gz https://go.dev/dl/go${GO_VERSION:-"1.23.1"}.linux-amd64.tar.gz
  if [ -d /usr/local/go ]; then
    sudo rm -rf /usr/local/go
  fi
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  empty_line
  echo 'export PATH=$PATH:/usr/local/go/bin' >>$HOME/.bashrc
  source $HOME/.bashrc
  echo "Installed go:" $(go version)

  # NeoVim/LazyVim
  brew install neovim
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
  cp ./nvim/lua/config/options.lua ~/.config/nvim/lua/config/
  empty_line
  echo 'alias vi=nvim' >>~/.bashrc
  echo 'alias vim=nvim' >>~/.bashrc
  echo "Installed Neovim with LazyVim."
  brew install ripgrep # required by telescope.live_grep

  # Bash completions (optional)
  git_ver=$(git version | awk '{print $3}')
  wget -q -O ~/.git-completion.bash https://raw.githubusercontent.com/git/git/refs/tags/v$git_ver/contrib/completion/git-completion.bash
  empty_line
  echo 'source ~/.git-completion.bash' >>~/.bashrc
  source ~/.bashrc

  # Docker engine
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  # see https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
  sudo usermod -aG docker $USER
  newgrp docker # activate the changes to groups
  docker version

  # minikube
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
}

# Set the following environment variables to configure the installation process:
# - PYTHON_VERSION (default: 3.11.10)
# - GO_VERSION (default: 1.23.1)
# - NVM_VERSION (default: 0.40.1)
# - NODEJS_VERSION (default: lts)

main "$@"
