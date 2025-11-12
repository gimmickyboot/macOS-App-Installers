#!/bin/sh

appInstallPath="/Library/Application Support/GPGTools"
bundleName="GPG Tools"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/version.plist CFBundleShortVersionString 2>/dev/null)

downloadURL=$(/usr/bin/curl -Ls "https://gpgtools.org" | /usr/bin/grep dmg | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - 2>/dev/null)
currentVers=$(/bin/echo ${downloadURL}| /usr/bin/cut -d "/" -f 4- - | /usr/bin/grep -oE 'GPG_Suite-[0-9]+(\.[0-9]+)*' | /usr/bin/sed 's/GPG_Suite-//')
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "v${installedVers} of ${bundleName} is installed."
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
  /bin/echo "Installing v${currentVers} of ${bundleName}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
