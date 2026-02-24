#!/bin/sh

appInstallPath="/Applications"
bundleName=$(/usr/bin/find /Applications -name "SF Symbols*" -maxdepth 1 | /usr/bin/cut -d "/" -f 3 -)
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

downloadURL=$(/usr/bin/curl -fs "https://developer.apple.com/sf-symbols/" | /usr/bin/grep dmg | head -n 1 | /usr/bin/cut -d \" -f 2 -)
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/grep -oE 'SF-Symbols-[0-9]' | /usr/bin/sed 's/SF-Symbols-//')
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
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
