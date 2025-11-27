#!/bin/sh

appInstallPath="/Applications"
bundleName="Plex Media Player"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

jsonData=$(/usr/bin/curl -s "https://plex.tv/api/downloads/3.json")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .computer.Mac.version)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/jq -r '.computer.Mac.releases[].url')
else
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract computer.Mac.version raw -o - -)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract computer.Mac.releases.0.url raw -o - -)
fi
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${bundleName} v${installedVers} is installed."
  installedVersNoDots=$(/bin/echo "${installedVers}" | /usr/bin/sed -e 's/\.//g' -e 's/-//g' -e 's/[a-zA-Z]//g')
  currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed -e 's/\.//g' -e 's/-//g' -e 's/[a-zA-Z]//g')

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
