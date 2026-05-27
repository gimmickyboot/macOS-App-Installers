#!/bin/sh

appInstallPath="/Applications"
bundleName="Gemini"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

jSON=$(/usr/bin/curl -s -X POST "https://update.googleapis.com/service/update2/json" --data-raw '{"request":{"@updater":"GoogleUpdater","domainjoined":true,"protocol":"4.0","dlpref":"cacheable","dedup":"cr","os":{"platform":"MacOSX","version":"26.0.0","arch":"arm64"},"@os":"mac","arch":"arm64","acceptformat":"crx3,download,puff,run,xz,zucc","apps":[{"ap":"m1-prod","enabled":true,"version":"1.00.0.000","updatecheck":{},"appid":"com.google.GeminiMacOS"}]}}' | /usr/bin/tail -c +6)
if $(sw_vers -buildVersion | /usr/bin/cut -c 1-2 -) -ge 24; then
  currentVers=$(printf '%s' "${jSON}" | /usr/bin/jq -r '.response.apps[0].updatecheck.nextversion')
else
  currentVers=$(printf '%s' "${jSON}" | /usr/bin/plutil -extract response.apps.0.updatecheck.nextversion raw -o - -)
fi
downloadURL="https://dl.google.com/release2/j33ro/release/Gemini.dmg"
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
