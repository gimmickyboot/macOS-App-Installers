#!/bin/sh

appInstallPath="/Applications"
bundleName="OpenVPN Connect"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL=$(/usr/bin/curl -sI "https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/grep -oE "openvpn-connect-[0-9]+(\.[0-9]+)*" | /usr/bin/cut -d - -f 3- - | rev | /usr/bin/cut -d . -f 2- - | rev)
FILE=${downloadURL##*/}
SHAHash=$(/usr/bin/curl -s "https://openvpn.net/connect-docs/macos-release-notes.html" | /usr/bin/xmllint --html --xpath '//*[starts-with(@id,"sha-256-checksum-")]/div[2]/table/tbody/tr/td[2]/div/p/span/text()' - 2>/dev/null)

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
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*$(uname -m)*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
