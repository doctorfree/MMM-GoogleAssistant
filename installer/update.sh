#!/bin/bash
# +---------+
# | updater |
# +---------+

# get the installer directory
Installer_get_current_dir () {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

Installer_dir="$(Installer_get_current_dir)"

# move to installler directory
cd "$Installer_dir"
source utils.sh

Installer_info "Welcome to GA updater !"
echo

Installer_update_dependencies () {
  Installer_debug "Test Wanted dependencies: ${dependencies[*]}"
  local missings=()
  for package in "${dependencies[@]}"; do
      Installer_is_installed "$package" || missings+=($package)
  done
  if [ ${#missings[@]} -gt 0 ]; then
    Installer_warning "Updating package..."
    for missing in "${missings[@]}"; do
      Installer_error "Missing package: $missing"
    done
    Installer_info "Installing missing package..."
    Installer_update || exit 1
    Installer_install ${missings[@]} || exit 1
  fi
}

echo
# Check dependencies
# Required packages on Debian based systems
deb_dependencies=(wget unclutter build-essential vlc libmagic-dev libatlas-base-dev cec-utils libudev-dev)
# Required packages on RPM based systems
rpm_dependencies=(atlas-devel file-devel file-libs vlc wget autoconf automake binutils bison flex gcc gcc-c++ glibc-devel libtool make pkgconf strace byacc ccache cscope ctags elfutils indent ltrace perf valgrind libudev-devel libcec)
# Check dependencies
if [ "${debian}" ]
then
  dependencies=( "${deb_dependencies[@]}" )
else
  if [ "${have_dnf}" ]
  then
    dependencies=( "${rpm_dependencies[@]}" )
  else
    if [ "${have_yum}" ]
    then
      dependencies=( "${rpm_dependencies[@]}" )
    else
      dependencies=( "${deb_dependencies[@]}" )
    fi
  fi
fi

[ "${__NO_DEP_CHECK__}" ] || {
  Installer_info "Update all dependencies..."
  Installer_update_dependencies
  Installer_success "All Dependencies needed are updated !"
}

cd ~/MagicMirror/modules/MMM-GoogleAssistant
# deleting package.json because npm install add/update package
rm -f package.json package-lock.json

Installer_info "Updating Main core..."

git reset --hard HEAD
git pull
#fresh package.json
git checkout package.json
cd ~/MagicMirror/modules/MMM-GoogleAssistant/node_modules

Installer_info "Deleting ALL @bugsounet libraries..."

rm -rf @bugsounet
cd ~/MagicMirror/modules/MMM-GoogleAssistant

Installer_info "Ready for Installing..."

# launch installer
npm install
