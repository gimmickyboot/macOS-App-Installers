#!/bin/sh

appInstallPath="/Library/Application Support/JamfConnect"
bundleName="JCDaemon"
appName="Jmaf Connect Login"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL="https://files.jamfconnect.com/JamfConnect.dmg"
currentVers=$(/usr/bin/curl -sI "${downloadURL}" | /usr/bin/grep "x-amz-meta-version" | /usr/bin/awk '{print $2}')
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
  /usr/bin/hdiutil convert /tmp/"${FILE}" -quiet -format UDTO -o /tmp/"${FILE%.*}.cdr"
  /usr/bin/hdiutil attach /tmp/"${FILE%.*}.cdr" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -maxdepth 1 -name "*.pkg" -exec /usr/sbin/installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
  /bin/rm /tmp/"${FILE%.*}.cdr"
fi
