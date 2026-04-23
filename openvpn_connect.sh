#!/bin/sh

appInstallPath="/Applications"
bundleName="OpenVPN Connect"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL=$(/usr/bin/curl -sI "https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//')
currentVers=$(printf '%s' "${downloadURL}" | /usr/bin/grep -oE "openvpn-connect-[0-9]+(\.[0-9]+)*" | /usr/bin/cut -d - -f 3- - | rev | /usr/bin/cut -d . -f 2- - | rev)
FILE=${downloadURL##*/}
SHAHash=$(/usr/bin/curl -s "https://openvpn.net/connect-docs/macos-release-notes.html" | /usr/bin/xmllint --html --xpath '//*[starts-with(@id,"sha-256-checksum-")]/div[2]/table/tbody/tr/td[2]/div/p/span/text()' - 2>/dev/null)

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
  SHAResult=$(printf '%s' "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 256 -c 2>/dev/null)
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
  case $(uname -m) in
    arm64)
      archType="arm64"
      ;;

    x86_64)
      archType="x86_64"
      ;;

    *)
      /bin/echo "Unknown processor architecture. Exiting"
      exit 1
      ;;
  esac
  /usr/bin/find "${TMPDIR}" -name "*${archType}*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
