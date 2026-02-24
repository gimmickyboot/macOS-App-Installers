#!/bin/sh

appInstallPath="/Applications"
bundleName="Pacifist"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

xmlData=$(/usr/bin/curl -s "https://www.charlessoft.com/cgi-bin/pacifist_sparkle.cgi")
versionCount=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/title' - | /usr/bin/wc -l | /usr/bin/xargs)
currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "//rss/channel/item[${versionCount}]/title/text()" - | /usr/bin/awk '{print $2}')
downloadURL=$(/usr/bin/curl -sI "$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "string(//rss/channel/item[${versionCount}]/enclosure/@url)" -)" | /usr/bin/grep ^location | /usr/bin/awk '{print $2}')
FILE=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE "Pacifist.*$")

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
