#!/bin/sh

downloadURL=""  # get this from within your Avid account

appInstallPath="/Applications/Avid Media Composer"
bundleName="AvidMediaComposer"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | /usr/bin/xmllint --html --xpath '//*/tr[2]/td[2]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
if [ ! "${currentVers}" ] || [ "${currentVers}" = "N/A" ]; then
  currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | /usr/bin/xmllint --html --xpath '//*/tr[2]/td[1]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
  case "${currentVers}" in
    *.0)
      /bin/echo "Version ends in .0. Nothing to do"
      ;;

    *)
      currentVers="${currentVers}.0"
      ;;
  esac
fi

FILE=${downloadURL##*/}

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
