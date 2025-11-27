#!/bin/sh

appInstallPath="/Applications"
bundleName="Opera"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

linkOne=$(/usr/bin/curl -sI "https://download.opera.com/download/get/?partner=www&opsys=MacOS" | /usr/bin/grep -i "^location" | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
linkTwo=$(/usr/bin/curl -sL "${linkOne}" | /usr/bin/grep "thanks-download-link" | /usr/bin/xmllint --html --xpath 'string(//html/body/p/a/@href)' - 2>/dev/null | /usr/bin/sed 's/\&amp;/\&/g')
downloadURL=$(/usr/bin/curl -sI "${linkTwo}" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/grep -oE 'desktop/[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/desktop\///g')
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
