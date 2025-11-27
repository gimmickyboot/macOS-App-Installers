#!/bin/sh

appInstallPath="/Applications"
bundleName="Alfred 5"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

xmlData=$(/usr/bin/curl -s "https://www.alfredapp.com/app/update5/general.xml")
currentVers=$(/bin/echo "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="version"]/following-sibling::*[1])' -)
downloadURL=$(/bin/echo "${xmlData}" | /usr/bin/xmllint --xpath 'string(//key[.="location"]/following-sibling::*[1])' -)
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
  /bin/rm "${appInstallPath}"/"${bundleName}.app" 2>/dev/null
  /usr/bin/tar -xf /tmp/"${FILE}" -C /tmp/
  /bin/mv /tmp/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod a+x "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
