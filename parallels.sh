#!/bin/sh

appInstallPath="/Applications"
bundleName="Parallels Desktop"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

i=15
while true; do
  theResult=$(/usr/bin/curl -sLI "https://parallels.com/directdownload/pd${i}/" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/tail -n 1 | /usr/bin/sed 's/\r//')
  if printf '%s' "${theResult}" | /usr/bin/grep -vq '\.dmg*'; then
    majVers=$((i-1))
    break
  else
    i=$((i+1))
  fi
done
xmlData=$(/usr/bin/curl -s "https://update.parallels.com/desktop/v${majVers}/parallels/parallels_updates.xml")
downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '(//Product/Version/Update/FilePath)[1]/text()' -)
currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath "concat(//Major/text(), '.', //Minor/text(), '.', //SubMinor/text())" -)
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${appName} v${installedVers} is installed."
  installedVersNoDots=$(printf '%s' "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  "${TMPDIR}"/"${bundleName}.app"/Contents/MacOS/inittool install -t "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
