#!/bin/sh

appInstallPath="/Library/KeyAccess"
bundleName="KeyAccess"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

URL="http://www.sassafras.com/client-download/"
currentVers=$(/usr/bin/curl -sL "${URL}" | /usr/bin/xmllint --format --html - 2>/dev/null | /usr/bin/grep "KeyAccess.*for Mac" | /usr/bin/awk '{print $2}')
downloadURL=$(/usr/bin/curl -sL "${URL}" | /usr/bin/tr '>' '\n' | /usr/bin/grep "https.*ksp-client.*pkg" | /usr/bin/cut -d '"' -f 2 | /usr/bin/head -n 1)
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${bundleName} v${installedVers} is installed."
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
    /bin/echo "Updating ${bundleName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${bundleName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
