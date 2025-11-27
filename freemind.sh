#!/bin/sh

appInstallPath="/Applications"
bundleName="FreeMind"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null | /usr/bin/awk '{print $1}')

currentVers=$(/usr/bin/curl -s "https://freemind.sourceforge.io/wiki/index.php/Download" | /usr/bin/grep "stable release" | /usr/bin/xmllint --html --xpath '//p/text()' - | /usr/bin/awk '{print $8}' | /usr/bin/sed 's/.$//')
downloadURL="http://prdownloads.sourceforge.net/freemind/FreeMind_${currentVers}.dmg?download"
FILE=$(/bin/echo "${downloadURL##*/}" | /usr/bin/sed 's/?download//')

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /bin/rm -rf /Library/QuickLook/FreemindQL.qlgenerator >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/ditto "${TMPDIR}"/${bundleName}QL.qlgenerator /Library/QuickLook/"${bundleName}"QL.qlgenerator
  /usr/sbin/chown -R root:admin /Library/QuickLook/"${bundleName}"QL.qlgenerator
  /bin/chmod -R 755 /Library/QuickLook/"${bundleName}"QL.qlgenerator
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
