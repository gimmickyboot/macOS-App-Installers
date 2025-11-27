#!/bin/sh

appInstallPath="/Applications"
bundleName="pgAdmin 4"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

case $(uname -m) in
  arm64)
    myArch="arm64"
    ;;

  x86_64)
    myArch="x64"
    ;;

*)
    /bin/echo "Unknow architecture. Exiting"
    exit 1
    ;;
esac
currentVers=$(/usr/bin/curl -s "https://pgadmin-archive.postgresql.org/pgadmin4/index.html" | /usr/bin/grep 'href="v'  | /usr/bin/tail -n 1 | /usr/bin/xmllint --xpath '//li/a/text()' - | /usr/bin/cut -c 2- -)
downloadURL="https://pgadmin-archive.postgresql.org/pgadmin4/v${currentVers}/macos/pgadmin4-${currentVers}-${myArch}.dmg"
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
  /usr/bin/hdiutil convert -quiet /tmp/"${FILE}" -format UDTO -o /tmp/"${FILE}".cdr
  /usr/bin/hdiutil attach /tmp/"${FILE}".cdr -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}".cdr
  /bin/rm /tmp/"${FILE}"
fi
