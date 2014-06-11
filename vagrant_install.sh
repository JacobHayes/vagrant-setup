#!/usr/bin/env bash
set -eu
set -o pipefail
IFS=$'\n\t'

# Params:
#   url ending in dmg name
function strip_url {
  echo $( echo ${1} | sed "s/^.*\///" )
}

# Params:
#   dmg file path
#   pkg file name
function install_dmg {
  echo "Installing '${2}'. Do not run the .pkg file that may pop up."
  volume=$(sudo hdiutil attach "${1}" | grep "Volumes" | cut -f 3- )
  sudo installer -pkg "${volume}/${2}" -target / >> /dev/null
  sudo hdiutil detach "${volume}" >> /dev/null
}

osx_clt_mavericks_url="https://developer.apple.com/downloads/index.action/downloads/download.action?path=Developer_Tools/command_line_tools_os_x_mavericks_for_xcode__april_2014/command_line_tools_for_osx_mavericks_april_2014.dmg"
osx_clt_mountain_lion_url="https://developer.apple.com/downloads/index.action/downloads/download.action?path=Developer_Tools/command_line_tools_os_x_mountain_lion_for_xcode__april_2014/command_line_tools_for_osx_mountain_lion_april_2014.dmg"

echo "This will install OS X Command Line Tools, Vagrant 1.6.3, vagrant-omnibus, vagrant-berkshelf 2.0.1, and vagrant-vbguest"
echo ""

# OS X Command Line Tools
echo "To download the OS X Command Line Tools, login to the webpage that pops up and save the file to ~/Downloads.

Press enter to start and again when the download is complete"
read

os_version=$( sw_vers | grep "ProductVersion" | cut -f2 )
if [[ "${os_version}" =~ '10.9' ]]
then
  osx_clt_url=${osx_clt_mavericks_url}
  osx_clt_pkg="Command Line Tools (OS X 10.9).pkg"
elif [[ "${os_version}" =~ '10.8' ]]
then
  osx_clt_url=${osx_clt_mountain_lion_url}
  osx_clt_pkg="Command Line Tools (Mountain Lion).mpkg"
fi

osx_clt_dmg="${HOME}/Downloads/$( strip_url "${osx_clt_url}" )"

open "${osx_clt_url}"

read

while [[ ! -f "${osx_clt_dmg}" ]]
do
  echo "OS X Command Line Tools not found. Enter the file location:"
  read osx_clt_dmg
  echo ""
done

install_dmg "${osx_clt_dmg}" "${osx_clt_pkg}"

rm -f ${osx_clt_dmg}

# Vagrant
vagrant_url="https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.3.dmg"
vagrant_dmg=$( strip_url "${vagrant_url}" )
vagrant_pkg=""

echo "Downloading Vagrant"
curl -sOL $vagrant_url

install_dmg "${vagrant_dmg}" "Vagrant.pkg"

rm -f ${vagrant_dmg}

echo "Locking nokogiri to < 1.6.2 to stop compile failure."
sudo perl -p -i -e "s/^end$/\n  s.add_dependency\(\%q\<nokogiri\>, \[\"<= 1.6.2\"\]\)\nend/" "/Applications/Vagrant/embedded/gems/specifications/vagrant-1.6.3.gemspec"

# vagrant-omnibus
vagrant plugin install vagrant-omnibus

# vagrant-berkshelf
vagrant plugin install vagrant-berkshelf --plugin-version '>= 2.0.1'

# vagrant-vbguest
vagrant plugin install vagrant-vbguest

# Done!
echo -e "\n\nThe installations are complete!"
