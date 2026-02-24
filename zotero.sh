#!/bin/sh

appInstallPath="/Applications"
bundleName="Zotero"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  currentVers=$(/usr/bin/curl -s "https://www.zotero.org/download/" | /usr/bin/grep mac | /usr/bin/awk '{print $2}' | /usr/bin/sed -e 's/,"Windows$//' -e 's/$/}}/' | /usr/bin/tail -n 1 | /usr/bin/jq -r .standaloneVersions.mac)
else
  currentVers=$(/usr/bin/curl -s "https://www.zotero.org/download/" | /usr/bin/grep mac | /usr/bin/awk '{print $2}' | /usr/bin/sed -e 's/,"Windows$//' -e 's/$/}}/' | /usr/bin/tail -n 1 | /usr/bin/plutil -extract standaloneVersions.mac raw -o - -)
fi
downloadURL="https://download.zotero.org/client/release/${currentVers}/Zotero-${currentVers}.dmg"
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
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
