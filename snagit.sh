#!/bin/sh

appInstallPath="/Applications"
bundleName="Snagit"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

currentVers=$(/usr/bin/curl -s "https://support.techsmith.com/hc/en-us/articles/115006443147-Snagit-Mac-Version-History" | /usr/bin/xmllint --html --xpath '//*/head/meta[2]/@content' - 2>/dev/null | /usr/bin/cut -d \" -f 2- - | /usr/bin/grep -oE 'Snagit[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/awk '{print $2}')
versionYear=$(printf '%s' "${currentVers}" | /usr/bin/cut -c 1-4 -)
downloadURL=$(/usr/bin/curl -s "https://sparkle.cloud.techsmith.com/api/v1/AppcastManifest/?version=${currentVers}&utm_source=product&utm_medium=snagit&utm_campaign=sm${versionYear}&ipc_item_name=snagit&ipc_platform=macos" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/cut -d \" -f 2 -)
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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil convert -quiet /tmp/"${FILE}" -format UDTO -o /tmp/"${FILE}".cdr
  /usr/bin/hdiutil attach /tmp/"${FILE}".cdr -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}".cdr
  /bin/rm /tmp/"${FILE}"
fi
