#!/bin/sh

appInstallPath="/Applications"
bundleName="TeamViewer"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL=$(/usr/bin/curl -s "https://download.teamviewer.com/download/update/macupdates.xml?version=15.1.1&os=macos&osversion=$(/usr/bin/sw_vers -productVersion)" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/grep -v Host | /usr/bin/cut -d \" -f 2 - | /usr/bin/head -n 1)
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/grep -v Host | /usr/bin/cut -d \" -f 2 - | /usr/bin/rev | /usr/bin/cut -d "/" -f 2 - | /usr/bin/rev)
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  installedVersNoDots=$(/bin/echo "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    /bin/echo "${bundleName} does not need to be updated"
    exit 0
  else
    /bin/echo "${bundleName} needs to be updated"
  fi
else
  /bin/echo "Installing ${bundleName}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
