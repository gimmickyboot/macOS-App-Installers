#!/bin/sh

appInstallPath="/Library/Application Support/Dialog"
bundleName="Dialog"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

gitHubURL="https://github.com/swiftDialog/swiftDialog"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(/bin/echo "${latestReleaseURL}" | rev | /usr/bin/awk -F "/" '{print $1}' | rev)
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/sed 's/v//')
assetsURL=$(/usr/bin/curl -s "${latestReleaseURL}" | /usr/bin/grep expanded_assets | /usr/bin/xmllint --html --xpath '//*/include-fragment/@src' - 2>/dev/null | /usr/bin/awk -F \" '{print $2}')
downloadURL="${gitHubURL}/$(/usr/bin/curl -s "${assetsURL}" | /usr/bin/tr '"' "\n" | /usr/bin/grep pkg | /usr/bin/cut -d "/" -f 4- -)"
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
