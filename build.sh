#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version       : 202207041633-git
# @Author        : Jason Hempstead
# @Contact       : jason@casjaysdev.com
# @License       : LICENSE.md
# @ReadME        : build.sh --help
# @Copyright     : Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @Created       : Monday, Jul 04, 2022 16:33 EDT
# @File          : build.sh
# @Description   : Installer script for st
# @TODO          :
# @Other         :
# @Resource      :
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0")"
VERSION="202207041633-git"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
if [[ "$1" == "--debug" ]]; then shift 1 && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"; fi
trap 'exitCode=${exitCode:-$?};[ -n "$BUILD_SH_TEMP_FILE" ] && [ -f "$BUILD_SH_TEMP_FILE" ] && rm -Rf "$BUILD_SH_TEMP_FILE" &>/dev/null;exit ${exitCode:-$?}' EXIT
set -Eo pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup build function
__make_build() {
  local exitCode=1
  local exitCode_make=0
  local exitCode_cmake=0
  local exitCode_configure=0
  if [[ -f "./config.mk" ]]; then
    grep -q 'PREFIX = ' "./config.mk" &&
      sed -i 's|PREFIX =.*|PREFIX = '$BUILD_DESTDIR'|g' "./config.mk"
  fi
  if [[ -f "configure" ]]; then
    printf_color "$GREEN" "running configure"
    ./configure \
      --prefix="$BUILD_DESTDIR" 2>&1 |
      tee -a "$BUILD_LOG_FILE" &>/dev/null
    exitCode_configure=$?
  fi
  if [[ -f "Makefile" ]]; then
    printf_color "$GREEN" "running make"
    make clean 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null &&
      make -j$(nproc) 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null &&
      sudo make install DESTDIR="$BUILD_DESTDIR" 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null
    exitCode_make=$?
  fi
  if [[ -f "CMakeLists.txt" ]]; then
    mkdir build && cd build || exit 10
    cmake .. 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null &&
      make -j$(nproc) 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null &&
      sudo make install 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null &&
      exitCode_cmake=$?
  fi
  [[ $exitCode_configure = 0 ]] &&
    [[ $exitCode_make = 0 ]] &&
    [[ $exitCode_cmake = 0 ]] &&
    exitCode=0
  return "${exitCode:-$?}"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Set main functions
__run_git() {
  if [[ -d ".git" ]]; then
    printf_color "$CYAN" "Updating the git repo"
    git reset --hard && git pull 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null
    if [[ $? = 0 ]]; then
      return 0
    else
      printf_color "$RED" "Failed to clone from $BUILD_SRC_URL"
      exit 1
    fi
  elif [[ -n "$BUILD_SRC_URL" ]]; then
    printf_color "$CYAN" "Cloning the git repo"
    git clone "$BUILD_SRC_URL" "$BUILD_SRC_DIR" 2>&1 | tee -a "$BUILD_LOG_FILE" &>/dev/null
    if [[ $? = 0 ]]; then
      return 0
    else
      printf_color "$RED" "Failed to clone from $BUILD_SRC_URL"
      exit 1
    fi
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__check_log() {
  local exitCode="$?"
  if [[ -f "$BUILD_LOG_FILE" ]]; then
    errors="$(grep 'fatal error' "$BUILD_LOG_FILE" || echo '')"
    if [[ -n "$errors" ]] || [[ "$exitCode" -ne 0 ]]; then
      printf_color "$RED" "The following errors have occurred:"
      echo -e "$errors"
      printf_color "$YELLOW" "Log file saved to $BUILD_LOG_FILE"
      exitCode=1
    else
      rm -Rf "$BUILD_LOG_FILE" &>/dev/null
      printf_color "$GREEN" "Build of $BUILD_NAME has completed without error"
      exitCode=0
    fi
  fi
  return "${exitCode:-$?}"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf_color() { echo -e "\t\t${1:-}${2:-}${NC}"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__help() {
  [[ -z "$ARRAY" ]] || local array="[${ARRAY//,/ }]"
  [[ -z "$LONGOPTS" ]] || local opts="[--${LONGOPTS//,/ --}]"
  printf_color "$BLUE" "Usage: $APPNAME $opts $array"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for needed applications
type -P bash &>/dev/null || { printf_color "$RED" "Missing: bash" && exit 1; }
type -P make &>/dev/null || { printf_color "$RED" "Missing: make" && exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
exitCode=10
NC="$(tput sgr0 2>/dev/null)"
RESET="$(tput sgr0 2>/dev/null)"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
ORANGE="\033[0;33m"
LIGHTRED='\033[1;31m'
BG_GREEN="\[$(tput setab 2 2>/dev/null)\]"
BG_RED="\[$(tput setab 9 2>/dev/null)\]"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Application Folders

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show warn message if variables are missing

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set options
SETARGS="$*"
SHORTOPTS=""
LONGOPTS="version,help,raw"
ARRAY=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup application options
setopts=$(getopt -o "$SHORTOPTS" --long "$LONGOPTS" -a -n "$APPNAME" -- "$@" 2>/dev/null)
eval set -- "${setopts[@]}" 2>/dev/null
while :; do
  case $1 in
  --help)
    shift 1
    __help
    exit
    ;;
  --version)
    shift 1
    printf_color "$YELLOW" "$APPNAME Version: $VERSION\n"
    exit
    ;;
  --raw)
    shift 1
    printf_color() { shift 1 && echo -e "$1"; }
    ;;
  --)
    shift 1
    ARGS="$1"
    set --
    break
    ;;
  esac
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables
BUILD_NAME="st"
BUILD_SRC_URL="${BUILD_SRC_URL:-https://gitlab.com/dwt1/st-distrotube}"
BUILD_SRC_DIR="${BUILD_SRC_DIR:-$HOME/.local/share/$BUILD_NAME/source}"
BUILD_LOG_FILE="${BUILD_LOG_FILE:-/tmp/$BUILD_NAME_build.log}"
if command -v "$BUILD_NAME" | grep -q '^/bin' || command -v "$BUILD_NAME" | grep -q '^/usr/bin'; then
  BUILD_DESTDIR="/usr"
else
  BUILD_DESTDIR="${BUILD_DESTDIR:-/usr/local}"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install required packages
# if cmd_exists apt-get; then
#   if cmd_exists pkmgr; then
#     for pkg in LIST; do
#        printf_color "$CYAN" "Installing $pkg"
#        pkmgr silent install $pkg &>/dev/null
#        [[ $? = 0 ]] && printf_color "$GREEN" "Installed $pkg" || printf_color "$RED" "Failed to installed $pkg"
#     done
#   fi
# elif cmd_exists dnf; then
#   if cmd_exists pkmgr; then
#     for pkg in LIST; do
#        printf_color "$CYAN" "Installing $pkg"
#        pkmgr silent install $pkg &>/dev/null
#        [[ $? = 0 ]] && printf_color "$GREEN" "Installed $pkg" || printf_color "$RED" "Failed to installed $pkg"
#     done
#   fi
# elif cmd_exists yum; then
#   if cmd_exists pkmgr; then
#     for pkg in LIST; do
#        printf_color "$CYAN" "Installing $pkg"
#        pkmgr silent install $pkg &>/dev/null
#        [[ $? = 0 ]] && printf_color "$GREEN" "Installed $pkg" || printf_color "$RED" "Failed to installed $pkg"
#     done
#   fi
# fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
if [[ -d "$BUILD_SRC_DIR" ]]; then
  if ! builtin cd "$BUILD_SRC_DIR"; then
    printf_color "$RED" "Failed to cd into $BUILD_SRC_DIR"
    exit 1
  fi
  __run_git
  __make_build
  __check_log
  exitCode=$?
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check
if [[ "$exitCode" -eq 0 ]] && builtin type -P "$BUILD_NAME"; then
  printf_color "$GREEN" "Successfully installed $BUILD_NAME"
  exitCode=0
else
  printf_color "$RED" "Failed to install $BUILD_NAME"
  exitCode=1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
