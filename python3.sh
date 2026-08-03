#!/bin/sh

appInstallPath="/Applications"
bundleName="IDLE"
appName="Python 3"

URL="https://www.python.org/downloads/"
downloadURL=$(/usr/bin/curl -s --compressed "${URL}" | /usr/bin/awk '/macos/ && /ftp/ {print;}' | /usr/bin/cut -d \" -f 4 -)
FILE=${downloadURL##*/}
currentVers=$(printf '%s' "${FILE}" | /usr/bin/awk -F- '{print $2}')
currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')
SHAHash=$(/usr/bin/curl -s --compressed "${URL}/release/python-${currentVersNoDots}/" | /usr/bin/grep -A 8 pkg.sigstore | /usr/bin/tail -n 1 | /usr/bin/xmllint --html --xpath 'string(//code[@class="checksum"])' - 2>/dev/null | /usr/bin/tr -d '\n')
shortVers=$(printf '%s' "${currentVers}" | /usr/bin/cut -d . -f 1-2 -)

installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName} ${shortVers}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

# compare version numbers
if [ "${installedVers}" ]; then
  printf '%s\n' "${appName} v${installedVers} is installed."
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
    printf '%s\n' "${appName} does not need to be updated"
    exit 0
  else
    printf '%s\n' "Updating ${appName} to v${currentVers}"
  fi
else
  printf '%s\n' "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  SHAResult=$(printf '%s' "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 256 -c 2>/dev/null)
  case "${SHAResult}" in
    *OK)
      printf '%s\n' "SHA hash has successfully verifed."
      ;;

    *FAILED)
      printf '%s\n' "SHA hash has failed verification"
      exit 1
      ;;

    *)
      printf '%s\n' "An unknown error has occured."
      exit 1
      ;;
  esac
  if ! installResult=$(/usr/sbin/installer -pkg /tmp/"${FILE}" -target / 2>&1); then
    printf '%s\n' "An error occurred installing ${FILE}:"
    printf '%s\n' "${installResult}"
  else
    printf '%s\n' "Successfully installed ${FILE}"
  fi
  /bin/rm /tmp/"${FILE}"
  /bin/rm /tmp/checksum.md5
fi
