#!/bin/sh

appInstallPath="/Library/KeyAccess"
bundleName="KeyAccess"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

htmlData=$(/usr/bin/curl -s "https://solutions.teamdynamix.com/TDClient/1965/Portal/KB/Article/169236/Current-ITAM-Downloads")
currentVers=$(printf '%s' "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep -A1 "Minor Version" | /usr/bin/tail -n 1 | /usr/bin/sed 's/<\/p//' | /usr/bin/xargs)
downloadURL=$(printf '%s' "${htmlData}" | /usr/bin/tr '>' '\n' | /usr/bin/grep pkg | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
FILE=${downloadURL##*/}
SHAHash=$(printf '%s' "${htmlData}" | /usr/bin/grep -A1 ksp-client.pkg | /usr/bin/xmllint --html --xpath 'string(//a[contains(@href,"ksp-client.pkg")]/span[contains(.,"sha256")])' - | /usr/bin/awk '{print $2}')

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
fi
