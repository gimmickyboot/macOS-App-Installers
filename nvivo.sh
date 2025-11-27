#!/bin/sh

appInstallPath="/Applications"

majVers=$(/usr/bin/curl -s "https://techcenter.qsrinternational.com/Content/welcome/toc_welcome.htm" | /usr/bin/grep Mac | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//span/@class)' - | /usr/bin/sed 's/[^0-9]//g')
bundleName="NVivo ${majVers}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)
downloadURL="https://download.qsrinternational.com/Software/NVivo${majVers}forMac/NVivo.dmg"
FILE=${downloadURL##*/}
currentVers="$(/usr/bin/curl -sIL "${downloadURL}" | /usr/bin/grep ^location | /usr/bin/awk '{print $2}' | rev | /usr/bin/cut -d "/" -f 2 - | rev | /usr/bin/cut -d . -f 1-3 -)"

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
