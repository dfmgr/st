#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version       : 202207040852-git
# @Author        : Jason Hempstead
# @Contact       : jason@casjaysdev.com
# @License       : LICENSE.md
# @ReadME        : build.sh --help
# @Copyright     : Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @Created       : Monday, Jul 04, 2022 08:52 EDT
# @File          : build.sh
# @Description   : script to build dmenu
# @TODO          :
# @Other         :
# @Resource      :
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202207040852-git"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
if [[ "$1" == "--debug" ]]; then shift 1 && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"; fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Set functions
__help() { printf_color "$BLUE" "Usage: $APPNAME []"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__list_options() { echo "${1:-$ARRAY}" | sed 's|:||g;s|'$2'| '$3'|g' 2>/dev/null; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional functions
printf_color() { echo -e "\t\t${1:-}${2:-}${NC}"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for needed applications
type -P bash &>/dev/null || { echo "Missing: bash" && exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
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
exitCode=

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Application Folders

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show warn message if variables are missing

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set options
SETARGS="$*"
SHORTOPTS=""
LONGOPTS="options,version,help,raw"
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
  --options)
    shift 1
    [ -n "$1" ] || printf_color "$PURPLE" "Current options for ${PROG:-$APPNAME}\n"
    [ -z "$SHORTOPTS" ] || __list_options "Short Options" "-$SHORTOPTS" ',' '-'
    [ -z "$LONGOPTS" ] || __list_options "Long Options" "--$LONGOPTS" ',' '--'
    [ -z "$ARRAY" ] || __list_options "Base Options" "$ARRAY" ',' ''
    exit $?
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
if command -v st | grep -q '^/bin' || command -v st | grep -q '^/usr/bin'; then
  BUILD_DESTDIR="/usr"
else
  BUILD_DESTDIR="${BUILD_DESTDIR:-/usr/local}"
fi
BUILD_SRC_DIR="${BUILD_SRC_DIR:-$HOME/.local/share/st/st-distrotube}"
BUILD_LOG_FILE="${BUILD_LOG_FILE:-/tmp/st_build.log}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
if [[ -d "$BUILD_SRC_DIR" ]]; then
  builtin cd "$BUILD_SRC_DIR" || exit 1
  if [[ -d ".git" ]]; then
    git reset --hard &>/dev/null && git pull -q &>/dev/null
  fi
  if [[ -f "./config.mk" ]]; then
    grep -q 'PREFIX = ' "./config.mk" &&
      sed -i 's|PREFIX =.*|PREFIX = '$BUILD_DESTDIR'|g' "./config.mk"
  fi
  if [[ -f "Makefile" ]]; then
    sudo make clean install DESTDIR="$BUILD_DESTDIR" | tee -a "$BUILD_LOG_FILE" &>/dev/null
  fi
  if [[ -f "$BUILD_LOG_FILE" ]]; then
    errors="$(grep 'fatal error' "$BUILD_LOG_FILE" || echo '')"
    if [[ -n "$errors" ]]; then
      printf_color "$RED" "The following errors have occurred:"
      echo -e "$errors"
    else
      printf_color "$GREEN" "Build of st has completed without error"
    fi
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
