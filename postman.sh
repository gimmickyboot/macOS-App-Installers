#!/bin/sh

appInstallPath="/Applications"
bundleName="Postman"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

postmanJson=$(/usr/bin/curl -s "https://www.postman.com/mkapi/release.json")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  currentMajVers=$(printf '%s' "${postmanJson}" | /usr/bin/jq -r .latestVersion)
  currentVers=$(printf '%s' "${postmanJson}" | /usr/bin/jq -r ".${currentMajVers}[0].version")
else
  currentMajVers=$(printf '%s' "${postmanJson}" | /usr/bin/plutil -extract latestVersion raw -o - -)
  currentVers=$(printf '%s' "${postmanJson}" | /usr/bin/plutil -extract "${currentMajVers}".0.version raw -o - -)
fi
case "$(uname -m)" in
  arm64)
    downloadURL="https://dl.pstmn.io/download/latest/osx_arm64"
    ;;

  x86_64)
    downloadURL="https://dl.pstmn.io/download/latest/osx_64"
    ;;

  *)
    /bin/echo "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
FILE=$(/usr/bin/curl -sL --head "${downloadURL}" | /usr/bin/grep content-disposition | /usr/bin/awk -F "=" '{print $2}' | tr -d '\r')

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${appName} v${installedVers} is installed."
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
    /bin/echo "${appName} does not need to be updated"
    exit 0
  else
    /bin/echo "Updating ${appName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
