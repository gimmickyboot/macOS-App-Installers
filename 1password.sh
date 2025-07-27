#!/bin/sh

appInstallPath="/Applications"
bundleName="1Password"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL="https://downloads.1password.com/mac/1Password.pkg"
FILE=${downloadURL##*/}
currentVers=$(/usr/bin/curl -s "https://releases.1password.com/mac/" | /usr/bin/xmllint --format --html - 2>/dev/null | /usr/bin/grep -B 7 '<h2 class="c-heading c-heading--2 u-mb-2 u-mb-0@md u-mt-4 u-mt-0@md">1Password for Mac</h2>' | /usr/bin/grep "Updated to" | /usr/bin/awk -F ">" '{ print $2 }' | /usr/bin/awk '{print $3}' | /usr/bin/head -n 1)

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
