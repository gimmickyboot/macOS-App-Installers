#!/bin/sh

appInstallPath="/Applications"
bundleName="IDLE"

URL="https://www.python.org/downloads/"
downloadURL=$(/usr/bin/curl -s --compressed "${URL}" | /usr/bin/awk '/macos/ && /ftp/ {print;}' | /usr/bin/cut -d \" -f 4 -)
FILE=${downloadURL##*/}
currentVers=$(/bin/echo "${FILE}" | /usr/bin/awk -F- '{print $2}')
currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed 's/\.//g')
SUM=$(/usr/bin/curl -s --compressed "${URL}/release/python-${currentVersNoDots}/" | /usr/bin/grep -A 4 pkg | /usr/bin/head -n 4 | /usr/bin/tail -n 1 | /usr/bin/awk '{print $1}' | /usr/bin/sed -e 's/<td>//' -e 's/<\/td>//')
shortVers=$(/bin/echo "${currentVers}" | /usr/bin/cut -d . -f 1-2 -)

installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName} ${shortVers}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

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
  # verify the hash
  /bin/echo "${SUM} */tmp/${FILE}" > /tmp/checksum.md5
  SUMResult=$(/sbin/md5sum --check /tmp/checksum.md5 2>/dev/null)
  case "${SUMResult}" in
    *OK)
      /bin/echo "Hash has successfully verifed."
      ;;

    *FAILED)
      /bin/echo "Hash has failed verification"
      exit 1
      ;;

    *)
      /bin/echo "An unknown error has occured."
      exit 1
      ;;
  esac
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
  /bin/rm /tmp/checksum.md5
fi
