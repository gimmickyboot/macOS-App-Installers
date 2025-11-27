#!/bin/sh

appInstallPath="/Applications"
bundleName="Citrix Workspace"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CitrixVersionString 2>/dev/null)

URL="https://www.citrix.com/downloads/workspace-app/mac/workspace-app-for-mac-latest.html"
currentVers=$(/usr/bin/curl -s "${URL}" -H sec-ch-ua-platform: "macOS" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | /usr/bin/xmllint --html --xpath 'string(//p[contains(., "Version")])' 2> /dev/null - | /usr/bin/awk '{print $2}')
tempDownloadURL=$(/usr/bin/curl -s "${URL}#ctx-dl-eula-external" -H sec-ch-ua-platform: "macOS" -H user-agent:" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" | /usr/bin/xmllint --html --xpath "string(//a[contains(@rel, 'downloads.citrix.com')]/@rel)" 2> /dev/null -)
downloadURL="http:${tempDownloadURL}"
FILE="CitrixWorkspaceApp.dmg"

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
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec /usr/sbin/installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
