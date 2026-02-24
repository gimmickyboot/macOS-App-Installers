#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="mafft"
appName="${bundleName}"
installedVers=$("${appInstallPath}"/${bundleName} --version 2>&1 | /usr/bin/awk '{print $1}' | /usr/bin/sed 's/[^0-9.]//g')

URL="https://mafft.cbrc.jp/alignment/software"
FILE=$(/usr/bin/curl -s "${URL}/macstandard.html" | /usr/bin/grep signed | /usr/bin/xmllint --html --xpath '//a/text()' - | /usr/bin/sort | /usr/bin/tail -n 1 | /usr/bin/sed 's/\?.*//')
currentVers="$(/bin/echo "${FILE}" | /usr/bin/cut -d "-" -f 2 -)"
downloadURL="${URL}/${FILE}"

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
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
