#!/bin/sh

appInstallPath="/Applications"
bundleName="ChatGPT"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

case $(uname -m) in
  arm64)
    printf '%s\n' "Apple Silicon detected. Continuing..."
    ;;

  x86_64)
    printf '%s\n' "Intel detected. Can not continue.
App requires Apple Silicon."
    exit 1
    ;;

  *)
    printf '%s\n' "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac

xmlData=$(/usr/bin/curl -s https://persistent.oaistatic.com/codex-app-prod/appcast.xml)
currentVers=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/title/text()' - | /usr/bin/head -n 1)
downloadURL=$(printf '%s' "${xmlData}" | /usr/bin/xmllint --xpath '//rss/channel/item/enclosure/@url' - | /usr/bin/head -n 1 | /usr/bin/cut -d \" -f 2 - -)
FILE=${downloadURL##*/}

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
