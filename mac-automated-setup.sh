#!/usr/bin/env bash
###############################################################################
#  Mac Bootstrap – Preferences, Homebrew, MAS apps
###############################################################################

###############################################################################
#  Colours / log helpers
###############################################################################
GREEN=$'\033[0;32m'; BLUE=$'\033[0;34m'
RED=$'\033[0;31m';   YELLOW=$'\033[1;33m'; NC=$'\033[0m'; BOLD=$'\033[1m'

log_info()    { printf '%sℹ️  %s%s\n'  "$BLUE"  "$1" "$NC"; }
log_success() { printf '%s✅ %s%s\n'  "$GREEN" "$1" "$NC"; }
log_warning() { printf '%s⚠️  %s%s\n' "$YELLOW" "$1" "$NC"; }
log_error()   { printf '%s❌ %s%s\n'  "$RED"   "$1" "$NC"; }

###############################################################################
#  Robust shell behaviour & cleanup
###############################################################################
set -Eeuo pipefail

cleanup() {
  tput cnorm || true
}
trap cleanup EXIT
trap 'log_error "Interrupted"; exit 1' INT HUP TERM
trap 'log_error "Line $LINENO (exit $?) – $BASH_COMMAND"; exit 1' ERR

###############################################################################
#  Progress-bar helpers
###############################################################################
BAR_W=30
show_bar() {                   # no trailing newline
  local pct=$1 msg=$2
  local done=$(( BAR_W * pct / 100 ))
  local todo=$(( BAR_W - done ))
  printf '\r\033[K%s┃%s' "$BLUE" "$NC"
  printf '%*s' "$done" '' | tr ' ' '█'
  printf '%*s' "$todo" '' | tr ' ' '░'
  printf '%s┃ %3d%% %s%s' "$BLUE" "$pct" "$msg" "$NC"
}
newline_below_bar() { printf '\n'; }

###############################################################################
#  Welcome
###############################################################################
welcome() {
  echo "======================================================"
  log_info   "🎯  Automated setup of Macs – Preferences & Apps"
  echo "======================================================"
  echo
  read -p "Press RETURN to continue or CTRL-C to quit…"
}

###############################################################################
#  Preferences (abridged)
###############################################################################
configure_system() {
  # https://macos-defaults.com
  log_info "Configuring System Preferences…"
  defaults write com.apple.dock orientation -string bottom
  defaults write com.apple.dock autohide -bool true
  mkdir -p "$HOME/Documents/Screenshots"
  defaults write com.apple.screencapture location -string "$HOME/Documents/Screenshots"
  defaults write com.apple.dock "static-only" -bool "true"
  defaults write com.apple.dock "show-recents" -bool "true"
  killall Dock Finder Safari SystemUIServer 2>/dev/null || true
  log_success "System Preferences applied"
}

###############################################################################
#  Homebrew – install or update/upgrade
###############################################################################
brew_bootstrap() {
  if ! command -v brew &>/dev/null; then
    log_info "Homebrew not found → installing…"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_info "Homebrew found → updating & upgrading…"
    brew update; brew upgrade; brew cleanup
  fi
  [[ $(uname -m) == arm64 ]] &&
    { eval "$(/opt/homebrew/bin/brew shellenv)";
      grep -q "/opt/homebrew" ~/.zprofile 2>/dev/null ||
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile; }
}

###############################################################################
#  Lists
###############################################################################
APPS=(
  # Casks
  "appcleaner:cask"
  "balenaetcher:cask"
  "discord:cask"
  "google-chrome:cask"
  "fork:cask"
  "rectangle:cask"
  "tradingview:cask"
  "antigravity:cask"
  "vlc:cask"
  "clipaste:cask"
  "sublime-text:cask"
  "clicker-for-youtube:cask"
  "microsoft-excel:cask"
  "microsoft-onenote:cask"
  "microsoft-word:cask"
  "corretto@25:cask"
  "intellij-idea-ce:cask"
  "excalidrawz:cask"
  "whatsapp:cask"
  "tailscale-app:cask"
  "google-drive:cask" 


  # Formulae
  "wget:formula"
  "tmux:formula"
  "zsh-autosuggestions:formula"
  "zsh-syntax-highlighting:formula"
  "zsh-history-substring-search:formula"
  "powerlevel10k:formula"
  "pinentry-mac:formula"
  
)


###############################################################################
#  Portable helper – fill array with command output (no mapfile needed)
###############################################################################
cmd_to_array() {                                 # $1 = array-name  $2 = cmd…
  local _line
  eval "$1=()"
  while IFS= read -r _line; do
    eval "$1+=(\"\$_line\")"
  done < <(eval "$2")
}

###############################################################################
#  Install Brew items (skip already installed)
###############################################################################
install_brew_items() {
  INST_FORMULAE=()
  INST_CASKS=()
  cmd_to_array INST_FORMULAE "brew list --formula"
  cmd_to_array INST_CASKS    "brew list --cask 2>/dev/null || true"

  local total=${#APPS[@]} current=0 kind name pct
  show_bar 0 "starting…"; newline_below_bar
  for entry in "${APPS[@]}"; do
    current=$((current+1)); pct=$(( current * 100 / total ))
    IFS=':' read -r name kind flag <<< "$entry"

    if [[ $kind == cask ]] && [[ " ${INST_CASKS[@]-} " == *" $name "* ]] ||
       [[ $kind == formula ]] && [[ " ${INST_FORMULAE[@]-} " == *" $name "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar; continue
    fi

    show_bar "$pct" "↓ $name"; newline_below_bar
    if [[ $kind == cask ]]; then
      if [[ $flag == "no-quarantine" ]]; then
        brew install --cask --no-quarantine "$name"
      else
        brew install --cask "$name"
      fi
    else
      brew install "$name"
    fi
    show_bar "$pct" "✔︎ $name"; newline_below_bar
  done
  brew upgrade; brew cleanup
}



###############################################################################
#  Z-shell config (same as previous)
###############################################################################
setup_zsh() {
  log_info "Configuring Z-shell…"
  [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
  prefix=$(brew --prefix)
  cat > ~/.zshrc <<EOF
[[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]] &&
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"

source $prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh
source $prefix/share/powerlevel10k/powerlevel10k.zsh-theme

autoload -U compinit && compinit
alias c='clear' rmm='rm -rf' lss='ls -lah' reload='source ~/.zshrc'
alias t='tmux' e='code' z='zed' mtop='macmon'
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
  [[ $SHELL != "$(which zsh)" ]] && chsh -s "$(which zsh)"
  log_success "Z-shell configured"
}

setAutoUpdate() {
  brew autoupdate start --upgrade --cleanup --immediate --sudo 
}
###############################################################################
#  Main
###############################################################################
main() {
  welcome
  newline_below_bar
  brew_bootstrap
  newline_below_bar
  configure_system
  newline_below_bar
  log_info "Installing Homebrew apps…"; newline_below_bar
  install_brew_items
  newline_below_bar
  setAutoUpdate
  newline_below_bar
  setup_zsh
  echo -e "\n${GREEN}${BOLD}✨  All done! Consider rebooting.${NC}"
}

main "$@"
