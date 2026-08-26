#!/bin/sh

# official ffmpeg binaries require rosetta

appInstallPath="/usr/local/bin"
bundleName="ffserver"
appName="${bundleName}"
if ! /usr/sbin/pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
  printf 'Rosetta 2 not installed. Can not continue\n'
  exit 1
fi
installedVers=$("${appInstallPath}"/"${bundleName}" -version | awk '{print $3}' | head -n 1 | awk -F "-" '{print $1}')

jsonData=$(/usr/bin/curl -s "https://evermeet.cx/ffmpeg/info/ffserver/release")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 22 ]; then
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .version)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/jq -r .download.zip.url)
else
  currentVers=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract version raw -o - -)
  downloadURL=$(printf '%s' "${jsonData}" | /usr/bin/plutil -extract download.zip.url raw -o - -)
fi
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
  /bin/rm -rf "${appInstallPath:?}"/"${bundleName}" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}"
  /bin/rm /tmp/"${FILE}"
fi
