#!/bin/bash

# -e tells bash to exit immediately on error, instead of its default of continuing
# -x prints out each command being run for easier debugging
# set -e

# =======================================
# GETS CALLED AT THE BOTTOM OF THIS FILE.
# =======================================
function run() {
  printf "\n\n💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙\n"
  printf "💙 BINTI LAPTOP DEVELOPMENT INSTALLER 💙\n"
  printf "💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙\n\n\n"

  if $dry_run; then
    printf "🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵\n"
    printf "🌵 This script defaults to being a dry run! Add '${Yellow}--wet-run${Color_Off}' when you're ready to execute it for reals! 🌵\n"
    printf "🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵\n\n"
  fi

  run_all_non_installable_dependencies
  run_all_installable_dependencies
}

# ============================
# NON-INSTALLABLE DEPENDENCIES
# ============================
function run_all_non_installable_dependencies() {
  fail=0

  echo "=================================================="
  printf "${BWhite}Checking for dependencies we don't auto-install...${Color_Off}\n\n"

  non_installable_dependency_os_and_chip
  if [ $? -eq 1 ]; then
    fail=1
  fi

  non_installable_dependency_zsh
  if [ $? -eq 1 ]; then
    fail=1
  fi

  if [ $fail -eq 1 ]; then
    printf "\n\n🛑 ${BRed}Please address the above errors, get a new terminal, and run this installation again${Color_Off}\n"
    exit 1
  fi
  echo "=================================================="
}

function non_installable_dependency_os_and_chip() {
  if [[ $(uname -s) != 'Darwin' ]] || [[ $(uname -p) != "arm" ]]; then
    printf "🚫 - ${Red}OS & Chip Architecture${Color_Off} - This script is only designed to work on macOS machine's with Apple Silicon chips!\n"
    return 1
  else
    printf "✅ - OS & Chip Architecture\n"
    return 0
  fi
}

function non_installable_dependency_zsh() {
  if ! $shell_is_zsh; then
    printf "🚫 - ${Red}ZSH${Color_Off} - This script is only designed to work with 'zsh' and you use '$shell_bin'!\n"
    return 1
  else
    printf "✅ - ZSH Shell\n"
    return 0
  fi
}

# ========================
# INSTALLABLE DEPENDENCIES
# ========================
function run_all_installable_dependencies() {
  printf "\n===========================================================\n"
  printf "${BWhite}Checking for, and possibly installing, all dependencies...${Color_Off}\n\n"

  installable_dependency_xcode_cli
  echo "-----------------------------------------------------------"
  installable_dependency_brew
  echo "-----------------------------------------------------------"
  installable_dependency_gcloud
  echo "-----------------------------------------------------------"
  installable_dependecy_asdf
  echo "-----------------------------------------------------------"
  installable_dependency_libpq
  echo "-----------------------------------------------------------"

  installable_dependency_kubectl
  echo "==========================================================="
}

function installable_dependency_xcode_cli() {
  if xcode-select -p &>/dev/null; then
    printf "✅ - 'xcode' CLI\n"
  else
    printf "🚫 - 'xcode' CLI\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
xcode-select --install
EOF
)

    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
      wait_for_xcode_to_install
    fi
  fi
}

xcode_install_counter=0
function wait_for_xcode_to_install() {
  if xcode-select -p &>/dev/null; then
    printf "✅ - 'xcode' CLI\n"
  else
    local seconds=$((xcode_install_counter * 10))
    printf "Waiting for xcode tools to be installed. Sleeping for 10 seconds... (elapsed: $seconds seconds)\r"
    xcode_install_counter=$((xcode_install_counter + 1))
    sleep 10
    wait_for_xcode_to_install
  fi
}

function installable_dependency_brew() {
  if command -v brew &>/dev/null; then
    printf "✅ - 'brew'\n"
  else
    printf "🚫 - 'brew'\n"
    printf "$message_installing"

    # See: https://brew.sh
    local command=$(cat <<'EOF'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
EOF
)

    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
      echo >> $HOME/.zprofile
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
}

function installable_dependency_gcloud() {
  if command -v gcloud &>/dev/null; then
    printf "✅ - 'gcloud'\n"
  else
    printf "🚫 - 'gcloud'\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
brew install --cask gcloud-cli
EOF
)

    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
    fi
  fi
}

function installable_dependecy_asdf() {
  if command -v asdf &>/dev/null; then
    printf "✅ - 'asdf'\n"
  else
    printf "🚫 - 'asdf'\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
brew install asdf
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zprofile
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
EOF
)

    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
      export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    fi
  fi
}

function installable_dependency_libpq() {
  # Note we'll want to ditch the `@16` when we bump to a more modern pg version
  brew list libpq@16 &>/dev/null
  if [ $? -eq 0 ]; then
    printf "✅ - 'libpq' (needed for 'pg' gem)\n"
  else
    printf "🚫 - 'libpq' (needed for 'pg' gem)\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
brew install libpq@16
echo 'export PATH="/opt/homebrew/opt/libpq@16/bin:$PATH"' >> ~/.zprofile
EOF
)
    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
      export PATH="/opt/homebrew/opt/libpq@16/bin:$PATH"
    fi
  fi
}

function installable_dependency_kubectl() {
  if command -v kubectl &>/dev/null; then
    printf "✅ - 'kubectl'\n"
  else
    printf "🚫 - 'kubectl'\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
gcloud components install kubectl
EOF
)

    if $dry_run; then
      printf "$message_dry_run"
      printf "$command\n"
    else
      eval "$command"
    fi
  fi
}

# =============================================================================
# START OF ARGUMENT PARSING. FOR SOME REASON PUTTING THIS INTO FUNCTIONS BREAKS
# =============================================================================
dry_run=true
for var in "$@"; do
  if [ $var = "--wet-run" ]; then
    dry_run=false
  fi
done

shell_is_zsh=false
# Gnarly bash to: split $SHELL on `/` and get the last element of array
arrSHELL=(${SHELL//\// })
shell_bin=${arrSHELL[${#arrSHELL[@]} - 1]}
if [ $shell_bin = "zsh" ]; then
  shell_is_zsh=true
fi

# =======================================================================
# BELOW IS JUST PLACEHOLDER STUFF BECAUSE VSCODE WON'T COLLAPSE IT NICELY
# =======================================================================
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# How many spaces to use for indentation
Indent="      "
message_dry_run="🌵 ${BYellow}This is a dry run! Below is what would have run:${Color_Off} 🌵\n"
message_installing="${Indent}Installing...\n"

# ==================================================================
# KICKS EVERYTHING OFF. THIS WAY WE CAN USE FUNCTIONS AND BE CLEANER
# THIS HAS TO BE LAST FOR VARIABLES TO BE IN SCOPE
# ==================================================================
printf "✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋\n"
printf "This is ${BRed}${URed}EXPERIMENTAL!${Color_Off} Meaning if you're not comfortable\n"
printf "digging yourself out of a weird command-line-based\n"
printf "hole this probably is not for you and you should\n"
printf "stick to VM development!\n"
printf "✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋✋\n\n"

read -p "Would you like to continue? [yN] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  run
else
  echo "See ya later!"
fi
