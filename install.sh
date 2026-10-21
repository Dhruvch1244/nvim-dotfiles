#!/usr/bin/env bash
# Install this Neovim setup: dependencies (optional), a backup of any existing
# config, and a symlink ~/.config/nvim -> <this repo>/nvim.
#
#   ./install.sh            install dependencies, then link the config
#   ./install.sh --no-deps  only link the config
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG_HOME/nvim"
MIN_NVIM="0.11.0"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  \033[36m•\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

nvim_ok() {
  have nvim || return 1
  local v
  v="$(nvim --version | head -1 | sed -E 's/^NVIM v([0-9.]+).*/\1/')"
  version_ge "$v" "$MIN_NVIM"
}

confirm() {
  local reply
  read -r -p "  $1 [Y/n] " reply || true
  [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# Official release build into ~/.local when the distro's Neovim is too old
install_nvim_release() {
  local arch os url dir
  os="$(uname -s)"; arch="$(uname -m)"
  [ "$os" = "Linux" ] || { warn "Install Neovim >= $MIN_NVIM yourself: https://github.com/neovim/neovim/releases"; return; }
  case "$arch" in
    x86_64) url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz" ;;
    *) warn "No prebuilt Neovim for $arch; install >= $MIN_NVIM yourself"; return ;;
  esac
  dir="$HOME/.local/opt/nvim"
  info "Downloading the latest Neovim release to $dir"
  rm -rf "$dir" && mkdir -p "$dir" "$HOME/.local/bin"
  curl -fsSL "$url" | tar -xz -C "$dir" --strip-components=1
  ln -sf "$dir/bin/nvim" "$HOME/.local/bin/nvim"
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "Add ~/.local/bin to your PATH" ;; esac
}

install_deps() {
  bold "Dependencies"
  # git, ripgrep, fd, lazygit, a C compiler (treesitter), make/unzip/curl (Mason), node (LSPs), tree-sitter CLI
  if have pacman; then
    local pkgs=(neovim git ripgrep fd lazygit gcc make unzip curl nodejs npm tree-sitter-cli)
    info "Arch: sudo pacman -S --needed ${pkgs[*]}"
    confirm "Install them?" && sudo pacman -S --needed "${pkgs[@]}"
  elif have brew; then
    local pkgs=(neovim git ripgrep fd lazygit node tree-sitter)
    info "Homebrew: brew install ${pkgs[*]}"
    confirm "Install them?" && brew install "${pkgs[@]}"
  elif have apt-get; then
    local pkgs=(git ripgrep fd-find build-essential unzip curl nodejs npm)
    info "Debian/Ubuntu: sudo apt-get install -y ${pkgs[*]}"
    if confirm "Install them?"; then
      sudo apt-get update && sudo apt-get install -y "${pkgs[@]}"
      # Debian names the binary fdfind
      if ! have fd && have fdfind; then mkdir -p "$HOME/.local/bin" && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
    fi
    have lazygit || warn "lazygit isn't in apt: https://github.com/jesseduffield/lazygit#ubuntu (optional)"
  elif have dnf; then
    local pkgs=(neovim git ripgrep fd-find lazygit gcc make unzip curl nodejs npm tree-sitter-cli)
    info "Fedora: sudo dnf install -y ${pkgs[*]}"
    confirm "Install them?" && sudo dnf install -y "${pkgs[@]}"
  else
    warn "Unknown package manager. Install: neovim >= $MIN_NVIM, git, ripgrep, fd, gcc, make, unzip, curl, node/npm, tree-sitter CLI"
  fi

  if ! nvim_ok; then
    warn "Neovim >= $MIN_NVIM not found (distro packages are often too old)"
    confirm "Download the official release into ~/.local?" && install_nvim_release
  fi

  if ! have tree-sitter && have npm; then
    info "Installing the tree-sitter CLI into ~/.local (needed to build syntax parsers)"
    npm install -g --prefix "$HOME/.local" tree-sitter-cli >/dev/null || warn "tree-sitter CLI install failed (optional)"
  fi

  echo
  info "Optional extras: a JDK (Java support), python3 (Python debugging), the 'claude' CLI (AI commits)"
  info "Use a Nerd Font in your terminal for icons: https://www.nerdfonts.com (e.g. JetBrainsMono Nerd Font)"
}

link_config() {
  bold "Linking $TARGET -> $REPO/nvim"
  mkdir -p "$CONFIG_HOME"
  if [ -L "$TARGET" ] && [ "$(readlink -f "$TARGET")" = "$(readlink -f "$REPO/nvim")" ]; then
    info "Already linked"
    return
  fi
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    local backup
    backup="$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$TARGET" "$backup"
    info "Backed up your existing config to $backup"
  fi
  ln -s "$REPO/nvim" "$TARGET"
  info "Linked"
}

main() {
  echo
  bold "✦ Neovim setup"
  echo
  [ "${1:-}" = "--no-deps" ] || install_deps
  echo
  link_config
  echo
  if nvim_ok; then
    bold "Installing plugins (first run)…"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || warn "Plugin install had errors; open nvim and run :Lazy"
  fi
  echo
  bold "Done! Start it with: nvim"
  info "On first start it asks your name for the dashboard (change it later with :SetName)"
  info "Language servers install in the background on first start (see :Mason)"
}

main "$@"
