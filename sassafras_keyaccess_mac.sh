#!/bin/sh

appInstallPath="/Library/KeyAccess"
bundleName="KeyAccess"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

htmlData=$(/usr/bin/curl -s "https://solutions.teamdynamix.com/TDClient/1965/Portal/KB/ArticleDet?ID=169236")
currentVers=$(/bin/echo "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep -A1 "Minor Version" | /usr/bin/tail -n 1 | /usr/bin/sed 's/<\/p//' | /usr/bin/xargs)
downloadURL=$(/bin/echo "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
FILE=${downloadURL##*/}
SHAHash=$(/bin/echo "${htmlData}" | /usr/bin/grep -A1 ksp-client.pkg | /usr/bin/xmllint --html --xpath '//span/text()' - 2>/dev/null | /usr/bin/tail -n 1 | /usr/bin/awk '{print $2}')

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
  SHAResult=$(/bin/echo "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 256 -c 2>/dev/null)
  case "${SHAResult}" in
    *OK)
      /bin/echo "SHA hash has successfully verifed."
      ;;

    *FAILED)
      /bin/echo "SHA hash has failed verification"
      exit 1
      ;;

    *)
      /bin/echo "An unknown error has occured."
      exit 1
      ;;
  esac
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
