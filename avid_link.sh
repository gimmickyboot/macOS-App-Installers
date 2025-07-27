#!/bin/sh

appInstallPath="/Applications/Avid/Avid Link"
bundleName="Avid Link"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

downloadURL=$(/usr/bin/curl -s "https://www.avid.com/products/avid-link#Downloads" | /usr/bin/grep macOS | /usr/bin/xmllint --html --xpath "//script[@id='__NEXT_DATA__']/text()" - 2>/dev/null | /usr/bin/sed -e 's/<!\[CDATA\[//' -e 's/]]>$//' | /usr/bin/grep -oE 'https?://[^"]+\.pkg' | /usr/bin/head -n 1)
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/rev | /usr/bin/cut -d "/" -f 1 - | /usr/bin/cut -c 5- - | /usr/bin/rev | /usr/bin/sed 's/[^0-9.]//g')
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
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
