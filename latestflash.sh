#!/bin/sh
#########################################################
# Script to download and install Flash Player.
# Only works on Intel systems. Run as root.
# The original idea was taken from adobe.com forums
#
# Fixed and improved by Kyle Evans kevans@highline.edu
#########################################################

if [[ "$USER" != "root" ]]; then
  echo "You must run this script as root."
  exit 1
fi

dmgfile="flash.dmg"
volname="Flash"
logfile="/Library/Logs/FlashUpdateScript.log"
echo "Updating Flash player…"
# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    # Get the latest version of Flash Player available from Adobe's About Flash page.
    latestver=`/usr/bin/curl -s http://www.adobe.com/software/flash/about/ | sed -n '/Safari/,/<\/tr/s/[^>]*>\([0-9].*\)<.*/\1/p'`
    # Get the version number of the currently-installed Flash Player, if any.
    if [ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]; then
       currentinstalledver=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
    else
        currentinstalledver="none"
    fi
    echo "Installed version:                 ${currentinstalledver}"
    echo "Currently last version to install: ${latestver}"
    # Compare the two versions, if they are different of Flash is not present then download and install the new version.
    if [ ${currentinstalledver} != ${latestver} ]; then
        echo "UPDATING…"
        /bin/echo "`date`: Current Flash version: ${currentinstalledver}" >> ${logfile}
        /bin/echo "`date`: Available Flash version: ${latestver}" >> ${logfile}
        /bin/echo "`date`: Downloading newer version." >> ${logfile}
        /usr/bin/curl -s -o `/usr/bin/dirname $0`/flash.dmg http://fpdownload.macromedia.com/get/flashplayer/pdc/${latestver}/install_flash_player_osx.dmg
        /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
        /usr/bin/hdiutil attach `dirname $0`/flash.dmg -nobrowse -quiet
        /bin/echo "`date`: Installing..." >> ${logfile}
        /usr/sbin/installer -pkg /Volumes/Flash\ Player/Install\ Adobe\ Flash\ Player.app/Contents/Resources/Adobe\ Flash\ Player.pkg -target / > /dev/null
        /bin/sleep 10
        /bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
        /usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep ${volname} | awk '{print $1}') -quiet
        /bin/sleep 10
        /bin/echo "`date`: Deleting disk image." >> ${logfile}
        /bin/rm `/usr/bin/dirname $0`/${dmgfile}
        newlyinstalledver=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
        if [ "${latestver}" = "${newlyinstalledver}" ]; then
            /bin/echo "`date`: SUCCESS: Flash has been updated to version ${newlyinstalledver}" >> ${logfile}
            echo "SUCCESS: Flash has been updated to version ${newlyinstalledver}"
        else
            /bin/echo "`date`: ERROR: Flash update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
            /bin/echo "--" >> ${logfile}
            echo "ERROR: Flash update unsuccessful, version remains at ${currentinstalledver}."
        fi
    # If Flash is up to date already, just log it and exit.
    else
        /bin/echo "`date`: Flash is already up to date, running ${currentinstalledver}." >> ${logfile}
        /bin/echo "--" >> ${logfile}
        echo "Flash is already up to date, running ${currentinstalledver}."
    fi
else
    /bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
    echo "ERROR: This script is for Intel Macs only."
fi
