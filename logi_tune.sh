#!/bin/sh

# requires /usr/bin/jq

appInstallPath="/Applications"
bundleName="Logi Tune"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL="https://software.vc.logitech.com/downloads/tune/LogiTuneInstaller.dmg"
FILE=${downloadURL##*/}
pageURL=$(/usr/bin/curl -s "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | /usr/lbin/jq -r '.articles | map(select(.name == "Logi Tune")) | .[0] | .html_url')
currentVers=$(/usr/bin/curl -s "${pageURL}" | /usr/bin/grep "Software Version" | /usr/bin/head -n 1 | /usr/bin/sed 's/[^0-9.]//g')

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
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/tar zxf "${TMPDIR}"/LogiTuneInstaller.app/Contents/Resources/Applications/LogiTune.tgz -C "${appInstallPath}"/
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  cd "${TMPDIR}"/LogiTuneInstaller.app/Contents/Resources || exit
  sh application-scripts/postinstall
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
