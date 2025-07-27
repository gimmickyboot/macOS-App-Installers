#!/bin/sh

appInstallPath="/Library/Internet Plug-Ins"
bundleName="JavaAppletPlugin.plugin"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}"/Contents/Info.plist 2>/dev/null | /usr/bin/grep jpi-version | /usr/bin/sed -e 's/[^0-9_.]//g' -e 's/_/./' 2>/dev/null)

case $(uname -m) in
  arm64)
    URL="https://javadl-esd-secure.oracle.com/update/mac/map-mac-aarch64-1.8.0.xml"
    ;;

  x86_64)
    URL="https://javadl-esd-secure.oracle.com/update/mac/map-mac-1.8.0.xml"
    ;;

  *)
    /bin/echo "Unknow architecture. Exiting"
    exit 1
    ;;
esac
TMPURL=$(/usr/bin/curl -s "${URL}" | /usr/bin/xmllint --xpath 'string(//url[1]/text())' -)
downloadURL=$(/usr/bin/curl -s "${TMPURL}" | /usr/bin/xmllint --xpath 'string(//rss/channel/item/enclosure/@url)' -)
currentVers=$(/bin/echo "${downloadURL}" | /usr/bin/cut -d "/" -f 7 - | /usr/bin/awk -F "-" '{print $1}' | /usr/bin/sed 's/_/./')
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
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
    /bin/echo "${bundleName} needs to be updated"
  fi
else
  /bin/echo "Installing ${bundleName}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec /usr/sbin/installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
