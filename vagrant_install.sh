#!/usr/bin/env bash
readonly IFS=$'\n\t'

set -o errexit # set -e
set -o nounset # set -u
set -o pipefail

# Params
#   string to indent and print
function ECHO {
  echo -e "\t${1}"
}

function USAGE
{
   echo "
############
SCRIPT USAGE
############

Script to install OS X Command Line Tools, Vagrant, vagrant-omnibus, vagrant-berkshelf, and vagrant-vbguest.

OPTIONS:
   -a
      Install all (OS X Command Line Tools, Vagrant, vagrant-omnibus, vagrant-berkshelf, and vagrant-vbguest)
   -c
      Install only OS X Command Line Tools
   -p
      Install only vagrant-omnibus, vagrant-berkshelf, and vagrant-vbguest
   -v
      Install only Vagrant
"
  exit 1
}



# Params:
#   url ending in dmg name
function strip_url {
  echo $( sed "s/^.*\///" <(echo "${1}"))
}

# Params:
#   dmg file path
#   varaible for return volume path
function attach_volume {
  ECHO "Attaching ${1}"
  volume="$(sudo hdiutil attach "${1}" | grep "Volumes" | cut -f 3- )"
  eval "${2}=\"${volume}\""
  ECHO "\tAttached to ${volume}"
}

# Params:
#   volume path
function detach_volume {
  ECHO "Detaching ${1}"
  sudo hdiutil detach "${1}" >> /dev/null
  ECHO "\tDetached"
}
# Params:
#   volume path
#   pkg file name
function install_pkg {
  ECHO "Installing '${1}/${2}'. Do not run the .pkg file that may pop up."
  sudo installer -pkg "${volume}/${2}" -target / >> /dev/null
  ECHO "\tInstalled ${2}"
}

# Params:
#   dmg file path
#   pkg file name
function install_dmg {
  volume_path=''

  attach_volume "${1}" volume_path
  install_pkg "${volume_path}" ${2}
  detach_volume "${volume_path}"
}

function install_command_line_tools {
  local readonly osx_clt_mavericks_url="https://developer.apple.com/downloads/index.action/downloads/download.action?path=Developer_Tools/command_line_tools_os_x_mavericks_for_xcode__april_2014/command_line_tools_for_osx_mavericks_april_2014.dmg"
  local readonly osx_clt_mountain_lion_url="https://developer.apple.com/downloads/index.action/downloads/download.action?path=Developer_Tools/command_line_tools_os_x_mountain_lion_for_xcode__april_2014/command_line_tools_for_osx_mountain_lion_april_2014.dmg"

  echo -e "#### Installing OS X Command Line Tools\n"

  # OS X Command Line Tools
  ECHO "To download the OS X Command Line Tools, login to the webpage that pops up and save the file to ~/Downloads."
  echo -en "\tPress enter to start download. "
  read

  local os_version=$( sw_vers | grep "ProductVersion" | cut -f2 )
  if [[ "${os_version}" =~ '10.9' ]]
  then
    local osx_clt_url="${osx_clt_mavericks_url}"
    local osx_clt_pkg="Command Line Tools (OS X 10.9).pkg"
  elif [[ "${os_version}" =~ '10.8' ]]
  then
    local osx_clt_url="${osx_clt_mountain_lion_url}"
    local osx_clt_pkg="Command Line Tools (Mountain Lion).mpkg"
  fi

  local osx_clt_dmg="${HOME}/Downloads/$( strip_url "${osx_clt_url}" )"

  open "${osx_clt_url}"

  echo -en "\tPress enter when the download is complete. "
  read

  while [[ ! -f "${osx_clt_dmg}" ]]
  do
    echo -en "\tOS X Command Line Tools not found. Enter the absolute file location: "
    read osx_clt_dmg
    echo ""
  done

  install_dmg "${osx_clt_dmg}" "${osx_clt_pkg}"

  rm -f "${osx_clt_dmg}"

  ECHO "Done installing OS X Command Line Tools.\n"
}

function install_vagrant {
  local vagrant_url="https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.3.dmg"
  local vagrant_dmg=$( strip_url "${vagrant_url}" )
  local vagrant_pkg="Vagrant.pkg"

  echo -e "#### Installing Vagrant\n"

  ECHO "Downloading Vagrant"
  curl -sOL "$vagrant_url"

  local vagrant_path=''

  attach_volume "${vagrant_dmg}" vagrant_path

  ECHO "Uninstalling previous Vagrant"
  echo -e "Yes\n\n" | "${vagrant_path}/uninstall.tool" >> /dev/null
  rm -rf "${HOME}/.vagrant.d"

  install_pkg "${vagrant_path}" "${vagrant_pkg}"
  detach_volume "${vagrant_path}"

  rm -f "${vagrant_dmg}"

  ECHO "Done installing Vagrant.\n"
}

function install_vagrant_plugins {
  if [[ ! $(which vagrant) ]]
  then
    echo "Vagrant must be installed to install Vagrant plugins."
    echo "Rerun with the '-v' flag..."
    exit 1
  fi

  if [[ ! $(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables) ]]
  then
    echo "OS X Command Line Tools must be installed to install Vagrant plugins."
    echo "Rerun with the '-c' flag..."
    exit 1
  fi

  echo -e "#### Installing Vagrant plugins\n"

  ECHO "Installing vagrant-omnibus >= 1.4.1"
  vagrant plugin install vagrant-omnibus --plugin-version '>= 1.4.1' >> /dev/null

  ECHO "Installing vagrant-berkshelf >= 2.0.1"
  vagrant plugin install vagrant-berkshelf --plugin-version '>= 2.0.1' >> /dev/null

  ECHO "Installing vagrant-vbguest "
  vagrant plugin install vagrant-vbguest >> /dev/null

  ECHO "Done installing Vagrant plugins.\n"
}

function all {
  install_command_line_tools
  install_vagrant
  install_vagrant_plugins
}

flag=''
while getopts ":acpv" opt
do
   case $opt in
      a)
         all
         flag="a"
         ;;
      c)
         install_command_line_tools
         flag="c"
         ;;
      p)
         install_vagrant_plugins
         flag="p"
         ;;
      v)
         install_vagrant
         flag="v"
         ;;
      ?)
         ECHO ""
         ECHO "Invalid option: -${OPTARG}" >&2
         USAGE
         ;;
   esac
done

if [[ -z $flag ]]
then
   USAGE
fi
