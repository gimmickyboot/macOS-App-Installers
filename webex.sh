#!/bin/sh

appInstallPath="/Applications"
bundleName="Webex"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

currentVers=$(/usr/bin/curl -s "https://help.webex.com/en-us/article/mqkve8/Webex-App-%7C-Release-notes" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep -E '^\s*Mac—' | /usr/bin/head -n 1 | /usr/bin/sed -e 's/ //g' -e 's/Mac—//')
case $(uname -m) in
  arm64)
    downloadURL=$(/usr/bin/curl -s "https://www.webex.com/downloads.html" | /usr/bin/grep "macOS (Apple M1 chip)" | /usr/bin/head -n 1 | /usr/bin/grep -o 'uri="[^"]*' | /usr/bin/sed 's/uri="//')
    ;;

  x86_64)
    downloadURL=$(/usr/bin/curl -s "https://www.webex.com/downloads.html" | /usr/bin/grep "macOS (Intel chip)" | /usr/bin/head -n 1 | /usr/bin/grep -o 'uri="[^"]*' | /usr/bin/sed 's/uri="//')
    ;;

  *)
    /bin/echo "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
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
