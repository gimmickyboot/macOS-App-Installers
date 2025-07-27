#!/bin/sh

appInstallPath="/Applications"
bundleName="DisplayLink Manager"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

URL="https://www.synaptics.com"
currentVers=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release" | /usr/bin/head -n 1 | /usr/bin/sed -n 's/.*Release: \([^ ]*\).*/\1/p')
releaseDate=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release Notes" | /usr/bin/grep "${currentVers}" | /usr/bin/cut -d \" -f 2 - | rev | /usr/bin/cut -d "/" -f 2 - | rev)
downloadURL="${URL}/sites/default/files/exe_files/${releaseDate}/DisplayLink%20Manager%20Graphics%20Connectivity${currentVers}-EXE.pkg"
FILE=${downloadURL##*/}
LSEURL="https://www.displaylink.com/downloads/macos_extension"
TMPLSEURL=$(/usr/bin/curl -sI "${LSEURL}" | /usr/bin/grep -i "^Location" | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
LSEFILE=${TMPLSEURL##*/}

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
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${TMPLSEURL}" -o /tmp/"${LSEFILE}"; then
  /usr/sbin/installer -pkg /tmp/"${LSEFILE}" -target /
  /bin/rm /tmp/"${LSEFILE}"
fi
