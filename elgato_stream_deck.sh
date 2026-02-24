#!/bin/sh

appInstallPath="/Applications"
bundleName="Elgato Stream Deck"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

jsonData=$(/usr/bin/curl -s "https://gc-updates.elgato.com")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  currentVers=$(/bin/echo "${jsonData}"| /usr/bin/jq -r '."sd-mac"."version"')
  downloadURL=$(/bin/echo "${jsonData}" | /usr/bin/jq -r '."sd-mac"."downloadURL"')
else
  currentVers=$(/bin/echo "${jsonData}"| /usr/bin/plutil -extract sd-mac.version raw -o - -)
  downloadURL=$(/bin/echo "${jsonData}" | /usr/bin/plutil -extract sd-mac.downloadURL raw -o - -)
fi
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${appName} v${installedVers} is installed."
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
    /bin/echo "${appName} does not need to be updated"
    exit 0
  else
    /bin/echo "Updating ${appName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
