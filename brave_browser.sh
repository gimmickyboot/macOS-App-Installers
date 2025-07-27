#!/bin/sh

appInstallPath="/Applications"
bundleName="Brave Browser"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

case "$(uname -m)" in
  arm64)
    URLpath="stable-arm64"
    ;;

  x86_64)
    URLpath="stable"
    ;;

  *)
    /bin/echo "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
BBXML=$(/usr/bin/curl -s "https://updates.bravesoftware.com/sparkle/Brave-Browser/${URLpath}/appcast.xml")
currentVers=$(/bin/echo "${BBXML}" | /usr/bin/sed 's/sparkle://g' | /usr/bin/xmllint --xpath '/rss/channel/item[last()]/enclosure/@version' - | /usr/bin/awk -F\" '{print $2}')
downloadURL=$(/bin/echo "${BBXML}" | /usr/bin/xmllint --xpath '//rss/channel/item[last()]/enclosure/@url' - | /usr/bin/awk -F\" '{print $2}')
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
