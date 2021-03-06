#!/bin/bash

# This first part is Rich Trouton's Command Line Tools install script in its entirety
# Installing the Xcode command line tools on 10.7.x or higher

osx_vers=$(sw_vers -productVersion | awk -F "." '{print $2}')
cmd_line_tools_temp_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

# Installing the latest Xcode command line tools on 10.9.x or higher

if [[ "$osx_vers" -ge 9 ]]; then

	# Create the placeholder file which is checked by the softwareupdate tool 
	# before allowing the installation of the Xcode command line tools.
	
	touch "$cmd_line_tools_temp_file"
	
	# Identify the correct update in the Software Update feed with "Command Line Tools" in the name for the OS version in question.
	
	if [[ "$osx_vers" -gt 9 ]]; then
	   cmd_line_tools=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | grep "$osx_vers" | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	elif [[ "$osx_vers" -eq 9 ]]; then
	   cmd_line_tools=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | grep "Mavericks" | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	fi
	
	#Install the command line tools
	
	softwareupdate -i "$cmd_line_tools" --verbose
	
	# Remove the temp file
	
	if [[ -f "$cmd_line_tools_temp_file" ]]; then
	  rm "$cmd_line_tools_temp_file"
	fi
fi

# Installing the latest Xcode command line tools on 10.7.x and 10.8.x

# on 10.7/10.8, instead of using the software update feed, the command line tools are downloaded
# instead from public download URLs, which can be found in the dvtdownloadableindex:
# https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex

if [[ "$osx_vers" -eq 7 ]] || [[ "$osx_vers" -eq 8 ]]; then

	if [[ "$osx_vers" -eq 7 ]]; then
	    DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
	fi
	
	if [[ "$osx_vers" -eq 8 ]]; then
	     DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_osx_mountain_lion_april_2014.dmg
	fi

		TOOLS=cltools.dmg
		curl "$DMGURL" -o "$TOOLS"
		TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
		hdiutil attach "$TOOLS" -mountpoint "$TMPMOUNT" -nobrowse
		# The "-allowUntrusted" flag has been added to the installer
		# command to accomodate for now-expired certificates used
		# to sign the downloaded command line tools.
		installer -allowUntrusted -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
		hdiutil detach "$TMPMOUNT"
		rm -rf "$TMPMOUNT"
		rm "$TOOLS"
fi

# This second part is taken from Tom Bridge's Munki in a Box Script

####
# Get AutoPkg
####

# Nod and Toast to Nate Felton!

LOGGER="/usr/bin/logger -t CIT-AutoPkg-Auto"


AUTOPKG_LATEST=$(curl https://api.github.com/repos/autopkg/autopkg/releases | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["assets"][0]["browser_download_url"]')
curl -L "${AUTOPKG_LATEST}" -o autopkg-latest1.pkg

sudo installer -pkg autopkg-latest1.pkg -target /

echo "AutoPkg Installed"

# This third part adds jss importer and is also borrowing from Munki in a Box

autopkg repo-add http://github.com/autopkg/recipes.git
autopkg repo-add rtrouton-recipes
autopkg repo-add jleggat-recipes
autopkg repo-add nmcspadden-recipes
autopkg repo-add jessepeterson-recipes

git clone https://github.com/sheagcraig/JSSImporter.git
cp JSSImporter/JSSImporter.py /Library/AutoPkg/autopkglib


echo "AutoPkg Configured"



exit 0
