#!/bin/sh

appInstallPath="/Applications"
bundleName="logioptionsplus"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null | /usr/bin/cut -d "." -f 1-2 -)

currentVers=$(/usr/bin/curl -s "https://support.logi.com/hc/en-au/articles/1500005516462-Logi-Options-Release-Notes" | /usr/bin/grep "Version Release Date" | /usr/bin/grep -o 'content="[^"]*' | /usr/bin/head -n 1 | /usr/bin/awk '{print $4}')
downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
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
  /usr/bin/ditto -xk /tmp/"${FILE}" /tmp/
  /tmp/"${bundleName}"_installer.app/Contents/MacOS/"${bundleName}"_installer --quiet
  /bin/rm -rf /tmp/"${bundleName}"_installer.app
fi
