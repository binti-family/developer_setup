#!/bin/bash

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# THIS IS A PUBLIC SCRIPT VIEWABLE BY ANYONE ON THE INTERNET!
# DO NOT PUT ANYTHING SENSITIVE IN HERE!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# =======================================
# GETS CALLED AT THE BOTTOM OF THIS FILE.
# =======================================
function run() {
  printf "\n\n💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙\n"
  printf "💙 ${BBlue}BINTI CORE MACOS INSTALLER${Color_Off} 💙\n"
  printf "💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙💙\n\n\n"

  printf "This will check, and install if needed, core dependencies required\n"
  printf "for either VM-only or laptop-based development.\n\n"

  printf "First we're going to check:\n"
  printf "${Indent}- Which dependencies you have: ✅\n"
  printf "${Indent}- Which are missing: 🚫\n"
  printf "${Indent}- Show you the commands we'd run to install anything needed\n\n"
  printf "${BBlue}Would you like to continue?${Color_Off} [${Green}y${BRed}N${Color_Off}]${Color_Off}"
  read -p " " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_all_dependencies

    if $all_dependencies_met; then
      post_dependencies_met
    else
      printf "\n\n${Yellow}Looks like you have some unmet dependencies!${Color_Off}\n"
      printf "Take a look above at the commands that we're planning on running to meet dependency needs.\n"
      printf "If you're comfortable with that, continue. Otherwise feel free to meet those dependencies however you'd like.\n\n"
      printf "${BBlue}Would you like to continue?${Color_Off} [${Green}y${BRed}N${Color_Off}]${Color_Off}"
      read -p " " -n 1 -r
      echo    # (optional) move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        dry_run=false
        run_all_dependencies
        post_dependencies_met
      else
        echo "See ya later!"
        exit
      fi
    fi
  else
    echo "See ya later!"
    exit
  fi
}

function run_all_dependencies() {
  run_all_non_installable_dependencies
  run_all_installable_dependencies
}

function post_dependencies_met() {
  printf "\n\n${BGreen}FANTASTIC! ${Green}You're all set to go!${Color_Off}\n"

  gh auth status &>/dev/null
  if [ $? -eq 0 ]; then
    if [ -d "$HOME/family" ]; then
      printf "🚨 ${Red}Looks like you already have a directory at '$HOME/family'${Color_Off}\n"
      printf "Probably best to get a new shell, go there, pull 'main', and run one of:\n"
      printf "${Indent}'${Yellow}./scripts/b/lib/setup_vm_laptop${Color_Off}' (if you want to use a development VM)\n"
      printf "${Indent}'${Yellow}./scripts/b/lib/setup_mac_for_local_development.sh${Color_Off}' (if you want to develop directly on this machine)\n"
    else
      clone_family
    fi
  else
    printf "${Yellow}You need to authenticate with 'gh'. About to run 'gh auth login --web'...${Color_Off}\n"
    gh auth login --web
    clone_family
  fi
}

function clone_family() {
  printf "${Green}Looks like you are authenticated with 'gh'. Cloning 'family' repo to '$HOME/family'${Color_Off}\n"
  cd $HOME
  gh repo clone binti-family/family
  printf "${BGreen}Repo cloned! Next, get a new shell, 'cd $HOME/family', and run one of:\n"
  printf "${Indent}'${Yellow}./scripts/b/lib/setup_mac_for_vm_development.sh${Color_Off}' (RECOMMENDED: if you want to use a development VM)\n"
  printf "${Indent}'${Yellow}./scripts/b/lib/setup_mac_for_local_development.sh${Color_Off}' (EXPERIMENTAL: if you want to develop directly on this machine)\n"
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
  installable_dependency_gh
  echo "==========================================================="
}

function installable_dependency_xcode_cli() {
  if xcode-select -p &>/dev/null; then
    printf "✅ - 'xcode' CLI\n"
  else
    all_dependencies_met=false
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
    all_dependencies_met=false
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

function installable_dependency_gh() {
  command -v gh &>/dev/null
  if [ $? -eq 0 ]; then
    printf "✅ - 'gh'\n"
  else
    all_dependencies_met=false
    printf "🚫 - 'gh'\n"
    printf "$message_installing"

    local command=$(cat <<'EOF'
brew install gh
git config --global credential.https://github.com.helper '!/opt/homebrew/bin/gh auth git-credential'
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
all_dependencies_met=true

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
run
